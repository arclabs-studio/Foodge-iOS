//
//  FavouriteFamiliesSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The dish families of one category, each of which the user can mark as a favourite.
///
/// One section per category rather than one long list: the categories are what the verdict
/// actually rules for, so seeing which is which is part of understanding the app.
@MainActor
struct FavouriteFamiliesSection: View {
    let category: DinnerCategory
    let favourites: [DishFamily]
    let toggle: (DishFamily) -> Void

    var body: some View {
        Section {
            ForEach(category.families, id: \.self) { family in
                SelectableRow(
                    title: family.displayName,
                    isSelected: favourites.contains(family)
                ) {
                    toggle(family)
                }
            }
        } header: {
            Text(category.displayName)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        FavouriteFamiliesSection(category: .treat, favourites: [.tacos], toggle: { _ in })
        FavouriteFamiliesSection(category: .light, favourites: [], toggle: { _ in })
    }
}
