//
//  DeliberatingJudgeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The judge mid-deliberation: a gavel-tap tilt while the court works.
///
/// Decorative — the loading view's `ProgressView` is the accessible status, and the system owns
/// that indicator's animation. The tilt is extra, so it follows the plan's motion policy the way
/// `JudgeHeroView`'s breath does (to be recorded as D147): none under Reduce Motion, and stopped
/// by a 4.8 s timer — under WCAG 2.2.2's five seconds — after which the judge holds still and the
/// spinner carries on alone.
@MainActor
struct DeliberatingJudgeView: View {
    let artwork: ImageResource
    /// `false` keeps the judge still even where the system would allow motion.
    var motion = true

    @State private var tapsExpired = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var moves: Bool {
        motion && !reduceMotion
    }

    var body: some View {
        Image(artwork)
            .resizable()
            .scaledToFit()
            // The hero's size on Today, so the judge does not jump when the loading state takes over.
            .frame(height: StageArtworkSize.height(StageArtworkSize.judge, at: dynamicTypeSize))
            .keyframeAnimator(initialValue: Angle.zero, repeating: moves && !tapsExpired) { content, tilt in
                content.rotationEffect(tilt, anchor: .bottom)
            } keyframes: { _ in
                // One tap of the gavel, 1.25 s, its last 0.45 s at rest — so the timer below, which
                // runs on its own clock, stops the judge during the fourth tap's rest.
                KeyframeTrack {
                    CubicKeyframe(.degrees(-5), duration: 0.3)
                    SpringKeyframe(.degrees(2), duration: 0.2, spring: .snappy)
                    CubicKeyframe(.zero, duration: 0.3)
                    LinearKeyframe(.zero, duration: 0.45)
                }
            }
            .accessibilityHidden(true)
            .task(id: moves) {
                guard moves else { return }
                do {
                    try await Task.sleep(for: .seconds(4.8))
                } catch {
                    return
                }
                tapsExpired = true
            }
    }
}

#Preview("Deliberating") {
    DeliberatingJudgeView(artwork: .judgeVerdict)
}

#Preview("Held still") {
    DeliberatingJudgeView(artwork: .judgeVerdict, motion: false)
}
