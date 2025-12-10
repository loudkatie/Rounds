import Foundation
import Combine
import WearablesDeviceAccess
import AVFoundation

enum GlassesConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)
}

enum GlassesModel: String {
    case rayBanMeta = "Ray-Ban Meta"
    case unknown = "Unknown Device"
}

struct ConnectedGlasses {
    let id: String
    let name: String
    let model: GlassesModel
    let batteryLevel: Int?
    let wearableDevice: WearableDevice?

    init(id: String, name: String, model: GlassesModel, batteryLevel: Int?, wearableDevice: WearableDevice? = nil) {
        self.id = id
        self.name = name
        self.model = model
        self.batteryLevel = batteryLevel
        self.wearableDevice = wearableDevice
    }
}

@MainActor
final class GlassesSessionManager: NSObject, ObservableObject {
    @Published private(set) var connectionState: GlassesConnectionState = .disconnected
    @Published private(set) var connectedDevice: ConnectedGlasses?
    @Published private(set) var availableDevices: [ConnectedGlasses] = []

    private var currentSession: WearableDeviceSession?
    private var pendingDevice: WearableDevice?

    var onAudioStreamReady: ((WearableDeviceSession) -> Void)?

    // MARK: - Initialization

    override init() {
        super.init()
        WearablesManager.shared.delegate = self
    }

    // MARK: - Discovery

    func startScanning() {
        connectionState = .scanning
        availableDevices = []

        do {
            try WearablesManager.shared.startDiscovery()
            print("[GlassesSession] Started discovery")
        } catch {
            connectionState = .error("Failed to start discovery: \(error.localizedDescription)")
            print("[GlassesSession] Discovery error: \(error)")
        }
    }

    func stopScanning() {
        WearablesManager.shared.stopDiscovery()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
        print("[GlassesSession] Stopped discovery")
    }

    // MARK: - Connection

    func connect(to device: ConnectedGlasses) {
        guard let wearableDevice = device.wearableDevice else {
            connectionState = .error("Invalid device reference")
            return
        }

        connectionState = .connecting
        pendingDevice = wearableDevice

        do {
            try WearablesManager.shared.connect(to: wearableDevice)
            print("[GlassesSession] Connecting to \(device.name)")
        } catch {
            connectionState = .error("Connection failed: \(error.localizedDescription)")
            print("[GlassesSession] Connection error: \(error)")
        }
    }

    func disconnect() {
        if let session = currentSession {
            session.audioStream.stop()
            session.audioStream.delegate = nil
        }

        if let device = connectedDevice?.wearableDevice {
            WearablesManager.shared.disconnect(from: device)
        }

        currentSession = nil
        connectedDevice = nil
        connectionState = .disconnected
        print("[GlassesSession] Disconnected")
    }

    // MARK: - Session Management

    private func setupSession(for device: WearableDevice) {
        guard let session = WearablesManager.shared.session(for: device) else {
            connectionState = .error("Failed to obtain session")
            return
        }

        currentSession = session
        print("[GlassesSession] Session established, audio stream ready")

        // Notify that audio stream is ready
        onAudioStreamReady?(session)
    }

    // MARK: - Helper

    private func mapToGlassesModel(_ device: WearableDevice) -> GlassesModel {
        let name = device.name.lowercased()
        if name.contains("ray-ban") || name.contains("meta") {
            return .rayBanMeta
        }
        return .unknown
    }
}

// MARK: - WearablesManagerDelegate

extension GlassesSessionManager: WearablesManagerDelegate {
    nonisolated func wearablesManager(_ manager: WearablesManager, didDiscover device: WearableDevice) {
        Task { @MainActor in
            let glasses = ConnectedGlasses(
                id: device.identifier.uuidString,
                name: device.name,
                model: mapToGlassesModel(device),
                batteryLevel: nil,
                wearableDevice: device
            )

            if !availableDevices.contains(where: { $0.id == glasses.id }) {
                availableDevices.append(glasses)
                print("[GlassesSession] Discovered device: \(device.name)")
            }
        }
    }

    nonisolated func wearablesManager(_ manager: WearablesManager, didConnect device: WearableDevice) {
        Task { @MainActor in
            let glasses = ConnectedGlasses(
                id: device.identifier.uuidString,
                name: device.name,
                model: mapToGlassesModel(device),
                batteryLevel: nil,
                wearableDevice: device
            )

            connectedDevice = glasses
            connectionState = .connected
            print("[GlassesSession] Connected to \(device.name)")

            setupSession(for: device)
        }
    }

    nonisolated func wearablesManager(_ manager: WearablesManager, didDisconnect device: WearableDevice, error: Error?) {
        Task { @MainActor in
            if let error = error {
                connectionState = .error("Disconnected: \(error.localizedDescription)")
                print("[GlassesSession] Disconnected with error: \(error)")
            } else {
                connectionState = .disconnected
                print("[GlassesSession] Disconnected cleanly")
            }

            currentSession = nil
            connectedDevice = nil
        }
    }

    nonisolated func wearablesManager(_ manager: WearablesManager, didFailToConnect device: WearableDevice, error: Error) {
        Task { @MainActor in
            connectionState = .error("Connection failed: \(error.localizedDescription)")
            pendingDevice = nil
            print("[GlassesSession] Failed to connect: \(error)")
        }
    }
}
