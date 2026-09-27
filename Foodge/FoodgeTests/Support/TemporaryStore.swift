//
//  TemporaryStore.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// A fresh on-disk store location per test, so nothing leaks between them.
///
/// Lifted out of `ContainerFactoryTests`, which had it as a private helper, once
/// `DemonstrationSessionTests` needed the same thing — two copies of "where does a test put a real
/// store" is the drift D63 exists to stop.
enum TemporaryStore {
    static func makeURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "FoodgeTests-\(UUID().uuidString)")
            .appendingPathExtension("store")
    }
}
