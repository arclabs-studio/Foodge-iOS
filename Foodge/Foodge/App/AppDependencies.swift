//
//  AppDependencies.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData

/// Everything the app's screens need, in Domain terms.
///
/// The composition root builds one of these; nothing in Presentation ever names a concrete Data
/// type, which is what keeps the dependency direction one-way.
struct AppDependencies: Sendable {
    let authorization: any HealthAuthorizing
    let evidence: any HealthEvidenceProvider
    let store: any PreferencesStore
    let clock: any EvaluationClock

    init(
        authorization: any HealthAuthorizing,
        evidence: any HealthEvidenceProvider,
        store: any PreferencesStore,
        clock: any EvaluationClock
    ) {
        self.authorization = authorization
        self.evidence = evidence
        self.store = store
        self.clock = clock
    }

    /// Builds the onboarding view model from these dependencies.
    ///
    /// The assembly lives here, in the composition root, rather than as an initializer on the
    /// view model: `AppDependencies` is an App-layer type, and Presentation may not name it
    /// (D34). Presentation only ever sees the four Domain protocols.
    @MainActor
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            authorization: authorization,
            evidence: evidence,
            store: store,
            clock: clock
        )
    }

    /// The real thing: HealthKit, the on-disk store, and the device's own clock.
    init(container: ModelContainer) {
        self.init(
            authorization: HealthAuthorizationService(),
            evidence: HealthEvidenceReader(source: HealthKitSampleSource()),
            store: PersistenceActor(modelContainer: container),
            clock: SystemClock()
        )
    }
}
