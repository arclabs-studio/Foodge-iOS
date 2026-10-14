//
//  JudgeButtonStyle.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The judge's press: a squash toward the floor while a finger is down (D146).
///
/// Only restyles `Button`'s own `isPressed`; the press tracking itself — cancelling by dragging
/// off, keyboard and assistive activation — is the `Button`'s. With motion off, the squash becomes
/// a dim, so a press still shows without anything moving.
@MainActor
struct JudgeButtonStyle: ButtonStyle {
    /// `false` under Reduce Motion, or wherever the judge is held still.
    let motion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(motion && configuration.isPressed ? 0.92 : 1, anchor: .bottom)
            .opacity(!motion && configuration.isPressed ? 0.7 : 1)
            .animation(
                motion ? .spring(duration: 0.2, bounce: 0.5) : .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
            .contentShape(.rect)
    }
}
