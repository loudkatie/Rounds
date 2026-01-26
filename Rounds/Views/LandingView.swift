//
//  LandingView.swift
//  Rounds AI
//
//  Main recording screen - Sprint A updates:
//  - Navy blue ready button (not green)
//  - Red stop button during recording
//  - Transcript box stays blue (not red) during recording
//  - Better visual hierarchy for results
//

import SwiftUI

// MARK: - Heart + Cross Icon Component
struct HeartPlusIcon: View {
    var size: CGFloat = 32
    var heartColor: Color = RoundsColor.brandBlue
    var plusColor: Color = .white
    var useGradient: Bool = false
    
    var body: some View {
        ZStack {
            if useGradient {
                Image(systemName: "heart.fill")
                    .font(.system(size: size, weight: .regular))
                    .foregroundStyle(RoundsColor.brandGradient)
            } else {
                Image(systemName: "heart.fill")
                    .font(.system(size: size, weight: .regular))
                    .foregroundColor(heartColor)
            }
            
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
    @State private var showProfileBuilder = false
    @FocusState private var isFollowUpFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Compact Header (when showing results)
                        if viewModel.analysis != nil {
                            // Minimal header when we have results
                            HStack {
                                HeartPlusIcon(size: 24, useGradient: true)
                                Text("ROUNDS AI")
                                    .font(.system(size: 14, weight: .semibold))
                                    .tracking(2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        } else {
                            // Full header when recording/idle
                            VStack(spacing: 8) {
                                HeartPlusIcon(size: 36, useGradient: true)
                                
                                Text("R O U N D S   A I")
                                    .font(.system(size: 26, weight: .medium))
                                    .tracking(6)
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 50)
                            .padding(.bottom, 30)
                        }

                        // MARK: - Record Button (hide transcript box after analysis)
                        if viewModel.analysis == nil {
                            RecordingSection(viewModel: viewModel)
                        }
                        
                        // MARK: - Post-Recording: Translate Button
                        if !viewModel.isSessionActive && !viewModel.liveTranscript.isEmpty && viewModel.analysis == nil {
                            PostRecordingActions(viewModel: viewModel)
                                .padding(.top, 20)
                        }
                        
                        // MARK: - Error Message
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                        }

                        // MARK: - Analysis Results
                        if let analysis = viewModel.analysis {
                            AnalysisResultsView(
                                viewModel: viewModel,
                                analysis: analysis,
                                showFullTranscript: $showFullTranscript,
                                showShareSheet: $showShareSheet,
                                followUpText: $followUpText,
                                isFollowUpFocused: $isFollowUpFocused,
                                scrollProxy: scrollProxy
                            )
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            
            // MARK: - Footer Navigation
            FooterNavBar(
                showPreviousRounds: $showPreviousRounds,
                showProfileBuilder: $showProfileBuilder,
                hasHistory: !sessionStore.sessions.isEmpty
            )
        }
        .background(Color.white.ignoresSafeArea())
        .onTapGesture { isFollowUpFocused = false }
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                text: formatShareText(),
                subject: "\(profileStore.patientName)'s Health Appointment - \(getDayOfWeek()) Recap"
            )
        }
        .sheet(isPresented: $showFullTranscript) {
            FullTranscriptSheet(
                transcript: formatTranscriptWithParagraphs(viewModel.liveTranscript),
                patientName: profileStore.patientName,
                sessionDate: viewModel.currentSession?.startTime ?? Date()
            )
        }
    }
    
    // MARK: - Share Formatting
    
    private func formatShareText() -> String {
        let patientName = profileStore.patientName
        let caregiverName = profileStore.caregiverName
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeek = dateFormatter.string(from: viewModel.currentSession?.startTime ?? Date())
        
        // Header matching the report
        var text = "🩺 \(patientName)'s Health Appointment - \(dayOfWeek) Recap\n\n"
        text += "Here's a recap of \(patientName)'s \(dayOfWeek) health meeting, sent from Rounds AI:\n\n"
        text += "━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        if let analysis = viewModel.analysis {
            if !analysis.summaryPoints.isEmpty {
                text += "📌 KEY POINTS\n\n"
                for point in analysis.summaryPoints {
                    text += "• \(cleanMarkdown(point))\n\n"
                }
            }
            
            if !analysis.explanation.isEmpty {
                text += "💬 WHAT THIS MEANS\n\n"
                text += "\(formatForShare(cleanMarkdown(analysis.explanation)))\n\n"
            }
            
            if !analysis.followUpQuestions.isEmpty {
                text += "❓ QUESTIONS TO CONSIDER\n\n"
                for (i, q) in analysis.followUpQuestions.prefix(3).enumerated() {
                    text += "\(i + 1). \(cleanMarkdown(q))\n\n"
                }
            }
            
            if !viewModel.conversationHistory.isEmpty {
                text += "💭 FOLLOW-UP Q&A\n\n"
                text += "Here are a few follow-up questions I asked today:\n\n"
                for msg in viewModel.conversationHistory {
                    if msg.isUser {
                        text += "Q: \(msg.content)\n\n"
                    } else {
                        text += "A: \(cleanMarkdown(msg.content))\n\n"
                    }
                }
            }
        }
        
        text += "━━━━━━━━━━━━━━━━━━━━━━\n"
        text += "Sent by \(caregiverName) via Rounds AI 💙"
        
        return text
    }
    
    /// Remove markdown ** markers for plain text sharing
    private func cleanMarkdown(_ text: String) -> String {
        return text.replacingOccurrences(of: "**", with: "")
    }
    
    private func formatForShare(_ text: String) -> String {
        var result = ""
        var count = 0
        for sentence in text.components(separatedBy: ". ") {
            result += sentence + ". "
            count += 1
            if count >= 2 { result += "\n\n"; count = 0 }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatTranscriptWithParagraphs(_ text: String) -> String {
        var result = text
        let transitions = ["So ", "Now ", "We're ", "The ", "I'd ", "Any ", "From ", "On ", "For ", "Starting ", "Looking "]
        for t in transitions {
            result = result.replacingOccurrences(of: ". \(t)", with: ".\n\n\(t)")
        }
        return result
    }
    
    private func getDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.currentSession?.startTime ?? Date())
    }
}

// MARK: - Recording Section

private struct RecordingSection: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    private var buttonColor: Color {
        viewModel.isSessionActive ? .red : RoundsColor.navyBlue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Record Button
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
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Duration or hint
            if viewModel.isSessionActive {
                Text(viewModel.formattedDuration)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(.top, 16)
            } else if viewModel.isInSessionChain && !viewModel.liveTranscript.isEmpty {
                Text("Tap to continue recording")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 12)
            }

            Spacer().frame(height: 24)

            // Transcript Box - ALWAYS blue background, never red
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RoundsColor.transcriptBackground)  // Always blue tint
                        .frame(height: 140)
                    
                    if viewModel.liveTranscript.isEmpty {
                        Text(viewModel.isSessionActive ? "Listening..." : "Tap the microphone to start")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(16)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(viewModel.liveTranscript)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .id("end")
                            }
                            .frame(height: 140)
                            .onChange(of: viewModel.liveTranscript) { _, _ in
                                withAnimation { proxy.scrollTo("end", anchor: .bottom) }
                            }
                        }
                    }
                }
                
                // Recording indicator
                if viewModel.isSessionActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            // Ready pill (idle state)
            if !viewModel.isSessionActive && viewModel.liveTranscript.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("Ready")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .padding(.top, 24)
            }
        }
    }
}

// MARK: - Post Recording Actions

private struct PostRecordingActions: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Main CTA - Translate
            Button {
                Task { await viewModel.analyzeWithRoundsAI() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isAnalyzing {
                        ProgressView().tint(.white)
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

            // Continue recording hint
            Text("You can tap the mic again to add more to this recording")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            // Discard
            Button {
                viewModel.discardRecording()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Discard & Start Over")
                }
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Analysis Results View

private struct AnalysisResultsView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var profileStore = ProfileStore.shared
    let analysis: RoundsAnalysis
    @Binding var showFullTranscript: Bool
    @Binding var showShareSheet: Bool
    @Binding var followUpText: String
    var isFollowUpFocused: FocusState<Bool>.Binding
    let scrollProxy: ScrollViewProxy
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // MARK: - Big Header
            HStack {
                HeartPlusIcon(size: 28, useGradient: true)
                Text("\(profileStore.patientName)'s \(dayOfWeek) Recap")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Continue Recording (if in chain window)
            if viewModel.isInSessionChain {
                ContinueRecordingBanner(viewModel: viewModel)
                    .padding(.horizontal, 24)
            }
            
            // View Transcript Link
            Button { showFullTranscript = true } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View Full Transcript")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundColor(RoundsColor.brandBlue)
                .padding(14)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            // Key Points
            if !analysis.summaryPoints.isEmpty {
                SectionCard(title: "Key Points", icon: "list.bullet") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(analysis.summaryPoints.enumerated()), id: \.offset) { _, point in
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
                }
                .padding(.horizontal, 24)
            }

            // Discussion - Scrollable
            if !analysis.explanation.isEmpty {
                SectionCard(title: "\(dayOfWeek) Discussion", icon: "text.quote") {
                    ScrollView {
                        Text(formatWithParagraphs(analysis.explanation))
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 24)
            }

            // Consider Asking
            if !analysis.followUpQuestions.isEmpty {
                SectionCard(title: "Consider Asking...", icon: "questionmark.circle") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(analysis.followUpQuestions.enumerated()), id: \.offset) { i, q in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1).")
                                    .fontWeight(.semibold)
                                    .foregroundColor(RoundsColor.brandBlue)
                                    .frame(width: 20)
                                Text(q)
                            }
                            .font(.body)
                            if i < analysis.followUpQuestions.count - 1 {
                                Divider().padding(.leading, 30)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Follow-up Q&A
            if !viewModel.conversationHistory.isEmpty {
                SectionCard(title: "Follow-up Q&A", icon: "bubble.left.and.bubble.right") {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.conversationHistory.enumerated()), id: \.offset) { _, msg in
                            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                Text(msg.isUser ? "You asked:" : "Rounds AI:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                // Render markdown bold (**text**) as actual bold
                                Text(renderBoldText(msg.content))
                                    .font(.body)
                                    .padding(12)
                                    .background(msg.isUser ? RoundsColor.brandBlue : Color(UIColor.systemGray5))
                                    .foregroundColor(msg.isUser ? .white : .black)
                                    .cornerRadius(16)
                            }
                            .frame(maxWidth: .infinity, alignment: msg.isUser ? .trailing : .leading)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Ask Follow-up
            VStack(alignment: .leading, spacing: 8) {
                Text("Ask Rounds AI")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    TextField("Ask a follow-up question...", text: $followUpText)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .focused(isFollowUpFocused)
                        .submitLabel(.send)
                        .onSubmit { sendFollowUp() }

                    Button { sendFollowUp() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(followUpText.isEmpty ? .gray : RoundsColor.brandBlue)
                    }
                    .disabled(followUpText.isEmpty || viewModel.isAnalyzing)
                }
                
                if viewModel.isAnalyzing {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("Thinking...").font(.caption).foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 24)
            .id("followUp")

            // Share Button
            Button { showShareSheet = true } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share \(profileStore.patientName)'s \(dayOfWeek) Recap")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundsColor.brandBlue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            // New Session
            Button {
                viewModel.discardRecording()
            } label: {
                Text("Start Fresh Session")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func sendFollowUp() {
        guard !followUpText.isEmpty && !viewModel.isAnalyzing else { return }
        let q = followUpText
        followUpText = ""
        isFollowUpFocused.wrappedValue = false
        Task {
            await viewModel.askFollowUp(q)
            withAnimation { scrollProxy.scrollTo("followUp", anchor: .bottom) }
        }
    }
    
    private func formatWithParagraphs(_ text: String) -> String {
        var result = ""
        var count = 0
        for sentence in text.components(separatedBy: ". ") {
            let s = sentence.trimmingCharacters(in: .whitespaces)
            if s.isEmpty { continue }
            result += s + ". "
            count += 1
            if count >= 2 { result += "\n\n"; count = 0 }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(RoundsColor.brandBlue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Continue Recording Banner

private struct ContinueRecordingBanner: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        Button {
            Task { await viewModel.startSession() }
        } label: {
            HStack {
                Image(systemName: "mic.badge.plus")
                Text("Continue Recording")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline)
            .foregroundColor(RoundsColor.navyBlue)
            .padding(14)
            .background(RoundsColor.navyBlue.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Footer Navigation Bar

private struct FooterNavBar: View {
    @Binding var showPreviousRounds: Bool
    @Binding var showProfileBuilder: Bool
    let hasHistory: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // Archive
                if hasHistory {
                    Button { showPreviousRounds = true } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "archivebox")
                            Text("Archive")
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Profile Builder (future)
                Button { showProfileBuilder = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Add Info")
                    }
                    .font(.caption2)
                    .foregroundColor(RoundsColor.brandBlue)
                }
                
                Spacer()
                
                // Powered by
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

// MARK: - Full Transcript Sheet

private struct FullTranscriptSheet: View {
    let transcript: String
    let patientName: String
    let sessionDate: Date
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: sessionDate)
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
                    ShareLink(item: "🩺 \(patientName)'s Transcript\n📅 \(formattedDate)\n\n\(transcript)\n\n— Rounds AI 💙") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RoundsColor.brandBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet with Email Subject

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    var subject: String = ""
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: [ShareText(text: text, subject: subject)], applicationActivities: nil)
        return activityVC
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Custom class to provide email subject line
class ShareText: NSObject, UIActivityItemSource {
    let text: String
    let subject: String
    
    init(text: String, subject: String) {
        self.text = text
        self.subject = subject
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}

// MARK: - Bold Text Rendering Helper

/// Converts **text** markdown to AttributedString with bold
func renderBoldText(_ input: String) -> AttributedString {
    var result = AttributedString(input)
    
    // Find all **bold** patterns and make them bold
    let pattern = /\*\*(.+?)\*\*/
    var plainText = input
    
    // Simple approach: just remove the ** markers for display
    // SwiftUI Text doesn't easily support inline bold, so we clean it
    plainText = plainText.replacingOccurrences(of: "**", with: "")
    
    return AttributedString(plainText)
}

#Preview {
    LandingView(viewModel: TranscriptViewModel())
}
