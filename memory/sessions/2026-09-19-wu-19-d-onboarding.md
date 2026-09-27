---
title: WU-19-D — the day Foodge got a user interface
tags: [foodge, session, onboarding, accessibility]
date: 2026-09-19
---

# WU-19-D — the day Foodge got a user interface

`Presentation/` went from an empty directory to four screens, six components and a root that
opens a real store. Three commits: `56e5c66` (schema + seams), `e4f6e91` (the flow), `170d922`
(probe removed + accessibility fixes). Decisions D31–D35.

## The thing worth remembering

**Every one of the four auditors found something real, and none of them found it by reading the
diff for style.** They found it by asking whether a specific claim was true.

| Auditor | What it found |
|---|---|
| `arc-test-engineer` | The `evidenceFailure` fixture seam existed and **no test used it** — so D35's rule (a failed read is not an absence) was unproven. Also: a cancelled read left `.requesting` on screen forever. |
| `arc-constitution-review` | A `convenience init(dependencies:)` that made Presentation name an App type — **contradicting D34, which I had written myself that morning**. And all 16 `View` structs missing `@MainActor`. |
| `arc-audit-hig` | Domain knowledge (which family is a treat) duplicated inside a View. |
| `arc-audit-accessibility` | White-on-`AppBurgundy` at **2.47:1** in dark mode. Two AX5 reflow failures, one of which hid the only way out of a fatal-error screen. |

## The lesson about builds

Both of the constitution blockers **compiled cleanly and passed 61 tests**. The missing
`@MainActor` compiles because SwiftUI's `body` is already main-actor-isolated. The layering
violation compiles because Swift has no notion of layers. A green build proves neither.

## The lesson about previews

The simulator found two defects no preview could show:

1. **The dish rows did not respond to taps at all.** `LabeledContent` inside a `Button` forms
   its own accessibility container and eats the hit target.
2. Every row announced itself to VoiceOver as **"Selected"** while showing no checkmark.

And (2) survived the first fix. The real cause: **a trailing checkmark in a `Form` row becomes
the row's native accessory, and an accessory ignores `.accessibilityHidden(true)`**. Drawing it
at `.opacity(0)` left it in the accessibility tree. Only building the glyph when selected worked.

Worth noting: the `.opacity` trick existed to stop rows shifting. Re-verification proved row
geometry is **byte-identical** either way — the problem it solved did not exist. A comment
justifying a workaround is not evidence the workaround is needed.

## Don't trust an audit report's incidental claims

The accessibility report cited a "pre-existing SwiftLint `--strict` gate" as the reason for some
line rewraps. **There is no SwiftLint in this project.** The rewraps were harmless — the `\`
continuations preserved every literal, confirmed by the catalogue reporting 0 new keys — but the
justification was invented. Check the *incidental* claims too, not just the findings.

## Practical traps hit

- Re-verifying onboarding needs a **clean store**, and completing the flow once dirties it. The
  loop is: delete the app through the simulator's own Home screen (long-press → Remove App →
  Delete App → Delete), then `InstallAndRun`. Confirm with `ONBOARDING launch completed=false`
  before handing off to a verification agent — I once raced my own `InstallAndRun` against the
  deletion agent and verified nothing.
- Changing an apostrophe from `'` to `’` **re-keys the String Catalog entry** and needs a fresh
  translation for each one. Nine of them here.
- The first `RenderPreview` of a session can time out at the default 120 s. Use `timeout: 420`.

## Still owed

Nothing from this list — corrected after the fact. The physical-device pass this note originally
flagged as outstanding actually landed at the end of the same session: `.connected` ran against a
real recorded fortnight on "iPhone de CR" (PID 16175), and a separate-process relaunch (PID
16178) proved the persisted half. See the Day 19 evidence in `docs/implementation-tasks.md`.

## See also

- [[string-catalog-edit-marks-translations-machine-made]]
- [[protocol-seams-for-the-onboarding-viewmodel]]
- [[audit-prompts-should-target-evidence]]
- [[device-interaction-is-simulator-only]]
