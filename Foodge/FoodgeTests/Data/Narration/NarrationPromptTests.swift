//
//  NarrationPromptTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The input half of the injection defence, and the test the whole numeric ban rests on.
@Suite("Narration prompt", .tags(.unit, .critical))
struct NarrationPromptTests {

    private func makeDecision(
        category: DinnerCategory = .balanced,
        isProvisional: Bool = false
    ) -> VerdictDecision {
        VerdictDecision(
            category: category,
            basis: .energyBalance(SampleDecisions.moderateAllowance),
            reasonCodes: [.moderateAllowance],
            isProvisional: isProvisional,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    }

    // MARK: - Contents

    @Test("The prompt carries the category and the dish, and nothing else about the evidence")
    func promptCarriesCategoryAndDish() {
        // Given a decided verdict
        let prompt = NarrationPrompt.prompt(for: makeDecision(category: .treat), dishName: "Pesto pasta")

        // Then the model is told what it needs and no more — no reason codes, no basis
        #expect(prompt.contains("Category: treat"))
        #expect(prompt.contains("Dish: Pesto pasta"))
        #expect(!prompt.contains("withinRecordedPattern"))
        #expect(!prompt.contains("Ruling: provisional"))
    }

    @Test("A provisional ruling says so")
    func provisionalRulingIsNamed() {
        let prompt = NarrationPrompt.prompt(for: makeDecision(isProvisional: true), dishName: "Pesto pasta")

        #expect(prompt.contains("Ruling: provisional"))
    }

    // MARK: - The numeric ban

    @Test("The prompt contains no number of any kind")
    func promptContainsNoNumbers() {
        // Given a decision whose basis carries a ratio of 1.02 against a median of 400
        let prompt = NarrationPrompt.prompt(for: makeDecision(), dishName: "Pesto pasta")

        // Then not one numeral reaches the model. This is what makes the validator's total ban on
        // numerals legitimate rather than arbitrary: any number in the output is invented, because
        // there was none in the input.
        let carriesANumber = prompt.contains { $0.isNumber }
        #expect(!carriesANumber)
    }

    @Test("The dish name is the only free text the prompt carries")
    func theDishNameIsTheOnlyFreeText() {
        // Given a verdict and a dish
        let prompt = NarrationPrompt.prompt(for: makeDecision(), dishName: "Pesto pasta")

        // Then every line is one this app composed: a category, a dish, and nothing the user
        // wrote. The free note was the only user text that ever reached a prompt, and it left
        // with D138 — this is what would fail if anything user-written came back
        let lines = prompt.split(separator: "\n").map(String.init)
        #expect(lines == ["Category: balanced", "Dish: Pesto pasta"])
    }

    @Test(
        "The instructions name the language to answer in",
        arguments: [
            (Locale(identifier: "es_ES"), "Spanish"),
            (Locale(identifier: "en_GB"), "English"),
        ]
    )
    func instructionsNameTheLanguage(locale: Locale, expected: String) {
        let instructions = NarrationPrompt.instructions(locale: locale)

        #expect(instructions.contains("You MUST write your response in \(expected)."))
    }
}
