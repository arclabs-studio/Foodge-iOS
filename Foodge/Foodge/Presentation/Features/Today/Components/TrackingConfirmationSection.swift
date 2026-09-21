//
//  TrackingConfirmationSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// "Does the recorded activity reflect today?" — asked before a low reading may become a light
/// verdict, because a forgotten watch looks exactly like a quiet day.
@MainActor
struct TrackingConfirmationSection: View {
    let confirm: (Bool) -> Void

    var body: some View {
        Section {
            Text("Today’s recorded activity is well below your usual pattern.")
            Text("Does that reflect today — or is something like a forgotten watch more likely?")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Yes, that’s today") { confirm(true) }
            Button("No, that’s not today") { confirm(false) }
        }
    }
}

#Preview {
    Form {
        TrackingConfirmationSection(confirm: { _ in })
    }
}
