//
//  TranscriptViewModel.swift
//  Rounds AI
//
//  Core ViewModel - Uses Apple Speech Recognition + OpenAI for analysis
//  Supports SESSION CHAINING: Multiple record/stop cycles within 1 hour
//  are treated as the same session and transcripts are appended.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class TranscriptViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var isSessionActive = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var elapsedSeconds: Int = 0
    
    // Analysis state
    @Published private(set) var isAnalyzing = false
    @Published private(set) var analysis: RoundsAnalysis?
    @Published private(set) var hasTranscriptToAnalyze = false
    
    // Session & Conversation
    @Published private(set) var currentSession: RecordingSession?
    @Published private(set) var conversationHistory: [ConversationMessage] = []
    
    // Session chaining - tracks when the session started for 1-hour window
    private var sessionStartTime: Date?
    private let sessionChainWindowSeconds: TimeInterval = 3600 // 1 hour
    
    // MARK: - Dependencies
    
    private let sttService = STTService()
    private let openAIService = OpenAIService.shared
    private let sessionStore = SessionStore.shared
    
    private var durationTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        sttService.onTranscriptUpdate = { [weak self] text in
            Task { @MainActor in
                guard let self = self else { return }
                // If we have existing transcript from previous recording in this session,
                // append the new text with a separator
                if let existingBase = self.currentSession?.transcript, !existingBase.isEmpty {
                    // Only update the "new" portion
                    self.liveTranscript = existingBase + "\n\n[continued]\n\n" + text
                } else {
                    self.liveTranscript = text
                }
            }
        }
    }
    
    // MARK: - Session Control
    
    func startSession() async {
        guard !isSessionActive else { return }
        
        // Request speech recognition permission
        let authorized = await sttService.requestAuthorization()
        guard authorized else {
            errorMessage = "Speech recognition permission denied. Please enable in Settings."
            return
        }
        
        errorMessage = nil
        
        // Check if we should CHAIN to existing session (within 1-hour window)
        let now = Date()
        let shouldChain = shouldChainToExistingSession(currentTime: now)
        
        if shouldChain {
            // APPEND MODE: Keep existing transcript, analysis, and conversation
            print("[TranscriptViewModel] Chaining to existing session (within 1-hour window)")
            // Store the current transcript as the base for appending
            // Also preserve the accumulated duration
            if currentSession == nil {
                currentSession = RecordingSession(
                    transcript: liveTranscript,
                    durationSeconds: elapsedSeconds
                )
            } else {
                // Load duration from existing session if we have one
                elapsedSeconds = currentSession?.durationSeconds ?? elapsedSeconds
            }
        } else {
            // NEW SESSION: Reset everything
            print("[TranscriptViewModel] Starting fresh session")
            liveTranscript = ""
            analysis = nil
            conversationHistory = []
            currentSession = nil
            elapsedSeconds = 0
            sessionStartTime = now
        }
        
        // Start Apple Speech Recognition
        let started = sttService.startTranscription()
        guard started else {
            errorMessage = "Failed to start speech recognition"
            return
        }
        
        isSessionActive = true
        startDurationTimer()
        print("[TranscriptViewModel] Recording started")
    }
    
    private func shouldChainToExistingSession(currentTime: Date) -> Bool {
        // Chain if:
        // 1. We have a session start time
        // 2. We're within the 1-hour window
        // 3. We have some existing content (transcript or analysis)
        guard let startTime = sessionStartTime else { return false }
        let elapsed = currentTime.timeIntervalSince(startTime)
        let hasExistingContent = !liveTranscript.isEmpty || analysis != nil
        return elapsed < sessionChainWindowSeconds && hasExistingContent
    }
    
    func endSession() async {
        guard isSessionActive else { return }
        
        stopDurationTimer()
        sttService.stopTranscription()
        
        let transcript = liveTranscript
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("TRANSCRIPT (\(transcript.count) chars)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        isSessionActive = false
        hasTranscriptToAnalyze = !transcript.isEmpty
        
        if transcript.isEmpty {
            errorMessage = "No speech detected. Try speaking closer to the microphone."
        } else {
            // Update or create session
            if currentSession != nil {
                currentSession?.transcript = transcript
                currentSession?.durationSeconds = elapsedSeconds
            } else {
                currentSession = RecordingSession(
                    transcript: transcript,
                    durationSeconds: elapsedSeconds
                )
            }
        }
        
        print("[TranscriptViewModel] Recording stopped - ready for analysis or more recording")
    }
    
    func cancelSession() {
        stopDurationTimer()
        sttService.stopTranscription()
        isSessionActive = false
        // Don't clear transcript - user might want to resume
    }
    
    /// Completely discard current session and start fresh
    func discardRecording() {
        liveTranscript = ""
        analysis = nil
        hasTranscriptToAnalyze = false
        currentSession = nil
        conversationHistory = []
        errorMessage = nil
        elapsedSeconds = 0
        sessionStartTime = nil // Reset the chain window
    }
    
    /// Start a new recording - checks if we should chain or start fresh
    func startNewRecording() {
        // This is called from "New Recording" button
        // Check if within chain window - if so, just ready the mic
        // If outside window, clear everything
        let now = Date()
        if !shouldChainToExistingSession(currentTime: now) {
            discardRecording()
        }
        // Either way, user can now tap mic to record
    }
    
    // MARK: - Timer
    
    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    // MARK: - OpenAI Analysis
    
    func analyzeWithRoundsAI() async {
        guard !liveTranscript.isEmpty else {
            errorMessage = "No transcript to analyze"
            return
        }
        
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        do {
            let result = try await openAIService.analyzeTranscript(liveTranscript)
            analysis = result
            hasTranscriptToAnalyze = false
            
            // Update session with analysis
            currentSession?.aiExplanation = result.explanation
            currentSession?.keyPoints = result.summaryPoints
            currentSession?.followUpQuestions = result.followUpQuestions
            currentSession?.analysis = result
            
            if let session = currentSession {
                sessionStore.saveSession(session)
            }
            
            print("[TranscriptViewModel] Analysis complete")
        } catch {
            errorMessage = error.localizedDescription
            print("[TranscriptViewModel] Analysis failed: \(error)")
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Follow-up Conversation
    
    func askFollowUp(_ question: String) async {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isAnalyzing else { return }
        guard let explanation = analysis?.explanation else {
            errorMessage = "Please analyze the transcript first"
            return
        }
        
        isAnalyzing = true
        errorMessage = nil
        
        let userMessage = ConversationMessage(isUser: true, content: question)
        conversationHistory.append(userMessage)
        
        do {
            let response = try await openAIService.askFollowUp(
                question: question,
                transcript: liveTranscript,
                previousExplanation: explanation,
                conversationHistory: conversationHistory
            )
            
            let aiMessage = ConversationMessage(isUser: false, content: response)
            conversationHistory.append(aiMessage)
            
            currentSession?.conversationHistory = conversationHistory
            if let session = currentSession {
                sessionStore.saveSession(session)
            }
        } catch {
            conversationHistory.removeLast()
            errorMessage = error.localizedDescription
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Load Previous Session
    
    func loadSession(_ session: RecordingSession) {
        liveTranscript = session.transcript
        elapsedSeconds = session.durationSeconds
        currentSession = session
        conversationHistory = session.conversationHistory
        sessionStartTime = session.startTime // Restore chain window
        
        if let explanation = session.aiExplanation {
            analysis = RoundsAnalysis(
                explanation: explanation,
                summaryPoints: session.keyPoints,
                followUpQuestions: session.followUpQuestions
            )
            hasTranscriptToAnalyze = false
        } else {
            analysis = nil
            hasTranscriptToAnalyze = true
        }
        
        errorMessage = nil
        isSessionActive = false
    }
    
    // MARK: - Computed Properties
    
    var formattedDuration: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Whether we're in an active session chain (can append more recordings)
    var isInSessionChain: Bool {
        guard let startTime = sessionStartTime else { return false }
        return Date().timeIntervalSince(startTime) < sessionChainWindowSeconds
    }
}
