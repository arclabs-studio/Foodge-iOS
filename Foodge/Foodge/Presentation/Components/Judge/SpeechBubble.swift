//
//  SpeechBubble.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A line spoken by the judge, in a bubble whose tail points up at whoever is speaking.
///
/// It sits **below** the speaker, so the speaker never moves when a bubble opens or changes size —
/// the judge stays under the finger that tapped it. The bubble is a stage surface (`StageSurface`),
/// so its text is primary `label` on the fill `PaletteContrastTests` measures.
@MainActor
struct SpeechBubble: View {
    let text: Text

    var body: some View {
        text
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.top, Outline.tailHeight)
            .stageSurface(in: Outline())
    }
}

extension SpeechBubble {
    /// A rounded rectangle with a tail centred on its top edge.
    private struct Outline: Shape {
        static let tailHeight: CGFloat = 10
        private static let tailWidth: CGFloat = 20
        private static let cornerRadius: CGFloat = 18

        func path(in rect: CGRect) -> Path {
            let body = CGRect(
                x: rect.minX,
                y: rect.minY + Self.tailHeight,
                width: rect.width,
                height: rect.height - Self.tailHeight
            )
            let bubble = Path(roundedRect: body, cornerRadius: Self.cornerRadius, style: .continuous)
            var tail = Path()
            // Ends a point inside the body so the union has no seam where the two meet.
            tail.move(to: CGPoint(x: rect.midX - Self.tailWidth / 2, y: body.minY + 1))
            tail.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            tail.addLine(to: CGPoint(x: rect.midX + Self.tailWidth / 2, y: body.minY + 1))
            tail.closeSubpath()
            return bubble.union(tail)
        }
    }
}

#Preview {
    SpeechBubble(text: Text(JudgeQuip.regulationWig.text))
        .padding()
        .background { StageBackground(accent: .appBurgundy) }
}
