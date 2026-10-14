//
//  StageCardGroupBoxStyle.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The card look for a native `GroupBox` on a stage screen (D145).
///
/// Drawn as a `StageSurface`: `AppCard` with a hairline edge — white in light appearance, and in
/// dark a warm grey lighter than dough and than the top of every stage wash, so the card advances
/// the way the HIG asks elevated content to in Dark Mode. `secondarySystemGroupedBackground` was the
/// first choice and is darker than the dark stage — the card read as a hole in it.
///
/// Colour goes into the stage around the cards, never under their text. Inside a card, text is
/// primary `label`, `appBurgundy` or `appBurgundyMuted` — the three `PaletteContrastTests` measures
/// on that fill — and never the system's `.secondary`, which reads at about 3.4:1 on a light row
/// (D134). Deliberately not Liquid Glass: the HIG keeps glass for the navigation and control
/// layer, and a card is content.
///
/// Declared on the type, matching `ReadableValueLabeledContentStyle`.
@MainActor
struct StageCardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline)
                // A card's title names the section below it, the way a `Section` header would in
                // a `Form` — so it reaches the VoiceOver rotor's Headings list.
                .accessibilityAddTraits(.isHeader)
            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .stageSurface(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

extension GroupBoxStyle where Self == StageCardGroupBoxStyle {
    /// A card on a stage screen.
    static var stageCard: StageCardGroupBoxStyle {
        .init()
    }
}

#Preview("On the stage") {
    VStack(spacing: 16) {
        GroupBox("Eaten so far") {
            Text("Nothing was recorded for tonight.")
        }
        GroupBox {
            Text("Nothing was recorded for tonight.")
        }
    }
    .groupBoxStyle(.stageCard)
    .padding()
    .frame(maxHeight: .infinity, alignment: .top)
    .background { StageBackground(accent: Color(DinnerCategory.balanced.tint)) }
}
