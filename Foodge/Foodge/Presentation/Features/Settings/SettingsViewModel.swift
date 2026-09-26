//
//  SettingsViewModel.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation
import OSLog

/// Everything the Settings screen can change, and the rules about what it may claim.
///
/// Three of those rules are why this type has as much state as it does:
/// - A failed write is never reported as a write. ``saveState`` stays `.failed` with the edit
///   still on screen, exactly as onboarding's single save does.
/// - A reminder that was refused permission is **not** shown as on, and its time is **not**
///   stored. ``isReminderScheduled`` tracks what the system actually accepted, never what the
///   toggle looks like.
/// - Deleted data is only reported deleted once the store said so.
@MainActor
@Observable
final class SettingsViewModel {
    enum LoadState: Hashable, Sendable {
        case loading
        case ready
        /// The stored preferences could not be read. Editing is offered anyway — the screen's
        /// other rows (Health guidance, deletion) still work — but nothing pretends the values
        /// on screen came from disk.
        case unreadable
    }

    enum SaveState: Hashable, Sendable {
        case idle
        case saving
        case failed(FoodgeError)
    }

    enum DeleteState: Hashable, Sendable {
        case idle
        case deleting
        case deleted
        case failed(FoodgeError)
    }

    var draft = PreferencesDraft()
    /// What the toggle shows. Only ever `true` while ``isReminderScheduled`` agrees, or in the
    /// instant between the user flipping it and the system answering.
    var reminderEnabled = false
    /// The `DatePicker`'s value. Only its hour and minute are ever used.
    var reminderTime: Date

    private(set) var loadState: LoadState = .loading
    private(set) var saveState: SaveState = .idle
    private(set) var deleteState: DeleteState = .idle
    /// Set when the system refused permission, or when scheduling did not complete. The two are
    /// kept apart because only the first is something the user can act on.
    private(set) var reminderFailure: FoodgeError?

    /// Whether a reminder is actually scheduled with the system right now.
    ///
    /// Distinct from ``reminderEnabled``, which is only what the control shows. Keeping them
    /// apart is what lets the failure path put the toggle back without the resulting change
    /// notification being mistaken for the user switching the reminder off.
    private(set) var isReminderScheduled = false

    @ObservationIgnored private let store: any PreferencesStore
    @ObservationIgnored private let reminders: any ReminderService
    @ObservationIgnored private let localData: any LocalDataErasing
    @ObservationIgnored private let clock: any EvaluationClock

    init(
        store: any PreferencesStore,
        reminders: any ReminderService,
        localData: any LocalDataErasing,
        clock: any EvaluationClock
    ) {
        self.store = store
        self.reminders = reminders
        self.localData = localData
        self.clock = clock
        reminderTime = Self.defaultReminderTime(clock: clock)
    }

    // MARK: - Loading

    /// Reads the stored preferences once, and shapes the reminder rows from them.
    func load() async {
        let stored: PreferencesDraft?
        do {
            stored = try await store.preferences()
        } catch {
            loadState = .unreadable
            SettingsLog.logger.error("SETTINGS load=unreadable")
            return
        }

        if let stored {
            draft = stored
            if let time = Self.time(hour: stored.reminderHour, minute: stored.reminderMinute, clock: clock) {
                reminderTime = time
                reminderEnabled = true
                isReminderScheduled = true
            }
        }

        loadState = .ready
        SettingsLog.logger.info("SETTINGS load=ready")
    }

    // MARK: - Preferences

    /// Adds or removes a favourite, preserving the order they were chosen in, then saves.
    func toggleFavourite(_ family: DishFamily) async {
        if let index = draft.favouriteFamilies.firstIndex(of: family) {
            draft.favouriteFamilies.remove(at: index)
        } else {
            draft.favouriteFamilies.append(family)
        }
        await persist()
    }

    /// Adds or removes an ingredient exclusion, then saves.
    func toggleExclusion(_ ingredientID: String) async {
        if draft.excludedIngredientIDs.contains(ingredientID) {
            draft.excludedIngredientIDs.remove(ingredientID)
        } else {
            draft.excludedIngredientIDs.insert(ingredientID)
        }
        await persist()
    }

    /// Saves an edit the view bound straight into ``draft`` — diet, dinner routine, narration.
    func preferencesChanged() async {
        await persist()
    }

    // MARK: - Reminder

    /// Schedules or cancels the evening reminder.
    ///
    /// The guard is what makes the failure path safe: when scheduling is refused this method puts
    /// ``reminderEnabled`` back to `false` itself, and the change notification that follows
    /// arrives here as "switch off a reminder that was never on" — which is exactly the state
    /// already recorded, so it returns without clearing the failure the user still needs to see.
    func reminderEnabledChanged(to isEnabled: Bool) async {
        guard isEnabled != isReminderScheduled else { return }

        if isEnabled {
            await scheduleReminder()
        } else {
            await cancelReminder()
        }
    }

    /// Reschedules at the new time, but only when a reminder is actually scheduled. Moving the
    /// picker with the reminder off changes nothing and asks for no permission.
    func reminderTimeChanged() async {
        guard isReminderScheduled else { return }
        await scheduleReminder()
    }

    private func scheduleReminder() async {
        let components = clock.calendar.dateComponents([.hour, .minute], from: reminderTime)

        do {
            try await reminders.schedule(at: components)
        } catch {
            // Neither the toggle nor the store may claim a reminder the system did not accept.
            isReminderScheduled = false
            reminderEnabled = false
            reminderFailure = (error as? FoodgeError) ?? .reminderSchedulingFailed
            SettingsLog.logger.error("SETTINGS reminder=notScheduled")
            return
        }

        isReminderScheduled = true
        reminderFailure = nil
        draft.reminderHour = components.hour
        draft.reminderMinute = components.minute
        SettingsLog.logger.info("SETTINGS reminder=scheduled")
        await persist()
    }

    private func cancelReminder() async {
        await reminders.cancel()
        isReminderScheduled = false
        reminderFailure = nil
        draft.reminderHour = nil
        draft.reminderMinute = nil
        SettingsLog.logger.info("SETTINGS reminder=cancelled")
        await persist()
    }

    // MARK: - Deletion

    /// Deletes everything stored locally, then cancels the pending reminder.
    ///
    /// Apple Health records are never touched. The reminder is cancelled only after the store
    /// confirms the deletion: a failed delete leaves the user exactly as they were, rather than
    /// silently losing the reminder they still have data for.
    func deleteLocalData() async {
        deleteState = .deleting

        do {
            try await localData.eraseLocalData()
        } catch {
            deleteState = .failed(.saveFailed)
            SettingsLog.logger.error("SETTINGS delete=failed")
            return
        }

        await reminders.cancel()

        draft = PreferencesDraft()
        reminderEnabled = false
        isReminderScheduled = false
        reminderFailure = nil
        reminderTime = Self.defaultReminderTime(clock: clock)
        saveState = .idle
        deleteState = .deleted
        SettingsLog.logger.info("SETTINGS delete=completed")
    }

    // MARK: - Writing

    /// The single write path. Every edit on this screen goes through it, and a failure stays
    /// visible rather than being swallowed.
    private func persist() async {
        saveState = .saving

        do {
            try await store.savePreferences(draft)
        } catch {
            saveState = .failed(.saveFailed)
            SettingsLog.logger.error("SETTINGS save=failed")
            return
        }

        saveState = .idle
        SettingsLog.logger.info("SETTINGS save=completed")
    }

    // MARK: - Time shaping

    /// 8 p.m. on the clock's own day — a plausible evening default, never `Date()`.
    private static func defaultReminderTime(clock: any EvaluationClock) -> Date {
        time(hour: 20, minute: 0, clock: clock) ?? clock.now
    }

    /// The stored hour and minute as a `Date` the picker can show, or `nil` when either is
    /// missing — an incomplete pair is not a reminder.
    private static func time(hour: Int?, minute: Int?, clock: any EvaluationClock) -> Date? {
        guard let hour, let minute else { return nil }
        return clock.calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: clock.now
        )
    }
}
