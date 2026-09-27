//
//  LocalReminderServiceTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The evening reminder is the one place Foodge asks the system for permission to interrupt
/// someone, so the rules here are about what it may claim afterwards: a refusal is a refusal, a
/// failure is a failure, and neither is a scheduled reminder.
@Suite("Local reminder service", .tags(.unit, .critical))
struct LocalReminderServiceTests {
    private struct SUT {
        let service: LocalReminderService
        let centre: FixtureNotificationCentre
    }

    private func makeSUT(
        isAuthorized: Bool = true,
        authorizationFailure: (any Error)? = nil,
        addFailure: (any Error)? = nil
    ) -> SUT {
        let centre = FixtureNotificationCentre(
            isAuthorized: isAuthorized,
            authorizationFailure: authorizationFailure,
            addFailure: addFailure
        )
        return SUT(service: LocalReminderService(centre: centre), centre: centre)
    }

    @Test("A granted request schedules one reminder that repeats at the chosen time")
    func aGrantedRequestSchedulesTheChosenTime() async throws {
        // Given a notification centre that grants permission
        let sut = makeSUT(isAuthorized: true)

        // When the user asks for a reminder at 19:45
        try await sut.service.schedule(at: DateComponents(hour: 19, minute: 45))

        // Then exactly one request was added, carrying that wall-clock time, repeating
        let added = await sut.centre.added
        let request = try #require(added.first)
        #expect(added.count == 1)
        #expect(request.time.hour == 19)
        #expect(request.time.minute == 45)
        #expect(request.repeats)
        #expect(request.identifier == LocalReminderService.requestIdentifier)
    }

    @Test("A refused request schedules nothing and says so")
    func aRefusedRequestSchedulesNothing() async {
        // Given a notification centre that refuses permission
        let sut = makeSUT(isAuthorized: false)

        // When the user asks for a reminder
        await #expect(throws: FoodgeError.reminderNotAuthorized) {
            try await sut.service.schedule(at: DateComponents(hour: 21, minute: 0))
        }

        // Then nothing was scheduled — a refusal is never reported as a reminder
        let added = await sut.centre.added
        #expect(added.isEmpty)
    }

    @Test("A request that does not complete is a failure, never a refusal")
    func aFailedRequestIsNotReportedAsARefusal() async {
        // Given a notification centre whose authorization request itself throws
        let sut = makeSUT(authorizationFailure: FixtureFailure())

        // When the user asks for a reminder
        await #expect(throws: FoodgeError.reminderSchedulingFailed) {
            try await sut.service.schedule(at: DateComponents(hour: 21, minute: 0))
        }

        // Then nothing was scheduled, and the error is the "we cannot say why" one — claiming a
        // refusal here would assert an answer the system never gave
        let added = await sut.centre.added
        #expect(added.isEmpty)
    }

    @Test("A granted request whose add fails is reported as a failure")
    func aFailedAddIsReportedAsAFailure() async {
        // Given permission granted but the request itself rejected
        let sut = makeSUT(isAuthorized: true, addFailure: FixtureFailure())

        // When the user asks for a reminder
        await #expect(throws: FoodgeError.reminderSchedulingFailed) {
            try await sut.service.schedule(at: DateComponents(hour: 21, minute: 0))
        }

        // Then the centre holds nothing
        let added = await sut.centre.added
        #expect(added.isEmpty)
    }

    @Test("Cancelling removes the one pending reminder and asks for no permission")
    func cancellingRemovesThePendingReminder() async {
        // Given a service over a centre that has been asked for nothing yet
        let sut = makeSUT()

        // When the reminder is cancelled
        await sut.service.cancel()

        // Then exactly the reminder's own identifier was removed, and no permission was requested
        let removed = await sut.centre.removedIdentifiers
        let requestCount = await sut.centre.authorizationRequestCount
        #expect(removed == [[LocalReminderService.requestIdentifier]])
        #expect(requestCount == 0)
    }
}
