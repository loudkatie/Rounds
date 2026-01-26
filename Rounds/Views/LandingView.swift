//
//  LandingView.swift
//  Rounds AI
//
//  Main recording screen with session chaining, auto-scroll, and improved sharing
//

import SwiftUI

// MARK: - Heart + Cross Icon Component
struct HeartPlusIcon: View {
    var size: CGFloat = 32
    var heartColor: Color = RoundsColor.brandBlue
    var plusColor: Color = .white
    
    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(heartColor)
            
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(plusColor)
                .offset(y: -size * 0.02)
        }
    }
}

struct LandingView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var sessionStore = SessionStore.shared
    @ObservedObject var profileStore = ProfileStore.shared
    @State private var followUpText = ""
    @State private var showPreviousRounds = false
    @State private var showShareSheet = false
    @State private var showFullTranscript = false
    @FocusState private var isFollowUpFocused: Bool

    // Colors for button states
    private let readyGreen = Color(red: 52/255, green: 199/255, blue: 89/255) // iOS green
    private let recordingRed = Color.red

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header
                        VStack(spacing: 8) {
                            HeartPlusIcon(size: 36)
                            
                            Text("R O U N D S   A I")
                                .font(.system(size: 26, weight: .medium))
                                .tracking(6)
                                .foregroundColor(.black)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                        // MARK: - Record Button
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
                                    .fill(buttonColor)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: buttonColor.opacity(0.3), radius: 12, y: 6)

                                if viewModel.isSessionActive {
                                    // Stop icon (white square on red)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white)
                                        .frame(width: 36, height: 36)
                                } else {
                                    // Mic icon
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 44, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Duration or status text
                        if viewModel.isSessionActive {
                            Text(viewModel.formattedDuration)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(recordingRed)
                                .padding(.top, 16)
                        } else if viewModel.isInSessionChain && !viewModel.liveTranscript.isEmpty {
                            Text("Tap to continue recording")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 12)
                        }

                        Spacer().frame(height: 32)

                        // MARK: - Live Transcription Box with Auto-Scroll
                        VStack(alignment: .leading, spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.isSessionActive ? recordingRed.opacity(0.08) : RoundsColor.brandBlue.opacity(0.08))
                                    .frame(height: 140)
                                
                                if viewModel.liveTranscript.isEmpty {
                                    Text(viewModel.isSessionActive ? "Listening..." : "Tap the microphone to start")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .padding(16)
                                } else {
                                    ScrollViewReader { transcriptScroll in
                                        ScrollView {
                                            Text(viewModel.liveTranscript)
                                                .font(.body)
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(16)
                                                .id("transcriptEnd")
                                        }
                                        .frame(height: 140)
                                        .onChange(of: viewModel.liveTranscript) { _, _ in
                                            // Auto-scroll to bottom as new text comes in
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                transcriptScroll.scrollTo("transcriptEnd", anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 24)

                        // MARK: - Ready Pill
                        if !viewModel.isSessionActive && viewModel.analysis == nil && viewModel.liveTranscript.isEmpty {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(readyGreen)
                                    .frame(width: 10, height: 10)
                                
                                Text("Ready")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(20)
                        }

                        // MARK: - Post-Recording Actions
                        if !viewModel.isSessionActive && !viewModel.liveTranscript.isEmpty && viewModel.analysis == nil {
                            VStack(spacing: 16) {
                                Button {
                                    Task {
                                        await viewModel.analyzeWithRoundsAI()
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        if viewModel.isAnalyzing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            HeartPlusIcon(size: 18, heartColor: .white, plusColor: RoundsColor.brandBlue)
                                        }
                                        Text(viewModel.isAnalyzing ? "Analyzing..." : "Translate with Rounds AI")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.isAnalyzing ? RoundsColor.brandBlue.opacity(0.5) : RoundsColor.brandBlue)
                                    .cornerRadius(14)
                                }
                                .disabled(viewModel.isAnalyzing)

                                Button {
                                    viewModel.discardRecording()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                        Text("Discard & Start Over")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                        
                        // MARK: - Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                        }

                        // MARK: - Analysis Results
                        if let analysis = viewModel.analysis {
                            // Share button at TOP of results
                            ShareButtonsSection(showShareSheet: $showShareSheet, isCompact: true)
                                .padding(.top, 24)
                                .padding(.horizontal, 24)
                            
                            AnalysisResultsSection(
                                analysis: analysis,
                                transcript: viewModel.liveTranscript,
                                conversationHistory: viewModel.conversationHistory,
                                showFullTranscript: $showFullTranscript,
                                patientName: profileStore.patientName,
                                sessionDate: viewModel.currentSession?.startTime ?? Date()
                            )
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                            // MARK: - Follow-up Conversation Thread
                            if !viewModel.conversationHistory.isEmpty {
                                ConversationThreadView(messages: viewModel.conversationHistory)
                                    .padding(.top, 20)
                                    .padding(.horizontal, 24)
                            }

                            // MARK: - Follow-up Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ask Rounds AI")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 12) {
                                    TextField("Ask a follow-up question...", text: $followUpText)
                                        .textFieldStyle(.plain)
                                        .padding(14)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(12)
                                        .focused($isFollowUpFocused)
                                        .submitLabel(.send)
                                        .onSubmit {
                                            sendFollowUp(scrollProxy: scrollProxy)
                                        }

                                    Button {
                                        sendFollowUp(scrollProxy: scrollProxy)
                                    } label: {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(followUpText.isEmpty ? .gray : RoundsColor.brandBlue)
                                    }
                                    .disabled(followUpText.isEmpty || viewModel.isAnalyzing)
                                }
                                
                                if viewModel.isAnalyzing && !viewModel.conversationHistory.isEmpty {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                            .id("followUpInput")

                            // MARK: - Bottom Share & Actions
                            VStack(spacing: 12) {
                                ShareButtonsSection(showShareSheet: $showShareSheet, isCompact: false)
                                
                                // Continue Recording button (if within chain window)
                                if viewModel.isInSessionChain {
                                    Button {
                                        Task {
                                            await viewModel.startSession()
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "mic.badge.plus")
                                                .font(.system(size: 14))
                                            Text("Continue Recording")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(readyGreen)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(readyGreen.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }

                                Button {
                                    viewModel.discardRecording()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 14))
                                        Text("Start Fresh Session")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                        }

                        Spacer().frame(height: 120)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            
            // MARK: - Footer
            FooterBar(showPreviousRounds: $showPreviousRounds, hasHistory: !sessionStore.sessions.isEmpty)
        }
        .background(Color.white.ignoresSafeArea())
        .onTapGesture {
            isFollowUpFocused = false
        }
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: formatShareText())
        }
        .sheet(isPresented: $showFullTranscript) {
            FullTranscriptSheet(
                transcript: formatTranscriptWithParagraphs(viewModel.liveTranscript),
                patientName: profileStore.patientName,
                sessionDate: viewModel.currentSession?.startTime ?? Date()
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if viewModel.isSessionActive {
            return recordingRed
        } else {
            return readyGreen
        }
    }
    
    // MARK: - Helper Functions
    
    private func sendFollowUp(scrollProxy: ScrollViewProxy) {
        guard !followUpText.isEmpty && !viewModel.isAnalyzing else { return }
        let question = followUpText
        followUpText = ""
        isFollowUpFocused = false
        
        Task {
            await viewModel.askFollowUp(question)
            withAnimation {
                scrollProxy.scrollTo("followUpInput", anchor: .bottom)
            }
        }
    }
    
    private func formatTranscriptWithParagraphs(_ text: String) -> String {
        var result = text
        let pattern = /\. ([A-Z])/
        result = result.replacing(pattern) { match in
            ".\n\n\(match.1)"
        }
        let transitions = ["So ", "Now ", "We're ", "The ", "I'd ", "Any ", "From ", "On ", "For ", "Starting "]
        for transition in transitions {
            result = result.replacingOccurrences(of: ". \(transition)", with: ".\n\n\(transition)")
        }
        return result
    }
    
    private func formatShareText() -> String {
        let caregiverName = profileStore.caregiverName
        let patientName = profileStore.patientName
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let dateString = dateFormatter.string(from: viewModel.currentSession?.startTime ?? Date())
        
        var text = "🩺 \(patientName)'s Rounds\n"
        text += "📅 \(dateString)\n"
        text += "━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        if let analysis = viewModel.analysis {
            // Key Points
            if !analysis.summaryPoints.isEmpty {
                text += "📌 KEY POINTS\n\n"
                for point in analysis.summaryPoints.prefix(4) {
                    text += "• \(point)\n\n"
                }
            }
            
            // Summary with paragraph breaks
            if !analysis.explanation.isEmpty {
                text += "💬 SUMMARY\n\n"
                let paragraphs = formatExplanationForShare(analysis.explanation)
                text += "\(paragraphs)\n\n"
            }
            
            // Suggested Questions
            if !analysis.followUpQuestions.isEmpty {
                text += "❓ QUESTIONS TO CONSIDER\n\n"
                for (index, question) in analysis.followUpQuestions.prefix(3).enumerated() {
                    text += "\(index + 1). \(question)\n\n"
                }
            }
            
            // Include conversation if any
            if !viewModel.conversationHistory.isEmpty {
                text += "💭 FOLLOW-UP Q&A\n\n"
                for message in viewModel.conversationHistory {
                    if message.isUser {
                        text += "Q: \(message.content)\n\n"
                    } else {
                        text += "A: \(message.content)\n\n"
                    }
                }
            }
        }
        
        text += "━━━━━━━━━━━━━━━━━━━━━━\n"
        text += "Sent by \(caregiverName) via Rounds AI 💙"
        
        return text
    }
    
    private func formatExplanationForShare(_ explanation: String) -> String {
        // Break into paragraphs every 2-3 sentences
        var result = ""
        var sentenceCount = 0
        var currentParagraph = ""
        
        let sentences = explanation.components(separatedBy: ". ")
        for sentence in sentences {
            currentParagraph += sentence + ". "
            sentenceCount += 1
            
            if sentenceCount >= 2 {
                result += currentParagraph.trimmingCharacters(in: .whitespaces) + "\n\n"
                currentParagraph = ""
                sentenceCount = 0
            }
        }
        
        if !currentParagraph.isEmpty {
            result += currentParagraph.trimmingCharacters(in: .whitespaces)
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Share Buttons Section

private struct ShareButtonsSection: View {
    @Binding var showShareSheet: Bool
    let isCompact: Bool
    
    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                Text(isCompact ? "Share" : "Share Full Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompact ? 12 : 14)
            .background(RoundsColor.brandBlue)
            .cornerRadius(12)
        }
    }
}

// MARK: - Conversation Thread View

private struct ConversationThreadView: View {
    let messages: [ConversationMessage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-up Q&A")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                    Text(message.isUser ? "You asked:" : "Rounds AI:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatMessageContent(message.content))
                        .font(.body)
                        .padding(12)
                        .background(message.isUser ? RoundsColor.brandBlue : Color(UIColor.systemGray5))
                        .foregroundColor(message.isUser ? .white : .black)
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatMessageContent(_ content: String) -> String {
        // Clean up markdown formatting for display
        var result = content
        result = result.replacingOccurrences(of: "**", with: "")
        return result
    }
}

// MARK: - Analysis Results Section

private struct AnalysisResultsSection: View {
    let analysis: RoundsAnalysis
    let transcript: String
    let conversationHistory: [ConversationMessage]
    @Binding var showFullTranscript: Bool
    let patientName: String
    let sessionDate: Date

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: sessionDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Date header
            HStack {
                HeartPlusIcon(size: 20)
                Text("Recap from \(dayOfWeek)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // View Full Transcript Button
            Button {
                showFullTranscript = true
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                    Text("View Full Transcript")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(RoundsColor.brandBlue)
                .padding(14)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }

            // Key Points
            if !analysis.summaryPoints.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(dayOfWeek)'s Key Points")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(analysis.summaryPoints.prefix(4).enumerated()), id: \.offset) { _, point in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(RoundsColor.brandBlue)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)

                            Text(point)
                                .font(.body)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }

            // Discussion Summary - WITH PARAGRAPH BREAKS
            if !analysis.explanation.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(dayOfWeek) Discussion")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Break into paragraphs for readability
                    let paragraphs = breakIntoParagraphs(analysis.explanation)
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }

            // Questions to Consider
            if !analysis.followUpQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Consider Asking...")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(analysis.followUpQuestions.enumerated()), id: \.offset) { index, question in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(RoundsColor.brandBlue)
                                .frame(width: 20, alignment: .leading)

                            Text(question)
                                .font(.body)
                        }
                        
                        if index < analysis.followUpQuestions.count - 1 {
                            Divider().padding(.leading, 30)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func breakIntoParagraphs(_ text: String) -> [String] {
        // Break every 2-3 sentences for readability
        var paragraphs: [String] = []
        var currentParagraph = ""
        var sentenceCount = 0
        
        let sentences = text.components(separatedBy: ". ")
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            currentParagraph += trimmed + ". "
            sentenceCount += 1
            
            if sentenceCount >= 2 {
                paragraphs.append(currentParagraph.trimmingCharacters(in: .whitespaces))
                currentParagraph = ""
                sentenceCount = 0
            }
        }
        
        if !currentParagraph.isEmpty {
            let final = currentParagraph.trimmingCharacters(in: .whitespaces)
            if !final.isEmpty && final != "." {
                paragraphs.append(final)
            }
        }
        
        return paragraphs.isEmpty ? [text] : paragraphs
    }
}

// MARK: - Full Transcript Sheet

private struct FullTranscriptSheet: View {
    let transcript: String
    let patientName: String
    let sessionDate: Date
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: sessionDate)
    }
    
    private var shareText: String {
        "🩺 \(patientName)'s Appointment\n📅 \(formattedDate)\n━━━━━━━━━━━━━━━━━━━━━━\n\n\(transcript)\n\n━━━━━━━━━━━━━━━━━━━━━━\nSent via Rounds AI 💙"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(patientName)'s Appointment")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    Text(transcript)
                        .font(.body)
                        .lineSpacing(8)
                }
                .padding(24)
            }
            .navigationTitle("Full Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(RoundsColor.brandBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RoundsColor.brandBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Footer Bar

private struct FooterBar: View {
    @Binding var showPreviousRounds: Bool
    let hasHistory: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                if hasHistory {
                    Button {
                        showPreviousRounds = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 20))
                            Text("Archive")
                                .font(.caption2)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Link(destination: URL(string: "https://loudlabs.xyz")!) {
                    VStack(spacing: 2) {
                        Text("LOUD")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                        Text("powered by")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
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
