//
//  OnboardingViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Onboarding is where Foodge decides what it is allowed to say about someone's Health data.
///
/// Every test here is about a claim the app must not make: that an absence is a denial, that a
/// failed request is an absence, that a missing day is a zero, or that a failed save was a save.
@Suite("Onboarding view model", .tags(.unit, .critical))
@MainActor
struct OnboardingViewModelTests {
    private struct SUT {
        let viewModel: OnboardingViewModel
        let authorization: FixtureHealthAuthorization
        let evidence: FixtureEvidenceProvider
        let store: FixturePreferencesStore
    }

    private func makeSUT(
        isHealthDataAvailable: Bool = true,
        authorizationFailure: (any Error)? = nil,
        snapshot: EvidenceSnapshot = SyntheticScenarios.typicalDay.snapshot,
        evidenceFailure: (any Error)? = nil,
        storeFailure: (any Error)? = nil,
        clock: FixedClock = SyntheticScenarios.clock
    ) -> SUT {
        let authorization = FixtureHealthAuthorization(
            isHealthDataAvailable: isHealthDataAvailable,
            failure: authorizationFailure
        )
        let evidence = evidenceFailure.map(FixtureEvidenceProvider.init(failure:))
            ?? FixtureEvidenceProvider(snapshot: snapshot)
        let store = FixturePreferencesStore(failure: storeFailure)

        return SUT(
            viewModel: OnboardingViewModel(
                authorization: authorization,
                evidence: evidence,
                store: store,
                clock: clock
            ),
            authorization: authorization,
            evidence: evidence,
            store: store
        )
    }

    /// A snapshot with exactly the readings a test wants, for the cases no scenario covers.
    private func makeSnapshot(
        today: HealthAggregates,
        history: [DailyActivityObservation]
    ) -> EvidenceSnapshot {
        EvidenceSnapshot(
            evaluatedAt: SyntheticScenarios.evaluationDate,
            timeZoneIdentifier: SyntheticScenarios.timeZoneIdentifier,
            today: today,
            history: history,
            availability: .readable(missing: [])
        )
    }

    // MARK: - Connecting to Health

    @Test("A device without Health is told so, and is asked for nothing")
    func anUnavailableDeviceIsNeverQueried() async {
        // Given a device that has no Health data at all
        let sut = makeSUT(isHealthDataAvailable: false)

        // When the user taps Connect
        await sut.viewModel.connectHealth()

        // Then the state says unavailable — the one refusal that is provable — and neither the
        // authorization sheet nor the evidence reader was touched
        #expect(sut.viewModel.healthState == .unavailable)
        #expect(await sut.authorization.requestCount == 0)
        #expect(await sut.evidence.callCount == 0)
    }

    @Test(
        "An authorization failure is reported as a failure, never as an absence",
        arguments: [
            (
                FixtureFailure("sheet could not present") as any Error,
                OnboardingViewModel.HealthState.requestFailed
            ),
            (
                FoodgeError.healthUnavailable as any Error,
                OnboardingViewModel.HealthState.unavailable
            )
        ]
    )
    func authorizationFailuresAreMappedHonestly(
        failure: any Error,
        expected: OnboardingViewModel.HealthState
    ) async {
        // Given an authorization request that will not complete
        let sut = makeSUT(authorizationFailure: failure)

        // When the user taps Connect
        await sut.viewModel.connectHealth()

        // Then the state distinguishes "the request failed" from "there is no data": claiming
        // an absence the app never observed is the same lie as claiming a denial
        #expect(sut.viewModel.healthState == expected)
        // And nothing was read, because there was never an authorized read to make
        #expect(await sut.evidence.callCount == 0)
    }

    @Test("A read that fails is a failed read, not an empty Health store")
    func anEvidenceReadFailureIsReportedAsAFailedRequest() async {
        // Given authorization that completes, and a read that then fails
        let sut = makeSUT(evidenceFailure: FixtureFailure("the read did not complete"))

        // When the user taps Connect
        await sut.viewModel.connectHealth()

        // Then the state says the attempt failed. `.noReadableData` would assert an absence
        // nothing ever observed — the read never returned at all — which is the same false
        // claim as saying permission was denied.
        #expect(sut.viewModel.healthState == .requestFailed)
        #expect(sut.viewModel.healthState != .noReadableData)
    }

    @Test("A cancelled read puts back the state the user last saw")
    func aCancelledReadDoesNotLeaveASpinnerOnScreen() async {
        // Given a read that is cancelled rather than failing
        let sut = makeSUT(evidenceFailure: CancellationError())

        // When the user taps Connect
        await sut.viewModel.connectHealth()

        // Then they are back where they started. Leaving `.requesting` would strand them on a
        // spinner that can never resolve, and `.requestFailed` would blame a failure on
        // someone who simply moved on.
        #expect(sut.viewModel.healthState == .idle)
    }

    @Test("A fully tracked fortnight becomes an active-energy pattern")
    func aTrackedFortnightProducesAnEnergyBaseline() async throws {
        // Given fourteen recorded days whose energy median is 400 kcal by hand
        let sut = makeSUT(snapshot: SyntheticScenarios.typicalDay.snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then the pattern is built from active energy over all fourteen days
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        let baseline = try #require(try? summary.pattern.get())
        #expect(baseline.metric == .activeEnergy)
        #expect(baseline.median == 400)
        #expect(baseline.observationCount == 14)
        #expect(summary.daysWithAnyReading == 14)
    }

    @Test("Eleven untracked days stay missing rather than becoming zeroes")
    func untrackedDaysAreNotCountedAsZero() async throws {
        // Given a fortnight where only three days recorded anything at all
        let snapshot = makeSnapshot(
            today: SyntheticScenarios.typicalDay.snapshot.today,
            history: SyntheticScenarios.observations(
                days: SyntheticScenarios.historyDays,
                energy: [410, 430, 390],
                steps: [8100, 8200, 8300]
            )
        )
        let sut = makeSUT(snapshot: snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then three observations are reported, not fourteen. Coercing the missing eleven to
        // zero would produce fourteen observations with a zero median, so the refusal would
        // come back as `.zeroMedian` and the count would be wrong in the user's face.
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        #expect(summary.pattern == .failure(.insufficientHistory(found: 3)))
        #expect(summary.daysWithAnyReading == 3)
        #expect(summary.daysConsidered == 14)
    }

    @Test("Steps carry the pattern when energy cannot")
    func stepsTakeOverWhenEnergyCannotCompare() async throws {
        // Given a fortnight with energy on three days only, but steps throughout
        let sut = makeSUT(snapshot: SyntheticScenarios.stepsFallback.snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then the comparison is made in steps. Reducing the history to energy before handing
        // it to the calculator would leave this user with no pattern at all.
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        let baseline = try #require(try? summary.pattern.get())
        #expect(baseline.metric == .steps)
        #expect(baseline.median == 8200)
        #expect(summary.daysWithAnyReading == 14)
    }

    @Test("Health with nothing in it says so, and does not pretend to be connected")
    func anEmptyHealthStoreIsReportedAsNoReadableData() async {
        // Given a Health store that returns nothing for any kind
        let sut = makeSUT(snapshot: SyntheticScenarios.noHealthData.snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then the state is the absence wording, never a connected summary over empty numbers
        #expect(sut.viewModel.healthState == .noReadableData)
    }

    @Test("An empty workout list is not a reading")
    func anEmptyWorkoutListDoesNotCountAsData() async {
        // Given today's readings that are all missing, with an empty — not absent — workout list
        let snapshot = makeSnapshot(
            today: HealthAggregates(
                activeEnergy: nil,
                restingEnergy: nil,
                steps: nil,
                sleep: nil,
                workouts: [],
                dietaryEnergy: nil
            ),
            history: []
        )
        let sut = makeSUT(snapshot: snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then there is still no readable data. `today != .empty` is true here — `.empty` has a
        // nil workout list and this one has an empty array — so that shortcut would report a
        // connected Health store to someone who has recorded nothing.
        #expect(sut.viewModel.healthState == .noReadableData)
    }

    @Test("Energy days and step days are both counted as recorded")
    func daysRecordedCountsEitherMetric() async throws {
        // Given three days recorded only in energy and five more recorded only in steps
        let days = SyntheticScenarios.historyDays
        let history = (0 ..< days.count).map { index in
            DailyActivityObservation(
                day: days[index],
                activeEnergyAtCutoff: index < 3 ? 410 : nil,
                stepsAtCutoff: (3 ..< 8).contains(index) ? 8200 : nil
            )
        }
        let sut = makeSUT(
            snapshot: makeSnapshot(today: SyntheticScenarios.typicalDay.snapshot.today, history: history)
        )

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then eight days recorded something, even though the calculator's own refusal counts
        // only the three energy days (D23). Telling this user "3 of 14 days" would understate
        // what Health actually holds — which is the whole reason the summary carries its own
        // count instead of reading `insufficientHistory(found:)`.
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        #expect(summary.daysWithAnyReading == 8)
        #expect(summary.pattern == .failure(.insufficientHistory(found: 3)))
    }

    // MARK: - The recorded days the user disowns

    @Test("Marking the days unrepresentative refuses the pattern and writes nothing")
    func markingUnrepresentativeRefusesThePatternWithoutSaving() async throws {
        // Given a connected, fully tracked fortnight
        let sut = makeSUT(snapshot: SyntheticScenarios.typicalDay.snapshot)
        await sut.viewModel.connectHealth()

        // When the user says these days do not reflect how they usually live
        sut.viewModel.markUnrepresentative(true)

        // Then the pattern is refused for that reason
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        #expect(summary.pattern == .failure(.markedUnrepresentative))
        #expect(sut.viewModel.draft.trackingRepresentative == false)
        // And nothing has been written: abandoning onboarding here must leave no trace
        #expect(await sut.store.savedDrafts.isEmpty)
    }

    @Test("Taking the mark back restores the pattern without re-reading Health")
    func unmarkingRestoresThePattern() async throws {
        // Given a fortnight the user has just disowned
        let sut = makeSUT(snapshot: SyntheticScenarios.typicalDay.snapshot)
        await sut.viewModel.connectHealth()
        sut.viewModel.markUnrepresentative(true)

        // When they change their mind
        sut.viewModel.markUnrepresentative(false)

        // Then the same 400 kcal pattern is back, from the retained snapshot rather than a
        // second read — discarding the snapshot on the first mark would lose it for good
        let summary = try #require(sut.viewModel.healthState.connectedSummary)
        let baseline = try #require(try? summary.pattern.get())
        #expect(baseline.median == 400)
        #expect(await sut.evidence.callCount == 1)
    }

    @Test("Disowning the days before connecting just records the choice")
    func markingUnrepresentativeWithoutASnapshotRecordsTheChoiceOnly() {
        // Given a user who has not connected Health at all
        let sut = makeSUT()

        // When they say their recorded days are not representative
        sut.viewModel.markUnrepresentative(true)

        // Then the choice is kept for the eventual save, and nothing pretends to be connected
        #expect(sut.viewModel.draft.trackingRepresentative == false)
        #expect(sut.viewModel.healthState == .idle)
    }

    @Test("Continuing without Health clears a failed attempt and moves on")
    func skippingHealthClearsTheFailureAndAdvances() async {
        // Given an authorization attempt that failed
        let sut = makeSUT(authorizationFailure: FixtureFailure())
        await sut.viewModel.connectHealth()
        #expect(sut.viewModel.healthState == .requestFailed)

        // When the user chooses to continue without Health
        sut.viewModel.skipHealth()

        // Then the failure is not left on screen behind them, and the flow advances
        #expect(sut.viewModel.healthState == .idle)
        #expect(sut.viewModel.path == [.preferences])
    }

    // MARK: - The injected clock

    @Test("Health is read at the injected instant, in the injected time zone")
    func theEvidenceReaderIsHandedTheInjectedClock() async {
        // Given a clock frozen at 19:30 on 18 September 2026 in Europe/Madrid, and a user who
        // has already chosen a diet
        let sut = makeSUT()
        sut.viewModel.draft.dietProfile = .vegan

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then the reader was handed that instant and that calendar. Any `Date()` or
        // `Calendar.current` in the view model puts a different value here, while every
        // state-based assertion in this suite would still pass.
        #expect(await sut.evidence.receivedDates == [SyntheticScenarios.evaluationDate])
        #expect(await sut.evidence.receivedCalendars.first?.timeZone.identifier == "Europe/Madrid")
        // And it was told what the user will eat, rather than the unrestricted default
        #expect(await sut.evidence.receivedConstraints.first?.profile == .vegan)
    }

    // MARK: - Finishing

    @Test("Finishing writes everything the user chose, once, stamped with the injected clock")
    func finishingWritesTheCompletedDraftExactlyOnce() async throws {
        // Given a user who has made every choice onboarding offers
        let sut = makeSUT()
        sut.viewModel.draft.dietProfile = .pescatarian
        sut.viewModel.draft.dinnerRoutine = .relaxed
        sut.viewModel.toggleFavourite(.tacos)
        sut.viewModel.toggleFavourite(.pasta)
        sut.viewModel.markUnrepresentative(true)
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)

        // When they save and finish
        await sut.viewModel.finish()

        // Then exactly one write happened, carrying all of it
        let saved = try #require(await sut.store.savedDrafts.first)
        #expect(await sut.store.savedDrafts.count == 1)
        #expect(saved.dietProfile == .pescatarian)
        #expect(saved.dinnerRoutine == .relaxed)
        #expect(saved.favouriteFamilies == [.tacos, .pasta])
        #expect(saved.trackingRepresentative == false)
        #expect(saved.excludedIngredientIDs == [Ingredient.mushroom.id])
        // Stamped from the injected clock, not from `Date()`
        #expect(saved.onboardingCompletedAt == SyntheticScenarios.evaluationDate)
        #expect(sut.viewModel.draft.onboardingCompletedAt == SyntheticScenarios.evaluationDate)
        #expect(sut.viewModel.didFinish)
    }

    @Test("Tapping a favourite a second time takes it off the list")
    func tappingAFavouriteTwiceRemovesIt() async throws {
        // Given two favourites chosen
        let sut = makeSUT()
        sut.viewModel.toggleFavourite(.tacos)
        sut.viewModel.toggleFavourite(.pasta)

        // When the first is tapped again
        sut.viewModel.toggleFavourite(.tacos)
        await sut.viewModel.finish()

        // Then only the second is saved, in the order it was chosen — an implementation that
        // only ever appends would save tacos twice and never let anyone change their mind
        let saved = try #require(await sut.store.savedDrafts.first)
        #expect(saved.favouriteFamilies == [.pasta])
    }

    // MARK: - Ingredient exclusions

    @Test("Toggling an ingredient excludes it")
    func togglingAnIngredientExcludesIt() {
        // Given a user with nothing excluded
        let sut = makeSUT()

        // When they exclude mushroom
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)

        // Then it is recorded as excluded
        #expect(sut.viewModel.draft.excludedIngredientIDs == [Ingredient.mushroom.id])
    }

    @Test("Toggling the same ingredient twice removes the exclusion, not appends it again")
    func togglingTwiceRemovesTheExclusion() {
        // Given an ingredient already excluded
        let sut = makeSUT()
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)

        // When it is toggled a second time
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)

        // Then nothing is excluded — a Set already prevents a literal duplicate, so this proves
        // the toggle actually removes rather than merely failing to add a second time
        #expect(sut.viewModel.draft.excludedIngredientIDs.isEmpty)
    }

    @Test("Finishing saves the excluded ingredient ids that were chosen")
    func finishingSavesExcludedIngredients() async throws {
        // Given two ingredients excluded
        let sut = makeSUT()
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)
        sut.viewModel.toggleExclusion(Ingredient.olive.id)

        // When the user saves and finishes
        await sut.viewModel.finish()

        // Then both are written
        let saved = try #require(await sut.store.savedDrafts.first)
        #expect(saved.excludedIngredientIDs == [Ingredient.mushroom.id, Ingredient.olive.id])
    }

    @Test("A failed save is never reported as a save")
    func aFailedSaveLeavesNothingClaimingOnboardingHappened() async {
        // Given a store that will refuse the write
        let sut = makeSUT(storeFailure: FoodgeError.saveFailed)

        // When the user saves and finishes
        await sut.viewModel.finish()

        // Then the failure is visible, and nothing anywhere claims onboarding completed
        #expect(sut.viewModel.saveState == .failed(.saveFailed))
        #expect(sut.viewModel.didFinish == false)
        #expect(sut.viewModel.draft.onboardingCompletedAt == nil)
        #expect(await sut.store.savedDrafts.isEmpty)
    }

    @Test("Retrying after a failed save completes, and writes only once")
    func retryingAfterAFailedSaveWritesOnce() async {
        // Given a save that failed
        let sut = makeSUT(storeFailure: FoodgeError.saveFailed)
        await sut.viewModel.finish()

        // When the store recovers and the user taps Save again
        await sut.store.stopFailing()
        await sut.viewModel.finish()

        // Then onboarding completes, with a single record rather than the wreckage of the
        // first attempt plus a second one
        #expect(sut.viewModel.didFinish)
        #expect(sut.viewModel.saveState == .editing)
        #expect(await sut.store.savedDrafts.count == 1)
    }
}
