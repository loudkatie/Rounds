//
//  TranscriptView.swift
//  Rounds
//
//  DEPRECATED - Use LandingView instead
//  Kept for backwards compatibility
//

import SwiftUI

struct TranscriptView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        // Redirect to LandingView
        Text("Use LandingView")
    }
}

#Preview {
    TranscriptView(viewModel: TranscriptViewModel())
}
