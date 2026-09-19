//
//  WelcomeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The first screen: what Foodge is, in one sentence, and the way in.
///
/// It owns no state and reads none. The flow's stack is what carries the user forward, so the
/// action is a `NavigationLink` over a typed route rather than a button that mutates a path.
@MainActor
struct WelcomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                JudgeBadgeView()

                Text("The court is now in session.")
                    .font(.largeTitle.bold())

                Text("Foodge reads what Apple Health actually recorded, weighs today against your usual fortnight, and proposes one dinner.")
                    .font(.body)

                Text("You can always see the reasoning, and you can always appeal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 32)
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink("Continue", value: OnboardingRoute.healthConnection)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
