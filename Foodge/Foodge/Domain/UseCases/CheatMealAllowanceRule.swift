//
//  CheatMealAllowanceRule.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// Everything one allowance attempt needs, bundled to keep the call site readable.
///
/// Every input is `Optional` and nothing coalesces to zero: a missing reading produces a **named**
/// reason, never a plausible-looking number (D111).
struct AllowanceRequest: Sendable {
    let activeEnergy: EnergyAggregate?
    let resting: RestingEnergy?
    let intake: DailyIntake?
    /// Local midnight up to the evaluation instant.
    let window: DateInterval

    init(
        activeEnergy: EnergyAggregate?,
        resting: RestingEnergy?,
        intake: DailyIntake?,
        window: DateInterval
    ) {
        self.activeEnergy = activeEnergy
        self.resting = resting
        self.intake = intake
        self.window = window
    }
}

/// Why today has no allowance figure.
///
/// Never thrown — an unavailable allowance is a correct consequence of missing data, the same
/// reasoning `DishSelectionOutcome.noMatch(blockingIngredientIDs:)` uses (D43). Each case is
/// separate so it has its own oracle in tests and its own sentence on screen.
enum AllowanceUnavailableReason: Hashable, Sendable {
    case missingActiveEnergy
    /// Neither `basalEnergyBurned` nor usable body basics.
    case noRestingBasis
    /// Neither `dietaryEnergy` nor an answered questionnaire.
    case noIntakeBasis
    /// A share of a zero or negative maintenance figure is meaningless.
    case nonPositiveMaintenance
    /// Too little of the day has passed for the arithmetic to mean anything.
    case windowTooShort
    /// A component covers a different span from the evaluation window.
    case windowMismatch

    /// A label that is safe to log: the rule that refused, never the figures it refused.
    var logLabel: String {
        switch self {
        case .missingActiveEnergy: "missingActiveEnergy"
        case .noRestingBasis: "noRestingBasis"
        case .noIntakeBasis: "noIntakeBasis"
        case .nonPositiveMaintenance: "nonPositiveMaintenance"
        case .windowTooShort: "windowTooShort"
        case .windowMismatch: "windowMismatch"
        }
    }
}

enum AllowanceOutcome: Hashable, Sendable {
    case allowance(EnergyAllowance)
    case unavailable(AllowanceUnavailableReason)
}

/// The verdict rule: today's energy allowance as a **share of maintenance**, banded into the three
/// dinner categories (D112).
///
/// `share >= treatShare` is a treat, `>= balancedShare` is balanced, below that is light —
/// inclusive at each band's lower edge. The convention is stated once, here, and pinned by test at
/// both boundaries, mirroring the old table's "75 %–125 %, both inclusive".
///
/// These are prototype product heuristics, not validated nutritional advice, and the explanation
/// the user sees has to say so.
enum CheatMealAllowanceRule {
    static let treatShare = 0.35
    static let balancedShare = 0.20

    /// Below this much of the day elapsed there is no useful allowance: at 00:30 maintenance is a
    /// handful of kilocalories and the share divides by very nearly nothing (risk 6 of the
    /// rebuild plan).
    static let minimumWindowSeconds: TimeInterval = 90 * 60

    /// Bumped from `DinnerCategoryRule`'s `1.0.0`, so a saved case always says which rules
    /// produced it.
    static let ruleVersion = "2.0.0"

    /// A day carrying a recorded workout, or at least this many steps, is **remarked on** in the
    /// explanation. It is never added to the arithmetic: active energy already contains workout and
    /// step energy, so adding it would double-count (D121).
    static let strongActivitySteps = 12_000.0

    /// Below this much sleep the explanation says so. Also explanation only — sleep moves no
    /// figure.
    static let shortSleepThreshold = Duration.seconds(6 * 3600)

    /// Works out the allowance, in a **fixed guard order** so a request that breaks two
    /// preconditions always reports the same one:
    /// window length → active → resting → intake → window agreement → positive maintenance.
    static func allowance(_ request: AllowanceRequest) -> AllowanceOutcome {
        guard request.window.duration >= minimumWindowSeconds else {
            return .unavailable(.windowTooShort)
        }
        guard let activeEnergy = request.activeEnergy else {
            return .unavailable(.missingActiveEnergy)
        }
        guard let resting = request.resting else {
            return .unavailable(.noRestingBasis)
        }
        guard let intake = request.intake, let intakeKilocalories = usableKilocalories(of: intake) else {
            return .unavailable(.noIntakeBasis)
        }

        // D47's identical-window precondition, with the one deliberate relaxation that an
        // estimated intake is built from the request's own window and so matches by construction.
        guard
            activeEnergy.provenance.window == request.window,
            resting.window == request.window,
            recordedIntakeWindowAgrees(intake, with: request.window)
        else {
            return .unavailable(.windowMismatch)
        }

        let maintenance = resting.kilocalories + activeEnergy.kilocalories
        guard maintenance.isFinite, maintenance > 0 else {
            return .unavailable(.nonPositiveMaintenance)
        }

        // Never floored at zero: someone who has already eaten more than they have spent gets a
        // negative allowance, a light verdict, and still gets a dinner.
        let allowance = maintenance - intakeKilocalories

        return .allowance(
            EnergyAllowance(
                activeKilocalories: activeEnergy.kilocalories,
                restingKilocalories: resting.kilocalories,
                intakeKilocalories: intakeKilocalories,
                maintenanceKilocalories: maintenance,
                allowanceKilocalories: allowance,
                share: allowance / maintenance,
                restingIsEstimated: resting.isEstimated,
                intakeIsEstimated: isEstimated(intake),
                window: request.window
            )
        )
    }

    /// Turns an allowance into a verdict, with the reason codes that explain it.
    ///
    /// Sleep, steps and workouts inform the **explanation**, never the arithmetic. Every reason
    /// code this function can append is reachable, which is the point: an explanation assembled
    /// from codes nothing ever assigns is prose pretending to be facts (D62's tolerated gap, not
    /// reintroduced).
    static func decide(
        allowance: EnergyAllowance,
        today: HealthAggregates,
        context: DailyContext
    ) -> VerdictDecision {
        var reasonCodes: [ReasonCode] = [bandReason(forShare: allowance.share)]

        // A spent allowance gets its own sentence rather than being folded into "slim": having
        // eaten more than the day spent is a different thing to be told.
        if allowance.allowanceKilocalories <= 0 {
            reasonCodes.append(.allowanceSpent)
        }
        if allowance.restingIsEstimated {
            reasonCodes.append(.restingEnergyEstimated)
        }
        if allowance.intakeIsEstimated {
            reasonCodes.append(.intakeEstimated)
        }
        if hasStrongActivity(in: today) {
            reasonCodes.append(.strongActivityToday)
        }
        if hasShortSleep(in: today) {
            reasonCodes.append(.shortSleep)
        }
        if context.energyLevel == .low {
            reasonCodes.append(.lowReportedEnergy)
        }

        return VerdictDecision(
            category: category(forShare: allowance.share),
            basis: .energyBalance(allowance),
            reasonCodes: reasonCodes,
            isProvisional: false,
            ruleVersion: ruleVersion
        )
    }

    private static func bandReason(forShare share: Double) -> ReasonCode {
        switch category(forShare: share) {
        case .treat: .generousAllowance
        case .balanced: .moderateAllowance
        case .light: .slimAllowance
        }
    }

    /// A recorded workout, or a high step count. An absent reading is not a quiet day — it is an
    /// absent reading, and says nothing either way.
    private static func hasStrongActivity(in today: HealthAggregates) -> Bool {
        if let workouts = today.workouts, !workouts.isEmpty {
            return true
        }
        guard let steps = today.steps else { return false }
        return steps.count >= strongActivitySteps
    }

    private static func hasShortSleep(in today: HealthAggregates) -> Bool {
        guard let sleep = today.sleep else { return false }
        return sleep.asleepDuration < shortSleepThreshold
    }

    /// The band a share falls in. Inclusive at each lower edge.
    static func category(forShare share: Double) -> DinnerCategory {
        if share >= treatShare {
            return .treat
        }
        if share >= balancedShare {
            return .balanced
        }
        return .light
    }

    /// The fallback for a day with no readable active energy, where a number cannot be produced
    /// without inventing one: the user's own account decides, and with nothing at all the verdict
    /// is a provisional balanced.
    static func decide(selfReport: SelfReportedActivity?) -> VerdictDecision {
        guard let selfReport else {
            return VerdictDecision(
                category: .balanced,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: ruleVersion
            )
        }

        return VerdictDecision(
            category: category(for: selfReport),
            basis: .selfReported(selfReport),
            reasonCodes: [reasonCode(for: selfReport)],
            isProvisional: false,
            ruleVersion: ruleVersion
        )
    }

    // MARK: - Intake

    /// The intake figure, or `nil` when the questionnaire has not been answered at all — an
    /// untouched questionnaire is an absence, not a zero.
    private static func usableKilocalories(of intake: DailyIntake) -> Double? {
        switch intake {
        case .recorded(let aggregate):
            aggregate.kilocalories
        case .estimated(let questionnaire):
            questionnaire.isAnswered ? questionnaire.kilocalories : nil
        }
    }

    private static func recordedIntakeWindowAgrees(_ intake: DailyIntake, with window: DateInterval) -> Bool {
        switch intake {
        case .recorded(let aggregate): aggregate.provenance.window == window
        case .estimated: true
        }
    }

    private static func isEstimated(_ intake: DailyIntake) -> Bool {
        switch intake {
        case .recorded: false
        case .estimated: true
        }
    }

    // MARK: - Self-report

    private static func category(for report: SelfReportedActivity) -> DinnerCategory {
        switch report {
        case .more: .treat
        case .usual: .balanced
        case .less: .light
        }
    }

    private static func reasonCode(for report: SelfReportedActivity) -> ReasonCode {
        switch report {
        case .more: .selfReportedMore
        case .usual: .selfReportedUsual
        case .less: .selfReportedLess
        }
    }
}
