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
                        SelfReportCheckInCard { report in
                            Task { await vm.submitSelfReport(report) }
                        }
                    case .evidenceUnavailable:
                        EvidenceUnavailableCard {
                            Task { await vm.requestVerdict() }
                        }
                        // Never the only way out: the self-report's own copy — "There isn't enough
                        // readable data to work out today's allowance" — is true of a failed read as
                        // well as of an empty day, which is why no new sentence is invented here.
                        SelfReportCheckInCard { report in
                            Task { await vm.submitSelfReport(report) }
                        }
                    case let .noDishAvailable(decision):
                        NoDishAvailableCard(category: decision.category)
                    case .gathering, .evaluating, .verdict, .saveFailed:
                        EmptyView()
                    }

                    if !dynamicTypeSize.pinsPrimaryAction {
                        primaryAction
                    }
                }
                .padding()
            }
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
        // A card replaces the check-in in place, with no navigation, so VoiceOver has no reason
        // to land on it (WCAG 4.1.3). `logLabel` is the change key because `Stage` carries a draft
        // and an error and is deliberately not `Equatable`; "Try again" passes through
        // `.evaluating`, so a second failure announces too. `.noDishAvailable` is the same shape of
        // change — a card swapped in with no push — so it announces the same way.
        .onChange(of: vm.stage.logLabel) { _, _ in
            switch vm.stage {
            case .evaluating:
                // The column underneath is hidden from VoiceOver while the court deliberates, so
                // focus has nowhere to go; say what is happening rather than leave silence.
                AccessibilityNotification.Announcement(String(localized: evaluatingMessage)).post()
            case .evidenceUnavailable:
                AccessibilityNotification.Announcement(String(localized: EvidenceUnavailableCard.message)).post()
            case .noDishAvailable:
                AccessibilityNotification.Announcement(String(localized: noDishAvailableMessage)).post()
            case .gathering, .needsSelfReport, .verdict, .saveFailed:
                break
            }
        }
    }
}

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
