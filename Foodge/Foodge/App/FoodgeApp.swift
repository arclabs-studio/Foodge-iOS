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
            case let .ready(session):
                // `.modelContainer(_:)` rather than `.modelContainer(_:onSetup:)`, which is
                // otherwise the rule for initial load. That overload *builds* the container
                // itself and so cannot accept the hardened, backup-excluded one
                // `makeLive()` produces (D29) — and there is nothing here to seed.
                // A `VStack`, not `.safeAreaInset(edge: .top)`. The inset draws the banner *over*
                // the navigation bars inside, because each `NavigationStack` here lays its own bar
                // out against the window's safe area rather than the inset one — which hid the
                // back button on Evidence details and the Settings gear on Today, both of them
                // untappable underneath it. Taking the height out of the layout instead gives the
                // stacks a shorter region to lay out in, so their bars sit below the banner where
                // they can be reached (D103).
                VStack(spacing: 0) {
                    if session.isDemonstration {
                        DemonstrationBanner { launch.exitDemonstration() }
                    }

                    AppRootView(dependencies: session.dependencies, demonstration: controls(for: session))
                }
                .modelContainer(session.container)
                // Outermost, and the whole guarantee of demonstration mode: `.modelContainer`
                // rebinds `@Query` but leaves `MainTabView`'s `@State` view models alive, so
                // without this the demonstration would run the **live** `TodayViewModel`
                // against real HealthKit under a "demonstration data" banner (D98).
                .id(session.id)
            case .storeUnavailable:
                StoreUnavailableView { launch.retry() }
            }
        }
    }

    /// The demonstration controls for one session, in Presentation terms.
    ///
    /// Built here rather than held by `AppLaunch` because `DemonstrationControls` is a
    /// Presentation type and `AppLaunch` is the composition root's own state — the closures are
    /// what cross, never the object.
    private func controls(for session: AppSession) -> DemonstrationControls {
        DemonstrationControls(
            running: session.demonstration,
            failure: launch.demonstrationFailure,
            start: { scenario in
                Task { await launch.startDemonstration(scenario) }
            },
            exit: { launch.exitDemonstration() }
        )
    }
}
