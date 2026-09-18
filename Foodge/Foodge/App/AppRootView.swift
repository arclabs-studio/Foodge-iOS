//
//  AppRootView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import SwiftUI

/// Root of the app's view hierarchy and the single place that decides which experience is shown.
///
/// It currently shows a placeholder: the feasibility probe takes this slot for Day 18, and the
/// onboarding flow and main tabs replace it on Day 19.
@MainActor
struct AppRootView: View {
    var body: some View {
        ContentUnavailableView(
            "Foodge",
            systemImage: "fork.knife",
            description: Text("The court is not in session yet.")
        )
    }
}

#Preview {
    AppRootView()
}
