//
//  FoundationModelsNarrator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation
import FoundationModels
import OSLog

/// One short remark from the judge, the only thing the model is ever asked for.
///
/// One field on purpose. It still beats asking for a bare `String`: it gives the model a named
/// target and suppresses the "Sure! Here's a line:" preamble raw string responses routinely
/// produce — chatter that would otherwise be rejected as malformed and waste a generation.
@Generable
struct JudgeFlourish {
    @Guide(description: "One short, playful courtroom remark about tonight's dinner. No numbers, no health advice.")
    var line: String
}

/// Asks the on-device model for a flourish, and gives up quietly on anything at all going wrong.
///
/// **Privacy invariant: the prompt, the note and the model's output never reach a `Logger`.**
/// Only the case label of a failure is ever logged — never `errorDescription`, which can echo
/// prompt content.
///
/// Every request builds a **fresh `LanguageModelSession`**: no stored session, so no context
/// accumulates between days, no `isResponding` guard is needed, and this type stays a stateless
/// `Sendable` struct. There is no `prewarm` — a decoration does not justify holding model
/// resources for a screen the user may never reach.
///
/// With guided generation a refusal arrives as a typed `GenerationError.refusal`, rather than as
/// text that would need heuristic detection — one of the reasons `@Generable` earns its place
/// here for a single field.
struct FoundationModelsNarrator: VerdictNarrator {
    /// Injected so the unavailable branch is deterministically testable anywhere, including a
    /// simulator that has no Apple Intelligence at all.
    let availability: @Sendable () -> NarrationAvailability

    init(availability: @escaping @Sendable () -> NarrationAvailability = { .current }) {
        self.availability = availability
    }

    func flourish(
        for decision: VerdictDecision,
        dishName: String,
        note: Note?
    ) async -> String? {
        let status = availability()
        guard status.canNarrate else {
            NarrationLog.logger.info("NARRATION unavailable=\(status.logLabel, privacy: .public)")
            return nil
        }

        let locale = Locale.current
        guard SystemLanguageModel.default.supportsLocale(locale) else {
            NarrationLog.logger.info("NARRATION unavailable=unsupportedLocale")
            return nil
        }

        let session = LanguageModelSession(instructions: NarrationPrompt.instructions(locale: locale))
        // `samplingMode:`, not the deprecated `sampling:` — the installed SDK renamed it.
        let options = GenerationOptions(samplingMode: nil, temperature: 0.8, maximumResponseTokens: 80)

        do {
            let response = try await session.respond(
                to: NarrationPrompt.prompt(for: decision, dishName: dishName, note: note),
                generating: JudgeFlourish.self,
                includeSchemaInPrompt: true,
                options: options
            )
            return response.content.line
        } catch let error as LanguageModelSession.GenerationError {
            // The case label only. `errorDescription` can quote the prompt, which would put the
            // user's note in the log.
            NarrationLog.logger.info("NARRATION generation=\(Self.label(for: error), privacy: .public)")
            return nil
        } catch {
            // Cancellation lands here too, and is not a failure worth distinguishing: every path
            // out of this type is the same silent `nil`.
            NarrationLog.logger.info("NARRATION generation=other")
            return nil
        }
    }

    private static func label(for error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .assetsUnavailable: "assetsUnavailable"
        case .decodingFailure: "decodingFailure"
        case .exceededContextWindowSize: "exceededContextWindowSize"
        case .guardrailViolation: "guardrailViolation"
        case .rateLimited: "rateLimited"
        case .refusal: "refusal"
        case .concurrentRequests: "concurrentRequests"
        case .unsupportedGuide: "unsupportedGuide"
        case .unsupportedLanguageOrLocale: "unsupportedLanguageOrLocale"
        @unknown default: "other"
        }
    }
}
