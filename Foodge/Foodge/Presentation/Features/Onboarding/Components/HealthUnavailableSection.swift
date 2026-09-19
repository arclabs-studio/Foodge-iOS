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
            Section {
                Text("This iPhone doesn’t have Health data available.")
                Text("Foodge will ask you about your day instead, and the verdict says so.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .noReadableData:
            Section {
                Text("Health didn’t return anything readable for these days.")
                Text("That can simply mean nothing has been recorded yet. Foodge will ask you about your day instead.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
