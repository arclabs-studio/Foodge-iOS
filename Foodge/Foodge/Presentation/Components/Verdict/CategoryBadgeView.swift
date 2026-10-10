//
//  CategoryBadgeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A category as a small stamp for a list row: the fill, the symbol and the name in the measured
/// label colour (D145).
///
/// The name carries the meaning, so the badge reads the same to someone who cannot tell tomato from
/// basil, and the symbol is the first thing to go when space runs out.
@MainActor
struct CategoryBadgeView: View {
    let category: DinnerCategory

    var body: some View {
        // The widest form that fits on one line: with the symbol, without it, a size smaller, then
        // in mixed case, which is narrower than capitals. Past all four the name wraps rather than
        // shrinking what Dynamic Type enlarged.
        ViewThatFits(in: .horizontal) {
            capsule(showsSymbol: true, font: .caption.weight(.heavy))
            capsule(showsSymbol: false, font: .caption.weight(.heavy))
            capsule(showsSymbol: false, font: .caption2.weight(.heavy))
            capsule(showsSymbol: false, font: .caption2.weight(.heavy), textCase: nil)
        }
    }

    private func capsule(showsSymbol: Bool, font: Font, textCase: Text.Case? = .uppercase) -> some View {
        HStack(spacing: 6) {
            if showsSymbol {
                Image(systemName: category.symbolName)
                    .accessibilityHidden(true)
            }
            Text(category.displayName)
                .textCase(textCase)
                // A list row would otherwise measure it at one line and truncate it.
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(font)
        .foregroundStyle(Color(category.onTint))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(category.tint), in: .capsule)
    }
}

#Preview(traits: .sampleData) {
    VStack(spacing: 12) {
        ForEach(DinnerCategory.allCases, id: \.self) { category in
            CategoryBadgeView(category: category)
        }
    }
    .padding()
}
