import Foundation
import Combine
import Speech

@MainActor
final class TranscriptViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentEpisode: RoundsEpisode?
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var isSessionActive = false
    @Published private(set) var isGeneratingSummary = false
    @Published private(set) var summary: EpisodeSummary?
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    var wearablesManager: WearablesManager
    let audioCapture: AudioCaptureSession
    let sttService: STTService
    private let llamaService = LlamaAgentService.shared

    private var lastCommittedText: String = ""

    // MARK: - Initialization

    init() {
        self.wearablesManager = WearablesManager.shared
        self.audioCapture = AudioCaptureSession()
        self.sttService = STTService()

        setupBindings()
    }

    private func setupBindings() {
        sttService.onTranscriptUpdate = { [weak self] text in
            Task { @MainActor in
                self?.liveTranscript = text
            }
        }

        wearablesManager.onConnectionReady = { [weak self] in
            Task { @MainActor in
                print("[TranscriptViewModel] Glasses connection ready")
            }
        }
    }

    // MARK: - Session Control

    func startSession() async {
        guard !isSessionActive else { return }

        // Request speech recognition permission
        let authorized = await sttService.requestAuthorization()
        guard authorized else {
            errorMessage = "Speech recognition permission denied"
            return
        }

        // Create new episode
        currentEpisode = RoundsEpisode()
        liveTranscript = ""
        lastCommittedText = ""
        summary = nil
        errorMessage = nil

        // Start STT
        _ = sttService.startTranscription()

        // Start audio capture from iPhone mic
        audioCapture.startCapture()

        isSessionActive = true
    }

    func endSession() async {
        guard isSessionActive else { return }

        // Stop capture and transcription
        audioCapture.stopCapture()
        sttService.stopTranscription()

        // Commit final transcript
        if !liveTranscript.isEmpty {
            commitTranscriptEntry(text: liveTranscript)
        }

        // Finalize episode
        currentEpisode?.endTime = Date()

        isSessionActive = false

        // Generate summary
        await generateSummary()
    }

    func cancelSession() {
        audioCapture.stopCapture()
        sttService.stopTranscription()
        currentEpisode = nil
        liveTranscript = ""
        isSessionActive = false
    }

    // MARK: - Transcript Management

    private func commitTranscriptEntry(text: String) {
        guard !text.isEmpty, text != lastCommittedText else { return }

        let entry = TranscriptEntry(text: text)
        currentEpisode?.transcript.append(entry)
        lastCommittedText = text
    }

    // MARK: - Summary Generation

    private func generateSummary() async {
        guard let episode = currentEpisode else { return }

        let transcriptText = episode.fullTranscriptText
        guard !transcriptText.isEmpty else {
            errorMessage = "No transcript to summarize"
            return
        }

        isGeneratingSummary = true

        do {
            let generatedSummary = try await llamaService.generateSummary(from: transcriptText)
            self.summary = generatedSummary
            self.currentEpisode?.summary = generatedSummary
        } catch {
            errorMessage = "Failed to generate summary: \(error.localizedDescription)"
        }

        isGeneratingSummary = false
    }

    // MARK: - Computed Properties

    var sessionDuration: TimeInterval {
        guard let episode = currentEpisode else { return 0 }
        let endTime = episode.endTime ?? Date()
        return endTime.timeIntervalSince(episode.startTime)
    }

    var formattedDuration: String {
        let duration = sessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
