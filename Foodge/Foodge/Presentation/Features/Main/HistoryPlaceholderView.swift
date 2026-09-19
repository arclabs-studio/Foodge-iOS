//
//  HistoryPlaceholderView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// History, until cases start being recorded on Day 21.
@MainActor
struct HistoryPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "No cases yet",
            systemImage: "clock.arrow.circlepath",
            description: Text("Once Foodge has ruled on a day, it is filed here with the evidence it used.")
        )
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack {
        HistoryPlaceholderView()
    }
}
