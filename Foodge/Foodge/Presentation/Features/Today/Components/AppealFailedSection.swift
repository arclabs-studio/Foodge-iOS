//
//  AppealFailedSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// An appeal save that did not complete. Mirrors `VerdictView`'s own `.saveFailed` section —
/// `.secondary` measures below the WCAG 1.4.3 contrast floor here too, so `.appBurgundyMuted` is
/// used the same way.
@MainActor
struct AppealFailedSection: View {
    let retry: () -> Void

    var body: some View {
        Section {
            Text("Foodge couldn’t save this appeal. Nothing has been lost — try again.")
                .foregroundStyle(.appBurgundyMuted)
            Button("Retry") { retry() }
        }
    }
}

#Preview {
    Form {
        AppealFailedSection(retry: {})
    }
}
