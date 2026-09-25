//
//  AppealFailedSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import Accessibility
import SwiftUI

/// An appeal save that did not complete. Mirrors `VerdictView`'s own `.saveFailed` section —
/// `.secondary` measures below the WCAG 1.4.3 contrast floor here too, so `.appBurgundyMuted` is
/// used the same way.
@MainActor
struct AppealFailedSection: View {
    let retry: () -> Void

    private var failureMessage: LocalizedStringResource {
        "Foodge couldn’t save this appeal. Nothing has been lost — try again."
    }

    var body: some View {
        Section {
            Text(failureMessage)
                .foregroundStyle(.appBurgundyMuted)
            Button("Retry") { retry() }
        }
        // The sheet swaps its content in place, with no navigation and no focus change, so
        // VoiceOver never reaches this row on its own (WCAG 4.1.3). Announced on appearance
        // rather than from a state change: `retryAppeal()` goes `.appealFailed` straight back to
        // `.appealFailed` with no stage in between, so there is no transition to observe — a
        // second failure is silent for sighted and VoiceOver users alike. Narrowing that needs an
        // intermediate appeal stage, which is more than this unit's defect fix.
        .onAppear {
            AccessibilityNotification.Announcement(String(localized: failureMessage)).post()
        }
    }
}

#Preview {
    Form {
        AppealFailedSection(retry: {})
    }
}
