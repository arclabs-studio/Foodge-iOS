//
//  VerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Accessibility
import SwiftUI

/// Tonight's dinner, the category it landed in, and why — on a stage tinted by the category
/// (D145), revealed once per verdict (D147).
///
/// The reveal: the stamp lands, the dish pops with a burst of confetti, the cards arrive. It plays
/// only when `TodayViewModel.claimReveal()` says this revision has not been revealed yet in this
/// launch, so coming back from Evidence details — or to tonight's verdict from Today — shows it
/// settled. Reduce Motion is read here and passed down: every step is then a fade with the layout
/// settling at once, and there is no confetti.
@MainActor
struct VerdictView: View {
    @Bindable var vm: TodayViewModel
    /// `false` shows the settled verdict at once — what a preview needs, since a still frame cannot
    /// wait for the reveal.
    var playsReveal = true

    @State private var showingAlternative = false
    @State private var reveal = VerdictReveal()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What to draw. A revision whose reveal has not been claimed yet draws nothing until the reveal
    /// starts, so a new verdict never flashes fully drawn and then collapses into its reveal.
    private var phase: RevealPhase {
        guard playsReveal else { return .settled }
        // Read before the pending check, so the body tracks the reveal even while it is pending —
        // otherwise the stamp's first animated change would go unobserved and snap in.
        let current = reveal.phase
        return vm.isRevealPending ? .waiting : current
    }

    var body: some View {
        Group {
            if let display = vm.currentDisplay {
                content(for: display)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Tonight’s verdict")
        .navigationBarTitleDisplayMode(.inline)
        // Identity is the revision, so SwiftUI restarts narration on a new verdict and cancels it
        // on disappear — navigation away is handled by the framework, with no stored `Task` here.
        .task(id: vm.currentRevision?.id) {
            await vm.narrateIfNeeded()
        }
        // The same identity for the reveal: a new revision is a new reveal; reappearing for the
        // same one is not, because `claimReveal()` answers `true` only once per revision.
        .task(id: vm.currentRevision?.id) {
            if playsReveal, vm.claimReveal() {
                await reveal.play(motion: !reduceMotion)
            } else {
                reveal.settle()
            }
        }
        // Heavy with the slam; light with the fade that replaces it under Reduce Motion.
        .sensoryFeedback(.impact(weight: reduceMotion ? .light : .heavy), trigger: reveal.stampLandings)
        // The first failure pushes this screen already in `.saveFailed`, so the announcement has to
        // fire for the initial value too — VoiceOver would otherwise read only the navigation title.
        // A failed *retry* re-enters `.saveFailed` with the card already on screen and no push at all
        // (WCAG 4.1.3). `logLabel` is the change key because `Stage` carries a draft and an error and
        // is deliberately not `Equatable`; the retry passes through `.evaluating`, so a second failure
        // is a real change of label and does announce.
        .onChange(of: vm.stage.logLabel, initial: true) { _, _ in
            guard case .saveFailed = vm.stage else { return }
            AccessibilityNotification.Announcement(String(localized: SaveFailedCard.message)).post()
        }
    }

    /// With motion off a phase changes without animation, so each view carries its own fade.
    private static let fade = AnyTransition.opacity.animation(.easeInOut(duration: 0.25))

    /// Renders from ``TodayViewModel/Display`` rather than `SavedRevision` directly: a failed
    /// save has no `SavedRevision` yet — no id, no sequence — but the computed decision must stay
    /// visible with a retry regardless, never silently dropped to a spinner.
    private func content(for display: TodayViewModel.Display) -> some View {
        let category = display.decision.category
        let motion = !reduceMotion

        return ScrollView {
            VStack(spacing: 24) {
                if phase >= .stamp {
                    VerdictStampSection(category: category, isProvisional: display.decision.isProvisional)
                        .transition(motion ? AnyTransition(StampSlamTransition()) : Self.fade)
                }

                if case .saveFailed = vm.stage {
                    // Straight under the stamp, above the fold: nothing else on the screen says the
                    // verdict is unsaved, so the retry cannot wait at the bottom of a long scroll.
                    SaveFailedCard {
                        Task { await vm.retrySave() }
                    }
                }

                if phase >= .dish {
                    VerdictDishSection(dishOutcome: display.dishOutcome, showingAlternative: $showingAlternative)
                        .transition(motion ? .scale(scale: 0.4).combined(with: .opacity) : Self.fade)
                }

                if phase >= .cards {
                    VStack(spacing: 24) {
                        VerdictReasonsCard(reasonCodes: display.decision.reasonCodes)

                        if vm.currentRevision != nil {
                            // Gated on a saved revision: a decorative flourish over a verdict that
                            // has not actually been recorded reads as if everything went fine.
                            VerdictFlourishView(text: vm.narrationStage.text, category: category)
                        }

                        if vm.currentRevision != nil {
                            NavigationLink(value: TodayRoute.evidenceDetails) {
                                Text("Evidence details")
                            }
                            .secondaryAction()
                        }
                    }
                    .transition(motion ? .offset(y: 24).combined(with: .opacity) : Self.fade)
                }
            }
            .padding()
        }
        .background { StageBackground(accent: Color(category.tint)) }
        .overlay {
            if reveal.showsConfetti, playsReveal {
                ConfettiView(colors: [Color(category.tint), .appGold, .appTomato, .appCheese, .appBasil])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

#Preview("Verdict", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .balanced,
            basis: .energyBalance(SampleDecisions.moderateAllowance),
            reasonCodes: [.moderateAllowance],
            isProvisional: false,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    NavigationStack {
        VerdictView(vm: vm, playsReveal: false)
    }
    .task { await vm.onAppear() }
}

#Preview("Save failed", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.savingFails().makeTodayViewModel()

    NavigationStack {
        VerdictView(vm: vm, playsReveal: false)
    }
    .task { await vm.requestVerdict() }
}
