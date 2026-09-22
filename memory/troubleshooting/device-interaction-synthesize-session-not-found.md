---
title: "DeviceInteractionSynthesize: \"Session not found\" — a recurring MCP outage, not an app bug"
tags: [foodge, memory, troubleshooting, xcode-mcp, device-interaction]
date: 2026-09-22
ledger: WU-22-A
---

# `DeviceInteractionSynthesize` "Session not found" — a recurring MCP outage

WU-22-A needed a live simulator tap-through to verify the appeal flow (Appeal → pick a craving →
does the result stick or bounce back). Three independent attempts, all blocked identically:

1. A subagent's own `DeviceInteractionStartWorkspaceSession` → `DeviceInteractionInstallAndRun`
   (succeeded) → `DeviceInteractionSynthesize` → `"Session not found. It may have already been
   closed, or the identifier is wrong"`.
2. A second, fresh subagent on a different simulator — identical failure.
3. The main session itself opened the session and ran `DeviceInteractionInstallAndRun`
   (succeeded — app confirmed running via `GetConsoleOutput`), handed the exact session key to a
   third subagent instructed to reuse it rather than start its own. Same failure. Ending the
   session afterward from the main session reported `"Session doesn't exist anymore"` —
   internally inconsistent state on the MCP side, not a client-side mistake.

`DeviceInteractionInstallAndRun` worked every single time; only the interaction/capture step
(`DeviceInteractionSynthesize`) was broken, and identically broken regardless of who opened the
session or how fresh it was.

## What this means going forward

This is the same class of gap D21 already named for physical devices ("Device Interaction refuses
a physical iPhone outright"), now also hitting simulators, at least for this session's MCP
instance. Retrying with a new session/device pairing does not help — three different
session/device combinations all failed the same way in the same session.

## What to do when this happens again

- Don't burn more than 2 attempts retrying `DeviceInteractionSynthesize` itself — it's not a
  timing/race issue on the caller's side.
- Fall back to the evidence tier this project already normalized for exactly this gap: build +
  tests + standalone-component `RenderPreview`s + source-level reasoning, stated honestly as
  "not device-confirmed" rather than silently accepted as equivalent. See WU-22-A's ledger entry
  for the exact wording that held up under `arc-constitution-review`.
- Worth trying once, cheaply, at the start of a session that needs device verification: does a
  bare `DeviceInteractionSynthesize` with an empty command succeed at all, before investing in a
  full walkthrough plan.

## See also

- [[../decisions/physical-device-verification-uses-runproject-not-device-interaction]] if that
  memory exists — same root cause class, different device type.
