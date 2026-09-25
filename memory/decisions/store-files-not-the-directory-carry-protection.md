---
title: The store's files, not its directory, are what carry file protection
tags: [foodge, decision, data, persistence, privacy, regression-risk]
date: 2026-09-25
ledger: D107 (amends D29)
---

# The store's files, not its directory, are what carry file protection

## The trap

`ContainerFactory.makeLive()` read in the order a reasonable person writes it:

```swift
let directory = try storeDirectory(using: fileManager)      // create the directory
let container = try make(at: directory.appending(path: storeFileName))  // write the store
try harden(directory, using: fileManager)                   // ...then protect it
```

Every line is correct on its own and the whole thing is wrong. A file's data-protection class is
fixed **when the file is created**, inherited from the directory it is created in, and
`FileManager.setAttributes` is **not recursive**. So `Foodge.store`, `Foodge.store-wal` and
`Foodge.store-shm` were all created under the unhardened directory and kept the container default
(`CompleteUntilFirstUserAuthentication`) for the life of the install — one class weaker than D29
promised, on the files holding Health-derived evidence and user notes.

`arc-audit-security` found it. Nothing in the suite could have: `ContainerFactoryTests` never
called `makeLive()`, so the protection half of D29 was a claim, not a tested fact. The backup half
was real (`com.apple.metadata:com_apple_backup_excludeItem` verified by hand on all three files).

## Decision

Harden the directory **before** `make(at:)`, and set `.protectionKey` on the store and both
sidecars **after** creation:

```swift
static func makeProtected(in directory: URL, using fileManager: FileManager = .default) throws -> ModelContainer {
    try harden(directory, using: fileManager)
    let storeURL = directory.appending(path: storeFileName)
    let container = try make(at: storeURL)
    try protectStoreFiles(at: storeURL, using: fileManager)
    return container
}
```

The second pass is not redundant with the first. Ordering alone only fixes a *fresh* install;
an app already on someone's phone keeps its weakly-protected store forever unless something
re-applies the class to the existing files. `.completeUnlessOpen` is unchanged — D29's reason
(a lock mid-write must not fail an open database) still stands.

`makeProtected(in:using:)` is internal, not private, so it can be driven against a temporary
directory instead of the real Application Support container.

## Pinned by — and why there is no test

There is **no unit test**, deliberately. The obvious one — `attributesOfItem(atPath:)[.protectionKey]`
on the three files — was written, run, and **deleted**: data protection is not enforced on the
simulator and the attribute does not round-trip there, so it returned `nil` for all three files
and the test failed on correct code. A test that cannot pass in the only environment the suite
runs in is an environment trap, not coverage.

Verified instead on the **physical iPhone** (D21's route: `RunProject` + `GetConsoleOutput` with a
temporary bare-label probe, removed immediately after):

```
[persistence] PROBE file=store      state=complete-unless-open
[persistence] PROBE file=store-wal  state=complete-unless-open
[persistence] PROBE file=store-shm  state=complete-unless-open
```

That install pre-dated the fix, so the run also proves the upgrade-correction path: the
post-creation pass is what raised an already-created store to the right class.

## See also

- [[file-protection-complete-unless-open]] — D29, which this amends
- [[device-interaction-is-simulator-only]] — why the evidence had to come through the console
- [[audit-prompts-should-target-evidence]] — the audit found a claim, not a crash
