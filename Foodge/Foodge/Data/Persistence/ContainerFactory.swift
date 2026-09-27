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
    private static let storeSidecarSuffixes = ["-wal", "-shm"]

    static var schema: Schema {
        Schema(versionedSchema: FoodgeSchemaV1.self)
    }

    /// The real on-disk container.
    static func makeLive(fileManager: FileManager = .default) throws -> ModelContainer {
        let directory = try storeDirectory(using: fileManager)
        return try makeProtected(in: directory, using: fileManager)
    }

    /// Creates the store inside `directory`, hardening around it in the order that actually works.
    ///
    /// A file's protection class is fixed when the file is created, inherited from the directory
    /// it is created in, and `setAttributes` is not recursive. So the directory is hardened
    /// *before* the container writes anything, and each store file is then set explicitly — the
    /// second pass is what corrects an app installed before this ordering existed, which would
    /// otherwise keep the container default for the life of the install.
    ///
    /// Internal rather than private so a test can drive it against a temporary directory instead
    /// of the real Application Support container.
    static func makeProtected(
        in directory: URL,
        using fileManager: FileManager = .default
    ) throws -> ModelContainer {
        try harden(directory, using: fileManager)
        let storeURL = directory.appending(path: storeFileName)
        let container = try make(at: storeURL)
        try protectStoreFiles(at: storeURL, using: fileManager)
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

    /// Excludes the store directory from backups and sets its protection class.
    ///
    /// Applied to the directory, which is what files created inside it inherit from — it does not
    /// reach files that already exist, which is why `protectStoreFiles(at:using:)` runs after
    /// creation as well. The level is `.completeUnlessOpen` rather than `.complete` deliberately:
    /// a database the app already has open must keep working if the screen locks mid-write, and
    /// `.complete` would fail those writes. A store that is not open stays unreadable while the
    /// device is locked.
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

    /// Sets the protection class on the database file and on its write-ahead log and shared
    /// memory sidecars, each of which holds the same Health-derived content as the store itself.
    private static func protectStoreFiles(at storeURL: URL, using fileManager: FileManager) throws {
        let storePath = storeURL.path(percentEncoded: false)
        let paths = [storePath] + storeSidecarSuffixes.map { storePath + $0 }

        for path in paths where fileManager.fileExists(atPath: path) {
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUnlessOpen],
                ofItemAtPath: path
            )
        }
    }
}
