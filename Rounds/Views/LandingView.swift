//
//  LandingView.swift
//  Rounds AI
//
//  Main recording + results screen
//  Design System: Uses RoundsColor, RoundsFont, SectionCard components
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
    @State private var showProfileBuilder = false
    @FocusState private var isFollowUpFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // Show different views based on state
                        if viewModel.analysis != nil {
                            // RESULTS VIEW
                            ResultsView(
                                viewModel: viewModel,
                                profileStore: profileStore,
                                showFullTranscript: $showFullTranscript,
                                showShareSheet: $showShareSheet,
                                followUpText: $followUpText,
                                isFollowUpFocused: $isFollowUpFocused,
                                scrollProxy: scrollProxy
                            )
                        } else {
                            // RECORDING VIEW
                            RecordingView(viewModel: viewModel)
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Footer Navigation
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
                subject: "\(profileStore.patientName)'s Health Appointment Recap - \(getDayOfWeek()), \(getShortDate())"
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
    
    // MARK: - Helpers
    
    private func getDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    private func getShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    private func formatShareText() -> String {
        let patientName = profileStore.patientName
        let caregiverName = profileStore.caregiverName
        let dayOfWeek = getDayOfWeek()
        let shortDate = getShortDate()
        
        var text = "📋 \(patientName)'s Health Appointment Recap - \(dayOfWeek), \(shortDate)\n\n"
        text += "Here's a recap of \(patientName)'s \(dayOfWeek) health meeting, sent from Rounds AI:\n\n"
        text += "━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        if let analysis = viewModel.analysis {
            if !analysis.summaryPoints.isEmpty {
                text += "🔑 KEY POINTS\n\n"
                for point in analysis.summaryPoints {
                    text += "• \(cleanMarkdown(point))\n\n"
                }
            }
            
            if !analysis.explanation.isEmpty {
                text += "💬 WHAT WE DISCUSSED\n\n"
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
                    text += msg.isUser ? "Q: \(msg.content)\n\n" : "A: \(cleanMarkdown(msg.content))\n\n"
                }
            }
        }
        
        text += "━━━━━━━━━━━━━━━━━━━━━━\n"
        text += "Sent by \(caregiverName) via Rounds AI 💙"
        
        return text
    }
    
    private func cleanMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
    }
    
    private func formatForShare(_ text: String) -> String {
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
    
    private func formatTranscriptWithParagraphs(_ text: String) -> String {
        var result = text
        let transitions = ["So ", "Now ", "We're ", "The ", "I'd ", "Any ", "From ", "On ", "For "]
        for t in transitions {
            result = result.replacingOccurrences(of: ". \(t)", with: ".\n\n\(t)")
        }
        return result
    }
}

// MARK: - Recording View

private struct RecordingView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with heart+cross and wordmark
            VStack(spacing: 8) {
                RoundsHeartIcon(size: 36, style: .gradient)
                
                Text("R O U N D S   A I")
                    .font(.system(size: 24, weight: .medium))
                    .tracking(6)
                    .foregroundColor(.black)
            }
            .padding(.top, 50)
            .padding(.bottom, 30)

            // LARGE Record Button (10% bigger = 132px)
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
                    // Button background - uses brand gradient when ready
                    Circle()
                        .fill(viewModel.isSessionActive ? Color.red : RoundsColor.brandBlue)
                        .frame(width: 132, height: 132)
                        .shadow(color: (viewModel.isSessionActive ? Color.red : RoundsColor.brandBlue).opacity(0.3), radius: 12, y: 6)

                    if viewModel.isSessionActive {
                        // Stop icon
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 40, height: 40)
                    } else {
                        // Mic icon
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Instruction text BELOW button, CENTERED
            if viewModel.isSessionActive {
                Text(viewModel.formattedDuration)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(.top, 16)
            } else if viewModel.isInSessionChain && !viewModel.liveTranscript.isEmpty {
                Text("Tap to continue recording")
                    .font(RoundsFont.body())
                    .foregroundColor(RoundsColor.textMuted)
                    .padding(.top, 16)
            } else {
                Text("Tap to start recording")
                    .font(RoundsFont.body())
                    .foregroundColor(RoundsColor.textMuted)
                    .padding(.top, 16)
            }

            Spacer().frame(height: 24)

            // Transcript Box - with placeholder inside
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RoundsColor.transcriptBackground)
                        .frame(height: 160)
                    
                    if viewModel.liveTranscript.isEmpty {
                        // Placeholder text - italic, gray
                        Text("Captured audio will appear here")
                            .font(.system(size: 15, weight: .regular))
                            .italic()
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(16)
                    } else {
                        // Live transcript with auto-scroll
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(viewModel.liveTranscript)
                                    .font(RoundsFont.body())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .id("end")
                            }
                            .frame(height: 160)
                            .onChange(of: viewModel.liveTranscript) { _, _ in
                                withAnimation { proxy.scrollTo("end", anchor: .bottom) }
                            }
                        }
                    }
                }
                
                // Recording indicator
                if viewModel.isSessionActive {
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("Recording").font(.caption).foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            // Ready pill (idle state only)
            if !viewModel.isSessionActive && viewModel.liveTranscript.isEmpty {
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("Ready").font(.subheadline).fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(RoundsColor.cardBackground)
                .cornerRadius(20)
                .padding(.top, 24)
            }

            // Post-recording actions
            if !viewModel.isSessionActive && !viewModel.liveTranscript.isEmpty && viewModel.analysis == nil {
                VStack(spacing: 16) {
                    // Translate button
                    Button {
                        Task { await viewModel.analyzeWithRoundsAI() }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isAnalyzing {
                                ProgressView().tint(.white)
                            } else {
                                RoundsHeartIcon(size: 20, style: .reversed)
                            }
                            Text(viewModel.isAnalyzing ? "Analyzing..." : "Translate with Rounds AI")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isAnalyzing ? RoundsColor.brandBlue.opacity(0.6) : RoundsColor.brandBlue)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isAnalyzing)

                    Text("You can tap the mic again to add more to this recording")
                        .font(RoundsFont.caption())
                        .foregroundColor(RoundsColor.textMuted)
                        .multilineTextAlignment(.center)

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
                .padding(.top, 24)
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(RoundsFont.caption())
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }
        }
    }
}

// MARK: - Results View

private struct ResultsView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var profileStore: ProfileStore
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
    
    private var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Compact header
            HStack {
                RoundsHeartIcon(size: 20, style: .gradient)
                Text("ROUNDS AI")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(RoundsColor.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            
            // MARK: - Report Title (H1)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("📋")
                        .font(.system(size: 24))
                    Text("\(profileStore.patientName)'s Appointment Recap")
                        .font(RoundsFont.h1())
                        .foregroundColor(RoundsColor.textPrimary)
                }
                Text(fullDate)
                    .font(RoundsFont.caption())
                    .foregroundColor(RoundsColor.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Continue Recording (top)
            if viewModel.isInSessionChain {
                ActionRow(title: "Continue \(dayOfWeek)'s Recording", icon: "mic.badge.plus") {
                    Task { await viewModel.startSession() }
                }
                .padding(.horizontal, 24)
            }
            
            // View Full Transcript
            ActionRow(title: "View Full Transcript", icon: "doc.text") {
                showFullTranscript = true
            }
            .padding(.horizontal, 24)

            // MARK: - Key Points
            if let analysis = viewModel.analysis, !analysis.summaryPoints.isEmpty {
                SectionCard(title: "\(dayOfWeek)'s Key Points", emoji: "🔑") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(analysis.summaryPoints.prefix(4).enumerated()), id: \.offset) { _, point in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(RoundsColor.brandBlue)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 7)
                                Text(cleanMarkdown(point))
                                    .font(RoundsFont.body())
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // MARK: - What We Discussed
            if let analysis = viewModel.analysis, !analysis.explanation.isEmpty {
                SectionCard(title: "What We Discussed", emoji: "💬") {
                    ScrollView {
                        Text(formatWithParagraphs(cleanMarkdown(analysis.explanation)))
                            .font(RoundsFont.body())
                            .lineSpacing(6)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 24)
            }

            // MARK: - Consider Asking
            if let analysis = viewModel.analysis, !analysis.followUpQuestions.isEmpty {
                SectionCard(title: "Consider Asking...", emoji: "❓") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(analysis.followUpQuestions.enumerated()), id: \.offset) { i, q in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1).")
                                    .font(RoundsFont.body())
                                    .fontWeight(.semibold)
                                    .foregroundColor(RoundsColor.brandBlue)
                                    .frame(width: 24, alignment: .leading)
                                Text(cleanMarkdown(q))
                                    .font(RoundsFont.body())
                            }
                            if i < analysis.followUpQuestions.count - 1 {
                                Divider().padding(.leading, 34)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // MARK: - Follow-up Q&A
            if !viewModel.conversationHistory.isEmpty {
                SectionCard(title: "Follow-up Q&A", emoji: "💭") {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.conversationHistory.enumerated()), id: \.offset) { _, msg in
                            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                Text(msg.isUser ? "You asked:" : "Rounds AI:")
                                    .font(RoundsFont.caption())
                                    .foregroundColor(RoundsColor.textMuted)
                                Text(cleanMarkdown(msg.content))
                                    .font(RoundsFont.body())
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

            // MARK: - Have More Questions?
            ActionRow(title: "Have more questions?", icon: "questionmark.circle") {
                isFollowUpFocused.wrappedValue = true
            }
            .padding(.horizontal, 24)
            
            // Question input
            HStack(spacing: 12) {
                TextField("Ask Rounds AI anything...", text: $followUpText)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(RoundsColor.cardBackground)
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
            .padding(.horizontal, 24)
            .id("followUp")
            
            if viewModel.isAnalyzing {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Thinking...").font(RoundsFont.caption()).foregroundColor(RoundsColor.textMuted)
                }
                .padding(.horizontal, 24)
            }

            // Continue Recording (bottom)
            if viewModel.isInSessionChain {
                ActionRow(title: "Continue \(dayOfWeek)'s Recording", icon: "mic.badge.plus") {
                    Task { await viewModel.startSession() }
                }
                .padding(.horizontal, 24)
            }

            // Share button
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

            // Start fresh
            Button {
                viewModel.discardRecording()
            } label: {
                Text("Start Fresh Session")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMuted)
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
    
    private func cleanMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
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

// MARK: - Footer Navigation

private struct FooterNavBar: View {
    @Binding var showPreviousRounds: Bool
    @Binding var showProfileBuilder: Bool
    let hasHistory: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if hasHistory {
                    Button { showPreviousRounds = true } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "archivebox")
                            Text("Archive")
                        }
                        .font(.caption2)
                        .foregroundColor(RoundsColor.textMuted)
                    }
                }
                
                Spacer()
                
                Button { showProfileBuilder = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Add Info")
                    }
                    .font(.caption2)
                    .foregroundColor(RoundsColor.brandBlue)
                }
                
                Spacer()
                
                Link(destination: URL(string: "https://loudlabs.xyz")!) {
                    VStack(spacing: 2) {
                        Text("LOUD").font(.system(size: 11, weight: .black)).tracking(1)
                        Text("powered by").font(.system(size: 9))
                    }
                    .foregroundColor(RoundsColor.textMuted)
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
                            .font(RoundsFont.h1())
                        Text(formattedDate)
                            .font(RoundsFont.caption())
                            .foregroundColor(RoundsColor.textMuted)
                    }
                    Divider()
                    Text(transcript)
                        .font(RoundsFont.body())
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
                    ShareLink(item: "📋 \(patientName)'s Transcript\n📅 \(formattedDate)\n\n\(transcript)\n\n— Rounds AI 💙") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RoundsColor.brandBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    var subject: String = ""
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [ShareText(text: text, subject: subject)], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class ShareText: NSObject, UIActivityItemSource {
    let text: String
    let subject: String
    
    init(text: String, subject: String) {
        self.text = text
        self.subject = subject
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { text }
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { text }
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String { subject }
}

#Preview {
    LandingView(viewModel: TranscriptViewModel())
}
