//
//  HistoryCaseRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// One judged day in History: the dish's artwork, its name and the date, and the category as a small
/// stamp (D145).
///
/// Side by side at standard sizes; at accessibility sizes the text column moves under the artwork so
/// a long dish name is never squeezed beside a picture.
@MainActor
struct HistoryCaseRow: View {
    let revision: SavedRevision

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 14))

        layout {
            DishArtworkView(family: revision.dishOutcome.family)

            VStack(alignment: .leading, spacing: 6) {
                Text(DishCatalogue.displayName(forVariantID: revision.dishOutcome.variantID))
                    .font(.headline)
                Text(revision.createdAt, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    // `.secondary` reads at about 3.4:1 on a light row; `appBurgundyMuted` is
                    // measured there (D134, D145).
                    .foregroundStyle(.appBurgundyMuted)
                CategoryBadgeView(category: revision.decision.category)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        List {
            NavigationLink(value: HistoryRoute.caseDetail(SampleDecisions.savedCase)) {
                HistoryCaseRow(revision: SampleDecisions.savedRevision)
            }
        }
    }
}
