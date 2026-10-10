//
//  StageArtworkSize.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// How large the artwork stands on a stage screen (D145): the plan's floor is 180 pt for the judge
/// and 200 pt for the verdict's dish, at standard text sizes.
///
/// At accessibility sizes art keeps ``accessibilityScale`` of its height, so the text around it —
/// which is what someone at those sizes came for — keeps more of the screen.
enum StageArtworkSize {
    static let judge: CGFloat = 180
    static let welcomeJudge: CGFloat = 220
    static let dish: CGFloat = 200
    static let accessibilityScale: CGFloat = 0.6

    /// `height`, or its accessibility share at accessibility text sizes.
    static func height(_ height: CGFloat, at size: DynamicTypeSize) -> CGFloat {
        size.isAccessibilitySize ? height * accessibilityScale : height
    }
}
