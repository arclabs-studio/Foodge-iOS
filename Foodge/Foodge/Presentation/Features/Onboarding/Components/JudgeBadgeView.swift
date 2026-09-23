//
//  JudgeBadgeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The food judge, standing in as an SF Symbol until the artwork lands on Day 24.
///
/// Deliberately the only place the judge is drawn, so that swap touches exactly one file (D15).
/// Decorative: it is a mascot logo, not content — `WelcomeView` and `TodayBeforeVerdictView` pair
/// it with an explanatory sentence, but `CategoryHeaderSection` (shared by `VerdictView` and
/// `CaseDetailView`) pairs it only with the one-word category name, which already stands on its
/// own as text. Either way the badge itself adds no information VoiceOver users would be missing.
@MainActor
struct JudgeBadgeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 76

    var body: some View {
        Image(systemName: "fork.knife.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .foregroundStyle(.appBurgundy)
            .accessibilityHidden(true)
    }
}

#Preview {
    JudgeBadgeView()
}
