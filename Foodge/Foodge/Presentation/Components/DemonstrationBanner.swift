//
//  DemonstrationBanner.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Accessibility
import SwiftUI

/// The strip that says, everywhere at once, that the numbers on screen are invented.
///
/// Attached as a top `safeAreaInset` on the root so it sits above the whole tab hierarchy, which
/// is every screen of the verdict and history flows at once (D103). Only `EvidenceDetailsView` and
/// `CaseDetailView` label their values individually from `isSynthetic`; the rest show a category,
/// a dish and a date, so for those this banner is the whole of the labelling.
///
/// The text wraps rather than truncates: at AX5 "Demonstration data — not your Health" is several
/// lines, and a truncated version of this particular sentence would be worse than no banner.
@MainActor
struct DemonstrationBanner: View {
    let onExit: () -> Void

    private var message: LocalizedStringResource {
        LocalizedStringResource(
            "Demonstration data — not your Health",
            comment: "Persistent banner shown while a demonstration scenario is running"
        )
    }

    private var enteredAnnouncement: LocalizedStringResource {
        LocalizedStringResource(
            "Demonstration mode on. Everything shown is invented.",
            comment: "Accessibility announcement made when a demonstration starts"
        )
    }

    private var exitedAnnouncement: LocalizedStringResource {
        LocalizedStringResource(
            "Demonstration mode off. Your own data is back.",
            comment: "Accessibility announcement made when a demonstration ends"
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Exit") {
                // Posted *before* the exit, because afterwards this banner no longer exists and
                // has nothing to announce from. The `DeleteLocalDataSection` precedent.
                AccessibilityNotification.Announcement(String(localized: exitedAnnouncement)).post()
                onExit()
            }
            .font(.footnote.weight(.semibold))
            // Footnote text is around 20pt tall; the control the user actually has to hit must be
            // at least 44. The frame grows the target without enlarging the label, and
            // `contentShape` makes the whole of it tappable rather than just the glyphs.
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(.rect)
            .accessibilityLabel("Exit demonstration mode")
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(.appBurgundy)
        .foregroundStyle(.appOnBurgundy)
        // Contained rather than combined, so Exit stays its own control while the strip still
        // reads as one thing.
        .accessibilityElement(children: .contain)
        .task {
            // Fires once per session: the root carries `.id(session.id)`, so entering a
            // demonstration builds a new banner and leaving destroys this one.
            AccessibilityNotification.Announcement(String(localized: enteredAnnouncement)).post()
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        DemonstrationBanner {}
        Spacer()
    }
}
