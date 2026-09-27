//
//  IntakeEstimate.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// The meals a day's intake is asked about before dinner.
///
/// Dinner is absent on purpose: it is what the verdict is *about*, so it cannot be an input.
enum MealSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case breakfast
    case lunch
    case snacks
}

/// How big a meal was, in the only terms someone can answer from memory.
///
/// `skipped` is an **answer**, not an absence: it means "I did not eat it", which is a reading
/// worth zero. An unanswered slot is `nil` and contributes nothing at all. That distinction is
/// what keeps "missing Health data stays missing" true once a questionnaire can supply intake.
enum MealPortion: String, Codable, CaseIterable, Hashable, Sendable {
    case skipped
    case light
    case normal
    case heavy

    /// The editorial figure for this portion of this meal.
    ///
    /// Indicative, not measured: a "normal lunch" is a made-up number that happens to be roughly
    /// right for most people, which is all a share-of-maintenance band needs (D112). It is never
    /// presented as a verified calorie figure — `CalorieReference` remains the only type allowed
    /// to claim one (D116).
    func kilocalories(for slot: MealSlot) -> Double {
        switch self {
        case .skipped:
            0
        case .light:
            switch slot {
            case .breakfast: 200
            case .lunch: 350
            case .snacks: 100
            }
        case .normal:
            switch slot {
            case .breakfast: 400
            case .lunch: 650
            case .snacks: 250
            }
        case .heavy:
            switch slot {
            case .breakfast: 650
            case .lunch: 1000
            case .snacks: 500
            }
        }
    }
}

/// What the user said they have eaten so far today.
///
/// Three explicit optionals rather than `[MealSlot: MealPortion]`: a dictionary with an enum key
/// does not round-trip through `Codable` as an object, and `nil` ("not answered") has to stay
/// distinct from `.skipped` ("I did not eat it").
struct IntakeQuestionnaire: Hashable, Codable, Sendable {
    let breakfast: MealPortion?
    let lunch: MealPortion?
    let snacks: MealPortion?

    init(
        breakfast: MealPortion? = nil,
        lunch: MealPortion? = nil,
        snacks: MealPortion? = nil
    ) {
        self.breakfast = breakfast
        self.lunch = lunch
        self.snacks = snacks
    }

    /// A questionnaire nobody has touched.
    static let unanswered = IntakeQuestionnaire()

    /// Whether any slot was answered at all.
    ///
    /// One answered slot is enough to make the questionnaire a usable basis, which is a
    /// deliberate trade: a partly answered day understates intake and so overstates the
    /// allowance, but refusing to rule until all three are answered would send most users to the
    /// self-report fallback instead, which carries no figure at all.
    var isAnswered: Bool {
        breakfast != nil || lunch != nil || snacks != nil
    }

    /// The sum of the answered slots. Unanswered slots contribute nothing — never a zero.
    var kilocalories: Double {
        var total = 0.0
        if let breakfast { total += breakfast.kilocalories(for: .breakfast) }
        if let lunch { total += lunch.kilocalories(for: .lunch) }
        if let snacks { total += snacks.kilocalories(for: .snacks) }
        return total
    }
}

/// Today's intake, and where it came from.
///
/// An enum rather than a total plus a flag, for D49's reason extended to estimates (D114): a
/// caller cannot physically hold both a Health total and an estimate to be summed, and every call
/// site has to read the provenance to get at the figure.
enum DailyIntake: Hashable, Codable, Sendable {
    /// HealthKit `dietaryEnergy`. Replaces an estimate, never adds to it.
    case recorded(EnergyAggregate)
    case estimated(IntakeQuestionnaire)
}
