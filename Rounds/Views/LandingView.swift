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
                        // Top safe area padding
                        Color.clear.frame(height: 12)
                        
                        // Show RecordingView when actively recording OR when no analysis yet
                        // Show ResultsView only when not recording AND have analysis
                        if viewModel.isSessionActive {
                            RecordingView(viewModel: viewModel)
                        } else if viewModel.analysis != nil {
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
                    .padding(.top, 1) // Prevents content from going behind status bar
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Footer
            FooterBar(
                showPreviousRounds: $showPreviousRounds,
                showAccount: $showAccount,
                hasHistory: !sessionStore.sessions.isEmpty,
                hasActiveSession: viewModel.isInSessionChain && !viewModel.liveTranscript.isEmpty
            )
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom) // Only ignore bottom for footer
        .onTapGesture { isFollowUpFocused = false }
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showAccount) {
            AccountSheet(profileStore: profileStore)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: formatShareText(), htmlText: formatShareHTML(), subject: shareSubject())
        }
        .sheet(isPresented: $showFullTranscript) {
            TranscriptSheet(transcript: viewModel.liveTranscript, patientName: profileStore.patientName, date: viewModel.currentSession?.startTime ?? Date())
        }
    }
    
    private func shareSubject() -> String {
        "🩺 \(profileStore.patientName)'s Appointment Recap - \(dayOfWeek()) \(shortDate())"
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
        
        // Cleaner, shorter title
        var text = "🩺 \(patient)'s Appointment Recap - \(day) \(date)\n\n"
        
        if let a = viewModel.analysis {
            if !a.summaryPoints.isEmpty {
                text += "KEY POINTS:\n\n"
                for p in a.summaryPoints { 
                    text += "• \(p.replacingOccurrences(of: "**", with: ""))\n\n" 
                }
            }
            if !a.explanation.isEmpty {
                text += "WHAT WE DISCUSSED:\n\n"
                // Split into paragraphs and add spacing between each
                let paragraphs = a.explanation.replacingOccurrences(of: "**", with: "")
                    .components(separatedBy: "\n\n")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                for para in paragraphs {
                    text += "\(para.trimmingCharacters(in: .whitespaces))\n\n"
                }
            }
            if !a.followUpQuestions.isEmpty {
                text += "QUESTIONS TO CONSIDER:\n\n"
                for (i, q) in a.followUpQuestions.enumerated() { 
                    text += "\(i+1). \(q)\n\n" 
                }
            }
        }
        text += "— Sent by \(caregiver) via Rounds AI 💙"
        return text
    }
    
    private func formatShareHTML() -> String {
        let patient = profileStore.patientName
        let caregiver = profileStore.caregiverName
        let day = dayOfWeek()
        let date = shortDate()
        
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, sans-serif; font-size: 16px; line-height: 1.5; color: #333; }
            h1 { font-size: 22px; color: #1a1a1a; margin-bottom: 20px; }
            h2 { font-size: 18px; color: #2563eb; margin-top: 24px; margin-bottom: 12px; border-bottom: 1px solid #e5e7eb; padding-bottom: 4px; }
            p { margin: 12px 0; }
            ul { margin: 12px 0; padding-left: 20px; }
            li { margin: 8px 0; }
            .footer { margin-top: 30px; color: #666; font-style: italic; }
        </style>
        </head>
        <body>
        <h1>🩺 \(patient)'s Appointment Recap — \(day) \(date)</h1>
        """
        
        if let a = viewModel.analysis {
            if !a.summaryPoints.isEmpty {
                html += "<h2>🔑 Key Points</h2><ul>"
                for p in a.summaryPoints { 
                    let cleaned = p.replacingOccurrences(of: "**", with: "")
                    html += "<li>\(cleaned)</li>" 
                }
                html += "</ul>"
            }
            if !a.explanation.isEmpty {
                html += "<h2>💬 What We Discussed</h2>"
                let paragraphs = a.explanation
                    .replacingOccurrences(of: "**", with: "<strong>")
                    .replacingOccurrences(of: "**", with: "</strong>")
                    .components(separatedBy: "\n\n")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                for para in paragraphs {
                    html += "<p>\(para.trimmingCharacters(in: .whitespaces))</p>"
                }
            }
            if !a.followUpQuestions.isEmpty {
                html += "<h2>❓ Questions to Consider</h2><ol>"
                for q in a.followUpQuestions { 
                    html += "<li>\(q)</li>" 
                }
                html += "</ol>"
            }
        }
        
        html += """
        <p class="footer">— Sent by \(caregiver) via Rounds AI 💙</p>
        </body>
        </html>
        """
        return html
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
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
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
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d, yyyy 'at' h:mm a"
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
            .id("top") // Anchor for scroll-to-top
            
            // REPORT TITLE - Bold with emoji!
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🩺")
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
            
            // Continue Recording - clearer action text
            if viewModel.isInSessionChain {
                ActionButton(title: "Continue Recording", icon: "🎤") {
                    Task { await viewModel.startSession() }
                }
                .padding(.horizontal, 24)
            }
            
            // View Transcript - emoji
            ActionButton(title: "View Full Transcript", icon: "📄") {
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

            // WHAT WE DISCUSSED - with Next Steps parsing
            if let a = viewModel.analysis, !a.explanation.isEmpty {
                ModuleCard(title: "💬 What We Discussed") {
                    let parsed = parseExplanationWithNextSteps(a.explanation)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Main explanation text (before "Next Steps:")
                        if !parsed.mainText.isEmpty {
                            Text(formatIntoParagraphs(parsed.mainText))
                                .font(.body)
                                .foregroundColor(RoundsColor.textDark)
                                .lineSpacing(6)
                        }
                        
                        // Next Steps section (if present) - visually distinct
                        if !parsed.nextSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                // Bold header
                                Text("Next Steps")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(RoundsColor.textDark)
                                
                                // Bullet points
                                ForEach(parsed.nextSteps, id: \.self) { step in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(RoundsColor.buttonBlue)
                                        Text(step)
                                            .font(.body)
                                            .foregroundColor(RoundsColor.textDark)
                                    }
                                }
                            }
                            .padding(12)
                            .background(RoundsColor.buttonBlue.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
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

            // Ask Rounds AI - Combined module with header and input
            ModuleCard(title: "💭 Still Have Questions?") {
                VStack(spacing: 12) {
                    Text("Ask Rounds AI anything about today's visit")
                        .font(.subheadline)
                        .foregroundColor(RoundsColor.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        TextField("Type your question...", text: $followUpText)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .focused(isFollowUpFocused)
                            .onSubmit { sendFollowUp() }

                        Button { sendFollowUp() } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(followUpText.isEmpty ? .gray.opacity(0.5) : RoundsColor.buttonBlue)
                        }
                        .disabled(followUpText.isEmpty || viewModel.isAnalyzing)
                    }
                }
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

            // Continue Recording (bottom) - emoji
            if viewModel.isInSessionChain {
                ActionButton(title: "Keep Recording", icon: "🎤") {
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

            // Start Fresh Session - now a proper button
            Button { viewModel.discardRecording() } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                    Text("Start Fresh Session")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(RoundsColor.textMuted)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            .padding(.top, 8)
            
            // Scroll to top button
            Button {
                withAnimation { scrollProxy.scrollTo("top", anchor: .top) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Top")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(RoundsColor.textMuted)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
    }
    
    private func sendFollowUp() {
        guard !followUpText.isEmpty && !viewModel.isAnalyzing else { return }
        let q = followUpText
        
        // Dismiss keyboard FIRST, then clear text
        isFollowUpFocused.wrappedValue = false
        
        // Small delay to let keyboard dismiss before clearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            followUpText = ""
        }
        
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

// MARK: - Action Button (supports both SF Symbols and emoji)

private struct ActionButton: View {
    let title: String
    let icon: String  // Can be SF Symbol name OR emoji
    let action: () -> Void
    
    private var isEmoji: Bool {
        // Emoji strings are typically 1-2 characters and don't contain only ASCII
        icon.count <= 4 && icon.unicodeScalars.first.map { !$0.isASCII } == true
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isEmoji {
                    Text(icon)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(RoundsColor.buttonBlue)
                }
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
                // Archive / History
                if hasHistory {
                    Button { showPreviousRounds = true } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 22))
                            Text("History")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Active Session indicator (when recording exists)
                if hasActiveSession {
                    VStack(spacing: 4) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 22))
                        Text("Active")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(RoundsColor.buttonBlue)
                    .frame(maxWidth: .infinity)
                }
                
                // Account
                Button { showAccount = true } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                        Text("Account")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                // Powered by Loud Labs - stacked
                Link(destination: URL(string: "https://loudlabs.xyz")!) {
                    VStack(spacing: 0) {
                        Text("powered by")
                            .font(.system(size: 8))
                        VStack(spacing: -2) {
                            Text("Loud")
                                .font(.system(size: 11, weight: .black))
                            Text("Labs")
                                .font(.system(size: 11, weight: .black))
                        }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    let htmlText: String
    var subject: String = ""
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [ShareItem(text: text, htmlText: htmlText, subject: subject)], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class ShareItem: NSObject, UIActivityItemSource {
    let text: String
    let htmlText: String
    let subject: String
    
    init(text: String, htmlText: String, subject: String) { 
        self.text = text
        self.htmlText = htmlText
        self.subject = subject 
    }
    
    func activityViewControllerPlaceholderItem(_ c: UIActivityViewController) -> Any { text }
    
    func activityViewController(_ c: UIActivityViewController, itemForActivityType t: UIActivity.ActivityType?) -> Any? { 
        // Use HTML for email, plain text for everything else
        if t == .mail {
            return htmlText
        }
        return text 
    }
    
    func activityViewController(_ c: UIActivityViewController, subjectForActivityType t: UIActivity.ActivityType?) -> String { subject }
    
    func activityViewController(_ c: UIActivityViewController, dataTypeIdentifierForActivityType t: UIActivity.ActivityType?) -> String {
        if t == .mail {
            return "public.html"
        }
        return "public.plain-text"
    }
}

// MARK: - Account Sheet

private struct AccountSheet: View {
    @ObservedObject var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false
    @State private var showResetConfirm = false
    
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
                    if let situation = profileStore.currentProfile?.patientSituation,
                       !situation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Situation")
                            Text(situation)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("Memory") {
                    let sessionCount = AIMemoryStore.shared.memory.sessions.count
                    HStack {
                        Text("Recorded Sessions")
                        Spacer()
                        Text("\(sessionCount)")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Clear Medical History") {
                        showClearConfirm = true
                    }
                    .foregroundColor(.orange)
                }
                
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("Reset Everything") {
                        showResetConfirm = true
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
            .alert("Clear Medical History?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    AIMemoryStore.shared.resetMemory()
                }
            } message: {
                Text("This will erase all learned medical facts, vital trends, and session history. Your profile will remain.")
            }
            .alert("Reset Everything?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    AIMemoryStore.shared.resetMemory()
                    profileStore.resetProfile()
                    dismiss()
                }
            } message: {
                Text("This will erase all data including your profile. You'll need to complete onboarding again.")
            }
        }
    }
}

// MARK: - Helper: Format text into paragraphs

private func formatIntoParagraphs(_ text: String) -> String {
    // First, normalize spaces and newlines - remove double spaces
    var cleaned = text
        .replacingOccurrences(of: "  ", with: " ")   // double space → single
        .replacingOccurrences(of: "\n\n\n", with: "\n\n") // triple newline → double
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // If text already has paragraph breaks (from GPT), preserve them
    if cleaned.contains("\n\n") {
        // Clean each paragraph individually
        let paragraphs = cleaned.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.joined(separator: "\n\n")
    }
    
    // Otherwise, split into sentences and group into paragraphs
    let sentences = cleaned.components(separatedBy: ". ")
    var result = ""
    var count = 0
    
    for sentence in sentences {
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        
        result += trimmed
        if !trimmed.hasSuffix(".") && !trimmed.hasSuffix("?") && !trimmed.hasSuffix("!") { 
            result += "." 
        }
        result += " "
        count += 1
        
        // Add paragraph break every 2-3 sentences
        if count >= 2 {
            result = result.trimmingCharacters(in: .whitespaces) + "\n\n"
            count = 0
        }
    }
    
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Next Steps Parsing

/// Parsed result from explanation text
private struct ParsedExplanation {
    let mainText: String
    let nextSteps: [String]
}

/// Parses the explanation text to extract "Next Steps:" section
/// Returns the main text and an array of next step bullet points
private func parseExplanationWithNextSteps(_ text: String) -> ParsedExplanation {
    // Clean up markdown bold markers
    let cleaned = text.replacingOccurrences(of: "**", with: "")
    
    // Look for "Next Steps:" (case insensitive variations)
    let patterns = ["Next Steps:", "Next steps:", "NEXT STEPS:", "next steps:"]
    
    for pattern in patterns {
        if let range = cleaned.range(of: pattern) {
            // Split into main text and next steps section
            let mainText = String(cleaned[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let nextStepsSection = String(cleaned[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse bullet points from next steps section
            let nextSteps = parseNextStepsBullets(nextStepsSection)
            
            return ParsedExplanation(mainText: mainText, nextSteps: nextSteps)
        }
    }
    
    // No "Next Steps:" found - return original text
    return ParsedExplanation(mainText: cleaned, nextSteps: [])
}

/// Parses bullet points from the next steps section
/// Handles "• item", "- item", "* item" formats and plain newlines
private func parseNextStepsBullets(_ text: String) -> [String] {
    var steps: [String] = []
    
    // Split by newlines first
    let lines = text.components(separatedBy: .newlines)
    
    for line in lines {
        var cleanedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Remove leading bullet characters
        let bulletPrefixes = ["• ", "- ", "* ", "· ", "‣ ", "● "]
        for prefix in bulletPrefixes {
            if cleanedLine.hasPrefix(prefix) {
                cleanedLine = String(cleanedLine.dropFirst(prefix.count))
                break
            }
        }
        
        // Skip empty lines
        cleanedLine = cleanedLine.trimmingCharacters(in: .whitespaces)
        if !cleanedLine.isEmpty {
            steps.append(cleanedLine)
        }
    }
    
    return steps
}

#Preview {
    LandingView(viewModel: TranscriptViewModel())
}
