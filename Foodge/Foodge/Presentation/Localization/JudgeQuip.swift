//
//  JudgeQuip.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Foundation

/// What the judge says when tapped (D146).
///
/// Decoration, written to the flourish's voice: about the case and the court, never about a
/// person's body, discipline or worth, and never telling anyone what to eat. That part is editorial.
/// The machine-checkable part — no number or unit, none of the banned phrases, one or two short
/// sentences — is enforced: `JudgeQuipLocalizationTests` runs every line, in both languages,
/// through `NarrationValidator`, the same check the model's flourish has to pass.
///
/// The declared order is the order the deck plays in.
enum JudgeQuip: CaseIterable {
    case orderInTheKitchen
    case noBribes
    case objectionOverruled
    case allRise
    case regulationWig
    case silenceInCourt
    case fridgeTakesTheStand
    case courtAdjourned

    var text: LocalizedStringResource {
        switch self {
        case .orderInTheKitchen:
            LocalizedStringResource("Order in the kitchen!", comment: "Judge quip when the judge is tapped")
        case .noBribes:
            LocalizedStringResource(
                "The court does not accept bribes. Unless it’s garlic bread.",
                comment: "Judge quip when the judge is tapped"
            )
        case .objectionOverruled:
            LocalizedStringResource("Objection noted. And overruled.", comment: "Judge quip when the judge is tapped")
        case .allRise:
            LocalizedStringResource(
                "All rise! The gavel has been polished for the occasion.",
                comment: "Judge quip when the judge is tapped"
            )
        case .regulationWig:
            LocalizedStringResource(
                "This wig is regulation. Do not ask about the wig.",
                comment: "Judge quip when the judge is tapped"
            )
        case .silenceInCourt:
            LocalizedStringResource(
                "Silence in court! The oven is deliberating.",
                comment: "Judge quip when the judge is tapped"
            )
        case .fridgeTakesTheStand:
            LocalizedStringResource(
                "The fridge will now take the stand.",
                comment: "Judge quip when the judge is tapped"
            )
        case .courtAdjourned:
            LocalizedStringResource(
                "Court is adjourned until someone mentions pizza.",
                comment: "Judge quip when the judge is tapped"
            )
        }
    }
}
