//
//  AppealRecordedSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// Confirms what an appeal recorded. Tonight's ruled category and dish stay exactly as they were
/// — this only names the additional fact just saved.
@MainActor
struct AppealRecordedSection: View {
    let choice: AppealChoice

    var body: some View {
        Section {
            switch choice {
            case let .catalogue(variantID, family):
                let name = DishCatalogue.displayName(forVariantID: variantID)
                Text("Noted: \(name) (\(String(localized: family.displayName))).")
            case let .freeText(text):
                Text("Noted: \(text).")
            }
            Text("Tonight’s verdict stays as it was — this is recorded alongside it.")
                .font(.footnote)
                // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                // light — below WCAG 1.4.3's 4.5:1. `appBurgundyMuted` is ≥4.5:1 (D134).
                .foregroundStyle(.appBurgundyMuted)
        }
    }
}

#Preview("Catalogue choice") {
    Form {
        AppealRecordedSection(choice: .catalogue(variantID: "dish.burgers.blackBean", family: .burgers))
    }
}

#Preview("Free text") {
    Form {
        AppealRecordedSection(choice: .freeText("Grandma’s stew"))
    }
}
