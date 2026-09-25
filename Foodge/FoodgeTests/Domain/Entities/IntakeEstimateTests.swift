//
//  IntakeEstimateTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The questionnaire's job is to keep two things apart that a `Double` cannot: a slot nobody
/// answered, and a meal the user says they skipped. The first contributes nothing and leaves the
/// questionnaire unusable; the second is an answer worth zero. That distinction is what keeps
/// "missing Health data stays missing" true once a questionnaire can supply intake, and the rule
/// half of it is pinned in `CheatMealAllowanceRuleTests`.
///
/// The bucket figures are checked against the table in the rebuild plan, written before the code:
/// breakfast 200 / 400 / 650 · lunch 350 / 650 / 1000 · snacks 100 / 250 / 500.
@Suite("Intake estimate", .tags(.unit, .domain, .critical))
struct IntakeEstimateTests {

    // MARK: - Answered versus unanswered

    @Test("An untouched questionnaire is unanswered, and its zero is not a reading")
    func anUntouchedQuestionnaireIsNotAnswered() {
        // Given a questionnaire nobody has touched
        let questionnaire = IntakeQuestionnaire.unanswered

        // Then it reports itself unanswered
        #expect(questionnaire.isAnswered == false)

        // And its sum is zero — which is exactly why `isAnswered` has to exist: the figure alone
        // cannot tell "nothing answered" from "nothing eaten"
        #expect(questionnaire.kilocalories == 0)
    }

    @Test("Skipping every meal is an answer worth zero, not an absence")
    func skippedSlotsAreAnAnsweredZero() {
        // Given a user who says they ate nothing all day
        let questionnaire = IntakeQuestionnaire(breakfast: .skipped, lunch: .skipped, snacks: .skipped)

        // Then the questionnaire is answered, and the figure is zero
        #expect(questionnaire.isAnswered)
        #expect(questionnaire.kilocalories == 0)
    }

    @Test("One answered slot is enough, and the unanswered ones add nothing")
    func aPartlyAnsweredQuestionnaireSumsOnlyWhatWasAnswered() {
        // Given only breakfast answered, as a light meal
        let questionnaire = IntakeQuestionnaire(breakfast: .light)

        // Then the questionnaire is usable and carries only breakfast's figure
        #expect(questionnaire.isAnswered)
        #expect(questionnaire.kilocalories == 200)
    }

    @Test("Answered slots are summed")
    func answeredSlotsAreSummed() {
        // Given a normal breakfast, a heavy lunch and light snacks
        let questionnaire = IntakeQuestionnaire(breakfast: .normal, lunch: .heavy, snacks: .light)

        // Then the total is the sum of the three table figures
        #expect(questionnaire.kilocalories == 400 + 1000 + 100)
    }

    // MARK: - The bucket table

    @Test("Each portion carries the plan's figure for its slot", arguments: [
        (MealSlot.breakfast, MealPortion.skipped, 0.0),
        (.breakfast, .light, 200.0),
        (.breakfast, .normal, 400.0),
        (.breakfast, .heavy, 650.0),
        (.lunch, .skipped, 0.0),
        (.lunch, .light, 350.0),
        (.lunch, .normal, 650.0),
        (.lunch, .heavy, 1000.0),
        (.snacks, .skipped, 0.0),
        (.snacks, .light, 100.0),
        (.snacks, .normal, 250.0),
        (.snacks, .heavy, 500.0),
    ])
    func theBucketTableMatchesThePlan(slot: MealSlot, portion: MealPortion, expected: Double) {
        #expect(portion.kilocalories(for: slot) == expected)
    }

    @Test("A heavier portion is never worth less than a lighter one")
    func portionsAreMonotonicWithinEverySlot() {
        for slot in MealSlot.allCases {
            let figures = [MealPortion.skipped, .light, .normal, .heavy].map { $0.kilocalories(for: slot) }
            #expect(figures == figures.sorted())
            #expect(Set(figures).count == figures.count)
        }
    }

    // MARK: - Persistence

    @Test("A skipped slot and an unanswered slot survive a round trip as different things")
    func encodingKeepsSkippedAndUnansweredApart() throws {
        // Given one questionnaire that skipped breakfast and one that was never asked
        let skipped = IntakeQuestionnaire(breakfast: .skipped)
        let unanswered = IntakeQuestionnaire.unanswered

        // When both are encoded and decoded again
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let decodedSkipped = try decoder.decode(
            IntakeQuestionnaire.self,
            from: encoder.encode(skipped)
        )
        let decodedUnanswered = try decoder.decode(
            IntakeQuestionnaire.self,
            from: encoder.encode(unanswered)
        )

        // Then they are still different, and still on the right sides of `isAnswered`
        #expect(decodedSkipped == skipped)
        #expect(decodedUnanswered == unanswered)
        #expect(decodedSkipped != decodedUnanswered)
        #expect(decodedSkipped.isAnswered)
        #expect(decodedUnanswered.isAnswered == false)
    }

    @Test("A recorded intake and an estimated one stay distinguishable through Codable")
    func dailyIntakeKeepsItsProvenanceThroughCodable() throws {
        // Given the same figure recorded by Health and estimated by questionnaire
        let window = DateInterval(
            start: TestCalendar.date(2026, 9, 15),
            end: TestCalendar.date(2026, 9, 15, 19, 30)
        )
        let recorded = DailyIntake.recorded(
            EnergyAggregate(
                kilocalories: 400,
                provenance: Provenance(sourceNames: ["Test"], readAt: window.end, window: window)
            )
        )
        let estimated = DailyIntake.estimated(IntakeQuestionnaire(breakfast: .normal))

        // When both are encoded and decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let decodedRecorded = try decoder.decode(DailyIntake.self, from: encoder.encode(recorded))
        let decodedEstimated = try decoder.decode(DailyIntake.self, from: encoder.encode(estimated))

        // Then the provenance survived — a stored case can still say which it was
        #expect(decodedRecorded == recorded)
        #expect(decodedEstimated == estimated)
    }
}
