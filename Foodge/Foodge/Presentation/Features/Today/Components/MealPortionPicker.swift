//
//  MealPortionPicker.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// One meal's portion: the whole row is a `Menu` holding a native `Picker`.
///
/// A bare `.menu` picker outside a `Form` is tappable only over its value, about 34 pt tall, and
/// inside a `ScrollView` it reported a one-line height while its value wrapped at XX Large, so the
/// second line ran across the divider (`arc-audit-accessibility`, WU-29-C). Here the row is the
/// menu's label — at least 44 pt, every word in it a target — and the `Picker` inside the menu keeps
/// the system's own choice list and checkmark. The label sits on one line when it fits and stacks
/// the meal above its value when it does not, at any text size.
@MainActor
struct MealPortionPicker: View {
    let title: LocalizedStringResource
    @Binding var portion: MealPortion?

    @ScaledMetric(relativeTo: .body) private var minimumRowHeight: CGFloat = 44

    private var value: LocalizedStringResource {
        portion?.displayName ?? "Not answered"
    }

    var body: some View {
        Menu {
            Picker(selection: $portion) {
                Text("Not answered").tag(MealPortion?.none)
                ForEach(MealPortion.allCases, id: \.self) { portion in
                    Text(portion.displayName).tag(MealPortion?.some(portion))
                }
            } label: {
                Text(title)
            }
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    name
                    Spacer(minLength: 8)
                    currentValue
                }
                VStack(alignment: .leading, spacing: 4) {
                    name
                    currentValue
                }
            }
            .frame(maxWidth: .infinity, minHeight: minimumRowHeight, alignment: .leading)
            .contentShape(.rect)
        }
        // Plain, so the meal keeps the primary text colour and only the value carries the tint.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }

    private var name: some View {
        Text(title)
            .foregroundStyle(.primary)
    }

    private var currentValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .accessibilityHidden(true)
        }
        // The tint marks the part that changes; `appBurgundy` is measured on the card fill.
        .foregroundStyle(.tint)
    }
}

#Preview {
    @Previewable @State var portion: MealPortion? = .light

    ScrollView {
        MealPortionPicker(title: MealSlot.breakfast.displayName, portion: $portion)
            .padding()
    }
}
