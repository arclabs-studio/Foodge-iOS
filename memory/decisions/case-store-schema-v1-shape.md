---
title: CaseStore's schema-V1 shape — blob evidence, two-case appeals, one day-key source
tags: [foodge, memory, decisions, swiftdata, case-store]
date: 2026-09-21
ledger: D51-D54
---

# CaseStore's schema-V1 shape

Four forks confirmed for WU-21-A, before `DailyCase`/`VerdictRevision`/`Appeal` existed.

## D51 — evidence and decision are persisted as whole JSON blobs

`VerdictRevision.decisionData`/`evidenceData` hold `VerdictDecision`/`EvidenceSnapshot`
JSON-encoded whole, not decomposed into flat columns. `CategoryBasis`'s associated values
(`.recorded(ratio:baseline:)` vs `.selfReported(_:)` vs `.provisional`) don't map to flat
SwiftData columns without a second entity hierarchy, which the constitution forbids. A blob
also guarantees byte-exact reproducibility for "reopen without regenerating" — no drift between
what was decided and what a rebuilt-from-columns version would say.

`PersistedDishOutcome` and `AppealChoice`, by contrast, **are** flattened to columns
(`recommendedVariantID`/`recommendedFamilyRawValue`/… on `VerdictRevision`;
`chosenVariantID`/`chosenFamilyRawValue`/`chosenFreeText` on `Appeal`) — both are small,
stable-shaped enums the app itself defines, unlike `CategoryBasis`'s open-ended associated data.

## D52 — AppealChoice is a concrete two-case enum, decided now

`AppealChoice.catalogue(variantID:family:)` / `.freeText(String)` — grounded directly in
`foodge-plan.md` section 3's own two named appeal outcomes ("a compatible catalogue craving can
be accepted... a free-text dish outside the catalogue receives no invented nutritional
analysis"). Appeal *negotiation* (matching a compatible craving, honest no-match) is WU-22-A's
job — this only gives an appeal a place to be recorded.

## D53 — local-day identity has exactly one source

`CaseStore` methods take no separate `day`/`calendar` parameter. `PersistenceActor`'s private
`localDayKey(for evidence:)` derives `"yyyy-MM-dd"` from `evidence.evaluatedAt` +
`evidence.timeZoneIdentifier` alone, Gregorian, falling back to `.gmt` only if the stored
identifier is unparseable (documented-unreachable, same idiom as `SyntheticScenarios.date`).
Every caller already carries an `EvidenceSnapshot` — a second `day` parameter would be a second
source of truth that could disagree with the one inside the evidence it was computed from.

Zero-padded by hand (`zeroPadded(_:width:)`), not `String(format:)` or `DateFormatter` — both
forbidden by the constitution, and this key is internal storage, never user-facing text, so it
must not vary with the device's locale the way a formatter's digit rendering can.

## D54 — `narrationText` is a nullable column with no write path yet

Added to `VerdictRevision` now (zero-risk under D10 — the app is unreleased, so growing schema
V1 is a dev reinstall, not a migration) but nothing writes it. `attachNarration` is WU-23-A's
job. Same class of change as [[schema-v1-grows-tracking-representative]].

See also [[swiftdata-unique-does-not-throw-on-save]] for what this unit's test plan got wrong
about SwiftData's actual failure behavior.
