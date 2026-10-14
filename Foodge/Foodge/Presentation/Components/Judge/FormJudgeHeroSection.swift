//
//  FormJudgeHeroSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// The tappable judge at the head of an onboarding form (D148, D150).
///
/// On the form's own background: a data-entry screen keeps the system grouped background rather
/// than a stage (D148), so the judge stands on a clear row instead. Smaller than on a stage
/// (`StageArtworkSize.formJudge`), which keeps the form's rows within reach. Apple Health and About
/// you both carry it, so onboarding keeps one judge from Welcome to the last step.
@MainActor
struct FormJudgeHeroSection: View {
    let reaction: JudgeReaction

    var body: some View {
        Section {
            JudgeHeroView(artwork: .judgeWelcome, height: StageArtworkSize.formJudge, reaction: reaction)
                .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var reaction = JudgeReaction()

    Form {
        FormJudgeHeroSection(reaction: reaction)
    }
}
