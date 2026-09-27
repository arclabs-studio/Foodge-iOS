//
//  BodyBasicsTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// `BodyBasics` is the only thing standing between a typo and a maintenance figure the whole
/// verdict rests on, so every boundary of its validation is pinned — including the decode path,
/// which is how an implausible figure would re-enter from a stored snapshot.
@Suite("Body basics", .tags(.unit, .domain))
struct BodyBasicsTests {

    // MARK: - Accepted

    @Test("Ordinary figures are accepted and kept verbatim")
    func plausibleFiguresAreAccepted() throws {
        // Given ordinary adult figures
        // When the basics are built
        let body = try #require(
            BodyBasics(sex: .female, ageYears: 35, heightCentimetres: 168, weightKilograms: 62)
        )

        // Then nothing was rounded, clamped or reinterpreted
        #expect(body.sex == .female)
        #expect(body.ageYears == 35)
        #expect(body.heightCentimetres == 168)
        #expect(body.weightKilograms == 62)
    }

    @Test("Each range is inclusive at both ends", arguments: [
        (13, 120.0, 30.0),
        (120, 230.0, 300.0),
    ])
    func theBoundsThemselvesAreAccepted(age: Int, height: Double, weight: Double) {
        // Given a figure sitting exactly on each bound
        // When the basics are built
        let body = BodyBasics(
            sex: .male,
            ageYears: age,
            heightCentimetres: height,
            weightKilograms: weight
        )

        // Then the bound is inside the accepted range
        #expect(body != nil)
    }

    // MARK: - Rejected

    @Test("A figure outside any range means no estimate is possible", arguments: [
        (12, 175.0, 70.0),
        (121, 175.0, 70.0),
        (35, 119.9, 70.0),
        (35, 230.1, 70.0),
        (35, 175.0, 29.9),
        (35, 175.0, 300.1),
        // 69 inches typed where centimetres were asked for — the unit mix-up a numeric keypad
        // invites. A weight mix-up is not caught this way: 154 lb read as kg is 154, which is a
        // plausible mass, so the ranges cannot see it.
        (35, 69.0, 70.0),
    ])
    func implausibleFiguresAreRejected(age: Int, height: Double, weight: Double) {
        // Given an implausible figure
        // When the basics are built
        let body = BodyBasics(
            sex: .male,
            ageYears: age,
            heightCentimetres: height,
            weightKilograms: weight
        )

        // Then there is no `BodyBasics` at all — never a clamped one
        #expect(body == nil)
    }

    @Test("A non-finite figure is rejected rather than propagating a NaN maintenance figure")
    func nonFiniteFiguresAreRejected() {
        #expect(BodyBasics(sex: .male, ageYears: 35, heightCentimetres: .nan, weightKilograms: 70) == nil)
        #expect(BodyBasics(sex: .male, ageYears: 35, heightCentimetres: 175, weightKilograms: .infinity) == nil)
    }

    // MARK: - Decoding

    @Test("Stored figures that break the invariant fail to decode")
    func decodingRejectsImplausibleStoredFigures() throws {
        // Given a stored payload with a weight no person has, as an older build or a hand-edited
        // store could hold
        let payload = Data(
            """
            {"sex":"male","ageYears":35,"heightCentimetres":175,"weightKilograms":900}
            """.utf8
        )

        // When it is decoded
        // Then it throws rather than admitting a figure the initializer would have refused
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(BodyBasics.self, from: payload)
        }
    }

    @Test("A valid payload round-trips")
    func encodingAndDecodingPreserveTheFigures() throws {
        // Given valid basics
        let body = try #require(
            BodyBasics(sex: .male, ageYears: 41, heightCentimetres: 181, weightKilograms: 78.5)
        )

        // When they are encoded and decoded again
        let decoded = try JSONDecoder().decode(BodyBasics.self, from: JSONEncoder().encode(body))

        // Then nothing changed on the way through
        #expect(decoded == body)
    }
}
