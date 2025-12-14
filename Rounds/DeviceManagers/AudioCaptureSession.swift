import Foundation
import AVFoundation

@MainActor
final class AudioCaptureSession: NSObject, ObservableObject {
    @Published private(set) var isCapturing = false
    @Published private(set) var audioLevel: Float = 0

    private let audioEngine = AVAudioEngine()
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Audio Session Setup

    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker]
        )

        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        print("[AudioCapture] Audio session configured for iPhone mic")
    }

    // MARK: - iPhone Microphone Capture

    func startCapture() {
        guard !isCapturing else { return }

        do {
            try configureAudioSession()

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.onAudioBuffer?(buffer)
                self?.updateAudioLevel(buffer: buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isCapturing = true
            print("[AudioCapture] Started capturing from iPhone mic")

        } catch {
            print("[AudioCapture] Failed to start: \(error.localizedDescription)")
        }
    }

    func stopCapture() {
        guard isCapturing else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        isCapturing = false
        audioLevel = 0
        print("[AudioCapture] Stopped capturing from iPhone mic")
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
