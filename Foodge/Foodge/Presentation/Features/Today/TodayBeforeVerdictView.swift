//
//  TodayBeforeVerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Accessibility
import SwiftUI

/// Today, before a verdict has been asked for: the judge, the check-ins the category rule needs, and
/// the one button that starts an evaluation — a stage with cards since D145.
///
/// Nothing on this screen asks the user what they feel like eating. The dinner-time, energy and
/// craving pickers and the free note all left with D138 — every one of them existed to steer the
/// dish, and Foodge chooses the dish. What remains is what the rule cannot work out on its own:
/// what was eaten today, and, on a day with no readable active energy, how the day went.
@MainActor
struct TodayBeforeVerdictView: View {
    @Bindable var vm: TodayViewModel
    @State private var judge = JudgeReaction()
    /// Where the column is scrolled — moved only to bring a card the stage just added into view.
    @State private var scrollPosition = ScrollPosition()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Where VoiceOver goes when the stage adds a card that asks for an answer: the self-report's
    /// question, or the failed read's message.
    @AccessibilityFocusState private var isSelfReportFocused: Bool
    @AccessibilityFocusState private var isEvidenceMessageFocused: Bool

    /// The identity of the first card the stage adds below the intake check-in, so the column can
    /// scroll to it. With a failed read that is the retry card; the self-report follows it.
    private static let stageCardID = "stageCard"

    /// At accessibility sizes the primary action flows as the last item in the scrolling column
    /// instead of being pinned, where it would grow tall enough to cover what is above it — the
    /// contract `pinnedPrimaryAction` sets, shared with `WelcomeView` (WCAG 1.4.10 Reflow).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var evaluatingMessage: LocalizedStringResource {
        LocalizedStringResource(
            "The judge is weighing tonight’s evidence…",
            comment: "Verdict preparation loading message"
        )
    }

    private var noDishAvailableMessage: LocalizedStringResource {
        "Nothing in Foodge’s menu fits tonight’s category on your diet. Nothing was recorded for tonight."
    }

    /// The same action in both places it can sit — pinned, or inline at accessibility sizes.
    private var primaryAction: some View {
        TodayPrimaryAction(hasVerdict: vm.currentRevision != nil, isEvaluating: isEvaluating) {
            Task { await vm.requestVerdict() }
        }
    }

    private var isEvaluating: Bool {
        if case .evaluating = vm.stage {
            true
        } else {
            false
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // The judge stops breathing once a verdict is asked for; the loading state
                    // takes over the stage from there.
                    JudgeHeroView(
                        artwork: .judgeVerdict,
                        height: StageArtworkSize.judge,
                        reaction: judge,
                        idles: !isEvaluating
                    )

                    Text(
                        """
                        Foodge reads today from Health and names dinner. Tell it what you have eaten if \
                        Health has not recorded it.
                        """
                    )
                    .font(.callout)
                    // On the stage itself: `appBurgundyMuted` is measured where the wash is
                    // strongest (D145); `.secondary` would not be (D134).
                    .foregroundStyle(.appBurgundyMuted)
                    .multilineTextAlignment(.center)

                    IntakeCheckInCard(vm: vm)

                    switch vm.stage {
                    case .needsSelfReport:
                        SelfReportCheckInCard(questionFocus: $isSelfReportFocused) { report in
                            Task { await vm.submitSelfReport(report) }
                        }
                        .id(Self.stageCardID)
                    case .evidenceUnavailable:
                        EvidenceUnavailableCard(messageFocus: $isEvidenceMessageFocused) {
                            Task { await vm.requestVerdict() }
                        }
                        .id(Self.stageCardID)
                        // Never the only way out: the self-report's own copy — "There isn't enough
                        // readable data to work out today's allowance" — is true of a failed read as
                        // well as of an empty day, which is why no new sentence is invented here.
                        SelfReportCheckInCard(questionFocus: $isSelfReportFocused) { report in
                            Task { await vm.submitSelfReport(report) }
                        }
                    case let .noDishAvailable(decision):
                        NoDishAvailableCard(category: decision.category)
                            .id(Self.stageCardID)
                    case .gathering, .evaluating, .verdict, .saveFailed:
                        EmptyView()
                    }

                    if !dynamicTypeSize.pinsPrimaryAction {
                        primaryAction
                    }
                }
                .scrollTargetLayout()
                .padding()
            }
            .scrollPosition($scrollPosition)
            .pinnedPrimaryAction {
                primaryAction
            }
            .background { StageBackground(accent: .appBurgundy) }
            .disabled(isEvaluating)
            .accessibilityHidden(isEvaluating)

            if isEvaluating {
                CourtLoadingView(message: evaluatingMessage, artwork: .judgeVerdict)
            }
        }
        .navigationTitle("Today")
        .task { await vm.onAppear() }
        // The stage adds a card below the intake check-in with no navigation — below the fold, and
        // under the pinned action at standard sizes — so *Give me a verdict* looked as if it had done
        // nothing (found on the WU-29 simulator walk). Each such card is therefore:
        // - **brought into view.** The HIG's *Scroll views* guidance allows scrolling automatically
        //   "when relevant content is no longer in view", "only as much as necessary". The anchor is
        //   the card's top: the card is the last thing in the column, so at standard sizes the scroll
        //   stops at the column's end — the same place a minimal scroll would — and at accessibility
        //   sizes, where the card is taller than the screen, it opens on the question rather than
        //   the buttons. Under Reduce Motion it jumps.
        // - **reached by VoiceOver.** A card that asks for an answer takes focus (WCAG 2.4.3), as
        //   *Continue* does on Apple Health; the announcement stays as well (WCAG 4.1.3), and is all
        //   the informational no-dish card gets.
        // `logLabel` is the change key because `Stage` carries a draft and an error and is
        // deliberately not `Equatable`; "Try again" passes through `.evaluating`, so a second failure
        // announces too.
        .onChange(of: vm.stage.logLabel) { _, _ in
            switch vm.stage {
            case .evaluating:
                // The column underneath is hidden from VoiceOver while the court deliberates, so
                // focus has nowhere to go; say what is happening rather than leave silence.
                AccessibilityNotification.Announcement(String(localized: evaluatingMessage)).post()
            case .needsSelfReport:
                revealStageCard()
                AccessibilityNotification.Announcement(String(localized: SelfReportCheckInCard.question)).post()
                isSelfReportFocused = true
            case .evidenceUnavailable:
                revealStageCard()
                AccessibilityNotification.Announcement(String(localized: EvidenceUnavailableCard.message)).post()
                isEvidenceMessageFocused = true
            case .noDishAvailable:
                revealStageCard()
                AccessibilityNotification.Announcement(String(localized: noDishAvailableMessage)).post()
            case .gathering, .verdict, .saveFailed:
                break
            }
        }
    }
}

extension TodayBeforeVerdictView {
    /// Scrolls the card the stage just added into view, its top first.
    private func revealStageCard() {
        withAnimation(reduceMotion ? nil : .default) {
            scrollPosition.scrollTo(id: Self.stageCardID, anchor: .top)
        }
    }
}

#if DEBUG
    #Preview("Gathering", traits: .sampleData) {
        NavigationStack {
            TodayBeforeVerdictView(vm: PreviewDependencies.all.makeTodayViewModel())
        }
    }

    #Preview("Needs the self-report", traits: .sampleData) {
        @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.noHealthData)
            .makeTodayViewModel()

        NavigationStack {
            TodayBeforeVerdictView(vm: vm)
        }
        .task { await vm.requestVerdict() }
    }
#endif
