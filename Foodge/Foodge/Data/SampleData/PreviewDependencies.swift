//
//  PreviewDependencies.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

#if DEBUG
import Foundation

/// The dependency sets previews are built from.
///
/// A `#Preview` is a composition root, which is why this file may name ``AppDependencies``
/// while production Presentation code may not (D34). It is `#if DEBUG` and never reaches the
/// shipped binary.
///
/// It vends **Domain-typed seams only**, never a ready-made ViewModel: handing out a ViewModel
/// would put presentation decisions in Data and quietly become a second place where a screen's
/// state is decided.
enum PreviewDependencies {
    /// A device with Health, a typical recorded fortnight, and a store that accepts writes.
    static var all: AppDependencies {
        connected(SyntheticScenarios.typicalDay)
    }

    /// A device with no Health data at all.
    static func healthUnavailable() -> AppDependencies {
        make(
            authorization: PreviewAuthorization(isHealthDataAvailable: false),
            snapshot: SyntheticScenarios.noHealthData.snapshot
        )
    }

    /// Health connected, reading one labelled demonstration scenario.
    static func connected(_ scenario: SyntheticScenario) -> AppDependencies {
        make(
            authorization: PreviewAuthorization(isHealthDataAvailable: true),
            snapshot: scenario.snapshot
        )
    }

    /// Everything readable, but the store refuses to write — the save-failed state.
    static func savingFails() -> AppDependencies {
        make(
            authorization: PreviewAuthorization(isHealthDataAvailable: true),
            snapshot: SyntheticScenarios.typicalDay.snapshot,
            storeFailure: .saveFailed
        )
    }

    private static func make(
        authorization: PreviewAuthorization,
        snapshot: EvidenceSnapshot,
        storeFailure: FoodgeError? = nil
    ) -> AppDependencies {
        AppDependencies(
            authorization: authorization,
            evidence: PreviewEvidence(scripted: snapshot),
            store: PreviewStore(failure: storeFailure),
            clock: SyntheticScenarios.clock
        )
    }
}

/// Reports availability without presenting anything — there is no system sheet in a preview.
private struct PreviewAuthorization: HealthAuthorizing {
    let isHealthDataAvailable: Bool

    func requestReadAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw FoodgeError.healthUnavailable
        }
    }
}

/// Hands back one fixed snapshot, whatever it is asked for.
private struct PreviewEvidence: HealthEvidenceProvider {
    let scripted: EvidenceSnapshot

    func snapshot(
        at date: Date,
        calendar: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        scripted
    }
}

/// Accepts writes and keeps them for the life of the preview, or refuses them all.
private actor PreviewStore: PreferencesStore {
    private let failure: FoodgeError?
    private var drafts: [PreferencesDraft] = []

    init(failure: FoodgeError?) {
        self.failure = failure
    }

    func savePreferences(_ draft: PreferencesDraft) async throws {
        if let failure {
            throw failure
        }
        drafts.append(draft)
    }

    func preferences() async throws -> PreferencesDraft? {
        drafts.last
    }
}
#endif
