//
//  SummaryView.swift
//  Rounds AI
//
//  DEPRECATED - Analysis now shown inline in LandingView
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    let onDismiss: () -> Void

    var body: some View {
        Text("Use LandingView for analysis")
    }
}

#Preview {
    SummaryView(viewModel: TranscriptViewModel()) { }
}
