---
title: Foodge memory
tags: [foodge, memory, index]
updated: 2026-09-21
---

# Foodge memory

Working memory for the Foodge build. The point is that the *next* agent — or the next me,
after a compaction — can reconstruct not just what the code does but **why it is that way and
what already went wrong**.

## What goes where

| Folder | Holds | Write one when |
|---|---|---|
| `decisions/` | Why a fork was taken, and what the alternative cost | You chose between two defensible options, or deviated from the plan |
| `troubleshooting/` | A concrete failure and its root cause | Something broke in a way that cost real time and could recur |
| `sessions/` | What a working session actually did | At the end of any session that produced commits |

**Write the note when the decision is made, not at the end of the session.** You are already
writing the ledger's D-number at that moment; the note costs nothing extra then, and it is the
only version that survives an unexpected compaction. Code survives a lost session. The *why*
does not.

Numbered decisions (D1, D2, …) live in `docs/implementation-tasks.md` — that is the canonical
ledger and the audit trail. This folder is for the ones that carry a *lesson*, written long
enough to be useful cold. A note here links back to its ledger number.

## Conventions

- One idea per file, kebab-case filename, `.md`.
- Frontmatter: `title`, `tags`, `date`, and `ledger` when a numbered decision exists.
- Link with `[[wikilinks]]` so the vault renders the graph.
- Write for someone with no memory of the session. Name the file, the symbol, the error text.
- Never record a Health value, a user note or a model prompt. Behaviour and state labels only.

## Index

### Decisions
- [[swift-6-language-mode-not-template-default]] — the template ships Swift 5 and hides it
- [[device-interaction-is-simulator-only]] — how device verification actually works here
- [[file-protection-complete-unless-open]] — why not `.complete` on a live database
- [[metric-preference-and-failure-reporting]] — energy vs steps, and which refusal is reported
- [[baseline-window-ownership]] — who owns calendar correctness
- [[claude-md-kept-out-of-the-remote]] — why hiding one file was the wrong fix
- [[audit-prompts-should-target-evidence]] — ask whether a test *could fail*
- [[exclusions-screen-waits-for-the-catalogue]] — a picker over identifiers that do not exist yet
- [[schema-v1-grows-tracking-representative]] — the standing question, not the per-day one
- [[colour-sets-before-artwork]] — why an `.xcassets` write is not a pbxproj edit
- [[protocol-seams-for-the-onboarding-viewmodel]] — and why a `#Preview` is a composition root
- [[a-sixth-health-state-for-a-failed-request]] — a failed request is not an absence
- [[the-catalogue-is-a-domain-constant-not-a-seam]] — 27 compile-time values need no protocol
- [[dynamic-name-keys-need-a-shipped-strings-oracle]] — seed-and-delete, and a locale API that lies in tests
- [[rotation-is-a-continuous-day-index]] — never day-of-year, never the candidate count
- [[calorie-references-stand-alone-until-a-meal-picks-one]] — verified references, wired to nothing yet
- [[recorded-intake-is-an-enum-not-two-fields]] — "replaces, never adds" as a type-level guarantee
- [[case-store-schema-v1-shape]] — blob evidence, two-case appeals, one day-key source
- [[today-viewmodel-bypasses-verdict-engine]] — a protocol that fits no caller stays unconformed
- [[tracking-confirmation-must-discard-not-replay]] — "No" must not replay into the same guard
- [[no-match-still-reaches-a-verdict]] — the category rules even when the dish pick can't

### Troubleshooting
- [[healthkit-terminates-without-usage-description]] — a tool said success and changed nothing
- [[filter-branch-deletes-the-working-file]] — purging a tracked file takes the file with it
- [[string-catalog-edit-marks-translations-machine-made]] — the state is the tool's choice, not ours
- [[sf-symbol-checkmark-hijacks-voiceover-selection]] — a symbol *name* the OS itself recognizes, no modifier stops it
- [[swiftdata-unique-does-not-throw-on-save]] — `@Attribute(.unique)` merges silently, it never throws

### Sessions
- [[2026-09-18-day-18-and-19]] — project creation through the persistence layer
- [[2026-09-19-wu-19-d-onboarding]] — the day Foodge got a user interface, and what four auditors caught
- [[2026-09-21-wu-21-b-today-flow]] — the day the verdict became a screen, and two bugs no test caught
