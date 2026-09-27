//
//  HealthReadTypes.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import HealthKit

/// The complete set of Health types Foodge asks to read.
///
/// Exactly the six the product uses and nothing more — no weight, no body mass index, no
/// medical history. Nothing is ever requested for writing.
enum HealthReadTypes {
    static let activeEnergy = HKQuantityType(.activeEnergyBurned)
    static let restingEnergy = HKQuantityType(.basalEnergyBurned)
    static let steps = HKQuantityType(.stepCount)
    static let sleep = HKCategoryType(.sleepAnalysis)
    static let workouts = HKObjectType.workoutType()
    static let dietaryEnergy = HKQuantityType(.dietaryEnergyConsumed)

    static let all: Set<HKObjectType> = [
        activeEnergy,
        restingEnergy,
        steps,
        sleep,
        workouts,
        dietaryEnergy
    ]
}
