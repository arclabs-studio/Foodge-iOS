//
//  CategoryStampView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Tonight's category as a rubber stamp: the category's fill, a symbol, and the name in the
/// measured label colour (D145).
///
/// The name and the symbol carry the meaning; the colour only reinforces it. Treat and Light share a
/// luminance in light appearance (tomato and basil, 1.00:1, and close under red–green colour
/// blindness), so a stamp read by colour alone would fail — this one never asks to be. The dish
/// name below it stays the screen's largest text (D145), so the stamp tops out at `.title`.
@MainActor
struct CategoryStampView: View {
    let category: DinnerCategory

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: category.symbolName)
                .font(.title2.weight(.bold))
                .accessibilityHidden(true)
            // The widest face that fits on one line, stepping down a size before letting a one-word
            // name wrap. At AX 5 even the smallest step can be too wide (*Equilibrado* in Spanish);
            // the system then hyphenates rather than shrinking the word Dynamic Type enlarged.
            ViewThatFits(in: .horizontal) {
                name.font(.title.weight(.black)).fontWidth(.expanded)
                name.font(.title.weight(.black))
                name.font(.title3.weight(.black))
            }
        }
        .foregroundStyle(Color(category.onTint))
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(Color(category.tint), in: .rect(cornerRadius: 16, style: .continuous))
        .overlay {
            // The stamp's inked border, in the label colour so it reads on the fill.
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color(category.onTint).opacity(0.6), lineWidth: 2)
                .padding(5)
        }
        .rotationEffect(.degrees(-3))
        // The category is the verdict screen's heading: the first thing the rotor offers.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var name: some View {
        Text(category.displayName)
            .textCase(.uppercase)
    }
}

#Preview(traits: .sampleData) {
    VStack(spacing: 32) {
        ForEach(DinnerCategory.allCases, id: \.self) { category in
            CategoryStampView(category: category)
        }
    }
    .padding()
    .background { StageBackground(accent: .appBurgundy) }
}
