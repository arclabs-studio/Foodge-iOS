//
//  IntakeCheckInCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// Where the user says what they have eaten so far, for the days Health did not log it.
///
/// Three pickers, each with a "Not answered" option that is **not** the same as "Skipped": an
/// unanswered meal contributes nothing and leaves the questionnaire unusable, while a skipped one is
/// an answer worth zero. The rule depends on that distinction, so the control has to offer both.
///
/// A stage card since D145, so each meal is a menu: a `.navigationLink` picker needs a list to live
/// in, and this card is not one.
@MainActor
struct IntakeCheckInCard: View {
    @Bindable var vm: TodayViewModel

    var body: some View {
        GroupBox("Eaten so far") {
            VStack(alignment: .leading, spacing: 12) {
                MealPortionPicker(title: MealSlot.breakfast.displayName, portion: $vm.breakfast)
                Divider()
                MealPortionPicker(title: MealSlot.lunch.displayName, portion: $vm.lunch)
                Divider()
                MealPortionPicker(title: MealSlot.snacks.displayName, portion: $vm.snacks)

                Text(
                    """
                    Only used when Apple Health has no food logged for today. What Health recorded \
                    always replaces these answers rather than adding to them.
                    """
                )
                .font(.footnote)
                // `.secondary` reads at about 3.4:1 on a light card; `appBurgundyMuted` is measured
                // on it by `PaletteContrastTests` (D134, D145).
                .foregroundStyle(.appBurgundyMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            }
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.all.makeTodayViewModel()

    ScrollView {
        IntakeCheckInCard(vm: vm)
            .padding()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
