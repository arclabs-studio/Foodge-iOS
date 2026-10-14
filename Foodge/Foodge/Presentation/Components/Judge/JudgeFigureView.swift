//
//  JudgeFigureView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The judge's artwork with its two animations: a slow breath, and a hop on every tap (D146).
///
/// Decorative — `JudgeHeroView` wraps it in the `Button` that carries the name. Its own view so the
/// figure's body is skipped whenever its inputs are unchanged, such as when only the quip changes.
@MainActor
struct JudgeFigureView: View {
    let artwork: ImageResource
    let side: CGFloat
    /// `false` under Reduce Motion: every hop value collapses to rest.
    let motion: Bool
    /// Whether the breath is playing. When this turns `false` the figure returns to its rest pose.
    let breathes: Bool
    /// The hop's trigger: it plays each time this changes.
    let taps: Int

    var body: some View {
        let amplitude = motion ? 1.0 : 0.0

        Image(artwork)
            .resizable()
            .scaledToFit()
            .frame(height: side)
            .keyframeAnimator(initialValue: IdlePose(), repeating: breathes) { content, pose in
                content
                    .scaleEffect(pose.scale, anchor: .bottom)
                    .rotationEffect(pose.tilt, anchor: .bottom)
            } keyframes: { _ in
                // One breath is 2.4 s on both tracks, so a breath that stops on a cycle boundary
                // stops at rest.
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.03, duration: 1.2)
                    CubicKeyframe(1.0, duration: 1.2)
                }
                KeyframeTrack(\.tilt) {
                    CubicKeyframe(.degrees(1.5), duration: 0.6)
                    CubicKeyframe(.degrees(-1.5), duration: 1.2)
                    CubicKeyframe(.zero, duration: 0.6)
                }
            }
            .keyframeAnimator(initialValue: HopPose(), trigger: taps) { content, pose in
                content
                    .scaleEffect(x: 2 - pose.stretch, y: pose.stretch, anchor: .bottom)
                    .offset(y: pose.lift)
                    .rotationEffect(pose.wiggle, anchor: .bottom)
            } keyframes: { _ in
                // Every value is scaled by `amplitude`, so under Reduce Motion the same timeline
                // plays from rest to rest and nothing moves.
                KeyframeTrack(\.stretch) {
                    CubicKeyframe(1 - 0.12 * amplitude, duration: 0.1)
                    CubicKeyframe(1 + 0.08 * amplitude, duration: 0.15)
                    CubicKeyframe(1, duration: 0.35)
                }
                KeyframeTrack(\.lift) {
                    LinearKeyframe(0, duration: 0.1)
                    SpringKeyframe(-36 * amplitude, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(0, spring: .bouncy)
                }
                KeyframeTrack(\.wiggle) {
                    CubicKeyframe(.zero, duration: 0.25)
                    CubicKeyframe(.degrees(6 * amplitude), duration: 0.1)
                    CubicKeyframe(.degrees(-6 * amplitude), duration: 0.1)
                    CubicKeyframe(.zero, duration: 0.1)
                }
            }
            .accessibilityHidden(true)
    }
}

extension JudgeFigureView {
    /// The judge at rest, breathing.
    private struct IdlePose {
        var scale = 1.0
        var tilt = Angle.zero
    }

    /// The judge mid-hop: squash and stretch, height off the floor, and a wiggle at the top.
    private struct HopPose {
        var stretch = 1.0
        var lift = 0.0
        var wiggle = Angle.zero
    }
}

#Preview {
    JudgeFigureView(artwork: .judgeWelcome, side: 220, motion: true, breathes: true, taps: 0)
}
