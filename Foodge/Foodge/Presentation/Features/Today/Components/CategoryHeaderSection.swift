//
//  CategoryHeaderSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// The category header both `VerdictView` and `CaseDetailView` show: the judge badge, the
/// category name, and — when the decision was provisional — the caveat naming that.
@MainActor
struct CategoryHeaderSection: View {
    let category: DinnerCategory
    let isProvisional: Bool

    var body: some View {
        Section {
            JudgeBadgeView(artwork: .judgeVerdict)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(category.displayName)
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                // The category name is this screen's de facto page heading — `VerdictView` and
                // `CaseDetailView` are both single-Form screens with no other title-level text.
                // Expose it to the VoiceOver rotor's Headings list (4.1.2).
                .accessibilityAddTraits(.isHeader)
            if isProvisional {
                Text("Provisional — there wasn’t enough to go on yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    Form {
        CategoryHeaderSection(category: .balanced, isProvisional: false)
    }
}

#Preview("Provisional") {
    Form {
        CategoryHeaderSection(category: .balanced, isProvisional: true)
    }
}
