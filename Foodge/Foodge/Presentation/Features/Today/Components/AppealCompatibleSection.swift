//
//  AppealCompatibleSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// A known compatible variant negotiation found for the craved family — accepting it only
/// records an additional fact against the existing revision; it never rewrites tonight's ruled
/// category or displayed dish.
@MainActor
struct AppealCompatibleSection: View {
    let craving: DishFamily
    let entry: CatalogueEntry
    let accept: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Section {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        DishArtPlaceholderView(family: entry.family)
                        dishText
                    }
                } else {
                    HStack(spacing: 16) {
                        DishArtPlaceholderView(family: entry.family)
                        dishText
                    }
                }
            }
            Button("Accept this instead") { accept() }
            Text("Keep the original — close this sheet to leave tonight’s verdict unchanged.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var dishText: some View {
        VStack(alignment: .leading) {
            Text(entry.variant.displayName)
                .font(.headline)
            Text(entry.family.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    Form {
        AppealCompatibleSection(
            craving: .burgers,
            entry: CatalogueEntry(family: .burgers, variant: DishCatalogue.burgers.variants[2]),
            accept: {}
        )
    }
}
