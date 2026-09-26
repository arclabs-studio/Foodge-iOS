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

#Preview("Health unavailable", traits: .sizeThatFitsLayout) {
    Form {
        HealthUnavailableSection(state: .unavailable, retry: {})
    }
}

#Preview("Request failed", traits: .sizeThatFitsLayout) {
    Form {
        HealthUnavailableSection(state: .requestFailed, retry: {})
    }
}
