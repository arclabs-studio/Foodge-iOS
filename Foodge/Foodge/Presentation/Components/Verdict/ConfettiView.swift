//
//  ConfettiView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A short burst of confetti in the verdict's palette (D147).
///
/// Decorative and finite: it falls for 2.5 s from when it appears — inside WCAG 2.2.2's five
/// seconds — then draws nothing and pauses its timeline. Under Reduce Motion it draws nothing at
/// all, whoever inserts it. Hidden from VoiceOver and from hit testing.
@MainActor
struct ConfettiView: View {
    let colors: [Color]

    @State private var startDate = Date.now
    @State private var finished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let duration: TimeInterval = 2.5
    private static let pieceCount = 70

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: finished || reduceMotion)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard !reduceMotion, elapsed < Self.duration, !colors.isEmpty else { return }
                let progress = elapsed / Self.duration
                for index in 0 ..< Self.pieceCount {
                    let piece = Piece(index: index)
                    var pieceContext = context
                    pieceContext.opacity = progress < 0.7 ? 1 : max(0, (1 - progress) / 0.3)
                    pieceContext.translateBy(
                        x: piece.x * size.width + sin(elapsed * piece.sway + piece.phase) * 18,
                        y: -24 + size.height * 0.95 * progress * piece.fall
                    )
                    pieceContext.rotate(by: .radians(elapsed * piece.spin))
                    pieceContext.fill(
                        Path(roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12), cornerRadius: 2),
                        with: .color(colors[index % colors.count])
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            do {
                try await Task.sleep(for: .seconds(Self.duration))
            } catch {
                return
            }
            finished = true
        }
    }
}

extension ConfettiView {
    /// One piece's flight, fixed by its index so every burst looks the same and nothing random
    /// runs per frame.
    private struct Piece {
        let x: Double
        let fall: Double
        let sway: Double
        let phase: Double
        let spin: Double

        init(index: Int) {
            /// A stable value in 0..<1 from the index and a salt — the classic shader hash.
            func unit(_ salt: Double) -> Double {
                let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43_758.5453
                return value - value.rounded(.down)
            }
            x = unit(1)
            fall = 0.6 + unit(2) * 0.5
            sway = 2 + unit(3) * 4
            phase = unit(4) * .pi * 2
            spin = (unit(5) - 0.5) * 12
        }
    }
}

#Preview {
    ConfettiView(colors: [.appTomato, .appGold, .appBasil, .appCheese, .appBurgundy])
        .background { StageBackground(accent: Color(DinnerCategory.treat.tint)) }
}
