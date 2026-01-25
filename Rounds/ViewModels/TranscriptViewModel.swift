//
//  TranscriptViewModel.swift
//  Rounds AI
//
//  Core ViewModel - Uses Apple Speech Recognition + OpenAI for analysis
//  NO Meta glasses, NO ElevenLabs - pure native iOS
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
                self?.liveTranscript = text
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
        
        // Reset state
        liveTranscript = ""
        analysis = nil
        conversationHistory = []
        currentSession = nil
        errorMessage = nil
        elapsedSeconds = 0
        
        // Start Apple Speech Recognition
        let started = sttService.startTranscription()
        guard started else {
            errorMessage = "Failed to start speech recognition"
            return
        }
        
        isSessionActive = true
        startDurationTimer()
        print("[TranscriptViewModel] Session started with Apple Speech Recognition")
    }
    
    func endSession() async {
        guard isSessionActive else { return }
        
        stopDurationTimer()
        sttService.stopTranscription()
        
        let transcript = liveTranscript
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("FINAL TRANSCRIPT: \(transcript)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        isSessionActive = false
        hasTranscriptToAnalyze = !transcript.isEmpty
        
        if transcript.isEmpty {
            errorMessage = "No speech detected. Try speaking closer to the microphone."
        } else {
            currentSession = RecordingSession(
                transcript: transcript,
                durationSeconds: elapsedSeconds
            )
        }
        
        print("[TranscriptViewModel] Session ended - transcript ready for analysis")
    }
    
    func cancelSession() {
        stopDurationTimer()
        sttService.stopTranscription()
        liveTranscript = ""
        isSessionActive = false
        elapsedSeconds = 0
        analysis = nil
        hasTranscriptToAnalyze = false
        currentSession = nil
        conversationHistory = []
    }
    
    func discardRecording() {
        liveTranscript = ""
        analysis = nil
        hasTranscriptToAnalyze = false
        currentSession = nil
        conversationHistory = []
        errorMessage = nil
        elapsedSeconds = 0
    }
    
    func startNewRecording() {
        discardRecording()
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
}
