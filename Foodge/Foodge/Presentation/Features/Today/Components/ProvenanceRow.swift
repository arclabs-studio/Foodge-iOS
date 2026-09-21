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
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("No readable data")
                    .foregroundStyle(.secondary)
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
}
