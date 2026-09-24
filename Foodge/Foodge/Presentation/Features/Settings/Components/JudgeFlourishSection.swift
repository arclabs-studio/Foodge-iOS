//
//  JudgeFlourishSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// The on-device narration switch.
///
/// The flag has been read and honoured since WU-23 (D79 deferred only this row, never the
/// behaviour), so turning it off takes effect on the next verdict with nothing else to change.
@MainActor
struct JudgeFlourishSection: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Judge’s flourish", isOn: $vm.draft.narrationEnabled)
                .onChange(of: vm.draft.narrationEnabled) { _, _ in
                    Task { await vm.preferencesChanged() }
                }
        } header: {
            Text("On-device AI")
        } footer: {
            Text("When this iPhone can write on device, the judge adds a line of its own. Everything else works exactly the same without it.")
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        JudgeFlourishSection(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
