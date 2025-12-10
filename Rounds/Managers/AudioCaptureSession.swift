import Foundation
import AVFoundation
import Speech
import WearablesDeviceAccess

@MainActor
final class AudioCaptureSession: NSObject, ObservableObject {
    @Published private(set) var isCapturing = false
    @Published private(set) var audioLevel: Float = 0

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private weak var audioStream: AudioStream?

    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Audio Session Setup

    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        // Configure for Bluetooth audio input from glasses
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.allowBluetooth, .allowBluetoothA2DP]
        )

        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        print("[AudioCapture] Audio session configured for glasses input")
    }

    // MARK: - Glasses Audio Stream

    /// Start capturing audio from the glasses audio stream
    /// - Parameters:
    ///   - session: The wearable device session containing the audio stream
    ///   - recognitionRequest: The speech recognition request to receive audio buffers
    func startCapture(from session: WearableDeviceSession, with recognitionRequest: SFSpeechAudioBufferRecognitionRequest?) {
        guard !isCapturing else { return }

        self.recognitionRequest = recognitionRequest
        self.audioStream = session.audioStream

        do {
            try configureAudioSession()

            // Set ourselves as the audio stream delegate
            session.audioStream.delegate = self
            session.audioStream.start()

            isCapturing = true
            print("[AudioCapture] Started capturing from glasses audio stream")

        } catch {
            print("[AudioCapture] Failed to start: \(error.localizedDescription)")
        }
    }

    func stopCapture() {
        guard isCapturing else { return }

        // Stop and clean up the glasses audio stream
        audioStream?.stop()
        audioStream?.delegate = nil
        audioStream = nil

        recognitionRequest = nil

        isCapturing = false
        audioLevel = 0
        print("[AudioCapture] Stopped capturing from glasses")
    }

    // MARK: - Audio Level Metering

    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }

        let average = sum / Float(frameLength)
        let level = min(max(average * 10, 0), 1)

        Task { @MainActor in
            self.audioLevel = level
        }
    }
}

// MARK: - AudioStreamDelegate

extension AudioCaptureSession: AudioStreamDelegate {
    nonisolated func audioStream(_ stream: AudioStream, didReceive buffer: AVAudioPCMBuffer) {
        // Forward buffer to speech recognition
        recognitionRequest?.append(buffer)

        // Notify any external listeners
        onAudioBuffer?(buffer)

        // Update audio level meter
        updateAudioLevel(buffer: buffer)
    }

    nonisolated func audioStream(_ stream: AudioStream, didEncounterError error: Error) {
        print("[AudioCapture] Audio stream error: \(error.localizedDescription)")

        Task { @MainActor in
            self.isCapturing = false
            self.audioLevel = 0
        }
    }
}
