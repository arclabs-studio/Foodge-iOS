---
title: Device interaction is simulator-only; physical checks go through RunProject
tags: [foodge, decision, xcode-mcp, verification, healthkit]
date: 2026-09-18
ledger: D21
---

# Device interaction is simulator-only

## What happened

The plan's Day 18 exit criterion was a `DeviceInteractionStartWorkspaceSession` on the
connected iPhone, then `InstallAndRun`, then screenshots. The session refuses a physical device:

```
The device you are targeting is not supported for Device Interaction.
Supported: iOS [Simulator] 27.0+; watchOS [Simulator] 27.0+; tvOS [Simulator] 27.0+
```

Naming the device explicitly returns a list containing only simulators. It is a capability
boundary, not a connection problem — the same device builds, installs and runs fine.

## Decision

Physical-device verification uses `RunProject` (builds, installs and launches on the active
destination) plus `GetConsoleOutput` to read results back. The person taps; the log is the
evidence.

To make that work, code under verification emits **state labels** through `os.Logger`:

```swift
log.notice("PROBE health=\(String(describing: self.health), privacy: .public)")
```

`privacy: .public` is required or the value is redacted in the log. This is only ever safe
because what is logged is a case label — never a Health value, never model output.

## Consequences

- `arc-verify-ui` can only drive a simulator. Anything needing real Health data or real
  Apple Intelligence has to be a human-in-the-loop check.
- Budget a round trip with the user for every device acceptance criterion.
- Simulator has no Apple Intelligence and no real Health data, so it cannot substitute.

## See also

- [[2026-09-18-day-18-and-19]]
