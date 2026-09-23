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
    let caseStore: any CaseStore
    let clock: any EvaluationClock
    let narrator: any VerdictNarrator

    init(
        authorization: any HealthAuthorizing,
        evidence: any HealthEvidenceProvider,
        store: any PreferencesStore,
        caseStore: any CaseStore,
        clock: any EvaluationClock,
        narrator: any VerdictNarrator
    ) {
        self.authorization = authorization
        self.evidence = evidence
        self.store = store
        self.caseStore = caseStore
        self.clock = clock
        self.narrator = narrator
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

    /// Builds the Today view model from these dependencies.
    @MainActor
    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            evidence: evidence,
            preferences: store,
            caseStore: caseStore,
            clock: clock,
            narrator: narrator
        )
    }

    /// Builds the History view model from these dependencies.
    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(caseStore: caseStore)
    }

    /// The real thing: HealthKit, the on-disk store, and the device's own clock.
    ///
    /// `store` and `caseStore` share one `PersistenceActor` over the container — it already
    /// conforms to both protocols, and two separate actors over the same `ModelContainer` would
    /// race needlessly.
    init(container: ModelContainer) {
        let persistence = PersistenceActor(modelContainer: container)
        self.init(
            authorization: HealthAuthorizationService(),
            evidence: HealthEvidenceReader(source: HealthKitSampleSource()),
            store: persistence,
            caseStore: persistence,
            clock: SystemClock(),
            // Read outside in: the budget is enforced first, so a slow generation is cancelled
            // rather than validated late; validation then stands between the model and everything
            // above it. Splitting the chain this way is what makes the timeout, malformed output,
            // invented numbers and note-echo paths testable off-device.
            narrator: DeadlineNarrator(
                budget: .seconds(8),
                wrapped: ValidatingNarrator(wrapped: FoundationModelsNarrator())
            )
        )
    }
}
