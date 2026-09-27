---
title: Untyped is not unsafe — the scenario-id retype waits until after the freeze
tags: [foodge, decision, data, demonstration, scope]
date: 2026-09-25
ledger: D108 (defers D99)
---

# Untyped is not unsafe — the scenario-id retype waits until after the freeze

## The open item

D99 left `SyntheticScenario.id` as a `String` and assigned the retype to
`DemonstrationScenarioID` to WU-25-A. `arc-constitution-review` re-raised it there.

## Decision

Deferred past the hackathon freeze (user-settled), recorded rather than silently dropped.

The distinction that decides it: this is **untyped, not unsafe**. The ten ids already match the
enum case for case, `SyntheticScenarios.scenario(for:)` is an exhaustive switch — total by
construction, no optional, nothing to force-unwrap — so a wrong id cannot reach runtime. The only
thing the retype buys is compile-time spelling.

Against that: it touches every scenario definition and the demonstration entry path, two days from
the deadline, on a day whose brief is *fix defects only*. A mechanical change across working code
is exactly the kind of thing that turns a green suite red at the worst moment.

## See also

- [[the-catalogue-is-a-domain-constant-not-a-seam]] — D99's reasoning about the missing seam
- [[user-prefers-decisions-recorded-not-assumed]]
