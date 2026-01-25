//
//  LandingView.swift
//  Rounds AI
//
//  Main recording screen - matches your reference screenshot
//  Spaced wordmark, heart icon, big mic button, transcript box, Ready pill
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
    @FocusState private var isFollowUpFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header (Heart + ROUNDS AI wordmark)
                        VStack(spacing: 8) {
                            // Heart icon
                            Image(systemName: "heart")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(RoundsColor.brandBlue)
                            
                            // Spaced wordmark
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
                                    .fill(RoundsColor.brandBlue)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: RoundsColor.brandBlue.opacity(0.3), radius: 12, y: 6)

                                if viewModel.isSessionActive {
                                    // Stop icon (square)
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

                        // Duration when recording
                        if viewModel.isSessionActive {
                            Text(viewModel.formattedDuration)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.top, 16)
                        }

                        Spacer().frame(height: 32)

                        // MARK: - Live Transcription Box
                        VStack(alignment: .leading, spacing: 0) {
                            // Transcript content area
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RoundsColor.brandBlue.opacity(0.08))
                                    .frame(height: 140)
                                
                                if viewModel.liveTranscript.isEmpty {
                                    Text(viewModel.isSessionActive ? "Listening..." : "Tap the microphone to start")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .padding(16)
                                } else {
                                    ScrollView {
                                        Text(viewModel.liveTranscript)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                    }
                                    .frame(height: 140)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 24)

                        // MARK: - Ready Pill (when idle)
                        if !viewModel.isSessionActive && viewModel.analysis == nil && viewModel.liveTranscript.isEmpty {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.green)
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
                                // Analyze button
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
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 16))
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

                                // Discard button
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

                        // MARK: - Analysis Results
                        if let analysis = viewModel.analysis {
                            AnalysisResultsSection(
                                analysis: analysis,
                                transcript: viewModel.liveTranscript,
                                showFullTranscript: $showFullTranscript,
                                patientName: profileStore.patientName,
                                sessionDate: viewModel.currentSession?.startTime ?? Date()
                            )
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                            // Follow-up Input
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
                                            if !followUpText.isEmpty && !viewModel.isAnalyzing {
                                                Task {
                                                    let q = followUpText
                                                    followUpText = ""
                                                    await viewModel.askFollowUp(q)
                                                }
                                            }
                                        }

                                    Button {
                                        Task {
                                            let q = followUpText
                                            followUpText = ""
                                            await viewModel.askFollowUp(q)
                                        }
                                    } label: {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(followUpText.isEmpty ? .gray : RoundsColor.brandBlue)
                                    }
                                    .disabled(followUpText.isEmpty || viewModel.isAnalyzing)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                            .id("followUpInput")

                            // Share buttons
                            VStack(spacing: 12) {
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
                                    .padding(.vertical, 14)
                                    .background(RoundsColor.brandBlue)
                                    .cornerRadius(12)
                                }

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
                                    .foregroundColor(RoundsColor.brandBlue)
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
            
            // MARK: - Footer (anchored)
            FooterBar(showPreviousRounds: $showPreviousRounds, hasHistory: !sessionStore.sessions.isEmpty)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showPreviousRounds) {
            PreviousRoundsView(viewModel: viewModel, sessionStore: sessionStore)
        }
        .sheet(isPresented: $showShareSheet) {
            if let session = viewModel.currentSession {
                ShareSheet(text: formatShareText(session: session))
            }
        }
        .sheet(isPresented: $showFullTranscript) {
            FullTranscriptSheet(
                transcript: viewModel.liveTranscript,
                patientName: profileStore.patientName,
                sessionDate: viewModel.currentSession?.startTime ?? Date()
            )
        }
    }
    
    private func formatShareText(session: RecordingSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        let dateString = dateFormatter.string(from: session.startTime)
        
        var text = "📋 \(profileStore.patientName)'s Appointment Recap\n"
        text += "📅 \(dateString)\n\n"
        
        if let analysis = viewModel.analysis {
            text += "KEY POINTS:\n"
            for point in analysis.summaryPoints.prefix(3) {
                text += "• \(point)\n"
            }
            text += "\nSUMMARY:\n\(analysis.explanation)\n"
        }
        
        text += "\n---\nGenerated by Rounds AI"
        return text
    }
}

// MARK: - Analysis Results Section

private struct AnalysisResultsSection: View {
    let analysis: RoundsAnalysis
    let transcript: String
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
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(RoundsColor.brandBlue)
                
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

            // Key Points (max 3)
            if !analysis.summaryPoints.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(dayOfWeek)'s Key Points")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(analysis.summaryPoints.prefix(3).enumerated()), id: \.offset) { _, point in
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

            // Discussion Summary
            VStack(alignment: .leading, spacing: 10) {
                Text("\(dayOfWeek) Discussion")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(analysis.explanation)
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)

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
                        .lineSpacing(6)
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
                    ShareLink(item: "📋 \(patientName)'s Appointment Transcript\n📅 \(formattedDate)\n\n---\n\n\(transcript)\n\n---\nGenerated by Rounds AI") {
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
                // Archive button
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
                
                // Powered by Loud Labs
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
