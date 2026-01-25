//
//  ConnectView.swift
//  Rounds
//
//  DEPRECATED for hackathon - Meta glasses connection view
//  Using iPhone mic via ElevenLabs instead
//

import SwiftUI

struct ConnectView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(RoundsColor.bluePrimary)
            
            Text("Using iPhone Microphone")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Powered by ElevenLabs Scribe v2")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ConnectView(viewModel: TranscriptViewModel())
}
