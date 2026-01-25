import SwiftUI

struct SummaryView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isAnalyzing {
                        loadingView
                    } else if let analysis = viewModel.analysis {
                        summaryContent(analysis)
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    }

                    // Transcript Section
                    if !viewModel.liveTranscript.isEmpty {
                        transcriptSection(viewModel.liveTranscript)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if let session = viewModel.currentSession {
                        ShareLink(
                            item: session.shareableText,
                            subject: Text("Rounds Session"),
                            message: Text("Session from \(session.formattedDate)")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Generating summary...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    @ViewBuilder
    private func summaryContent(_ analysis: RoundsAnalysis) -> some View {
        // Session Info
        if let session = viewModel.currentSession {
            sessionInfoCard(session)
        }

        // Explanation
        sectionCard(title: "What This Means", icon: "doc.text.fill") {
            Text(analysis.explanation)
                .font(.body)
        }

        // Key Points
        sectionCard(title: "Key Points", icon: "lightbulb.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analysis.summaryPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                            .padding(.top, 6)
                        Text(point)
                    }
                }
            }
        }

        // Questions
        if !analysis.followUpQuestions.isEmpty {
            sectionCard(title: "Questions to Ask", icon: "questionmark.circle.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(analysis.followUpQuestions.enumerated()), id: \.offset) { index, question in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                            Text(question)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sessionInfoCard(_ session: RecordingSession) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(session.transcript.split(separator: " ").count)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Full Transcript", systemImage: "doc.text.fill")
                .font(.headline)

            Text(transcript)
                .font(.body)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

#Preview {
    SummaryView(viewModel: TranscriptViewModel()) { }
}
