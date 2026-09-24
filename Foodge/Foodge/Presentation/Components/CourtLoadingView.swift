//
//  CourtLoadingView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// A branded loading state for work that temporarily replaces the app's interactive content.
///
/// The indeterminate indicator stays native so the system owns its animation and Reduce Motion
/// behavior. The judge is decorative; the progress label is the single accessible status.
@MainActor
struct CourtLoadingView: View {
    let message: LocalizedStringResource
    let artwork: ImageResource

    var body: some View {
        VStack(spacing: 24) {
            JudgeBadgeView(artwork: artwork)

            ProgressView {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .controlSize(.large)
            .tint(.appBurgundy)
            .accessibilityIdentifier("court_loading_progress")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    CourtLoadingView(
        message: "The judge is weighing tonight’s evidence…",
        artwork: .judgeVerdict
    )
}
