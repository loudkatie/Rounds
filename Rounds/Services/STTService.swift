import Foundation
import Speech
import AVFoundation

@MainActor
final class STTService: ObservableObject {
    @Published private(set) var isTranscribing = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onTranscriptUpdate: ((String) -> Void)?

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    func startTranscription() -> SFSpeechAudioBufferRecognitionRequest? {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("[STTService] Speech recognizer not available")
            return nil
        }

        stopTranscription()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return nil }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.onTranscriptUpdate?(transcribedText)
                }
            }

            if let error = error {
                print("[STTService] Recognition error: \(error.localizedDescription)")
            }

            if result?.isFinal == true {
                Task { @MainActor in
                    self.stopTranscription()
                }
            }
        }

        isTranscribing = true
        return recognitionRequest
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stopTranscription() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }
}
