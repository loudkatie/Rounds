import SwiftUI

struct SummaryView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isGeneratingSummary {
                        loadingView
                    } else if let summary = viewModel.summary {
                        summaryContent(summary)
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    }

                    // Transcript Section
                    if let episode = viewModel.currentEpisode, !episode.fullTranscriptText.isEmpty {
                        transcriptSection(episode)
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
                    if let episode = viewModel.currentEpisode {
                        ShareLink(
                            item: episode.fullTranscriptText,
                            subject: Text("Rounds Session"),
                            message: Text("Session transcript from \(episode.startTime.formatted())")
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
    private func summaryContent(_ summary: EpisodeSummary) -> some View {
        // Session Info
        if let episode = viewModel.currentEpisode {
            sessionInfoCard(episode)
        }

        // Key Points
        sectionCard(title: "Key Points", icon: "lightbulb.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.keyPoints, id: \.self) { point in
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

        // Action Items
        if !summary.actionItems.isEmpty {
            sectionCard(title: "Action Items", icon: "checkmark.circle.fill") {
                VStack(spacing: 12) {
                    ForEach(summary.actionItems) { item in
                        actionItemRow(item)
                    }
                }
            }
        }

        // Sentiment & Tags
        HStack(spacing: 12) {
            // Sentiment
            VStack(alignment: .leading, spacing: 4) {
                Label("Sentiment", systemImage: "face.smiling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary.sentiment)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Participants
            VStack(alignment: .leading, spacing: 4) {
                Label("Participants", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(summary.participants.count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        // Tags
        if !summary.topicsTags.isEmpty {
            sectionCard(title: "Topics", icon: "tag.fill") {
                FlowLayout(spacing: 8) {
                    ForEach(summary.topicsTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sessionInfoCard(_ episode: RoundsEpisode) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Started")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(episode.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(episode.fullTranscriptText.split(separator: " ").count)")
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
    private func actionItemRow(_ item: ActionItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline)

                HStack(spacing: 12) {
                    if let assignee = item.assignee {
                        Label(assignee, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let due = item.dueDate {
                        Label(due, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func transcriptSection(_ episode: RoundsEpisode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Full Transcript", systemImage: "doc.text.fill")
                .font(.headline)

            Text(episode.fullTranscriptText)
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
