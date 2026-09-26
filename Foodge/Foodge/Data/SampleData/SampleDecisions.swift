//
//  SampleDecisions.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// Ready-made allowances and decisions for previews and sample stores.
///
/// Centralized because the alternative is what the rebuild found: the same seven-line
/// `VerdictDecision` literal copied into six `#Preview` bodies, each free to drift from the rule
/// and from the others. A preview that shows a decision the rule could not produce is worse than
/// no preview.
enum SampleDecisions {
    /// 1600 resting + 400 active = 2000 maintenance, 1460 eaten: 540 left, a share of 0.27.
    static let moderateAllowance = allowance(intakeKilocalories: 1460)

    /// The same day with 700 eaten: 1300 left, a share of 0.65.
    static let generousAllowance = allowance(intakeKilocalories: 700)

    /// The same day with 1760 eaten: 240 left, a share of 0.12.
    static let slimAllowance = allowance(intakeKilocalories: 1760)

    /// 2500 eaten against 2000 of maintenance: **−500 left**, a share of −0.25, both estimated.
    static let spentAllowance = allowance(
        intakeKilocalories: 2500,
        restingIsEstimated: true,
        intakeIsEstimated: true
    )

    /// An allowance on the standard sample day: resting 1600, active 400, cut at 19:30.
    static func allowance(
        intakeKilocalories: Double,
        restingIsEstimated: Bool = false,
        intakeIsEstimated: Bool = false
    ) -> EnergyAllowance {
        let resting = 1600.0
        let active = 400.0
        let maintenance = resting + active
        let allowance = maintenance - intakeKilocalories

        return EnergyAllowance(
            activeKilocalories: active,
            restingKilocalories: resting,
            intakeKilocalories: intakeKilocalories,
            maintenanceKilocalories: maintenance,
            allowanceKilocalories: allowance,
            share: allowance / maintenance,
            restingIsEstimated: restingIsEstimated,
            intakeIsEstimated: intakeIsEstimated,
            window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
        )
    }

    /// The balanced verdict the sample day produces.
    static let balancedVerdict = decision(
        category: .balanced,
        allowance: moderateAllowance,
        reasonCodes: [.moderateAllowance]
    )

    static let treatVerdict = decision(
        category: .treat,
        allowance: generousAllowance,
        reasonCodes: [.generousAllowance, .strongActivityToday]
    )

    static let lightVerdict = decision(
        category: .light,
        allowance: slimAllowance,
        reasonCodes: [.slimAllowance]
    )

    static let spentVerdict = decision(
        category: .light,
        allowance: spentAllowance,
        reasonCodes: [.slimAllowance, .allowanceSpent, .restingEnergyEstimated, .intakeEstimated]
    )

    static func decision(
        category: DinnerCategory,
        allowance: EnergyAllowance,
        reasonCodes: [ReasonCode]
    ) -> VerdictDecision {
        VerdictDecision(
            category: category,
            basis: .energyBalance(allowance),
            reasonCodes: reasonCodes,
            isProvisional: false,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    }
}
