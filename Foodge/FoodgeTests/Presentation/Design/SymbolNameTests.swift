//
//  SymbolNameTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 13/10/2026.
//

@testable import Foodge
import Foundation
import Testing
import UIKit

/// Every symbol a form screen reads from a model extension must be a real SF Symbol.
///
/// A symbol name is a bare string: a typo compiles, builds and ships, and `Image(systemName:)`
/// silently draws nothing. That is the failure these tests exist for, and the only way to catch it
/// is to ask the system. The oracle is UIKit's own SF Symbols catalogue — it knows nothing about
/// Foodge — and the tests never name a symbol, so swapping a symbol for another real one is free.
///
/// The second half pins one property of the mapping that no compiler can: the four allowance bands
/// must not share a symbol, so a reader can tell *Generous* from *Spent* by more than a word.
@Suite("Symbol names", .tags(.unit))
@MainActor
struct SymbolNameTests {
    // MARK: - Every name resolves

    @Test("Every reason code's symbol name is a real SF Symbol", arguments: ReasonCode.allCases)
    func reasonCodeSymbolNameResolves(code: ReasonCode) {
        // Given a reason code and the symbol name it draws beside its sentence
        let name = code.symbolName

        // When the system is asked for that symbol
        let image = UIImage(systemName: name)

        // Then it exists — a typo'd name would otherwise draw nothing, with no build error
        #expect(image != nil, "\(code.rawValue) names the symbol \"\(name)\", which is not an SF Symbol.")
    }

    @Test("Every Health kind's symbol name is a real SF Symbol", arguments: HealthKind.allCases)
    func healthKindSymbolNameResolves(kind: HealthKind) {
        // Given a kind of Health data and the symbol name its evidence row draws
        let name = kind.symbolName

        // When the system is asked for that symbol
        let image = UIImage(systemName: name)

        // Then it exists
        #expect(image != nil, "\(kind.rawValue) names the symbol \"\(name)\", which is not an SF Symbol.")
    }

    // MARK: - The bands differ

    @Test("The four allowance bands each have a symbol of their own")
    func allowanceBandsNeverShareASymbol() {
        // Given the four reason codes that name how much of today's allowance is left
        let bands: [ReasonCode] = [.generousAllowance, .moderateAllowance, .slimAllowance, .allowanceSpent]

        // When their symbol names are collected
        let names = bands.map(\.symbolName)

        // Then four bands mean four different symbols — the band is not carried by wording alone
        #expect(
            Set(names).count == bands.count,
            "Allowance bands must not share a symbol, got \(names) for \(bands.map(\.rawValue))."
        )
    }
}
