//
//  VerdictRevision.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import SwiftData

/// One immutable revision of a case's verdict.
///
/// `sequence`, not `createdAt`, is the canonical order: two revisions created in the same
/// instant could tie on a timestamp but never on sequence.
@Model
final class VerdictRevision {
    @Attribute(.unique) var id: UUID
    var sequence: Int
    var createdAt: Date
    var dailyCase: DailyCase?

    /// `VerdictDecision` JSON-encoded whole. `CategoryBasis`'s associated values don't map to
    /// flat SwiftData columns without a second entity hierarchy, which the constitution forbids.
    var decisionData: Data
    /// `EvidenceSnapshot` JSON-encoded whole, byte-exact so a reopened case reproduces the exact
    /// evidence it was decided from.
    var evidenceData: Data
    var catalogueVersion: String

    // `PersistedDishOutcome` flattened to columns. The recommendation is always present since
    // D139 — the rule no longer has an outcome without one — but the columns stay optional-free
    // only where the type is: a family arrives as its raw value and is parsed back on the way
    // out, where a value that does not parse is a corrupted row, not a silent fallback.
    var recommendedVariantID: String
    var recommendedFamilyRawValue: String
    var alternativeVariantID: String?
    var alternativeFamilyRawValue: String?

    /// A validated on-device model line, written once by `attachNarration(_:to:)` and never
    /// overwritten. Stays `nil` whenever no model line was produced — the reviewed template is
    /// never persisted.
    var narrationText: String?

    init(
        id: UUID = UUID(),
        sequence: Int,
        createdAt: Date,
        decisionData: Data,
        evidenceData: Data,
        catalogueVersion: String,
        dishOutcome: PersistedDishOutcome,
        narrationText: String? = nil
    ) {
        self.id = id
        self.sequence = sequence
        self.createdAt = createdAt
        self.decisionData = decisionData
        self.evidenceData = evidenceData
        self.catalogueVersion = catalogueVersion
        self.narrationText = narrationText
        self.recommendedVariantID = dishOutcome.variantID
        self.recommendedFamilyRawValue = dishOutcome.family.rawValue
        self.alternativeVariantID = dishOutcome.alternativeVariantID
        self.alternativeFamilyRawValue = dishOutcome.alternativeFamily?.rawValue
    }
}

extension VerdictRevision {
    /// - Throws: ``FoodgeError/caseCorrupted`` if the stored blob does not decode.
    func decodedDecision() throws -> VerdictDecision {
        do {
            return try JSONDecoder().decode(VerdictDecision.self, from: decisionData)
        } catch {
            throw FoodgeError.caseCorrupted
        }
    }

    /// - Throws: ``FoodgeError/caseCorrupted`` if the stored blob does not decode.
    func decodedEvidence() throws -> EvidenceSnapshot {
        do {
            return try JSONDecoder().decode(EvidenceSnapshot.self, from: evidenceData)
        } catch {
            throw FoodgeError.caseCorrupted
        }
    }

    /// Reassembles the flattened columns into a ``PersistedDishOutcome``.
    ///
    /// Throws rather than substituting a dish when the stored family does not parse. It is
    /// unreachable in practice — this project writes the raw value itself — but a row whose
    /// family is unreadable is a corrupted row, and inventing a family here would put a dish in
    /// front of the user that nothing ever chose. `allCases()` already skips a corrupted day
    /// rather than failing the whole list.
    ///
    /// - Throws: ``FoodgeError/caseCorrupted`` if the stored family raw value does not parse.
    func decodedDishOutcome() throws -> PersistedDishOutcome {
        guard let family = DishFamily(rawValue: recommendedFamilyRawValue) else {
            throw FoodgeError.caseCorrupted
        }
        return PersistedDishOutcome(
            variantID: recommendedVariantID,
            family: family,
            alternativeVariantID: alternativeVariantID,
            alternativeFamily: alternativeFamilyRawValue.flatMap(DishFamily.init(rawValue:))
        )
    }

    /// - Throws: ``FoodgeError/caseCorrupted`` if either stored blob does not decode.
    func asSavedRevision() throws -> SavedRevision {
        SavedRevision(
            id: id,
            sequence: sequence,
            createdAt: createdAt,
            decision: try decodedDecision(),
            evidence: try decodedEvidence(),
            catalogueVersion: catalogueVersion,
            dishOutcome: try decodedDishOutcome(),
            narrationText: narrationText
        )
    }
}
