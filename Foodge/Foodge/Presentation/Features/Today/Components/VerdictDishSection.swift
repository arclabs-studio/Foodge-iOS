//
//  VerdictDishSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Accessibility
import SwiftUI

/// Tonight's dish on the verdict stage: the artwork, the name — the screen's largest text (D145) —
/// and the two-state toggle to the runner-up (D144).
///
/// The toggle is not a picker: both dishes came out of the same selection, in the category the rule
/// decided and the stored diet profile, and no third dish is reachable.
@MainActor
struct VerdictDishSection: View {
    let dishOutcome: PersistedDishOutcome
    @Binding var showingAlternative: Bool
    /// `false` keeps the swap a crossfade even where the system would allow motion.
    var motion = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var moves: Bool {
        motion && !reduceMotion
    }

    var body: some View {
        let variantID = dishOutcome.shownVariantID(showingAlternative: showingAlternative)
        let family = dishOutcome.shownFamily(showingAlternative: showingAlternative)

        VStack(spacing: 16) {
            DishHeroView(family: family)
                .id(family)
                .transition(
                    moves
                        ? .scale(scale: 0.6).combined(with: .opacity)
                        : .opacity.animation(.easeInOut(duration: 0.25))
                )

            DishTitleView(variantID: variantID, family: family)

            // The name above changes in place with no navigation, so VoiceOver has no reason to
            // land on it (WCAG 4.1.3) — the announcement says which dish is now shown. The label
            // carries the same information for anyone revisiting the button (WCAG 4.1.2).
            Button(showingAlternative ? "See original dish" : "See alternative") {
                // Motion off: no animation here — the artwork fades itself and the text swaps in place.
                withAnimation(moves ? .spring(duration: 0.45, bounce: 0.35) : nil) {
                    showingAlternative.toggle()
                }
                let shownName = DishCatalogue.displayName(
                    forVariantID: dishOutcome.shownVariantID(showingAlternative: showingAlternative)
                )
                AccessibilityNotification.Announcement(String(localized: "Now showing \(shownName).")).post()
            }
            .secondaryAction()
            .disabled(dishOutcome.alternativeVariantID == nil)
        }
    }
}

#Preview("Chosen dish", traits: .sampleData) {
    @Previewable @State var showingAlternative = false

    VerdictDishSection(dishOutcome: SampleDecisions.dishOutcome, showingAlternative: $showingAlternative)
        .padding()
        .background { StageBackground(accent: Color(DinnerCategory.balanced.tint)) }
}

#Preview("Runner-up", traits: .sampleData) {
    @Previewable @State var showingAlternative = true

    VerdictDishSection(dishOutcome: SampleDecisions.dishOutcome, showingAlternative: $showingAlternative)
        .padding()
        .background { StageBackground(accent: Color(DinnerCategory.balanced.tint)) }
}
