//
//  FlourishBubble.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// The judge and its flourish in a speech bubble — on the verdict (`VerdictFlourishView`) and on a
/// filed case (`NarrationSection`), so a case still sounds the way its verdict did.
///
/// `text` is a validated on-device model line, or `nil` for the category's reviewed template. The
/// model half is rendered with `Text(verbatim:)`, so model output is never treated as a format string.
/// The bubble's text is primary `label` on `AppCard`, the pair `PaletteContrastTests` measures.
@MainActor
struct FlourishBubble: View {
    let text: String?
    let category: DinnerCategory

    var body: some View {
        VStack(spacing: 8) {
            JudgeBadgeView(artwork: .judgeVerdict)
            SpeechBubble(text: line.italic())
        }
    }

    private var line: Text {
        if let text {
            Text(verbatim: text)
        } else {
            Text(category.flourishTemplate)
        }
    }
}

#Preview(traits: .sampleData) {
    FlourishBubble(text: nil, category: .balanced)
        .padding()
}
