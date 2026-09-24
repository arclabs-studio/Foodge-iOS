//
//  DemonstrationHealthAuthorization.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Reports Health as available and asks for nothing.
///
/// A demonstration must never raise Apple's own Health authorization sheet: the audience did not
/// consent to it, and a granted request would attach real permissions to synthetic data.
/// `isHealthDataAvailable` is `true` because the scenarios do carry readable evidence — reporting
/// `false` would send every screen down the "no readable data" path and hide nine of the ten
/// scenarios behind the tenth.
struct DemonstrationHealthAuthorization: HealthAuthorizing {
    let isHealthDataAvailable = true

    func requestReadAuthorization() async throws {}
}
