//
//  TodayPrimaryAction.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Today's one prominent action: ask for a verdict, or — once tonight has one — go back to it.
///
/// When tonight already has a verdict this offers the way back to it rather than a button that
/// would record a second revision for the same night (D130). Popping the navigation stack lands on
/// Today, and so does leaving a demonstration — both used to show "Give me a verdict" as if the
/// evening had never been judged.
@MainActor
struct TodayPrimaryAction: View {
    let hasVerdict: Bool
    let isEvaluating: Bool
    let requestVerdict: () -> Void

    var body: some View {
        if hasVerdict {
            NavigationLink(value: TodayRoute.verdict) {
                Text("Tonight’s verdict")
            }
            .primaryAction()
        } else {
            Button("Give me a verdict", action: requestVerdict)
                .primaryAction()
                .disabled(isEvaluating)
        }
    }
}

#Preview("Ask", traits: .sampleData) {
    NavigationStack {
        TodayPrimaryAction(hasVerdict: false, isEvaluating: false, requestVerdict: {})
            .padding()
    }
}

#Preview("Back to tonight's verdict", traits: .sampleData) {
    NavigationStack {
        TodayPrimaryAction(hasVerdict: true, isEvaluating: false, requestVerdict: {})
            .padding()
    }
}
