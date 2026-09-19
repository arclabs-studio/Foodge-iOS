---
title: Foodge memory
tags: [foodge, memory, index]
updated: 2026-09-19
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

### Troubleshooting
- [[healthkit-terminates-without-usage-description]] — a tool said success and changed nothing
- [[filter-branch-deletes-the-working-file]] — purging a tracked file takes the file with it
- [[string-catalog-edit-marks-translations-machine-made]] — the state is the tool's choice, not ours

### Sessions
- [[2026-09-18-day-18-and-19]] — project creation through the persistence layer
