//
//  StageBackground.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The backdrop of a stage screen: the dough veil, washed from the top with the screen's accent
/// (D145).
///
/// Opaque all the way down, so Reduce Transparency has nothing to remove, and static — the stage
/// never animates. Text drawn straight onto it is primary `label`, `appBurgundy` or
/// `appBurgundyMuted`, the three `PaletteContrastTests` measures where the wash is strongest, at the
/// top, in all four appearances — never the system's `.secondary`, which reads at about 3.3:1 on
/// light dough (D134).
@MainActor
struct StageBackground: View {
    /// How much of the accent shows at the top of the stage.
    ///
    /// The contrast tests composite the accent over dough at exactly this value, so raising it
    /// past what `appBurgundyMuted` can read on fails there rather than on someone's phone.
    static let accentOpacity = 0.15

    let accent: Color

    var body: some View {
        LinearGradient(
            colors: [accent.opacity(Self.accentOpacity), accent.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .background(.appDough)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Burgundy") {
    StageBackground(accent: .appBurgundy)
}

#Preview("Treat") {
    StageBackground(accent: Color(DinnerCategory.treat.tint))
}
