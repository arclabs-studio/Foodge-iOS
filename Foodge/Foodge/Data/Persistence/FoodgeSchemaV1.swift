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
/// reinstall. `DailyCase` and `VerdictRevision` joined this same version on Day 21, and `Appeal`
/// left it on Day 28 along with the appeal itself (D141) — while nothing has shipped, editing V1
/// in place is a development reinstall rather than a migration (D10, D140). Anything already in a
/// local store is discarded on the next install, which is the cost that decision accepted.
enum FoodgeSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [UserPreferences.self, DailyCase.self, VerdictRevision.self]
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
