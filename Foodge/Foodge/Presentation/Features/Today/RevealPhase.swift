//
//  RevealPhase.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// How far a verdict's reveal has got: the stamp lands, the dish pops, the cards arrive (D147).
enum RevealPhase: Int, Comparable {
    /// Nothing of the verdict shown yet: the reveal is about to start.
    case waiting
    case stamp
    case dish
    case cards
    /// Everything shown, nothing animating.
    case settled

    /// The three steps a reveal plays, in order.
    static let steps: [RevealPhase] = [.stamp, .dish, .cards]

    static func < (lhs: RevealPhase, rhs: RevealPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The wait before this step, measured from the one before it. The stamp's lead-in is about as
    /// long as a navigation push, so the slam does not start while the screen is still sliding in;
    /// only the three steps wait.
    var delay: Duration {
        switch self {
        case .stamp: .milliseconds(350)
        case .dish: .milliseconds(250)
        case .cards: .milliseconds(450)
        case .waiting, .settled: .zero
        }
    }

    /// How long the stamp's spring takes to touch down — when its haptic plays, so the thud lands
    /// with the stamp rather than ahead of it.
    static let stampTouchdown: Duration = .milliseconds(200)

    /// How this step arrives. Only played with motion on; with motion off the verdict settles at
    /// once and each view carries its own fade (D147).
    var springAnimation: Animation? {
        switch self {
        case .stamp: .spring(duration: 0.35, bounce: 0.25)
        case .dish: .spring(duration: 0.5, bounce: 0.4)
        case .cards: .spring(duration: 0.45, bounce: 0.15)
        case .waiting, .settled: nil
        }
    }
}
