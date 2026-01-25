//
//  STTService.swift
//  Rounds AI
//
//  Native Apple Speech Recognition Service
//  Uses on-device speech recognition for real-time transcription
//

import Foundation
import Speech
import AVFoundation

@MainActor
final class STTService: ObservableObject {
    @Published private(set) var isTranscribing = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published private(set) var finalTranscript: String = ""

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onTranscriptUpdate: ((String) -> Void)?

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        // Request speech recognition permission
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
        
        guard speechAuthorized else { return false }
        
        // Also request microphone permission
        let micAuthorized = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        return micAuthorized
    }

    func startTranscription() -> Bool {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("[STTService] Speech recognizer not available")
            return false
        }

        cancelTranscription()
        finalTranscript = ""

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[STTService] Audio session error: \(error)")
            return false
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return false }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.finalTranscript = transcribedText
                    self.onTranscriptUpdate?(transcribedText)
                }
            }

            if let error = error {
                print("[STTService] Recognition error: \(error.localizedDescription)")
            }
        }

        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isTranscribing = true
            print("[STTService] Started transcription with Apple Speech Recognition")
            return true
        } catch {
            print("[STTService] Audio engine start error: \(error)")
            cleanup()
            return false
        }
    }

    func stopTranscription() {
        guard isTranscribing else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        // Give it a moment to finalize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.cleanup()
        }
        
        print("[STTService] Stopped transcription")
    }
    
    func cancelTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        cleanup()
    }

    private func cleanup() {
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
