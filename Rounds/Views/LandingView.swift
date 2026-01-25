//
//  LandingView.swift
//  Rounds
//
//  Core recording interface. Jitterbug simple.
//  Matches Katie's previous iteration style.
//

import SwiftUI

struct LandingView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var sessionStore = SessionStore.shared
    @ObservedObject var profileStore = ProfileStore.shared
    @State private var followUpText = ""
    @State private var showPreviousRounds = false
    @State private var showShareSheet = false
    @State private var showFullTranscript = false
    @State private var showHelp = false
    @FocusState private var isFollowUpFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header (Rounds AI wordmark)
                        RoundsHeader()
                            .padding(.top, 60)
                            .padding(.bottom, 48)

                        // MARK: - Record / Stop Button
                        RecordButton(viewModel: viewModel)

                        // MARK: - Duration (when recording)
                        if viewModel.isSessionActive {
                            Text(viewModel.formattedDuration)
                                .font(.system(size: 28, weight: .medium, design: .monospaced))
                                .foregroundColor(RoundsColor.textPrimary)
                                .padding(.top, 20)
                        }

                        Spacer().frame(height: 48)

                        // MARK: - Live Transcription Section
                        LiveTranscriptSection(
                            transcript: viewModel.liveTranscript,
                            isRecording: viewModel.isSessionActive,
                            hasAnalysis: viewModel.analysis != nil
                        )
                        .padding(.horizontal, 24)

                        // MARK: - Status Pill (Ready state)
                        if viewModel.analysis == nil && !viewModel.isSessionActive && viewModel.liveTranscript.isEmpty {
                            StatusPill()
                                .padding(.top, 24)
                        }

                        // MARK: - Post-Recording Actions (before analysis)
                        if !viewModel.isSessionActive && !viewModel.liveTranscript.isEmpty && viewModel.analysis == nil {
                            PostRecordingActions(viewModel: viewModel)
                                .padding(.top, 24)
                                .padding(.horizontal, 24)
                        }

                        // MARK: - Analysis Results
                        if let analysis = viewModel.analysis {
                            AnalysisResultsView(
                                analysis: analysis,
                                transcript: viewModel.liveTranscript,
                                showFullTranscript: $showFullTranscript,
                                patientName: profileStore.patientName,
                                sessionDate: viewModel.currentSession?.date ?? Date()
                            )
                            .padding(.top, 32)
                            .padding(.horizontal, 24)

                            // Conversation History
                            if !viewModel.conversationHistory.isEmpty {
                                ConversationHistoryView(messages: viewModel.conversationHistory)
                                    .padding(.top, 24)
                                    .padding(.horizontal, 24)
                            }

                            // Follow-up Input
                            FollowUpInputView(
                                text: $followUpText,
                                isDisabled: viewModel.isAnalyzing,
                                isFocused: $isFollowUpFocused,
                                onSubmit: {
                                    Task {
                                        let question = followUpText
                                        followUpText = ""
                                        await viewModel.askFollowUp(question)
                                    }
                                }
                            )
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            .id("followUpInput")

                            // Share Actions
                            ShareActionsView(
                                viewModel: viewModel,
                                showShareSheet: $showShareSheet,
                                patientName: profileStore.patientName
                            )
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                        }

                        // Bottom spacing for footer
                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.conversationHistory.count) { _, _ in
                    withAnimation {
                        scrollProxy.scrollTo("followUpInput", anchor: .bottom)
                    }
                }
            }
            
            // MARK: - Anchored Footer Navigation
            FooterNavigation(
                showPreviousRounds: $showPreviousRounds,
                showHelp: $showHelp,
                hasHistory: !sessionStore.sessions.isEmpty
            )
        }
        .background(RoundsColor.background.ignoresSafeArea())
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showShareSheet) {
            if let session = viewModel.currentSession {
                ShareSheet(text: formatShareText(session: session))
            }
        }
        .sheet(isPresented: $showFullTranscript) {
            FullTranscriptView(
                transcript: viewModel.liveTranscript,
                patientName: profileStore.patientName,
                sessionDate: viewModel.currentSession?.date ?? Date(),
                onDismiss: { showFullTranscript = false }
            )
        }
    }
    
    private func formatShareText(session: RecordingSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        let dateString = dateFormatter.string(from: session.date)
        
        var text = "📋 \(profileStore.patientName)'s Medical Appointment Recap\n"
        text += "📅 \(dateString)\n\n"
        
        if let explanation = session.aiExplanation {
            text += "KEY POINTS:\n"
            for point in session.keyPoints.prefix(3) {
                text += "• \(point)\n"
            }
            text += "\nSUMMARY:\n\(explanation)\n"
            
            if !session.followUpQuestions.isEmpty {
                text += "\nQUESTIONS TO CONSIDER:\n"
                for (i, q) in session.followUpQuestions.prefix(3).enumerated() {
                    text += "\(i+1). \(q)\n"
                }
            }
        }
        
        text += "\n—\nGenerated by Rounds AI\nloudlabs.xyz"
        return text
    }
}

// MARK: - Rounds Header (Stacked icon + wordmark)

private struct RoundsHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            // Heart icon (outline style like previous iteration)
            Image(systemName: "heart")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(RoundsColor.bluePrimary)
            
            // Spaced wordmark - matching previous iteration
            Text("R O U N D S")
                .font(.system(size: 32, weight: .semibold))
                .tracking(8)
                .foregroundColor(RoundsColor.textPrimary)
        }
    }
}

// MARK: - Record Button

private struct RecordButton: View {
    @ObservedObject var viewModel: TranscriptViewModel

    var body: some View {
        Button {
            Task {
                if viewModel.isSessionActive {
                    await viewModel.endSession()
                } else {
                    await viewModel.startSession()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.isSessionActive ? Color.red : RoundsColor.bluePrimary)
                    .frame(width: 140, height: 140)
                    .shadow(
                        color: (viewModel.isSessionActive ? Color.red : RoundsColor.bluePrimary).opacity(0.3),
                        radius: 16,
                        y: 6
                    )

                if viewModel.isSessionActive {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isSessionActive ? "Stop recording" : "Start recording")
    }
}

// MARK: - Live Transcript Section

private struct LiveTranscriptSection: View {
    let transcript: String
    let isRecording: Bool
    let hasAnalysis: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Transcript card
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 0) {
                        if transcript.isEmpty {
                            Text("Tap the microphone to start")
                                .font(.body)
                                .foregroundColor(RoundsColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                        } else {
                            Text(transcript)
                                .font(.body)
                                .foregroundColor(RoundsColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("transcript")
                        }
                    }
                    .padding(16)
                    .onChange(of: transcript) { _, _ in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("transcript", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: hasAnalysis ? 0 : 140)
            .opacity(hasAnalysis ? 0 : 1)
            .background(RoundsColor.card)
            .cornerRadius(16)
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
            
            Text("Ready")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(RoundsColor.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RoundsColor.card)
        .cornerRadius(24)
    }
}

// MARK: - Post Recording Actions

private struct PostRecordingActions: View {
    @ObservedObject var viewModel: TranscriptViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Analyze button
            if viewModel.hasTranscriptToAnalyze {
                Button {
                    Task {
                        await viewModel.analyzeWithRoundsAI()
                    }
                } label: {
                    HStack(spacing: 12) {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .medium))
                        }

                        Text(viewModel.isAnalyzing ? "Analyzing..." : "Translate with Rounds AI")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.isAnalyzing ? RoundsColor.bluePrimary.opacity(0.5) : RoundsColor.bluePrimary)
                    .cornerRadius(16)
                }
                .disabled(viewModel.isAnalyzing)
            }

            // Discard button
            Button {
                viewModel.discardRecording()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("Discard & Start Over")
                        .font(.subheadline)
                }
                .foregroundColor(.red.opacity(0.8))
            }
        }
    }
}

// MARK: - Analysis Results View

private struct AnalysisResultsView: View {
    let analysis: RoundsAnalysis
    let transcript: String
    @Binding var showFullTranscript: Bool
    let patientName: String
    let sessionDate: Date

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: sessionDate)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: sessionDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // Session header with date
            Text("Recap: \(formattedDate)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(RoundsColor.textPrimary)
            
            // View Full Transcript Button
            Button {
                showFullTranscript = true
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 15))
                    Text("View Full Transcript")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(RoundsColor.bluePrimary)
                .padding(16)
                .background(RoundsColor.card)
                .cornerRadius(12)
            }

            // Key Points (3 max TL;DR)
            if !analysis.summaryPoints.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(dayName)'s Key Points")
                        .font(.headline)
                        .foregroundColor(RoundsColor.textPrimary)

                    ForEach(Array(analysis.summaryPoints.prefix(3).enumerated()), id: \.offset) { _, point in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(RoundsColor.bluePrimary)
                                .frame(width: 6, height: 6)
                                .padding(.top, 8)

                            Text(point)
                                .font(.body)
                                .foregroundColor(RoundsColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundsColor.card)
                .cornerRadius(16)
            }

            // What We Discussed (Summary)
            VStack(alignment: .leading, spacing: 14) {
                Text("\(dayName)'s Discussion")
                    .font(.headline)
                    .foregroundColor(RoundsColor.textPrimary)

                Text(analysis.explanation)
                    .font(.body)
                    .foregroundColor(RoundsColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundsColor.card)
            .cornerRadius(16)

            // Consider Asking
            if !analysis.followUpQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Consider Asking...")
                        .font(.headline)
                        .foregroundColor(RoundsColor.textPrimary)

                    ForEach(Array(analysis.followUpQuestions.enumerated()), id: \.offset) { index, question in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(RoundsColor.bluePrimary)
                                    .frame(width: 24, alignment: .leading)

                                Text(question)
                                    .font(.body)
                                    .foregroundColor(RoundsColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(2)
                            }
                            
                            if index < analysis.followUpQuestions.count - 1 {
                                Divider()
                                    .padding(.top, 14)
                                    .padding(.leading, 36)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundsColor.card)
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Full Transcript View (Sheet)

private struct FullTranscriptView: View {
    let transcript: String
    let patientName: String
    let sessionDate: Date
    let onDismiss: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: sessionDate)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(patientName)'s Appointment")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(RoundsColor.textPrimary)
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(RoundsColor.textSecondary)
                    }
                    
                    Divider()
                    
                    // Transcript
                    Text(transcript)
                        .font(.body)
                        .foregroundColor(RoundsColor.textPrimary)
                        .lineSpacing(6)
                }
                .padding(24)
            }
            .background(RoundsColor.background)
            .navigationTitle("Full Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(RoundsColor.bluePrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: formatTranscriptForShare()) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RoundsColor.bluePrimary)
                    }
                }
            }
        }
    }
    
    private func formatTranscriptForShare() -> String {
        """
        📋 \(patientName)'s Appointment Transcript
        📅 \(formattedDate)
        
        ───────────────────────
        
        \(transcript)
        
        ───────────────────────
        Generated by Rounds AI
        loudlabs.xyz
        """
    }
}

// MARK: - Conversation History

private struct ConversationHistoryView: View {
    let messages: [ConversationMessage]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-up Q&A")
                .font(.headline)
                .foregroundColor(RoundsColor.textPrimary)

            ForEach(messages) { message in
                MessageBubble(message: message)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: ConversationMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "Rounds AI")
                    .font(.caption)
                    .foregroundColor(RoundsColor.textSecondary)

                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : RoundsColor.textPrimary)
                    .padding(12)
                    .background(message.isUser ? RoundsColor.bluePrimary : RoundsColor.card)
                    .cornerRadius(12)
            }

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Follow-up Input

private struct FollowUpInputView: View {
    @Binding var text: String
    let isDisabled: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask Rounds AI")
                .font(.headline)
                .foregroundColor(RoundsColor.textPrimary)
            
            HStack(spacing: 12) {
                TextField("Ask a follow-up question...", text: $text)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(RoundsColor.card)
                    .cornerRadius(12)
                    .focused(isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.isEmpty && !isDisabled {
                            onSubmit()
                        }
                    }

                Button {
                    onSubmit()
                } label: {
                    if isDisabled {
                        ProgressView()
                            .tint(RoundsColor.bluePrimary)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(text.isEmpty ? RoundsColor.textSecondary : RoundsColor.bluePrimary)
                    }
                }
                .disabled(text.isEmpty || isDisabled)
            }
        }
    }
}

// MARK: - Share Actions

private struct ShareActionsView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @Binding var showShareSheet: Bool
    let patientName: String

    var body: some View {
        VStack(spacing: 12) {
            // Share Summary
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("Share AI Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundsColor.bluePrimary)
                .cornerRadius(12)
            }

            // New Recording
            Button {
                viewModel.startNewRecording()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mic.badge.plus")
                        .font(.system(size: 14))
                    Text("New Recording")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(RoundsColor.bluePrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundsColor.card)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Footer Navigation (Anchored to bottom)

private struct FooterNavigation: View {
    @Binding var showPreviousRounds: Bool
    @Binding var showHelp: Bool
    let hasHistory: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // Archive / Past Rounds
                Button {
                    showPreviousRounds = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 22))
                        Text("Archive")
                            .font(.caption2)
                    }
                    .foregroundColor(hasHistory ? RoundsColor.textSecondary : RoundsColor.textSecondary.opacity(0.4))
                }
                .disabled(!hasHistory)
                .frame(maxWidth: .infinity)
                
                // Help
                Button {
                    showHelp = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 22))
                        Text("Help")
                            .font(.caption2)
                    }
                    .foregroundColor(RoundsColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Powered by Loud Labs
                Link(destination: URL(string: "https://loudlabs.xyz")!) {
                    VStack(spacing: 2) {
                        Text("LOUD")
                            .font(.system(size: 14, weight: .black, design: .default))
                        Text("Powered by")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(RoundsColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(Color.white)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LandingView(viewModel: TranscriptViewModel())
}
