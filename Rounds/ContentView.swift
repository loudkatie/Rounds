import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptViewModel()
    @State private var showTranscript = false
    @State private var showSummary = false

    var body: some View {
        NavigationStack {
            ConnectView(viewModel: viewModel, showTranscript: $showTranscript)
                .navigationDestination(isPresented: $showTranscript) {
                    TranscriptView(viewModel: viewModel, showSummary: $showSummary)
                        .navigationBarBackButtonHidden(true)
                }
        }
        .sheet(isPresented: $showSummary) {
            SummaryView(viewModel: viewModel) {
                showSummary = false
                showTranscript = false
            }
        }
    }
}

#Preview {
    ContentView()
}
