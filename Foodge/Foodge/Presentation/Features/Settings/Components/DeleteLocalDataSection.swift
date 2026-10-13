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
            Button(role: .destructive) {
                isConfirming = true
            } label: {
                // System red reads at about 3.6:1 as text on a light row, under WCAG 1.4.3's 4.5:1.
                // The words take the label colour and the red goes to the symbol's tile, a graphic
                // that needs 3:1; the role still marks the action as destructive. `Color.primary`,
                // not `.primary`: inside a destructive button the hierarchical `.primary` *is* the red.
                Label {
                    Text("Delete local data")
                        .foregroundStyle(Color.primary)
                } icon: {
                    Image(systemName: "trash.fill")
                }
                .labelStyle(.destructiveSettingsIcon)
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
                .formCaption()
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

#Preview(traits: .sizeThatFitsLayout, .sampleData) {
    Form {
        DeleteLocalDataSection(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
