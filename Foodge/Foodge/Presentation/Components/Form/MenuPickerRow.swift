//
//  MenuPickerRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A choice as a whole row: the row is a `Menu`'s label and a native `Picker` sits inside the menu.
///
/// Every `Picker` in the app is one of these (D148), because of two failures of the plain picker.
/// Outside a `Form`, a `.menu` picker is tappable only over its value — about 34 pt — and inside a
/// `ScrollView` it reported a one-line height while its value wrapped, so the second line ran across
/// the divider (WU-29-C). Inside a `Form`, the system draws its value in `.secondary`, about 3.4:1 on
/// a light row. Here the row is at least 44 pt, every word in it a target; the value is drawn in the
/// tint (`appBurgundy`, measured on every surface a row sits on); and the `Picker` inside the menu
/// keeps the system's own choice list and checkmark. The label sits on one line when it fits and
/// stacks the name above the value when it does not.
///
/// A struct rather than a `*Style`, because no style can do this: `PickerStyle` has no public
/// requirements to implement, and `MenuStyleConfiguration` carries only a label and the content, with
/// no title and value to lay out. What it draws by hand is the row — the chevron, the tint and the
/// height; the menu, the list, the checkmark and the selection stay the system's. `Menu { Picker }` is
/// the pattern Apple's "Populating SwiftUI menus with adaptive controls" uses.
@MainActor
struct MenuPickerRow<Selection: Hashable, Options: View>: View {
    let title: LocalizedStringResource
    /// What the current selection is called — the text the row shows and VoiceOver reads as its value.
    let value: LocalizedStringResource
    @Binding var selection: Selection
    @ViewBuilder let options: Options

    @ScaledMetric(relativeTo: .body) private var minimumRowHeight: CGFloat = 44

    var body: some View {
        Menu {
            Picker(selection: $selection) {
                options
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
            // Breathing room once the text outgrows the minimum height, as the row insets this row
            // gives up (below) would have provided. At standard sizes the minimum height decides.
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minimumRowHeight, alignment: .leading)
            .contentShape(.rect)
        }
        // Plain, so the name keeps the primary text colour and only the value carries the tint.
        .buttonStyle(.plain)
        // In a `Form` the label *is* the row: without this the 44 pt label sat inside the row's own
        // vertical insets, about 20 pt taller than its neighbours, and the insets were not a target.
        // Outside a list it does nothing.
        .listRowInsets(.vertical, 0)
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
        .foregroundStyle(.tint)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var dietProfile = DietProfile.vegetarian

    Form {
        MenuPickerRow(title: "Diet", value: dietProfile.displayName, selection: $dietProfile) {
            ForEach(DietProfile.allCases, id: \.self) { profile in
                Text(profile.displayName).tag(profile)
            }
        }
    }
}
