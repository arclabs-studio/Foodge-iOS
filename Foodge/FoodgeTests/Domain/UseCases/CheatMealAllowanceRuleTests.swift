//
//  CheatMealAllowanceRuleTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The allowance rule (D112), pinned at both band edges, on a negative allowance, and on every
/// named unavailable reason.
///
/// Every expectation is arithmetic done by hand against a fixed maintenance of **1000 kcal**
/// (800 resting + 200 active), so the share is the intake read backwards: intake 650 leaves 350,
/// a share of exactly 0.35; intake 800 leaves 200, exactly 0.20. Both edges belong to the higher
/// band. The suite never calls the rule to check the rule.
///
/// The "replaces, never adds" rule has no test here on purpose: `DailyIntake` is an enum, so a
/// caller cannot hold a Health total and an estimate at once, and a test of that would be testing
/// the compiler.
@Suite("Cheat meal allowance rule", .tags(.unit, .domain, .critical))
struct CheatMealAllowanceRuleTests {

    // MARK: - Fixtures

    private static let restingKilocalories = 800.0
    private static let activeKilocalories = 200.0
    private static let maintenanceKilocalories = 1000.0

    private let window = DateInterval(
        start: TestCalendar.date(2026, 9, 15),
        end: TestCalendar.date(2026, 9, 15, 19, 30)
    )

    private func makeAggregate(_ kilocalories: Double, window: DateInterval) -> EnergyAggregate {
        EnergyAggregate(
            kilocalories: kilocalories,
            provenance: Provenance(sourceNames: ["Test"], readAt: window.end, window: window)
        )
    }

    /// A request whose maintenance is exactly 1000 kcal, with the intake left to the caller.
    private func makeRequest(
        active: EnergyAggregate? = nil,
        resting: RestingEnergy? = nil,
        intake: DailyIntake?,
        window: DateInterval? = nil
    ) -> AllowanceRequest {
        let window = window ?? self.window
        return AllowanceRequest(
            activeEnergy: active ?? makeAggregate(Self.activeKilocalories, window: window),
            resting: resting ?? .recorded(makeAggregate(Self.restingKilocalories, window: window)),
            intake: intake,
            window: window
        )
    }

    private func makeRecordedIntake(_ kilocalories: Double, window: DateInterval? = nil) -> DailyIntake {
        .recorded(makeAggregate(kilocalories, window: window ?? self.window))
    }

    private func allowance(intake kilocalories: Double) throws -> EnergyAllowance {
        try #require(
            CheatMealAllowanceRule
                .allowance(makeRequest(intake: makeRecordedIntake(kilocalories)))
                .allowanceValue
        )
    }

    private func reason(of outcome: AllowanceOutcome) throws -> AllowanceUnavailableReason {
        try #require(outcome.unavailableReason)
    }

    // MARK: - The arithmetic

    @Test("Maintenance is resting plus active, and the allowance is maintenance minus intake")
    func theComponentsAreKeptSeparateAndCombinedOnce() throws {
        // Given 800 kcal resting, 200 active and 650 eaten
        // When the allowance is computed
        let allowance = try allowance(intake: 650)

        // Then each component is reported as it came in, and combined exactly once
        #expect(allowance.restingKilocalories == 800)
        #expect(allowance.activeKilocalories == 200)
        #expect(allowance.intakeKilocalories == 650)
        #expect(allowance.maintenanceKilocalories == 1000)
        #expect(allowance.allowanceKilocalories == 350)
        #expect(allowance.share.isApproximately(350.0 / 1000.0))
        #expect(allowance.window == window)
        #expect(allowance.restingIsEstimated == false)
        #expect(allowance.intakeIsEstimated == false)
    }

    // MARK: - The band edges

    @Test("A share of exactly 0.35 is a treat")
    func theTreatEdgeBelongsToTreat() throws {
        // Given an intake that leaves exactly 35% of maintenance
        let allowance = try allowance(intake: 650)

        // Then the share is the boundary itself, and the boundary is a treat
        #expect(allowance.share.isApproximately(0.35))
        #expect(CheatMealAllowanceRule.category(forShare: allowance.share) == .treat)
    }

    @Test("A share a single kilocalorie below 0.35 is balanced")
    func justBelowTheTreatEdgeIsBalanced() throws {
        // Given one kilocalorie more eaten than the treat edge allows
        let allowance = try allowance(intake: 651)

        // Then the share slipped below the edge and the band with it
        #expect(allowance.share < 0.35)
        #expect(CheatMealAllowanceRule.category(forShare: allowance.share) == .balanced)
    }

    @Test("A share of exactly 0.20 is balanced")
    func theBalancedEdgeBelongsToBalanced() throws {
        // Given an intake that leaves exactly 20% of maintenance
        let allowance = try allowance(intake: 800)

        // Then the lower edge belongs to the higher band, as the plan's convention states
        #expect(allowance.share.isApproximately(0.20))
        #expect(CheatMealAllowanceRule.category(forShare: allowance.share) == .balanced)
    }

    @Test("A share a single kilocalorie below 0.20 is light")
    func justBelowTheBalancedEdgeIsLight() throws {
        // Given one kilocalorie more eaten than the balanced edge allows
        let allowance = try allowance(intake: 801)

        // Then it is a light night
        #expect(allowance.share < 0.20)
        #expect(CheatMealAllowanceRule.category(forShare: allowance.share) == .light)
    }

    // MARK: - A spent allowance

    @Test("Eating more than maintenance returns a negative allowance rather than a floor of zero")
    func aSpentAllowanceIsNegativeAndStillRuled() throws {
        // Given 1300 kcal eaten against 1000 kcal of maintenance
        let allowance = try allowance(intake: 1300)

        // Then the allowance is negative, not floored, and the share is negative with it
        #expect(allowance.allowanceKilocalories == -300)
        #expect(allowance.share.isApproximately(-0.3))

        // And the rule still rules: a light dinner, never a refusal to suggest one
        #expect(CheatMealAllowanceRule.category(forShare: allowance.share) == .light)
    }

    // MARK: - Estimated components

    @Test("An estimated resting figure is used and labelled as an estimate")
    func anEstimatedRestingFigureIsMarked() throws {
        // Given no basal samples, and a Mifflin estimate built from body basics
        let body = try #require(
            BodyBasics(sex: .male, ageYears: 35, heightCentimetres: 175, weightKilograms: 70)
        )
        let request = makeRequest(
            resting: .estimated(kilocalories: 800, body: body, window: window),
            intake: makeRecordedIntake(650)
        )

        // When the allowance is computed
        let outcome = CheatMealAllowanceRule.allowance(request)

        // Then the arithmetic is unchanged and the provenance is readable at the call site
        let allowance = try #require(outcome.allowanceValue)
        #expect(allowance.restingKilocalories == 800)
        #expect(allowance.restingIsEstimated)
        #expect(allowance.intakeIsEstimated == false)
    }

    @Test("An answered questionnaire supplies intake and is labelled as an estimate")
    func anAnsweredQuestionnaireSuppliesIntake() throws {
        // Given no dietary energy, and a normal breakfast plus a heavy lunch
        let request = makeRequest(
            intake: .estimated(IntakeQuestionnaire(breakfast: .normal, lunch: .heavy))
        )

        // When the allowance is computed
        let outcome = CheatMealAllowanceRule.allowance(request)

        // Then the questionnaire's own total is the intake, and it says it was estimated
        let allowance = try #require(outcome.allowanceValue)
        #expect(allowance.intakeKilocalories == 400 + 1000)
        #expect(allowance.allowanceKilocalories == 1000 - 1400)
        #expect(allowance.intakeIsEstimated)
    }

    @Test("A questionnaire of skipped meals is an answered zero and still produces an allowance")
    func aSkippedDayIsAnAnsweredZero() throws {
        // Given a user who says they skipped every meal
        let request = makeRequest(
            intake: .estimated(
                IntakeQuestionnaire(breakfast: .skipped, lunch: .skipped, snacks: .skipped)
            )
        )

        // When the allowance is computed
        let outcome = CheatMealAllowanceRule.allowance(request)

        // Then the whole of maintenance is available — an answered zero is a reading
        let allowance = try #require(outcome.allowanceValue)
        #expect(allowance.intakeKilocalories == 0)
        #expect(allowance.allowanceKilocalories == 1000)
        #expect(allowance.share.isApproximately(1))
    }

    @Test("An untouched questionnaire is no basis at all")
    func anUnansweredQuestionnaireIsNotAZero() throws {
        // Given the same request with a questionnaire nobody answered
        let request = makeRequest(intake: .estimated(.unanswered))

        // When the allowance is attempted
        let outcome = CheatMealAllowanceRule.allowance(request)

        // Then it is refused by name rather than treated as having eaten nothing — the distinction
        // that keeps "missing stays missing" true
        #expect(try reason(of: outcome) == .noIntakeBasis)
    }

    // MARK: - Every unavailable reason

    @Test("No readable active energy is refused by name")
    func missingActiveEnergyIsNamed() throws {
        let request = AllowanceRequest(
            activeEnergy: nil,
            resting: .recorded(makeAggregate(Self.restingKilocalories, window: window)),
            intake: makeRecordedIntake(650),
            window: window
        )

        #expect(try reason(of: CheatMealAllowanceRule.allowance(request)) == .missingActiveEnergy)
    }

    @Test("No resting basis is refused by name")
    func missingRestingBasisIsNamed() throws {
        let request = AllowanceRequest(
            activeEnergy: makeAggregate(Self.activeKilocalories, window: window),
            resting: nil,
            intake: makeRecordedIntake(650),
            window: window
        )

        #expect(try reason(of: CheatMealAllowanceRule.allowance(request)) == .noRestingBasis)
    }

    @Test("No intake basis is refused by name")
    func missingIntakeIsNamed() throws {
        #expect(try reason(of: CheatMealAllowanceRule.allowance(makeRequest(intake: nil))) == .noIntakeBasis)
    }

    @Test("A maintenance of zero is refused rather than divided by")
    func nonPositiveMaintenanceIsNamed() throws {
        // Given a watch that recorded a genuine zero for both resting and active energy
        let request = makeRequest(
            active: makeAggregate(0, window: window),
            resting: .recorded(makeAggregate(0, window: window)),
            intake: makeRecordedIntake(0)
        )

        // Then the share is never computed, because a share of zero is meaningless
        #expect(try reason(of: CheatMealAllowanceRule.allowance(request)) == .nonPositiveMaintenance)
    }

    @Test("Less than ninety minutes of the day is too little to rule on")
    func aShortWindowIsNamed() throws {
        // Given an evaluation at 01:29, one minute inside the guard
        let shortWindow = DateInterval(
            start: TestCalendar.date(2026, 9, 15),
            end: TestCalendar.date(2026, 9, 15, 1, 29)
        )
        let request = makeRequest(
            intake: makeRecordedIntake(10, window: shortWindow),
            window: shortWindow
        )

        #expect(try reason(of: CheatMealAllowanceRule.allowance(request)) == .windowTooShort)
    }

    @Test("Ninety minutes exactly is long enough")
    func theWindowEdgeIsAccepted() throws {
        // Given an evaluation at 01:30 exactly
        let edgeWindow = DateInterval(
            start: TestCalendar.date(2026, 9, 15),
            end: TestCalendar.date(2026, 9, 15, 1, 30)
        )
        let request = makeRequest(
            intake: makeRecordedIntake(650, window: edgeWindow),
            window: edgeWindow
        )

        // Then the boundary itself is allowed, like every other boundary in this rule
        #expect(CheatMealAllowanceRule.allowance(request).allowanceValue != nil)
    }

    @Test("A component covering a different span is refused, never subtracted")
    func aMismatchedWindowIsNamed() throws {
        // Given an active-energy reading cut at a different time from the evaluation window
        let otherWindow = DateInterval(
            start: TestCalendar.date(2026, 9, 15),
            end: TestCalendar.date(2026, 9, 15, 18, 0)
        )

        let mismatchedActive = makeRequest(
            active: makeAggregate(Self.activeKilocalories, window: otherWindow),
            intake: makeRecordedIntake(650)
        )
        let mismatchedResting = makeRequest(
            resting: .recorded(makeAggregate(Self.restingKilocalories, window: otherWindow)),
            intake: makeRecordedIntake(650)
        )
        let mismatchedIntake = makeRequest(intake: makeRecordedIntake(650, window: otherWindow))

        // Then each one is refused by name: kcal sums are duration-dependent, so two differently
        // sized periods must never be subtracted as if comparable (D47)
        #expect(try reason(of: CheatMealAllowanceRule.allowance(mismatchedActive)) == .windowMismatch)
        #expect(try reason(of: CheatMealAllowanceRule.allowance(mismatchedResting)) == .windowMismatch)
        #expect(try reason(of: CheatMealAllowanceRule.allowance(mismatchedIntake)) == .windowMismatch)
    }

    @Test("An estimated component matches the evaluation window by construction")
    func anEstimatedComponentNeedsNoWindowOfItsOwn() throws {
        // Given an estimated resting figure carrying the request's own window, and a questionnaire,
        // which carries no window at all
        let body = try #require(
            BodyBasics(sex: .female, ageYears: 30, heightCentimetres: 165, weightKilograms: 60)
        )
        let request = makeRequest(
            resting: .estimated(kilocalories: 800, body: body, window: window),
            intake: .estimated(IntakeQuestionnaire(lunch: .light))
        )

        // Then the window check passes rather than firing on an absent window
        #expect(CheatMealAllowanceRule.allowance(request).allowanceValue != nil)
    }

    // MARK: - Guard order

    @Test("A request that breaks two preconditions always reports the same one")
    func theGuardOrderIsFixed() throws {
        // Given a window too short *and* no readable active energy at all
        let shortWindow = DateInterval(
            start: TestCalendar.date(2026, 9, 15),
            end: TestCalendar.date(2026, 9, 15, 0, 30)
        )
        let request = AllowanceRequest(
            activeEnergy: nil,
            resting: nil,
            intake: nil,
            window: shortWindow
        )

        // Then the documented first guard is the one that reports, so the reason is deterministic
        #expect(try reason(of: CheatMealAllowanceRule.allowance(request)) == .windowTooShort)
    }

    // MARK: - The self-report fallback

    @Test("The user's own account decides when there is no number to use", arguments: [
        (SelfReportedActivity.more, DinnerCategory.treat, ReasonCode.selfReportedMore),
        (.usual, .balanced, .selfReportedUsual),
        (.less, .light, .selfReportedLess),
    ])
    func aSelfReportDecidesWithoutInventingAFigure(
        report: SelfReportedActivity,
        category: DinnerCategory,
        reason: ReasonCode
    ) {
        // When the user reports their day themselves
        let decision = CheatMealAllowanceRule.decide(selfReport: report)

        // Then the category follows the report, the basis says so, and nothing is provisional
        #expect(decision.category == category)
        #expect(decision.basis == .selfReported(report))
        #expect(decision.reasonCodes == [reason])
        #expect(decision.isProvisional == false)
        #expect(decision.ruleVersion == "2.0.0")
    }

    @Test("A skipped check-in is a provisional balanced, and says so")
    func aSkippedCheckInIsProvisional() {
        // When nothing at all is known
        let decision = CheatMealAllowanceRule.decide(selfReport: nil)

        // Then the verdict is balanced, flagged provisional, and carries the reason
        #expect(decision.category == .balanced)
        #expect(decision.basis == .provisional)
        #expect(decision.reasonCodes == [.checkInSkipped])
        #expect(decision.isProvisional)
    }
}

/// Reading one side of the outcome as an optional, so a suite can say `try #require(...)` and keep
/// the assertion on one line — the same convenience `CategoryOutcome.decision` provides.
extension AllowanceOutcome {
    fileprivate var allowanceValue: EnergyAllowance? {
        if case let .allowance(allowance) = self { allowance } else { nil }
    }

    fileprivate var unavailableReason: AllowanceUnavailableReason? {
        if case let .unavailable(reason) = self { reason } else { nil }
    }
}
