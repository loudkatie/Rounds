import SwiftUI

struct TranscriptView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @Binding var showSummary: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Live Transcript
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.liveTranscript.isEmpty && viewModel.isSessionActive {
                            placeholderView
                        } else {
                            transcriptTextView
                        }

                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.liveTranscript) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Controls
            controlsView
        }
        .onAppear {
            if !viewModel.isSessionActive {
                Task {
                    await viewModel.startSession()
                }
            }
        }
    }

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Button {
                viewModel.cancelSession()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Recording")
                    .font(.headline)

                if viewModel.isSessionActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text(viewModel.formattedDuration)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Audio level indicator
            audioLevelView
        }
        .padding()
    }

    @ViewBuilder
    private var audioLevelView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
        .frame(width: 30, height: 20)
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / 5.0
        return viewModel.audioCapture.audioLevel > threshold ? .green : .gray.opacity(0.3)
    }

    private func barHeight(for index: Int) -> CGFloat {
        CGFloat(8 + index * 3)
    }

    @ViewBuilder
    private var placeholderView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Listening...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    @ViewBuilder
    private var transcriptTextView: some View {
        Text(viewModel.liveTranscript)
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var controlsView: some View {
        HStack(spacing: 20) {
            // Device info
            if viewModel.wearablesManager.connectionState == .registered,
               let device = viewModel.wearablesManager.connectedDevice {
                HStack(spacing: 6) {
                    Image(systemName: "eyeglasses")
                        .foregroundStyle(.green)
                    Text(device.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // End Session Button
            Button {
                Task {
                    await viewModel.endSession()
                    showSummary = true
                }
            } label: {
                Label("End Session", systemImage: "stop.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.isSessionActive)
        }
        .padding()
    }
}

#Preview {
    TranscriptView(
        viewModel: TranscriptViewModel(),
        showSummary: .constant(false)
    )
}
