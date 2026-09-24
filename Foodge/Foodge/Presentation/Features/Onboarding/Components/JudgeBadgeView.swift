//
//  JudgeBadgeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The food judge rendered with the pose appropriate to its surrounding screen.
///
/// Deliberately the only place the judge artwork is configured, so its sizing and accessibility
/// treatment remain consistent everywhere (D15).
/// Decorative: it is a mascot logo, not content — `WelcomeView` and `TodayBeforeVerdictView` pair
/// it with an explanatory sentence, but `CategoryHeaderSection` (shared by `VerdictView` and
/// `CaseDetailView`) pairs it only with the one-word category name, which already stands on its
/// own as text. Either way the badge itself adds no information VoiceOver users would be missing.
@MainActor
struct JudgeBadgeView: View {
    let artwork: ImageResource

    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 76

    var body: some View {
        Image(artwork)
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

#Preview {
    JudgeBadgeView(artwork: .judgeVerdict)
}
