//
//  SettingsViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Settings is where someone changes what Foodge knows about them and, in one row, deletes it.
///
/// Every test here is about a claim the screen must not make: that a refused reminder is set,
/// that a failed write was saved, or that data still on disk is gone.
@Suite("Settings view model", .tags(.unit, .critical))
@MainActor
struct SettingsViewModelTests {
    private struct SUT {
        let viewModel: SettingsViewModel
        let store: FixturePreferencesStore
        let reminders: FixtureReminderService
        let localData: FixtureLocalDataEraser
    }

    private func makeSUT(
        seeded: PreferencesDraft? = nil,
        storeFailure: (any Error)? = nil,
        reminderFailure: (any Error)? = nil,
        eraseFailure: (any Error)? = nil
    ) -> SUT {
        let store = FixturePreferencesStore(failure: storeFailure, seeded: seeded)
        let reminders = FixtureReminderService(failure: reminderFailure)
        let localData = FixtureLocalDataEraser(failure: eraseFailure)

        return SUT(
            viewModel: SettingsViewModel(
                store: store,
                reminders: reminders,
                localData: localData,
                clock: SyntheticScenarios.clock
            ),
            store: store,
            reminders: reminders,
            localData: localData
        )
    }

    /// A time of day on the clock's own day, so a test can name an hour and a minute without
    /// reaching for `Date()`.
    private func time(hour: Int, minute: Int) throws -> Date {
        try #require(
            SyntheticScenarios.calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: SyntheticScenarios.evaluationDate
            )
        )
    }

    // MARK: - Loading

    @Test("Loading shows what was stored, reminder included")
    func loadingShowsTheStoredPreferences() async throws {
        // Given a profile already on disk with a reminder at 21:15
        let stored = PreferencesDraft(
            dietProfile: .vegetarian,
            excludedIngredientIDs: ["ingredient.rice"],
            favouriteFamilies: [.tacos],
            onboardingCompletedAt: SyntheticScenarios.evaluationDate,
            narrationEnabled: false,
            reminderHour: 21,
            reminderMinute: 15
        )
        let sut = makeSUT(seeded: stored)

        // When Settings opens
        await sut.viewModel.load()

        // Then the screen shows that profile, and the reminder rows reflect the stored time
        #expect(sut.viewModel.draft == stored)
        #expect(sut.viewModel.reminderEnabled)
        #expect(sut.viewModel.isReminderScheduled)
        let components = SyntheticScenarios.calendar
            .dateComponents([.hour, .minute], from: sut.viewModel.reminderTime)
        #expect(components.hour == 21)
        #expect(components.minute == 15)
    }

    @Test("A profile with no reminder opens with the reminder off")
    func aProfileWithoutAReminderOpensOff() async {
        // Given a stored profile that has never had a reminder
        let sut = makeSUT(seeded: PreferencesDraft(reminderHour: nil, reminderMinute: nil))

        // When Settings opens
        await sut.viewModel.load()

        // Then nothing claims a reminder exists
        #expect(!sut.viewModel.reminderEnabled)
        #expect(!sut.viewModel.isReminderScheduled)
    }

    // MARK: - Editing preferences

    @Test("Turning the judge's flourish off is saved")
    func turningNarrationOffIsSaved() async throws {
        // Given a loaded profile with narration on
        let sut = makeSUT(seeded: PreferencesDraft(narrationEnabled: true))
        await sut.viewModel.load()

        // When the toggle is switched off and the change reported
        sut.viewModel.draft.narrationEnabled = false
        await sut.viewModel.preferencesChanged()

        // Then the write actually carried the new value
        let saved = try #require(await sut.store.savedDrafts.last)
        #expect(saved.narrationEnabled == false)
        #expect(sut.viewModel.saveState == .idle)
    }

    @Test("A failed save is shown as a failure, and the edit stays on screen")
    func aFailedSaveIsNeverReportedAsASave() async {
        // Given a store that refuses every write
        let sut = makeSUT(seeded: PreferencesDraft(), storeFailure: FoodgeError.saveFailed)
        await sut.viewModel.load()

        // When the user excludes an ingredient
        await sut.viewModel.toggleExclusion("ingredient.rice")

        // Then the failure is visible, the choice is still on screen, and nothing was written
        #expect(sut.viewModel.saveState == .failed(.saveFailed))
        #expect(sut.viewModel.draft.excludedIngredientIDs.contains("ingredient.rice"))
        let saved = await sut.store.savedDrafts
        #expect(saved.isEmpty)
    }

    @Test("Favourites keep the order they were chosen in")
    func favouritesKeepTheirOrder() async throws {
        // Given a loaded profile with no favourites
        let sut = makeSUT(seeded: PreferencesDraft())
        await sut.viewModel.load()

        // When three are chosen and the first is taken back
        await sut.viewModel.toggleFavourite(.tacos)
        await sut.viewModel.toggleFavourite(.pasta)
        await sut.viewModel.toggleFavourite(.vegetableSoup)
        await sut.viewModel.toggleFavourite(.tacos)

        // Then what was saved is the remaining two, in the order they were picked
        let saved = try #require(await sut.store.savedDrafts.last)
        #expect(saved.favouriteFamilies == [.pasta, .vegetableSoup])
    }

    // MARK: - The reminder

    @Test("Enabling the reminder schedules the chosen time and stores it")
    func enablingTheReminderStoresTheChosenTime() async throws {
        // Given a loaded profile with no reminder
        let sut = makeSUT(seeded: PreferencesDraft())
        await sut.viewModel.load()

        // When the user picks 19:30 and switches the reminder on
        sut.viewModel.reminderTime = try time(hour: 19, minute: 30)
        sut.viewModel.reminderEnabled = true
        await sut.viewModel.reminderEnabledChanged(to: true)

        // Then that time was scheduled and stored
        let scheduled = try #require(await sut.reminders.scheduledTimes.last)
        #expect(scheduled.hour == 19)
        #expect(scheduled.minute == 30)
        #expect(sut.viewModel.isReminderScheduled)
        #expect(sut.viewModel.reminderFailure == nil)

        let saved = try #require(await sut.store.savedDrafts.last)
        #expect(saved.reminderHour == 19)
        #expect(saved.reminderMinute == 30)
    }

    @Test("A refused reminder is not shown as set, and its time is not stored")
    func aRefusedReminderIsNeverReportedAsSet() async {
        // Given a system that refuses notification permission
        let sut = makeSUT(seeded: PreferencesDraft(), reminderFailure: FoodgeError.reminderNotAuthorized)
        await sut.viewModel.load()

        // When the user switches the reminder on
        sut.viewModel.reminderEnabled = true
        await sut.viewModel.reminderEnabledChanged(to: true)

        // Then the toggle goes back, the refusal is explained, and no time was written
        #expect(!sut.viewModel.reminderEnabled)
        #expect(!sut.viewModel.isReminderScheduled)
        #expect(sut.viewModel.reminderFailure == .reminderNotAuthorized)
        let saved = await sut.store.savedDrafts
        #expect(saved.isEmpty)
    }

    @Test("The toggle going back after a refusal does not erase the explanation")
    func theRevertedToggleKeepsTheRefusalVisible() async {
        // Given a refused attempt, which has already put the toggle back to off
        let sut = makeSUT(seeded: PreferencesDraft(), reminderFailure: FoodgeError.reminderNotAuthorized)
        await sut.viewModel.load()
        sut.viewModel.reminderEnabled = true
        await sut.viewModel.reminderEnabledChanged(to: true)

        // When the change notification for that revert arrives, as SwiftUI's `onChange` sends it
        await sut.viewModel.reminderEnabledChanged(to: false)

        // Then the message the user needs is still there, and nothing was cancelled — the app
        // never asked the system for a reminder in the first place
        #expect(sut.viewModel.reminderFailure == .reminderNotAuthorized)
        let cancelCount = await sut.reminders.cancelCount
        #expect(cancelCount == 0)
    }

    @Test("Turning the reminder off cancels it and clears the stored time")
    func turningTheReminderOffClearsTheStoredTime() async throws {
        // Given a stored reminder at 21:15
        let sut = makeSUT(seeded: PreferencesDraft(reminderHour: 21, reminderMinute: 15))
        await sut.viewModel.load()

        // When the user switches it off
        sut.viewModel.reminderEnabled = false
        await sut.viewModel.reminderEnabledChanged(to: false)

        // Then the pending reminder was cancelled and nothing is stored for it
        let cancelCount = await sut.reminders.cancelCount
        #expect(cancelCount == 1)
        #expect(!sut.viewModel.isReminderScheduled)

        let saved = try #require(await sut.store.savedDrafts.last)
        #expect(saved.reminderHour == nil)
        #expect(saved.reminderMinute == nil)
    }

    @Test("Moving the time with the reminder off asks the system for nothing")
    func movingTheTimeWithTheReminderOffSchedulesNothing() async throws {
        // Given a loaded profile with no reminder
        let sut = makeSUT(seeded: PreferencesDraft())
        await sut.viewModel.load()

        // When the picker moves
        sut.viewModel.reminderTime = try time(hour: 18, minute: 0)
        await sut.viewModel.reminderTimeChanged()

        // Then nothing was scheduled and no permission was asked for
        let scheduled = await sut.reminders.scheduledTimes
        #expect(scheduled.isEmpty)
    }

    @Test("Moving the time with the reminder on reschedules it")
    func movingTheTimeWithTheReminderOnReschedulesIt() async throws {
        // Given a reminder already set for 21:15
        let sut = makeSUT(seeded: PreferencesDraft(reminderHour: 21, reminderMinute: 15))
        await sut.viewModel.load()

        // When the user moves it to 18:45
        sut.viewModel.reminderTime = try time(hour: 18, minute: 45)
        await sut.viewModel.reminderTimeChanged()

        // Then the new time replaced the old one, in the system and in the store
        let scheduled = try #require(await sut.reminders.scheduledTimes.last)
        #expect(scheduled.hour == 18)
        #expect(scheduled.minute == 45)

        let saved = try #require(await sut.store.savedDrafts.last)
        #expect(saved.reminderHour == 18)
        #expect(saved.reminderMinute == 45)
    }

    // MARK: - Deletion

    @Test("Deleting wipes the store and cancels the pending reminder")
    func deletingWipesAndCancels() async {
        // Given a profile with a reminder set
        let sut = makeSUT(seeded: PreferencesDraft(reminderHour: 21, reminderMinute: 15))
        await sut.viewModel.load()

        // When the user confirms deletion
        await sut.viewModel.deleteLocalData()

        // Then the store was emptied, the reminder cancelled, and the screen says so
        let eraseCount = await sut.localData.eraseCount
        let cancelCount = await sut.reminders.cancelCount
        #expect(eraseCount == 1)
        #expect(cancelCount == 1)
        #expect(sut.viewModel.deleteState == .deleted)
        #expect(sut.viewModel.draft == PreferencesDraft())
        #expect(!sut.viewModel.reminderEnabled)
    }

    @Test("A failed deletion is never reported as a deletion, and keeps the reminder")
    func aFailedDeletionKeepsEverything() async {
        // Given a store that refuses to delete
        let sut = makeSUT(
            seeded: PreferencesDraft(reminderHour: 21, reminderMinute: 15),
            eraseFailure: FoodgeError.saveFailed
        )
        await sut.viewModel.load()

        // When the user confirms deletion
        await sut.viewModel.deleteLocalData()

        // Then the failure is shown, and the reminder they still have data for is untouched
        #expect(sut.viewModel.deleteState == .failed(.saveFailed))
        let cancelCount = await sut.reminders.cancelCount
        #expect(cancelCount == 0)
        #expect(sut.viewModel.isReminderScheduled)
    }
}
