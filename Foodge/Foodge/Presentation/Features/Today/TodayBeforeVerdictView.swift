//
//  TodayBeforeVerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Accessibility
import SwiftUI

/// Today, before a verdict has been asked for: the check-ins the category rule needs, and the one
/// button that starts an evaluation.
///
/// Nothing on this screen asks the user what they feel like eating. The dinner-time, energy and
/// craving pickers and the free note all left with D138 — every one of them existed to steer the
/// dish, and Foodge chooses the dish. What remains is what the rule cannot work out on its own:
/// what was eaten today, and, on a day with no readable active energy, how the day went.
@MainActor
struct TodayBeforeVerdictView: View {
    @Bindable var vm: TodayViewModel

    private var evidenceFailureMessage: LocalizedStringResource {
        "Foodge couldn’t finish reading today’s evidence."
    }

    private var noDishAvailableMessage: LocalizedStringResource {
        "Nothing in Foodge’s menu fits tonight’s category on your diet. Nothing was recorded for tonight."
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
            Form {
                Section {
                    JudgeBadgeView(artwork: .judgeVerdict)
                        .frame(maxWidth: .infinity, alignment: .center)
                    // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                    // light appearance — below the 4.5:1 WCAG 1.4.3 needs. `appBurgundyMuted` is
                    // the brand's dedicated secondary-text color, tuned to ≥4.5:1 everywhere.
                    Text(
                        """
                        Foodge reads today from Health and names dinner. Tell it what you have eaten if \
                        Health has not recorded it.
                        """
                    )
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)

                IntakeCheckInSection(vm: vm)

                switch vm.stage {
                case .needsSelfReport:
                    SelfReportCheckInSection { report in
                        Task { await vm.submitSelfReport(report) }
                    }
                case .evidenceUnavailable:
                    Section {
                        Text(evidenceFailureMessage)
                        Button("Try again") {
                            Task { await vm.requestVerdict() }
                        }
                    }
                    // The retry comes first, because a read that failed once may well succeed.
                    // The user's own account comes second, because the retry must never be the
                    // only way out: on a phone whose Health has never been authorized every
                    // attempt throws, and before this the screen had no route to a verdict at
                    // all (D129). The section's own copy — "There isn't enough readable data to
                    // work out today's allowance" — is true of a failed read as well as of an
                    // empty day, which is why no new sentence is invented here.
                    SelfReportCheckInSection { report in
                        Task { await vm.submitSelfReport(report) }
                    }
                case let .noDishAvailable(decision):
                    Section {
                        // Unreachable for every shipped diet profile, and said plainly rather than
                        // papered over with a dish nothing chose (D139).
                        Text(
                            """
                            Tonight’s category is \(decision.category.displayName), and nothing in \
                            Foodge’s menu fits it on your diet.
                            """
                        )
                        Text("Nothing was recorded for tonight.")
                            .font(.footnote)
                            .foregroundStyle(.appBurgundyMuted)
                    }
                case .gathering, .evaluating, .verdict, .saveFailed:
                    EmptyView()
                }

                switch vm.stage {
                case .verdict:
                    // Tonight already has a verdict, so this offers the way back to it rather
                    // than a button that would record a second revision for the same night
                    // (D130). Popping the navigation stack lands here, and so does leaving a
                    // demonstration — both used to show "Give me a verdict" as if the evening
                    // had never been judged.
                    Section {
                        NavigationLink(value: TodayRoute.verdict) {
                            Text("Tonight’s verdict")
                        }
                    }
                case .gathering, .evaluating, .needsSelfReport, .evidenceUnavailable, .noDishAvailable, .saveFailed:
                    Section {
                        Button("Give me a verdict") {
                            Task { await vm.requestVerdict() }
                        }
                        .disabled(isEvaluating)
                    }
                }
            }
            .disabled(isEvaluating)
            .accessibilityHidden(isEvaluating)

            if isEvaluating {
                CourtLoadingView(
                    message: LocalizedStringResource(
                        "The judge is weighing tonight’s evidence…",
                        comment: "Verdict preparation loading message"
                    ),
                    artwork: .judgeVerdict
                )
            }
        }
        .navigationTitle("Today")
        .task { await vm.onAppear() }
        // The row replaces the check-in section in place, with no navigation, so VoiceOver has
        // no reason to land on it (WCAG 4.1.3). `logLabel` is the change key because `Stage`
        // carries a draft and an error and is deliberately not `Equatable`; "Try again" passes
        // through `.evaluating`, so a second failure announces too. `.noDishAvailable` is the same
        // shape of change — a section swapped in with no push — so it announces the same way.
        .onChange(of: vm.stage.logLabel) { _, _ in
            switch vm.stage {
            case .evidenceUnavailable:
                AccessibilityNotification.Announcement(String(localized: evidenceFailureMessage)).post()
            case .noDishAvailable:
                AccessibilityNotification.Announcement(String(localized: noDishAvailableMessage)).post()
            case .gathering, .evaluating, .needsSelfReport, .verdict, .saveFailed:
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
