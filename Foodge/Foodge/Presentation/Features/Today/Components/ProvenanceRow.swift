//
//  ProvenanceRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// One Health reading, or the honest absence of one.
///
/// "No readable data" only — never "denied": HealthKit cannot tell an app which one happened.
@MainActor
struct ProvenanceRow: View {
    let title: LocalizedStringResource
    let valueText: String?
    let readAt: Date?

    var body: some View {
        LabeledContent {
            if let valueText, let readAt {
                VStack(alignment: .trailing) {
                    Text(valueText)
                    Text(readAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        // `.secondary` measures ~3.4:1 against the row background in
                        // standard-contrast light — below WCAG 1.4.3's 4.5:1.
                        // `appBurgundyMuted` is ≥4.5:1 (D134).
                        .foregroundStyle(.appBurgundyMuted)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("No readable data")
                    .foregroundStyle(.appBurgundyMuted)
            }
        } label: {
            Text(title)
        }
    }
}

#Preview {
    Form {
        ProvenanceRow(title: HealthKind.activeEnergy.displayName, valueText: "410 kcal", readAt: .now)
        ProvenanceRow(title: HealthKind.dietaryEnergy.displayName, valueText: nil, readAt: nil)
    }
    // The app applies this once at `AppRootView` (D135), which no component preview sits under —
    // without it this preview renders the value slot at the platform's 3.44:1 and misrepresents
    // what ships.
    .labeledContentStyle(.readableValue)
}
