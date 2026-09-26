//
//  DishCatalogue+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import Foundation

extension DishCatalogue {
    /// The variant's display name for `id`, or `id` itself when a catalogue version has since
    /// renamed or removed it — the same "stored ids outlive the live catalogue" reasoning
    /// `entry(id:)` already documents.
    static func displayName(forVariantID id: String) -> String {
        entry(id: id).map { String(localized: $0.variant.displayName) } ?? id
    }
}
