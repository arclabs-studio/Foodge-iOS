//
//  WelcomeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The first screen: what Foodge is, in one sentence, and the way in.
///
/// It owns no state of its own — the two `@Environment` reads below only steer layout and label
/// color for accessibility. The flow's stack is what carries the user forward, so the action is
/// a `NavigationLink` over a typed route rather than a button that mutates a path.
@MainActor
struct WelcomeView: View {
    /// At accessibility sizes the pinned `safeAreaInset` button grows tall enough to overlap the
    /// scrolling text above it (observed at AX5 on device and in preview — the inset height and
    /// the button's own accessibility-scaled height fall out of sync). Below accessibility sizes
    /// the pinned bar is the correct pattern and stays; at accessibility sizes the button instead
    /// flows as the last item in the scrollable content, which cannot ever overlap what is above
    /// it (WCAG 1.4.10 Reflow).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                JudgeBadgeView(artwork: .judgeWelcome)

                Text("The court is now in session.")
                    .font(.largeTitle.bold())

                Text(
                    """
                    Foodge reads what Apple Health actually recorded, works out what today has \
                    left you to spend, and proposes one dinner.
                    """
                )
                .font(.body)

                // `.secondary` measures ~3.4:1 against the white/black scroll background in
                // standard-contrast light appearance (WCAG 1.4.3 needs 4.5:1) — confirmed by
                // sampling the rendered preview, not by the system's documented alpha alone.
                // `AppBurgundyMuted` is the brand's own dedicated secondary-text color, already
                // tuned to ≥4.5:1 against these surfaces in all four appearance/contrast
                // combinations, and was sitting unused in the asset catalog.
                Text("You can always see the reasoning, and you can always appeal.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)

                if dynamicTypeSize.isAccessibilitySize {
                    continueLink
                        .padding(.top, 12)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 32)
        }
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                continueLink
            }
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// `AppBurgundy` (= AccentColor) is tuned as a *foreground* colour: dark burgundy in light
    /// appearance, light pink in dark. `.borderedProminent` uses it as the button's *background*
    /// instead, with a white label by default — fine in light appearance (10.05:1), unreadable in
    /// dark (2.47:1, where WCAG 1.4.3 needs 4.5:1).
    ///
    /// `AppOnBurgundy` is the paired label colour, with its own four appearances, so the pairing
    /// lives in the asset catalogue where every other colour decision lives — rather than as a
    /// `colorScheme` branch in the view, which would have been a colour declared in code.
    private var continueLink: some View {
        NavigationLink("Continue", value: OnboardingRoute.healthConnection)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .foregroundStyle(.appOnBurgundy)
            .padding()
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
