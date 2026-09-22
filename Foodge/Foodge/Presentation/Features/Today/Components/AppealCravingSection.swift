//
//  AppealCravingSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// Every family the catalogue has, unrestricted by category — an appeal may accept a dish from a
/// different category than the ruled one (`foodge-plan.md` §3) — plus a free-text escape hatch.
@MainActor
struct AppealCravingSection: View {
    let choose: (DishFamily) -> Void
    let chooseFreeText: () -> Void

    var body: some View {
        Section("What are you craving instead?") {
            ForEach(DishFamily.allCases, id: \.self) { family in
                Button(String(localized: family.displayName)) { choose(family) }
            }
            Button("Something else") { chooseFreeText() }
        }
    }
}

#Preview {
    Form {
        AppealCravingSection(choose: { _ in }, chooseFreeText: {})
    }
}
