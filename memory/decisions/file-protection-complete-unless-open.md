---
title: completeUnlessOpen, not complete, on a live database
tags: [foodge, decision, security, swiftdata, persistence]
date: 2026-09-19
ledger: D29
---

# `.completeUnlessOpen`, not `.complete`, on a live database

## The requirement

The brief: "Keep Health-derived storage protected and excluded from device backups." The session
plan spelled that as *complete file protection*.

## Why complete is wrong here

`FileProtectionType.complete` makes a file unreadable the instant the device locks — **including
a file the app already has open**. For a SQLite database mid-write that means failed writes and
a plausible route to a corrupt store. The setting meant to protect the data becomes the thing
most likely to destroy it.

`.completeUnlessOpen` keeps the at-rest guarantee that matters — nothing readable while the
device is locked and the app is not running — while letting an already-open database finish
its work.

## What was implemented

Applied to the store *directory*, not just the store file, so SQLite's `-wal` and `-shm`
sidecars are covered:

```swift
var values = URLResourceValues()
values.isExcludedFromBackup = true
try directory.setResourceValues(values)

try fileManager.setAttributes(
    [.protectionKey: FileProtectionType.completeUnlessOpen],
    ofItemAtPath: directory.path(percentEncoded: false)
)
```

Store location is Application Support, not Documents: it is app state, not a user document.

## Open question

Foodge currently does no background work, so `.complete` would probably not bite today. If
background evaluation is ever added this decision needs revisiting in the other direction too —
`.complete` would then break it outright.
