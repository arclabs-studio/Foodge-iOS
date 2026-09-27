---
title: An auditor's fix stops at the edge of its own diff
tags: [foodge, decision, accessibility, wcag, audit]
date: 2026-09-26
ledger: D134
---

# An auditor's fix stops at the edge of its own diff

`arc-audit-accessibility` fixed six `.secondary` text sites during WU-EB and one more during
WU-26-A, each time measuring `.secondary` at ~3.44:1 against a Form row background — below WCAG
1.4.3's 4.5:1 floor — and swapping in `.appBurgundyMuted` (4.73:1 light / 5.66:1 dark, re-measured as 5.68:1 on 2026-09-26 — the same color, two rounding passes). Both
times the Checkpoint notes recorded "two contrast gaps remain" and named them.

**The count was wrong, and nobody checked it.** A repo-wide grep at the start of Day 27 found
**17** `.foregroundStyle(.secondary)` text sites still standing across 13 files — History's whole
list and detail screen, every appeal section, the demonstration scenario list, the onboarding
Health screen. The two named ones were simply the two that happened to sit inside the audited
diff's blast radius.

## Why it happened

Each auditor was pointed at a work unit, so it audited that unit's diff. That is the correct
scope for a *review*, and the wrong scope for a *floor*. A contrast floor is a property of every
screen, not of a changeset, and nothing in the loop ever asked "how many are left?" — the ledger
inherited the auditor's own phrasing ("the remaining gaps") and turned a diff-local observation
into a repo-wide claim.

## The rule that comes out of it

For any invariant that holds app-wide — contrast, hit targets, force-unwraps, `@MainActor` on
Views — **close it with a repo-wide search whose result is a number, and record the number.**
"The auditor fixed the ones it saw" is not a closure. See
[[arc-audit-agents-find-evidence-problems]]: their best findings here have been evidence
problems, and this is one they produced rather than caught.

## What was decided, not just done

The sweep converts *all* remaining secondary text, not only the small text. Body-size text at
4.5:1 and footnotes at 4.5:1 are the same criterion; picking only the ones that "look worst"
would leave the same ambiguity behind for the next reader. Native `LabeledContent` trailing
values are untouched — SwiftUI styles those itself, and restyling a native control to chase a
ratio is the parallel-struct mistake the doctrine forbids.
