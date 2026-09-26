//
//  HealthUnavailableSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// What Foodge says when there is no recorded pattern to show.
///
/// The single place these three outcomes are worded, so the distinction cannot drift: a device
/// without Health, a read that came back empty, and a request that did not complete are three
/// different facts. None of them is a denial — Health cannot tell an app that — and none of
/// them uses the word.
@MainActor
struct HealthUnavailableSection: View {
    let state: OnboardingViewModel.HealthState
    let retry: () -> Void

    var body: some View {
        switch state {
        case .unavailable:
            // `.secondary` measures ~3.4:1 against the row background in standard-contrast light
            // appearance — below the 4.5:1 WCAG 1.4.3 needs. `AppBurgundyMuted` is the brand's
            // dedicated secondary-text color, tuned to ≥4.5:1 in every appearance/contrast
            // combination.
            Section {
                Text("This iPhone doesn’t have Health data available.")
                Text("Foodge will ask you about your day instead, and the verdict says so.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }
        case .noReadableData:
            Section {
                // Two staleness bugs in one sentence, both found on the fresh-install rehearsal
                // (D133). "These days" is the deleted fourteen-day window still talking (D111),
                // when only **today** is ever at stake now; and the screen said nothing at all
                // about the request having completed, so after granting all six topics a user
                // saw an unchanged "Connect Apple Health" button and no sign it had worked.
                // The replacement says what Foodge actually knows — it asked, and nothing came
                // back for today — and still claims no grant, because HealthKit cannot report
                // one and this app never pretends otherwise.
                Text("Foodge asked Health for access. Nothing readable came back for today.")
                Text("That can simply mean nothing has been recorded yet. Foodge will ask you about your day instead.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }
        case .previouslyAnswered:
            Section {
                // The sheet is not coming back, and saying "try again" here would be a lie the
                // user can test in one tap (D137). The path is spelled out in the copy as well as
                // offered as a button, so the sentence stays true even where the link cannot
                // open. Still no word about a denial: iOS reports that it asked, never how it
                // was answered.
                Text("Health has already been asked about Foodge, so iOS won’t show its sheet again.")
                Text("Open Health, then Sharing → Apps → Foodge to change what Foodge may read. Until then it will ask you about your day instead.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
                if let url = URL.healthApp {
                    Link("Open Health", destination: url)
                }
            }
        case .requestFailed:
            Section {
                Text("Foodge couldn’t finish asking for access to Health.")
                Button("Try again", action: retry)
            }
        case .idle, .requesting, .connected:
            EmptyView()
        }
    }
}

private extension URL {
    /// Apple Health's own app.
    ///
    /// Optional rather than force-unwrapped, and the section renders without the button when it
    /// is `nil` — the written path above is what the user actually needs, and it does not depend
    /// on this resolving.
    static let healthApp = URL(string: "x-apple-health://")
}

#Preview("Health unavailable", traits: .sizeThatFitsLayout) {
    Form {
        HealthUnavailableSection(state: .unavailable, retry: {})
    }
}

#Preview("Already answered", traits: .sizeThatFitsLayout) {
    Form {
        HealthUnavailableSection(state: .previouslyAnswered, retry: {})
    }
}

#Preview("Request failed", traits: .sizeThatFitsLayout) {
    Form {
        HealthUnavailableSection(state: .requestFailed, retry: {})
    }
}
