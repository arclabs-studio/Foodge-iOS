//
//  FoodgeSchemaV1.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData

/// The first shipped schema.
///
/// Versioned from the start so that the first real change is a migration rather than a
/// reinstall. `DailyCase`, `VerdictRevision` and `Appeal` join this same version on Day 21,
/// while nothing has shipped and growing V1 is still a development reinstall (D10).
enum FoodgeSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [UserPreferences.self]
    }
}

/// The migration plan.
///
/// It has no stages yet because there is only one version. It exists now so that adding the
/// second version is an edit to an established path rather than a new decision made under time
/// pressure, and so the store is never migrated destructively by accident.
enum FoodgeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FoodgeSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
