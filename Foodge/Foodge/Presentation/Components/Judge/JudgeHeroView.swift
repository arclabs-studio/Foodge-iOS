//
//  JudgeHeroView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Accessibility
import SwiftUI

/// The judge as the star of a stage screen: large, breathing for a moment, and tappable (D146).
///
/// A tap plays a hop and a light haptic, shows the next quip in a speech bubble below the judge and
/// announces it to VoiceOver. That is everything it does — the reaction model reaches no rule, no
/// dish and no store, so the judge can be tapped any number of times without touching tonight's
/// verdict. `JudgeBadgeView` stays for the small, decorative uses.
///
/// Motion follows the plan's motion policy (`docs/migrations/2026-10-09-playful-redesign.md`, to be
/// recorded as D147 with the verdict reveal). Reduce Motion is read here, so no screen can forget
/// it; `motion` can only turn motion **off** further, which is how a preview shows the still
/// version of a setting it cannot inject. Still, the judge neither breathes nor hops, its press dims
/// instead of squashing, the bubble fades in while the layout around it settles at once, and the
/// haptic and the announcement still play.
///
/// The breath is an invitation, not a screensaver: two breaths (4.8 s, under WCAG 2.2.2's five
/// seconds for motion nobody asked for), and none at all once the judge has been tapped.
@MainActor
struct JudgeHeroView: View {
    let artwork: ImageResource
    /// How tall the judge stands at standard text sizes. Accessibility sizes take 60 % of it, so
    /// the text around the hero keeps more of the screen.
    let height: CGFloat
    /// Owned by the screen, so the judge keeps its place in the deck across that screen's updates.
    let reaction: JudgeReaction
    /// Whether the judge breathes on its own. A screen turns this off once a verdict is requested.
    var idles = true
    /// `false` keeps the judge still even where the system would allow motion.
    var motion = true

    @State private var breathExpired = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var moves: Bool {
        motion && !reduceMotion
    }

    private var side: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? height * 0.6 : height
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                let quip = reaction.tap()
                AccessibilityNotification.Announcement(String(localized: quip.text)).post()
            } label: {
                JudgeFigureView(
                    artwork: artwork,
                    side: side,
                    motion: moves,
                    breathes: moves && idles && !breathExpired && reaction.taps == 0,
                    taps: reaction.taps
                )
            }
            .buttonStyle(JudgeButtonStyle(motion: moves))
            .accessibilityLabel(Text("The judge"))
            .accessibilityHint(Text("Plays a line from the judge."))

            if let quip = reaction.quip {
                SpeechBubble(text: Text(quip.text))
                    // A new identity per line, so each tap opens a fresh bubble instead of
                    // retyping the old one.
                    .id(quip)
                    .transition(
                        moves
                            ? .scale(scale: 0.6, anchor: .top).combined(with: .opacity)
                            : .opacity.animation(.easeInOut(duration: 0.25))
                    )
            }
        }
        // `nil` under Reduce Motion: the layout below the bubble settles at once, and only the
        // bubble's own fade is animated.
        .animation(moves ? .spring(duration: 0.4, bounce: 0.45) : nil, value: reaction.taps)
        .sensoryFeedback(.impact(weight: .light), trigger: reaction.taps)
        .task(id: moves) {
            guard moves else { return }
            do {
                try await Task.sleep(for: .seconds(4.8))
            } catch {
                return
            }
            breathExpired = true
        }
    }
}

#Preview("Welcome") {
    @Previewable @State var reaction = JudgeReaction()

    JudgeHeroView(artwork: .judgeWelcome, height: 220, reaction: reaction)
}

#Preview("Speaking, held still") {
    @Previewable @State var reaction = {
        let reaction = JudgeReaction()
        reaction.tap()
        return reaction
    }()

    JudgeHeroView(artwork: .judgeVerdict, height: 180, reaction: reaction, motion: false)
        .padding()
        .background { StageBackground(accent: .appBurgundy) }
}

#Preview("Longest line") {
    @Previewable @State var reaction = {
        let reaction = JudgeReaction()
        while reaction.quip != .regulationWig {
            reaction.tap()
        }
        return reaction
    }()

    JudgeHeroView(artwork: .judgeVerdict, height: 180, reaction: reaction, motion: false)
        .padding()
        .background { StageBackground(accent: .appBurgundy) }
}
