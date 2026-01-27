//
//  LandingView.swift
//  Rounds AI
//
//  RESTORED: Big bright blue button, light modules, dark text, bold headers
//  Reference: IMG_9459 - the GOOD design
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
    @State private var showAccount = false
    @FocusState private var isFollowUpFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.analysis != nil {
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
                            RecordingView(viewModel: viewModel)
                        }
                        Spacer().frame(height: 100)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Footer
            FooterBar(
                showPreviousRounds: $showPreviousRounds,
                showAccount: $showAccount,
                hasHistory: !sessionStore.sessions.isEmpty,
                hasActiveSession: !viewModel.liveTranscript.isEmpty
            )
        }
        .background(Color.white)
        .onTapGesture { isFollowUpFocused = false }
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showAccount) {
            AccountSheet(profileStore: profileStore)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: formatShareText(), subject: shareSubject())
        }
        .sheet(isPresented: $showFullTranscript) {
            TranscriptSheet(transcript: viewModel.liveTranscript, patientName: profileStore.patientName, date: viewModel.currentSession?.startTime ?? Date())
        }
    }
    
    private func shareSubject() -> String {
        "\(profileStore.patientName)'s Health Appointment Recap - \(dayOfWeek()), \(shortDate())"
    }
    
    private func dayOfWeek() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    private func shortDate() -> String {
        let f = DateFormatter(); f.dateFormat = "M/d/yy"
        return f.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    private func formatShareText() -> String {
        let patient = profileStore.patientName
        let caregiver = profileStore.caregiverName
        let day = dayOfWeek()
        let date = shortDate()
        
        var text = "📋 \(patient)'s Health Appointment Recap - \(day), \(date)\n\n"
        text += "Here's a recap of \(patient)'s \(day) health meeting:\n\n"
        
        if let a = viewModel.analysis {
            if !a.summaryPoints.isEmpty {
                text += "🔑 KEY POINTS\n\n"
                for p in a.summaryPoints { text += "• \(p.replacingOccurrences(of: "**", with: ""))\n\n" }
            }
            if !a.explanation.isEmpty {
                text += "💬 WHAT WE DISCUSSED\n\n\(a.explanation.replacingOccurrences(of: "**", with: ""))\n\n"
            }
            if !a.followUpQuestions.isEmpty {
                text += "❓ QUESTIONS TO CONSIDER\n\n"
                for (i, q) in a.followUpQuestions.enumerated() { text += "\(i+1). \(q)\n\n" }
            }
        }
        text += "— Sent by \(caregiver) via Rounds AI 💙"
        return text
    }
}

// MARK: - Recording View (BIG BRIGHT BUTTON)

private struct RecordingView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with two hearts icon + ROUNDS AI wordmark
            VStack(spacing: 8) {
                RoundsHeartIcon(size: 36)
                VStack(spacing: 2) {
                    Text("R O U N D S")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(6)
                        .foregroundColor(RoundsColor.textDark)
                    Text("A I")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(8)
                        .foregroundColor(RoundsColor.buttonBlue)
                }
            }
            .padding(.top, 50)
            .padding(.bottom, 30)

            // BIG BRIGHT BLUE BUTTON (150px!)
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
                        .fill(viewModel.isSessionActive ? Color.red : RoundsColor.buttonBlue)
                        .frame(width: 150, height: 150)
                        .shadow(color: (viewModel.isSessionActive ? Color.red : RoundsColor.buttonBlue).opacity(0.4), radius: 20, y: 8)

                    if viewModel.isSessionActive {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            // Status text below button
            Group {
                if viewModel.isSessionActive {
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                } else if !viewModel.liveTranscript.isEmpty {
                    Text("Tap to continue recording")
                        .font(.body)
                        .foregroundColor(RoundsColor.textMuted)
                } else {
                    Text("Tap to start recording")
                        .font(.body)
                        .foregroundColor(RoundsColor.textMuted)
                }
            }
            .padding(.top, 20)

            // Transcript box - LIGHT BLUE background, DARK text
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(RoundsColor.moduleBackground)
                    .frame(height: 180)
                
                if viewModel.liveTranscript.isEmpty {
                    Text("Captured audio will appear here...")
                        .font(.body)
                        .italic()
                        .foregroundColor(RoundsColor.textMuted)
                        .padding(20)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(viewModel.liveTranscript)
                                .font(.body)
                                .foregroundColor(RoundsColor.textDark)
                                .padding(20)
                                .id("end")
                        }
                        .frame(height: 180)
                        .onChange(of: viewModel.liveTranscript) { _, _ in
                            withAnimation { proxy.scrollTo("end", anchor: .bottom) }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            // Recording indicator
            if viewModel.isSessionActive {
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 10, height: 10)
                    Text("Recording...").font(.subheadline).foregroundColor(.red)
                }
                .padding(.top, 12)
            }

            // Post-recording actions
            if !viewModel.isSessionActive && !viewModel.liveTranscript.isEmpty && viewModel.analysis == nil {
                VStack(spacing: 16) {
                    Button {
                        Task { await viewModel.analyzeWithRoundsAI() }
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isAnalyzing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            Text(viewModel.isAnalyzing ? "Analyzing..." : "Translate with Rounds AI")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(viewModel.isAnalyzing ? RoundsColor.buttonBlue.opacity(0.6) : RoundsColor.buttonBlue)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isAnalyzing)

                    Text("Tap mic to add more to this recording")
                        .font(.caption)
                        .foregroundColor(RoundsColor.textMuted)

                    Button { viewModel.discardRecording() } label: {
                        Label("Discard & Start Over", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
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

// MARK: - Results View (Light modules, dark text, bold headers)

private struct ResultsView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @ObservedObject var profileStore: ProfileStore
    @Binding var showFullTranscript: Bool
    @Binding var showShareSheet: Bool
    @Binding var followUpText: String
    var isFollowUpFocused: FocusState<Bool>.Binding
    let scrollProxy: ScrollViewProxy
    
    private var dayOfWeek: String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    private var fullDate: String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d, yyyy"
        return f.string(from: viewModel.currentSession?.startTime ?? Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Compact header
            HStack {
                RoundsHeartIcon(size: 22)
                Text("ROUNDS AI")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(RoundsColor.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            
            // REPORT TITLE - Bold with emoji!
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 26))
                    Text("\(profileStore.patientName)'s \(dayOfWeek) Recap")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(RoundsColor.textDark)
                }
                Text(fullDate)
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMuted)
            }
            .padding(.horizontal, 24)
            
            // Continue Recording
            if viewModel.isInSessionChain {
                ActionButton(title: "Continue \(dayOfWeek)'s Recording", icon: "mic.badge.plus") {
                    Task { await viewModel.startSession() }
                }
                .padding(.horizontal, 24)
            }
            
            // View Transcript
            ActionButton(title: "View Full Transcript", icon: "doc.text") {
                showFullTranscript = true
            }
            .padding(.horizontal, 24)

            // KEY POINTS - Light blue module, dark text, bold header
            if let a = viewModel.analysis, !a.summaryPoints.isEmpty {
                ModuleCard(title: "🔑 \(dayOfWeek)'s Key Points") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(a.summaryPoints.prefix(4).enumerated()), id: \.offset) { _, point in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(RoundsColor.buttonBlue)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                Text(point.replacingOccurrences(of: "**", with: ""))
                                    .font(.body)
                                    .foregroundColor(RoundsColor.textDark)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // WHAT WE DISCUSSED - with paragraph breaks
            if let a = viewModel.analysis, !a.explanation.isEmpty {
                ModuleCard(title: "💬 What We Discussed") {
                    Text(formatIntoParagraphs(a.explanation.replacingOccurrences(of: "**", with: "")))
                        .font(.body)
                        .foregroundColor(RoundsColor.textDark)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 24)
            }

            // CONSIDER ASKING
            if let a = viewModel.analysis, !a.followUpQuestions.isEmpty {
                ModuleCard(title: "❓ Consider Asking...") {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(a.followUpQuestions.enumerated()), id: \.offset) { i, q in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1).")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(RoundsColor.buttonBlue)
                                    .frame(width: 24)
                                Text(q)
                                    .font(.body)
                                    .foregroundColor(RoundsColor.textDark)
                            }
                            if i < a.followUpQuestions.count - 1 {
                                Divider().padding(.leading, 36)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Q&A
            if !viewModel.conversationHistory.isEmpty {
                ModuleCard(title: "💭 Follow-up Q&A") {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.conversationHistory.enumerated()), id: \.offset) { _, msg in
                            VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 6) {
                                Text(msg.isUser ? "You asked:" : "Rounds AI:")
                                    .font(.caption)
                                    .foregroundColor(RoundsColor.textMuted)
                                Text(msg.content.replacingOccurrences(of: "**", with: ""))
                                    .font(.body)
                                    .padding(14)
                                    .background(msg.isUser ? RoundsColor.buttonBlue : Color(UIColor.systemGray5))
                                    .foregroundColor(msg.isUser ? .white : RoundsColor.textDark)
                                    .cornerRadius(16)
                            }
                            .frame(maxWidth: .infinity, alignment: msg.isUser ? .trailing : .leading)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Ask more
            ActionButton(title: "Have more questions?", icon: "questionmark.circle") {
                isFollowUpFocused.wrappedValue = true
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                TextField("Ask Rounds AI anything...", text: $followUpText)
                    .padding(16)
                    .background(RoundsColor.moduleBackground)
                    .cornerRadius(14)
                    .focused(isFollowUpFocused)
                    .onSubmit { sendFollowUp() }

                Button { sendFollowUp() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(followUpText.isEmpty ? .gray : RoundsColor.buttonBlue)
                }
                .disabled(followUpText.isEmpty || viewModel.isAnalyzing)
            }
            .padding(.horizontal, 24)
            .id("followUp")

            if viewModel.isAnalyzing {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Thinking...").font(.caption).foregroundColor(RoundsColor.textMuted)
                }
                .padding(.horizontal, 24)
            }

            // Continue Recording (bottom)
            if viewModel.isInSessionChain {
                ActionButton(title: "Continue \(dayOfWeek)'s Recording", icon: "mic.badge.plus") {
                    Task { await viewModel.startSession() }
                }
                .padding(.horizontal, 24)
            }

            // Share
            Button { showShareSheet = true } label: {
                Label("Share \(profileStore.patientName)'s \(dayOfWeek) Recap", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundsColor.buttonBlue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)

            Button { viewModel.discardRecording() } label: {
                Text("Start Fresh Session")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
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
}

// MARK: - Module Card (Light blue background, dark text)

private struct ModuleCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RoundsColor.headerBlue)
            
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundsColor.moduleBackground)
        .cornerRadius(16)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(RoundsColor.buttonBlue)
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.buttonBlue)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RoundsColor.buttonBlue.opacity(0.5))
            }
            .padding(16)
            .background(RoundsColor.moduleBackground)
            .cornerRadius(14)
        }
    }
}

// MARK: - Footer

private struct FooterBar: View {
    @Binding var showPreviousRounds: Bool
    @Binding var showAccount: Bool
    let hasHistory: Bool
    let hasActiveSession: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                // Archive / Past Sessions
                if hasHistory {
                    Button { showPreviousRounds = true } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Past Sessions")
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Active Session indicator (when recording exists)
                if hasActiveSession {
                    VStack(spacing: 4) {
                        Image(systemName: "waveform.circle.fill")
                        Text("Active")
                    }
                    .font(.caption2)
                    .foregroundColor(RoundsColor.buttonBlue)
                    .frame(maxWidth: .infinity)
                }
                
                // Account
                Button { showAccount = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "person.circle")
                        Text("Account")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                // Powered by LOUD
                Link(destination: URL(string: "https://loudlabs.xyz")!) {
                    VStack(spacing: 2) {
                        Text("powered by").font(.system(size: 8))
                        Text("LOUD").font(.system(size: 11, weight: .black))
                    }
                    .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Transcript Sheet

private struct TranscriptSheet: View {
    let transcript: String
    let patientName: String
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(transcript)
                    .font(.body)
                    .foregroundColor(RoundsColor.textDark)
                    .padding(24)
            }
            .navigationTitle("Full Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
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
        UIActivityViewController(activityItems: [ShareItem(text: text, subject: subject)], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class ShareItem: NSObject, UIActivityItemSource {
    let text: String
    let subject: String
    init(text: String, subject: String) { self.text = text; self.subject = subject }
    func activityViewControllerPlaceholderItem(_ c: UIActivityViewController) -> Any { text }
    func activityViewController(_ c: UIActivityViewController, itemForActivityType t: UIActivity.ActivityType?) -> Any? { text }
    func activityViewController(_ c: UIActivityViewController, subjectForActivityType t: UIActivity.ActivityType?) -> String { subject }
}

// MARK: - Account Sheet

private struct AccountSheet: View {
    @ObservedObject var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Profile") {
                    HStack {
                        Text("Your Name")
                        Spacer()
                        Text(profileStore.caregiverName)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Patient")
                        Spacer()
                        Text(profileStore.patientName)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("Reset Onboarding") {
                        profileStore.resetProfile()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Helper: Format text into paragraphs

private func formatIntoParagraphs(_ text: String) -> String {
    // Split into sentences and group into paragraphs (2-3 sentences each)
    let sentences = text.components(separatedBy: ". ")
    var result = ""
    var count = 0
    
    for sentence in sentences {
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        
        result += trimmed
        if !trimmed.hasSuffix(".") { result += "." }
        result += " "
        count += 1
        
        // Add paragraph break every 2-3 sentences
        if count >= 2 {
            result += "\n\n"
            count = 0
        }
    }
    
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}

#Preview {
    LandingView(viewModel: TranscriptViewModel())
}
