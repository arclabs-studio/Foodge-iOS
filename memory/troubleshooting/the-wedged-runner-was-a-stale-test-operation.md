---
title: The wedged test runner — a stale test operation is part of it, not all of it
tags: [foodge, troubleshooting, xcode-mcp, testing]
date: 2026-09-26
ledger: WU-27-A
---

# The wedged test runner: a stale test operation is part of it, not all of it

From WU-EB onward this project recorded the Xcode MCP test runner as *wedged*: `RunSomeTests` and
`RunAllTests` started, created an `.xcresult`, and then never returned — 21+ minutes on the full
list, 120 s on a single cheap suite — while `BuildProject` answered in 5–9 s throughout. It cost
Pass C (see [[a-wedged-runner-decides-which-pass-ships]]) and every test claim since has had to be
made another way: ⌘U by hand, or `RunCodeSnippet` executing the real types.

## What it actually is

On 26 Sep 2026 a single-test `RunSomeTests` came back **immediately** with:

```
Could not start the scheme operation: There is already a test running.
```

- `ps` showed a simulator-side `testmanagerd` (iOS 27.0 runtime) alive since **09:38** that day.
- `DerivedData/Foodge-…/Logs/Test/` held `Test-Foodge-2026.09.26_09-57-36.xcresult`, from an
  earlier session.

So Xcode still believed a test operation was in progress, and a new one could not start.

**But clearing it was not enough.** The user pressed Stop in Xcode; the stale task duly reported
`Test execution was cancelled by a user interaction in Xcode`. After that a run *starts* — and
still never returns: `RunAllTests` sat at **11 m 28 s** and was stopped, and a fresh run of a
**single** test also passed **120 s** with no result, while `BuildProject` answered in 5–11 s
throughout. So the stale operation was *a* blocker, not *the* blocker.

## What does *not* clear it

`StopProject` answers `"No app is currently running."` It stops the **run** operation, not the
**test** operation.

## What to try, in order

1. Press **Stop (⌘.)** in Xcode, or close and reopen the project — the operation lives in Xcode's
   own state, so the fix is in Xcode.
2. Retry `RunSomeTests` with **one** test. It either starts or repeats the message; both answers
   are fast, so this is a cheap probe.
3. Only if it still refuses, kill the stale simulator `testmanagerd` (`launchd_sim` respawns it).
4. If a run now *starts* but does not return within ~2 minutes, stop it and **use ⌘U**. That is
   still the only path that has produced a result on this machine — 2.17 s for 271 tests.

**Run the one-test probe before ever calling the runner wedged again.** A refusal arrives in
seconds and tells you which failure you have; a hang tells you to stop waiting and reach for ⌘U.
Do not record "the cause is found" until a run has actually returned — the first version of this
note did exactly that, on the strength of the refusal message alone.
