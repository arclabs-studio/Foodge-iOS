//
//  DeleteLocalDataSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Accessibility
import SwiftUI

/// Deleting everything Foodge keeps on this iPhone.
///
/// A `confirmationDialog` rather than a one-tap button, and copy that says exactly what is and
/// is not removed: Apple Health records are never touched, and a failure is reported as a
/// failure rather than as a deletion.
@MainActor
struct DeleteLocalDataSection: View {
    @Bindable var vm: SettingsViewModel
    @State private var isConfirming = false

    private var isDeleting: Bool {
        vm.deleteState == .deleting
    }

    private var deleteFailureMessage: LocalizedStringResource {
        "Foodge couldn’t delete your data. Nothing was removed — try again."
    }

    var body: some View {
        Section {
            Button("Delete local data", role: .destructive) {
                isConfirming = true
            }
            .disabled(isDeleting)

            if isDeleting {
                ProgressView()
            }

            switch vm.deleteState {
            case .deleted:
                Text("Your preferences and every saved case are gone from this iPhone.")
            case .failed:
                Text(deleteFailureMessage)
                    .foregroundStyle(.appBurgundyMuted)
            case .idle, .deleting:
                EmptyView()
            }
        } footer: {
            Text("Removes your preferences, every saved case and any pending reminder. Your Apple Health records are never touched.")
        }
        .confirmationDialog(
            "Delete everything Foodge has saved here?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await vm.deleteLocalData() }
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This cannot be undone. Your Apple Health records are not affected.")
        }
        .onChange(of: vm.deleteState) { _, newValue in
            // Stays on this screen with no navigation, unlike a successful deletion, which
            // triggers `onLocalDataErased()` and leaves the screen almost immediately — a system
            // screen-changed notification covers that case, so only the failure needs its own
            // announcement here (WCAG 4.1.3).
            guard case .failed = newValue else { return }
            AccessibilityNotification.Announcement(String(localized: deleteFailureMessage)).post()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        DeleteLocalDataSection(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
