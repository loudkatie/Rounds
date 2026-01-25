//
//  TranscriptView.swift
//  Rounds AI
//
//  DEPRECATED - Not used in current version
//

import SwiftUI

struct TranscriptView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        Text("Use LandingView")
    }
}

#Preview {
    TranscriptView(viewModel: TranscriptViewModel())
}
