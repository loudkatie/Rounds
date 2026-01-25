//
//  ConnectView.swift
//  Rounds AI
//
//  DEPRECATED - Not used in current version
//

import SwiftUI

struct ConnectView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        Text("Use LandingView")
    }
}

#Preview {
    ConnectView(viewModel: TranscriptViewModel())
}
