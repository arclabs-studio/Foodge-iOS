//
//  TodayPlaceholderView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// Today, until the verdict flow arrives on Day 21.
///
/// Deliberately a `ContentUnavailableView` rather than an invented mock: showing a fake verdict
/// would make a screen that lies for a living.
@MainActor
struct TodayPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "No verdict yet",
            systemImage: "fork.knife",
            description: Text("The judge is still reviewing the evidence. Tonight’s verdict arrives soon.")
        )
        .navigationTitle("Today")
    }
}

#Preview {
    NavigationStack {
        TodayPlaceholderView()
    }
}
