//
//  DishSummaryRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// One dish, art plus name plus family — the row both `VerdictView` and `CaseDetailView` show for
/// a `.selected` dish outcome. Callers resolve which variant/family to display (e.g. `VerdictView`
/// toggling to an alternative) before handing this the id and family to render.
@MainActor
struct DishSummaryRow: View {
    let variantID: String
    let family: DishFamily

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // P2: at accessibility sizes the scaled art placeholder and a wrapped multi-line title
        // no longer fit side by side in an HStack — the title overlaps the icon. Stack vertically
        // once Dynamic Type crosses into accessibility sizes instead.
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                DishArtPlaceholderView(family: family)
                textColumn
            }
        } else {
            HStack(spacing: 16) {
                DishArtPlaceholderView(family: family)
                textColumn
            }
        }
    }

    private var textColumn: some View {
        VStack(alignment: .leading) {
            Text(DishCatalogue.displayName(forVariantID: variantID))
                .font(.headline)
            Text(family.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    Form {
        Section {
            DishSummaryRow(variantID: "dish.pasta.pesto", family: .pasta)
        }
    }
}
