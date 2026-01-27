//
//  PreviousRoundsView.swift
//  Rounds
//
//  List of saved recording sessions.
//

import SwiftUI

struct PreviousRoundsView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var sessionStore: SessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.sessions.isEmpty {
                    EmptyStateView()
                } else {
                    SessionListView(
                        sessions: sessionStore.sessions,
                        onSelect: { session in
                            viewModel.loadSession(session)
                            dismiss()
                        },
                        onDelete: { offsets in
                            sessionStore.deleteSession(at: offsets)
                        }
                    )
                }
            }
            .navigationTitle("Previous Rounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(RoundsColor.buttonBlue)
                }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.gray)

            Text("No recordings yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Your saved sessions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Session List

private struct SessionListView: View {
    let sessions: [RecordingSession]
    let onSelect: (RecordingSession) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(sessions) { session in
                SessionRowView(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(session)
                    }
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Session Row

private struct SessionRowView: View {
    let session: RecordingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.formattedDate)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(session.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(session.transcript.prefix(100) + (session.transcript.count > 100 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                if session.aiExplanation != nil {
                    Label("Analyzed", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundColor(RoundsColor.buttonBlue)
                }

                if !session.conversationHistory.isEmpty {
                    Label("\(session.conversationHistory.count / 2) follow-ups", systemImage: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PreviousRoundsView(
        viewModel: TranscriptViewModel(),
        sessionStore: SessionStore.shared
    )
}
