//
//  ReasonLabel.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// One of a verdict's reasons, with the symbol that names its kind (D151).
///
/// One view for both places the reasons are read — the verdict's card (`VerdictReasonsCard`) and a
/// filed case (`CaseReasonsSection`) — so the two cannot drift apart. At accessibility sizes the
/// symbol is left out: it took a quarter of the card's width at AX 5 and squeezed each reason into
/// short lines (`arc-audit-accessibility`), and it says nothing the sentence does not.
@MainActor
struct ReasonLabel: View {
    let reason: ReasonCode

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            sentence
        } else {
            Label {
                sentence
            } icon: {
                InformativeSymbol(name: reason.symbolName)
            }
        }
    }

    private var sentence: some View {
        Text(reason.displayText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview(traits: .sampleData) {
    Form {
        ForEach(SampleDecisions.spentVerdict.reasonCodes, id: \.self) { reason in
            ReasonLabel(reason: reason)
        }
    }
}
