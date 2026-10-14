//
//  StampSlamTransition.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// How the category stamp arrives on the verdict with motion on: from large and tilted, down onto
/// the page (D147). With motion off the verdict uses a plain fade instead.
@MainActor
struct StampSlamTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 2.2)
            .rotationEffect(.degrees(phase.isIdentity ? 0 : -12))
            .opacity(phase.isIdentity ? 1 : 0)
    }
}
