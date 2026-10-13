//
//  HistoryMonthTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 13/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// History groups its cases under one native `Section` per month. The grouping reads each case's
/// `localDayKey` — a string, so it can be malformed — and must neither drop a case nor invent a
/// month for a key it cannot read.
///
/// Every oracle here is a literal key or a literal id written into the test. Nothing calls
/// `grouping` to work out what `grouping` should have said.
///
/// `grouping` is a pure static function, so there is no object to build: `makeSavedCase` builds the
/// input and each test calls the function itself, which keeps the *When* visible.
@Suite("History month grouping", .tags(.unit))
struct HistoryMonthTests {
    /// A case for one local day. Each call gets its own revision id, so two cases never compare
    /// equal by accident and an assertion on whole cases can tell them apart.
    private func makeSavedCase(localDayKey: String, category: DinnerCategory = .balanced) -> SavedCase {
        SavedCase(
            localDayKey: localDayKey,
            revisions: [
                SavedRevision(
                    id: UUID(),
                    sequence: 0,
                    createdAt: SyntheticScenarios.evaluationDate,
                    decision: VerdictDecision(
                        category: category,
                        basis: .provisional,
                        reasonCodes: [.checkInSkipped],
                        isProvisional: true,
                        ruleVersion: CheatMealAllowanceRule.ruleVersion
                    ),
                    evidence: SyntheticScenarios.modestAllowance.snapshot,
                    catalogueVersion: DishCatalogue.version,
                    dishOutcome: PersistedDishOutcome(
                        variantID: "dish.pasta.pesto",
                        family: .pasta,
                        alternativeVariantID: nil,
                        alternativeFamily: nil
                    ),
                    narrationText: nil
                ),
            ]
        )
    }

    private func makeSavedCases(_ localDayKeys: [String]) -> [SavedCase] {
        localDayKeys.map { makeSavedCase(localDayKey: $0) }
    }

    // MARK: - Grouping

    @Test("Newest-first cases from two months become two groups, in that order, keeping each month's order")
    func twoMonthsBecomeTwoGroupsInInputOrder() throws {
        // Given History's own order — newest first — spanning October and September
        let cases = makeSavedCases(["2026-10-02", "2026-10-01", "2026-09-30", "2026-09-18"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then there is one group per month, no empty trailing group, October ahead of September
        try #require(groups.count == 2)
        #expect(groups.map(\.id) == ["2026-10", "2026-09"])

        // And the year and month are the numbers in the key (compactMap: a nil would shorten the array)
        #expect(groups.compactMap(\.year) == [2026, 2026])
        #expect(groups.compactMap(\.month) == [10, 9])

        // And each group holds exactly its own month's days, in the order they came in
        #expect(groups[0].cases.map(\.localDayKey) == ["2026-10-02", "2026-10-01"])
        #expect(groups[1].cases.map(\.localDayKey) == ["2026-09-30", "2026-09-18"])
        #expect(groups[0].cases == [cases[0], cases[1]])
        #expect(groups[1].cases == [cases[2], cases[3]])
    }

    @Test("No cases means no groups")
    func emptyInputYieldsNoGroups() {
        // Given nothing recorded
        let cases: [SavedCase] = []

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then there is nothing to show — in particular no empty "undated" group
        #expect(groups.isEmpty)
    }

    @Test("Months follow the order their first case appears, not the calendar")
    func monthsFollowFirstAppearanceNotTheCalendar() {
        // Given the same two months, but oldest first
        let cases = makeSavedCases(["2026-09-18", "2026-09-30", "2026-10-01"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then September still comes first: the function groups, it does not re-sort
        #expect(groups.map(\.id) == ["2026-09", "2026-10"])
        #expect(groups.map { $0.cases.map(\.localDayKey) } == [["2026-09-18", "2026-09-30"], ["2026-10-01"]])
    }

    @Test("Cases of one month merge into one group even when other months sit between them")
    func nonAdjacentCasesOfOneMonthMerge() {
        // Given October, September, then October again
        let cases = makeSavedCases(["2026-10-02", "2026-09-30", "2026-10-01"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then October is one group placed where it first appeared, its days in input order
        #expect(groups.map(\.id) == ["2026-10", "2026-09"])
        #expect(groups.map { $0.cases.map(\.localDayKey) } == [["2026-10-02", "2026-10-01"], ["2026-09-30"]])
    }

    @Test("The same month in different years stays in different groups")
    func sameMonthInDifferentYearsStaysApart() throws {
        // Given September of two consecutive years
        let cases = makeSavedCases(["2026-09-18", "2025-09-18"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then the year is part of the group's identity
        try #require(groups.count == 2)
        #expect(groups.map(\.id) == ["2026-09", "2025-09"])
        #expect(groups.compactMap(\.year) == [2026, 2025])
        #expect(groups.compactMap(\.month) == [9, 9])
    }

    // MARK: - Keys that parse

    @Test("A non-padded month groups with its zero-padded twin")
    func nonPaddedMonthGroupsWithPaddedMonth() throws {
        // Given two September days, one of which spells the month without its leading zero
        let cases = makeSavedCases(["2026-9-18", "2026-09-03"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then they are one September group, not two, and both days are in it in input order
        try #require(groups.count == 1)
        #expect(groups[0].id == "2026-09")
        #expect(groups.compactMap(\.month) == [9])
        #expect(groups[0].cases.map(\.localDayKey) == ["2026-9-18", "2026-09-03"])
    }

    @Test("The group id is year-month with the month zero-padded", arguments: [
        ("2026-1-5", "2026-01", 1),
        ("2026-09-18", "2026-09", 9),
        ("2026-12-31", "2026-12", 12),
        // Year and month are enough to place a case; the day is not needed.
        ("2026-09", "2026-09", 9),
    ])
    func groupIDIsYearAndPaddedMonth(localDayKey: String, expectedID: String, expectedMonth: Int) throws {
        // Given one case whose key is spelled this way
        let cases = makeSavedCases([localDayKey])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then it lands in the group with the expected id and the month as a number
        try #require(groups.count == 1)
        #expect(groups[0].id == expectedID)
        #expect(groups.compactMap(\.month) == [expectedMonth])
    }

    // MARK: - Keys that do not parse

    @Test("A key that cannot be read goes to a trailing undated group, and no case is lost", arguments: [
        "garbage",
        "2026-13-01",
        "2026-00-10",
        "2026",
        "2026-ab-01",
        "x-09-01",
        "",
    ])
    func unreadableKeyLandsInTrailingUndatedGroup(badKey: String) throws {
        // Given a readable October day, an unreadable key, and a readable September day
        let cases = makeSavedCases(["2026-10-02", badKey, "2026-09-18"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then the unreadable key sits alone in an "undated" group placed last, after both months
        try #require(groups.count == 3)
        #expect(groups.map(\.id) == ["2026-10", "2026-09", "undated"])

        let undated = groups[2]
        #expect(undated.year == nil)
        #expect(undated.month == nil)
        #expect(undated.cases == [cases[1]])

        // And the readable groups are untouched by it
        #expect(groups[0].cases == [cases[0]])
        #expect(groups[1].cases == [cases[2]])

        // And not a single case was dropped
        #expect(groups.flatMap(\.cases).count == cases.count)
    }

    @Test("The undated group comes last even when the unreadable key is the first case")
    func undatedGroupIsLastEvenWhenItsCaseComesFirst() {
        // Given an unreadable key ahead of a readable one
        let cases = makeSavedCases(["garbage", "2026-10-02"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then the dated month still leads: "undated" is placed last, not by first appearance
        #expect(groups.map(\.id) == ["2026-10", "undated"])
    }

    @Test("Every unreadable key shares one undated group, in input order")
    func allUnreadableKeysShareOneUndatedGroup() throws {
        // Given two different unreadable keys with a readable day between them
        let cases = makeSavedCases(["garbage", "2026-10-02", "2026-13-01"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then there is a single undated group holding both in input order, and every case survived
        try #require(groups.count == 2)
        #expect(groups.map(\.id) == ["2026-10", "undated"])
        #expect(groups[1].cases.map(\.localDayKey) == ["garbage", "2026-13-01"])
        #expect(groups.flatMap(\.cases).count == cases.count)
    }

    @Test("A list with only unreadable keys is one undated group, not an empty list")
    func onlyUnreadableKeysStillProduceTheUndatedGroup() throws {
        // Given nothing but an unreadable key
        let cases = makeSavedCases(["garbage"])

        // When the cases are grouped
        let groups = HistoryMonth.grouping(cases)

        // Then the case is still shown, under "undated"
        try #require(groups.count == 1)
        #expect(groups[0].id == "undated")
        #expect(groups[0].year == nil)
        #expect(groups[0].month == nil)
        #expect(groups[0].cases == cases)
    }

    // MARK: - The header's date

    @Test("A month's header date is the first day of that month in the Gregorian calendar")
    func firstDayIsTheFirstOfTheMonth() throws {
        // Given a month read from an unpadded key
        let groups = HistoryMonth.grouping(makeSavedCases(["2026-9-18"]))
        try #require(groups.count == 1)

        // When the header asks for its date
        let firstDay = try #require(groups[0].firstDay)

        // Then it falls on 1 September 2026 — the month the key names, not the case's own day
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: firstDay)
        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 1)
    }

    @Test("The undated group has no header date")
    func undatedGroupHasNoFirstDay() throws {
        // Given only an unreadable key
        let groups = HistoryMonth.grouping(makeSavedCases(["garbage"]))
        try #require(groups.count == 1)

        // Then there is no month to name, so the section is drawn without a header
        #expect(groups[0].firstDay == nil)
    }
}
