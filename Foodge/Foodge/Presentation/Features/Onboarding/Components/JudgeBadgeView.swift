//
//  JudgeBadgeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The food judge as a small, decorative badge.
///
/// The judge's large, interactive form is `JudgeHeroView`, and its loading form is
/// `DeliberatingJudgeView`; this badge stays for the small uses — `WelcomeView` until WU-29-E, the
/// verdict's `VerdictFlourishView`, and `CategoryHeaderSection` on case detail. Decorative: it is a
/// mascot logo, not content — where it appears it sits beside text that already says what the
/// screen is, so VoiceOver users miss nothing.
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
