//
//  MainTabView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The app after onboarding: Today and History, each owning its own navigation stack.
///
/// Both tabs are placeholders until Day 21 and Day 22 fill them. They are real tabs rather than
/// a "coming soon" screen so the shape of the app — and its navigation — is verified now.
@MainActor
struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "fork.knife") {
                NavigationStack {
                    TodayPlaceholderView()
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryPlaceholderView()
                }
            }
        }
    }
}

#Preview(traits: .completedOnboarding) {
    MainTabView()
}
