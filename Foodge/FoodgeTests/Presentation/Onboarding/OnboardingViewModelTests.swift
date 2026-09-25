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
        snapshot: EvidenceSnapshot = SyntheticScenarios.modestAllowance.snapshot,
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
        missing: Set<HealthKind> = []
    ) -> EvidenceSnapshot {
        EvidenceSnapshot(
            evaluatedAt: SyntheticScenarios.evaluationDate,
            timeZoneIdentifier: SyntheticScenarios.timeZoneIdentifier,
            today: today,
            availability: .readable(missing: missing)
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
            missing: Set(HealthKind.allCases)
        )
        let sut = makeSUT(snapshot: snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then there is still no readable data. `today != .empty` is true here — `.empty` has a
        // nil workout list and this one has an empty array — so that shortcut would report a
        // connected Health store to someone who has recorded nothing.
        #expect(sut.viewModel.healthState == .noReadableData)
    }

    @Test("A connected read reports which kinds came back empty")
    func connectingReportsTheKindsThatCameBackEmpty() async throws {
        // Given a day Health recorded everything but resting energy
        let sut = makeSUT(snapshot: SyntheticScenarios.estimatedResting.snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then the screen can say exactly what is missing — never that it was refused, which
        // HealthKit cannot tell an app
        let missing = try #require(sut.viewModel.healthState.missingKinds)
        #expect(missing == [.restingEnergy])
    }

    @Test("Nothing missing is still a connected state, and is not the same as not asking")
    func anEmptyMissingSetIsStillConnected() async throws {
        // Given a day Health recorded in full
        let sut = makeSUT(snapshot: SyntheticScenarios.modestAllowance.snapshot)

        // When Health is connected
        await sut.viewModel.connectHealth()

        // Then `missingKinds` is empty rather than `nil`: empty means "connected, nothing
        // missing", `nil` means the read has not happened
        let missing = try #require(sut.viewModel.healthState.missingKinds)
        #expect(missing.isEmpty)
    }

    // MARK: - Body basics

    @Test("All four figures produce a body; three do not")
    func bodyBasicsNeedAllFourFigures() {
        // Given a user who has answered everything but their weight
        let sut = makeSUT()
        sut.viewModel.bodySex = .male
        sut.viewModel.ageText = "35"
        sut.viewModel.heightText = "175"

        // Then there is no body yet, and nothing is recorded on the draft
        #expect(sut.viewModel.bodyBasicsFromInputs == nil)
        sut.viewModel.applyBodyBasics()
        #expect(sut.viewModel.draft.bodyBasics == nil)

        // When the last figure arrives
        sut.viewModel.weightText = "70"
        sut.viewModel.applyBodyBasics()

        // Then the whole body is recorded at once
        #expect(sut.viewModel.draft.bodyBasics?.weightKilograms == 70)
        #expect(sut.viewModel.draft.bodyBasics?.ageYears == 35)
    }

    @Test("An implausible figure records no body rather than a clamped one")
    func anImplausibleFigureRecordsNoBody() {
        // Given a height typed in inches by mistake
        let sut = makeSUT()
        sut.viewModel.bodySex = .female
        sut.viewModel.ageText = "35"
        sut.viewModel.heightText = "69"
        sut.viewModel.weightText = "62"

        // When the step is left
        sut.viewModel.applyBodyBasics()

        // Then no estimate is possible, which is the honest answer — never 69 cm clamped to 120
        #expect(sut.viewModel.draft.bodyBasics == nil)
        #expect(sut.viewModel.hasStartedBodyBasics)
    }

    @Test("An untouched body-basics step is not a half-answered one")
    func anUntouchedStepReportsItself() {
        let sut = makeSUT()

        #expect(sut.viewModel.hasStartedBodyBasics == false)
        #expect(sut.viewModel.bodyBasicsFromInputs == nil)
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
        #expect(sut.viewModel.path == [.bodyBasics])
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
        sut.viewModel.bodySex = .male
        sut.viewModel.ageText = "41"
        sut.viewModel.heightText = "181"
        sut.viewModel.weightText = "78"
        sut.viewModel.applyBodyBasics()
        sut.viewModel.toggleExclusion(Ingredient.mushroom.id)

        // When they save and finish
        await sut.viewModel.finish()

        // Then exactly one write happened, carrying all of it
        let saved = try #require(await sut.store.savedDrafts.first)
        #expect(await sut.store.savedDrafts.count == 1)
        #expect(saved.dietProfile == .pescatarian)
        #expect(saved.dinnerRoutine == .relaxed)
        #expect(saved.favouriteFamilies == [.tacos, .pasta])
        #expect(saved.bodyBasics?.sex == .male)
        #expect(saved.bodyBasics?.ageYears == 41)
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
