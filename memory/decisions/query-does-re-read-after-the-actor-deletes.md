---
title: D93 answered — @Query does re-read after the actor deletes
tags: [foodge, decision, swiftdata, presentation, device-verified]
date: 2026-09-25
ledger: D109 (answers D93)
---

# D93 answered — `@Query` does re-read after the actor deletes

## The question, carried since WU-19-D

`PersistenceActor` erases local data through **its own** `ModelContext`, not the one `@Query` reads
from. D93 built the within-session latch reset (`onLocalDataErased`) precisely because nobody knew
whether the `@Query`-backed root would notice the deletion on its own. The ledger recorded it as an
open device check rather than claiming it worked.

## The answer

**It re-reads.** On the physical iPhone, confirming *Eliminar los datos locales*:

1. the Settings sheet dismissed itself,
2. the reminder toggle was visibly back to off — the live view had re-read, not just the root,
3. the root view moved to `Bienvenida / "Se abre la sesión."`

One continuous screen recording, no launch screen, no process restart. So the latch and the
`@Query` root agree, and `AppRootView` needs nothing further.

## How it had to be evidenced

Not through the Xcode MCP: its device-interaction session layer was wedged for the whole of
WU-25-A — a session starts, the first `DeviceInteractionSynthesize` says *"Session not found"*, and
every later key is refused as *"already in use"*. Seven attempts, three arrangements, surviving a
Simulator quit and a full Xcode restart. The user drove the device by hand and recorded it; the
video is the oracle.

Worth keeping as a pattern: when the harness cannot observe, a recorded human walk is still real
evidence — and it caught four defects the preview matrix and three read-only audits all missed,
including a 51-second `.evaluating` stage and a floating tab bar sitting on top of the flourish.

## See also

- [[deletion-is-its-own-seam-and-the-latch-must-be-cleared]] — D93's original half
- [[device-interaction-is-simulator-only]]
- [[foodge-verification-habits]]
