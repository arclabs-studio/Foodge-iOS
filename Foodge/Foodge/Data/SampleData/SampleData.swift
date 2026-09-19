//
//  SampleData.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftData
import SwiftUI

/// An in-memory container for previews, so no preview can ever touch a real store.
///
/// `makeSharedContext()` is `async throws`, which is why no `#Preview` body ever needs a `try`
/// or a `fatalError`: a container that fails to build fails the preview, not the app.
struct SampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        try ContainerFactory.makeInMemory()
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

/// The same container, with onboarding already completed.
///
/// A separate type rather than a parameter because `makeSharedContext()` is static — a
/// parameter would have nowhere to live.
struct CompletedOnboardingSampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ContainerFactory.makeInMemory()
        try await PersistenceActor(modelContainer: container).savePreferences(
            PreferencesDraft(
                dietProfile: .vegetarian,
                favouriteFamilies: [.tacos, .riceBowls],
                dinnerRoutine: .quick,
                onboardingCompletedAt: SyntheticScenarios.evaluationDate
            )
        )
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    /// An empty store: what a first launch looks like.
    static var sampleData: Self { .modifier(SampleData()) }

    /// A store whose onboarding is already done: what every later launch looks like.
    static var completedOnboarding: Self { .modifier(CompletedOnboardingSampleData()) }
}
