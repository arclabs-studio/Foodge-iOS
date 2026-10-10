//
//  WelcomeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The first screen: the judge, what Foodge is in one sentence, and the way in — on the stage
/// (D145), with the judge as large as it gets in the app and tappable (D146).
///
/// It owns no state beyond the judge's reaction. The flow's stack is what carries the user forward,
/// so the action is a `NavigationLink` over a typed route rather than a button that mutates a path.
@MainActor
struct WelcomeView: View {
    @State private var judge = JudgeReaction()

    /// At accessibility sizes the action flows as the last item in the scrolling content instead of
    /// being pinned, where it would grow tall enough to cover the text above it (WCAG 1.4.10).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                JudgeHeroView(artwork: .judgeWelcome, height: StageArtworkSize.welcomeJudge, reaction: judge)

                Text("The court is now in session.")
                    .font(.largeTitle.bold())
                    // The screen's heading: the inline navigation title only says "Welcome".
                    .accessibilityAddTraits(.isHeader)

                Text(
                    """
                    Foodge reads what Apple Health actually recorded, works out what today has \
                    left you to spend, and proposes one dinner.
                    """
                )
                .font(.body)

                // On the stage: `appBurgundyMuted` is measured where the wash is strongest (D145);
                // `.secondary` would not be (D134).
                Text("You can always see the reasoning behind the verdict.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)

                if !dynamicTypeSize.pinsPrimaryAction {
                    continueLink
                        .padding(.top, 12)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .pinnedPrimaryAction {
            continueLink
        }
        .background { StageBackground(accent: .appBurgundy) }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The same link in both places it can sit — pinned, or inline at accessibility sizes.
    private var continueLink: some View {
        NavigationLink("Continue", value: OnboardingRoute.healthConnection)
            .primaryAction()
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        WelcomeView()
    }
}
