//
//  FoodgeApp.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import SwiftData
import SwiftUI

@main
@MainActor
struct FoodgeApp: App {
    @State private var launch = AppLaunch()

    var body: some Scene {
        WindowGroup {
            switch launch.state {
            case .loading:
                CourtLoadingView(
                    message: LocalizedStringResource(
                        "Preparing the court…",
                        comment: "Launch loading message"
                    ),
                    artwork: .judgeWelcome
                )
                .task { await launch.load() }
            case let .ready(container, dependencies):
                // `.modelContainer(_:)` rather than `.modelContainer(_:onSetup:)`, which is
                // otherwise the rule for initial load. That overload *builds* the container
                // itself and so cannot accept the hardened, backup-excluded one
                // `makeLive()` produces (D29) — and there is nothing here to seed.
                AppRootView(dependencies: dependencies)
                    .modelContainer(container)
            case .storeUnavailable:
                StoreUnavailableView { launch.retry() }
            }
        }
    }
}
