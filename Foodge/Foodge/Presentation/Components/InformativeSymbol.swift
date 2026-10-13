//
//  InformativeSymbol.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// The symbol beside a line that informs rather than acts — a Health source, a verdict reason (D151).
///
/// `appBurgundyMuted`, not the tint: the HIG's *Color* guidance keeps the brand colour for what is
/// interactive, and a burgundy symbol beside a row nobody can tap would read as one. The muted
/// colour clears 4.5:1 on every surface it sits on, more than the 3:1 a graphic needs. Decorative to
/// VoiceOver: the text beside it says everything.
///
/// Drawn in a column of one width, so the text beside a stack of them starts on one line wherever a
/// list does not align the icons itself — the verdict's reasons card (`arc-audit-hig`).
@MainActor
struct InformativeSymbol: View {
    let name: String

    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 26

    var body: some View {
        Image(systemName: name)
            .foregroundStyle(.appBurgundyMuted)
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

#Preview(traits: .sampleData) {
    Form {
        Label {
            Text(HealthKind.steps.displayName)
        } icon: {
            InformativeSymbol(name: HealthKind.steps.symbolName)
        }
    }
}
