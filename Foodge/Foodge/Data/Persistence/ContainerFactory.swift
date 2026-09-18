//
//  ContainerFactory.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData

/// Builds the app's one SwiftData container.
///
/// The live store lives in Application Support rather than Documents — it is app state, not a
/// user document — and it is excluded from backups and file-protected, because what it holds is
/// derived from Health data.
enum ContainerFactory {
    private static let directoryName = "Foodge"
    private static let storeFileName = "Foodge.store"

    static var schema: Schema {
        Schema(versionedSchema: FoodgeSchemaV1.self)
    }

    /// The real on-disk container.
    static func makeLive(fileManager: FileManager = .default) throws -> ModelContainer {
        let directory = try storeDirectory(using: fileManager)
        let container = try make(at: directory.appending(path: storeFileName))
        try harden(directory, using: fileManager)
        return container
    }

    /// A container at an explicit location, for tests that need a real store they can reopen.
    static func make(at url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: FoodgeMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, url: url)
        )
    }

    /// A throwaway container for previews, tests and demonstration mode.
    ///
    /// Demonstration mode gets its own store so that a labelled synthetic scenario can never be
    /// written into someone's real history.
    static func makeInMemory() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: FoodgeMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    private static func storeDirectory(using fileManager: FileManager) throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appending(path: directoryName)
        if !fileManager.fileExists(atPath: directory.path(percentEncoded: false)) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    /// Excludes the store from backups and protects it at rest.
    ///
    /// Applied to the directory so the database's sidecar files are covered too. The protection
    /// level is `.completeUnlessOpen` rather than `.complete` deliberately: a database the app
    /// already has open must keep working if the screen locks mid-write, and `.complete` would
    /// fail those writes. Everything still stays unreadable while the device is locked and the
    /// app is not running.
    private static func harden(_ directory: URL, using fileManager: FileManager) throws {
        var directory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)

        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUnlessOpen],
            ofItemAtPath: directory.path(percentEncoded: false)
        )
    }
}
