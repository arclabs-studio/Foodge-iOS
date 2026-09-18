//
//  FeasibilityProbeView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

#if DEBUG

import FoundationModels
import HealthKit
import OSLog
import SwiftUI

/// Day 18 only: proves on a real iPhone that Health authorization, a real Health read and
/// on-device generation all work before any feature is built on them.
///
/// This whole file — view, view model and probe — is deleted in the Day 19 onboarding work
/// unit, which is why it is kept together rather than split across the normal file layout.
/// It never displays a Health value: a reading is reported only as readable or not.
@MainActor
@Observable
final class FeasibilityProbeViewModel {
    enum HealthProbe: Hashable {
        case idle
        case requesting
        case readable
        case noReadableData
        case healthUnavailable
        case requestFailed
    }

    enum NarrationProbe: Hashable {
        case idle
        case asking
        case answered(characterCount: Int)
        case failed
    }

    private(set) var health: HealthProbe = .idle
    private(set) var narration: NarrationProbe = .idle

    var modelAvailability: NarrationAvailability { NarrationAvailability.current }

    private let authorization = HealthAuthorizationService()
    private let store = HKHealthStore()

    /// Records the probe's outcome so the result can be read back from the device log.
    ///
    /// Only the state labels below are ever logged — never a Health value, never model output.
    private let log = Logger(subsystem: "com.arclabs.Foodge", category: "FeasibilityProbe")

    func connectHealth() async {
        health = .requesting
        do {
            try await authorization.requestReadAuthorization()
            health = try await activeEnergyIsReadable(sinceDaysAgo: 0) ? .readable : .noReadableData
        } catch FoodgeError.healthUnavailable {
            health = .healthUnavailable
        } catch {
            health = .requestFailed
        }
        log.notice("PROBE health=\(String(describing: self.health), privacy: .public)")

        // Just after midnight there is legitimately nothing recorded today, which would leave the
        // probe unable to say whether reading a real value works at all. A seven-day window
        // answers that separately — still as a yes or no, never as a figure.
        let week = (try? await activeEnergyIsReadable(sinceDaysAgo: 7)) ?? false
        log.notice("PROBE lastSevenDaysReadable=\(week, privacy: .public)")
    }

    func sayHello() async {
        narration = .asking
        log.notice("PROBE availability=\(String(describing: self.modelAvailability), privacy: .public)")
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: "Reply with one word: hello")
            narration = .answered(characterCount: response.content.count)
        } catch {
            narration = .failed
        }
        log.notice("PROBE narration=\(String(describing: self.narration), privacy: .public)")
    }

    /// Whether Health returns any active-energy sum for a window ending now.
    ///
    /// `sinceDaysAgo: 0` means since local midnight. Returns a Boolean rather than the figure on
    /// purpose: the probe must not put a Health value on screen or anywhere near a log.
    private func activeEnergyIsReadable(sinceDaysAgo days: Int) async throws -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        let start = days == 0 ? midnight : calendar.date(byAdding: .day, value: -days, to: midnight) ?? midnight
        let samples = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: [.strictStartDate]
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HealthReadTypes.activeEnergy, predicate: samples),
            options: .cumulativeSum
        )
        return try await descriptor.result(for: store)?.sumQuantity() != nil
    }
}

@MainActor
struct FeasibilityProbeView: View {
    @State private var vm = FeasibilityProbeViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Health") {
                    Button("Connect Health") {
                        Task { await vm.connectHealth() }
                    }
                    .disabled(vm.health == .requesting)

                    LabeledContent("Result", value: healthDescription)
                }

                Section("Foundation Models") {
                    LabeledContent("Availability", value: availabilityDescription)

                    Button("Say hello") {
                        Task { await vm.sayHello() }
                    }
                    .disabled(vm.narration == .asking || !vm.modelAvailability.canNarrate)

                    LabeledContent("Result", value: narrationDescription)
                }
            }
            .navigationTitle("Feasibility probe")
        }
    }

    private var healthDescription: String {
        switch vm.health {
        case .idle: "Not run yet"
        case .requesting: "Requesting…"
        case .readable: "Readable"
        case .noReadableData: "No readable data"
        case .healthUnavailable: "Health unavailable on this device"
        case .requestFailed: "Request failed"
        }
    }

    private var availabilityDescription: String {
        switch vm.modelAvailability {
        case .available: "Available"
        case .deviceNotEligible: "Device not eligible"
        case .appleIntelligenceNotEnabled: "Apple Intelligence not enabled"
        case .modelNotReady: "Model not ready"
        case .unavailableForAnotherReason: "Unavailable"
        }
    }

    private var narrationDescription: String {
        switch vm.narration {
        case .idle: "Not run yet"
        case .asking: "Asking…"
        case let .answered(characterCount): "Answered, \(characterCount) characters"
        case .failed: "Failed"
        }
    }
}

#Preview {
    FeasibilityProbeView()
}

#endif
