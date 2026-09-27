//
//  StoreUnavailableView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// Shown when the local store cannot be opened.
///
/// The app stops here on purpose. Carrying on with a throwaway container would let someone
/// complete onboarding and lose it, which is worse than saying plainly that something is wrong.
@MainActor
struct StoreUnavailableView: View {
    let retry: () -> Void

    var body: some View {
        // This is the app's root when the store fails to open — no `NavigationStack` and no
        // `List` around it to supply scrolling, and `ContentUnavailableView` does not scroll on
        // its own. At accessibility text sizes the description alone can fill the screen and
        // push "Try again" out of reach, and this screen's only action is the way out of a
        // fatal error. `containerRelativeFrame(.vertical)` keeps it centred when the content
        // fits and lets it scroll when it does not (WCAG 1.4.10), without a `GeometryReader`.
        ScrollView {
            ContentUnavailableView {
                Label("Foodge can’t open its files", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text(
                    """
                    Your preferences and past verdicts are stored on this iPhone, and Foodge \
                    couldn’t reach them. Nothing has been deleted.
                    """
                )
            } actions: {
                Button("Try again", action: retry)
                    .buttonStyle(.borderedProminent)
                    // The paired label colour — see `WelcomeView.continueLink` for why the
                    // pairing lives in the asset catalogue rather than in a `colorScheme` branch.
                    .foregroundStyle(.appOnBurgundy)
            }
            .containerRelativeFrame(.vertical)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    StoreUnavailableView(retry: {})
}
