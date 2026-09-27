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

## Update, 2026-09-23 — resolved by falling back to physical device

Two more simulator attempts the next session, same outcome: one died again with "Session not
found", a second died differently — `"Target device has invalid screen scale. Make sure your
machine can access the remote device."` — after ~15 working interactions. Confirms the earlier
read: not a session-freshness or device-choice problem, the tool just fails mid-session
unpredictably.

What actually closed WU-22-A's verification gap was switching to the physical device path
(`RunProject` + `GetConsoleOutput`, D21) and asking the user to tap through by hand, reporting
back directly. Two caveats worth remembering for next time:
- Console logging only covers `TodayViewModel`'s top-level `Stage`, not sub-flow enums like
  `AppealStage` — a physical-device console check gives you crash/error absence and top-level
  stage transitions, nothing finer, unless you add logging first.
- A simulator with HealthKit access declined at onboarding gets permanently stuck at
  `.evidenceUnavailable` (no self-report fallback from a *thrown* snapshot error) — a real device
  with actual Health data sidesteps this entirely, which is a second reason physical device beat
  chasing a healthy simulator here.

## Update, 2026-09-25 (WU-25-A) — now it also holds a phantom lock, and how the walk got done

The same failure, plus a new half: after the dead `Synthesize`, the device stays **locked by the
session that no longer exists**. `EndSession` says *"Session doesn't exist anymore"* while every new
key is refused with *"The target device is already in use by a different session with key
'<the dead one>'"*. Gone and locking at once.

Seven attempts in one session across three arrangements — subagent opens its own session; main agent
opens it and hands the key to a subagent that has loaded the `device-interaction` skill (the
arrangement the tool's own response text demands); and no `InstallAndRun` at all, app pre-launched
from `RunProject`, straight to `Synthesize`. Also ineffective: quitting Simulator.app, a full Xcode
quit and relaunch, ending every stale key first, changing device. **Two attempts remains the right
budget — this update is the evidence that more is waste.**

Two side-traps met while chasing it:

- The eligible-device list prints every simulator with the **SDK** version (27.0), not its runtime,
  so an iOS 26.5 device looks like a 27.0 one and a real device can look absent. Ground truth is
  `~/Library/Developer/CoreSimulator/Devices/<uuid>/device.plist` (`runtime`, `state`: 3 = booted).
- Device interaction only ever offered 27.0 devices here, so an **iOS 26 walk is manual by nature**
  even when everything else works.

**What closed the gap: a recorded hand walk, read with ffmpeg.** The user walked the ritual on the
physical iPhone and screen-recorded it; `ffprobe` for duration, then
`ffmpeg -vf "fps=1,scale=130:-1,tile=9x8"` contact sheets to find the interesting spans, then a
full-resolution `crop` to read anything exactly. Frame index × interval times events to the second —
that is how a **51-second `.evaluating` stage** got measured.

That walk found four defects that a green preview matrix, `arc-audit-hig`, `arc-audit-accessibility`
and `arc-constitution-review` had all missed — including the floating tab bar rendering on top of
the flourish, which **previews structurally cannot show, because a preview has no tab bar**. Treat a
passing render matrix as evidence about a view, never about a screen.

## See also

- [[../decisions/physical-device-verification-uses-runproject-not-device-interaction]] if that
  memory exists — same root cause class, different device type.
