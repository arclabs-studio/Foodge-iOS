//
//  StoreUnavailableView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// Shown when the local store cannot be opened.
///
/// The app stops here on purpose. Carrying on with a throwaway container would let someone
/// complete onboarding and lose it, which is worse than saying plainly that something is wrong.
@MainActor
struct StoreUnavailableView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Foodge can’t open its files", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Your preferences and past verdicts are stored on this iPhone, and Foodge couldn’t reach them. Nothing has been deleted.")
        } actions: {
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    StoreUnavailableView(retry: {})
}
