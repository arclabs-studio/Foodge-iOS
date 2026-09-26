//
//  SelfReportCheckInSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// The user's own account of the day, asked only when no recorded comparison is usable.
///
/// Skipping is a real, honest option here — it produces a provisional balanced verdict rather
/// than forcing a choice the user cannot make.
@MainActor
struct SelfReportCheckInSection: View {
    let submit: (SelfReportedActivity?) -> Void

    var body: some View {
        Section {
            Text("There isn’t enough readable data to work out today’s allowance.")
            Text("How active was today, compared to usual?")
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(SelfReportedActivity.allCases, id: \.self) { report in
                Button(String(localized: report.displayName)) { submit(report) }
            }
            Button("Skip") { submit(nil) }
        }
    }
}

#Preview {
    Form {
        SelfReportCheckInSection(submit: { _ in })
    }
}
