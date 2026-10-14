//
//  MealPortionPicker.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// One meal's portion, with "Not answered" as a real option distinct from "Skipped it".
///
/// A `MenuPickerRow` (D148): the whole row opens the choice.
@MainActor
struct MealPortionPicker: View {
    let title: LocalizedStringResource
    @Binding var portion: MealPortion?

    var body: some View {
        MenuPickerRow(title: title, value: portion.displayName, selection: $portion) {
            ForEach(MealPortion?.answers, id: \.self) { answer in
                Text(answer.displayName).tag(answer)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var portion: MealPortion? = .light

    ScrollView {
        MealPortionPicker(title: MealSlot.breakfast.displayName, portion: $portion)
            .padding()
    }
}
