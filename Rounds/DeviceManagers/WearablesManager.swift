import Foundation
import Combine
import AVFoundation
import UIKit
import MWDATCore

/// Connection state for the Meta glasses (wrapper around SDK RegistrationState)
enum GlassesConnectionState: Equatable {
    case unavailable
    case available
    case registering
    case registered
    case notReady(NotReadyReason)  // Glasses/Meta AI app not ready (soft state, not an error)
    case error(String)             // Real configuration error (plist/portal issue)

    var isConnected: Bool {
        self == .registered
    }

    var isNotReady: Bool {
        if case .notReady = self { return true }
        return false
    }
}

/// Reasons why glasses aren't ready (distinct from hard errors)
enum NotReadyReason: Equatable {
    case metaViewNotInstalled
    case glassesNotPaired
    case glassesNotConnected
    case glassesAsleep
    case unknown

    var userMessage: String {
        switch self {
        case .metaViewNotInstalled:
            return "Meta AI app not installed. Install it from the App Store to continue."
        case .glassesNotPaired:
            return "Glasses not paired. Open Meta AI and pair your glasses first."
        case .glassesNotConnected, .glassesAsleep, .unknown:
            return "Glasses not connected yet. Open Meta AI, wake your glasses, then tap Connect Glasses."
        }
    }
}

/// Model representing glasses device info
enum GlassesModel: String {
    case rayBanMeta = "Ray-Ban Meta"
    case unknown = "Unknown Device"
}

/// Connected glasses device information
struct ConnectedGlasses: Identifiable {
    let id: String
    let name: String
    let model: GlassesModel
    let batteryLevel: Int?

    init(id: String, name: String, model: GlassesModel = .rayBanMeta, batteryLevel: Int? = nil) {
        self.id = id
        self.name = name
        self.model = model
        self.batteryLevel = batteryLevel
    }
}

/// WearablesManager is the SOLE interface for all Meta glasses interactions.
/// Uses MWDATCore SDK v0.2.1 for device registration and management.
@MainActor
final class WearablesManager: ObservableObject {

    // MARK: - Singleton

    static let shared = WearablesManager()

    // MARK: - Published State

    @Published private(set) var connectionState: GlassesConnectionState = .unavailable
    @Published private(set) var connectedDevice: ConnectedGlasses?
    @Published private(set) var availableDevices: [ConnectedGlasses] = []
    @Published private(set) var isAudioStreaming: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - SDK Interface

    private var wearables: (any WearablesInterface)?

    // MARK: - Task Management

    private var registrationStateTask: Task<Void, Never>?
    private var devicesTask: Task<Void, Never>?

    // MARK: - Audio Callbacks

    /// Called when audio buffers are received from the glasses.
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    /// Called when the glasses connection is ready for audio streaming.
    var onConnectionReady: (() -> Void)?

    // MARK: - Initialization

    init() {
        print("[WearablesManager] Initialized")
    }

    deinit {
        registrationStateTask?.cancel()
        devicesTask?.cancel()
    }

    // MARK: - SDK Configuration

    /// Configure the MWDATCore SDK. Call this once at app launch.
    func configure() {
        print("[WearablesManager] === SDK Configuration Starting ===")
        logMetaAIStatus()

        do {
            try Wearables.configure()
            wearables = Wearables.shared
            print("[WearablesManager] ✅ MWDATCore SDK configured successfully")
            setupRegistrationStateObserver()
        } catch let error as WearablesError {
            handleWearablesConfigError(error)
        } catch {
            print("[WearablesManager] ❌ Non-WearablesError: \(type(of: error)) - \(error.localizedDescription)")
            connectionState = .error("SDK configuration failed: \(error)")
        }
    }

    /// Known URL schemes for Meta AI app (handles glasses pairing/auth)
    private static let metaAISchemes = ["fb-orca://", "fb-messenger-api://", "metaai://"]

    /// Log Meta AI app installation status
    private func logMetaAIStatus() {
        // Check if Meta AI app can be opened (requires LSApplicationQueriesSchemes in Info.plist)
        var canOpenMetaAI = false

        for scheme in Self.metaAISchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                print("[WearablesManager] 📱 Meta AI detected via scheme: \(scheme)")
                canOpenMetaAI = true
                break
            }
        }

        if !canOpenMetaAI {
            print("[WearablesManager] ⚠️ Meta AI app not detected (may need LSApplicationQueriesSchemes or app not installed)")
        }
    }

    /// Handle WearablesError during configuration - distinguishes soft "not ready" from hard errors
    private func handleWearablesConfigError(_ error: WearablesError) {
        print("[WearablesManager] === WearablesError Analysis ===")
        print("[WearablesManager] rawValue: \(error.rawValue)")
        print("[WearablesManager] localizedDescription: \(error.localizedDescription)")

        // Error code analysis based on MWDATCore SDK patterns:
        // - rawValue 2 (configurationError): Often means glasses not available/connected
        // - Other codes may indicate actual plist/portal misconfiguration

        switch error.rawValue {
        case 2:
            // configurationError (2) - Most commonly: glasses not ready
            // This is a SOFT failure - the SDK config itself is likely correct
            print("[WearablesManager] ⚠️ configurationError(2): Likely glasses not ready")
            print("[WearablesManager] 💡 Diagnosis: Glasses may be asleep/unpaired, or Meta AI app not installed")

            let reason = diagnoseNotReadyReason()
            connectionState = .notReady(reason)
            print("[WearablesManager] 📋 State set to: notReady(\(reason))")

        case 1:
            // Often: plist misconfiguration or missing App ID
            print("[WearablesManager] ❌ Error code 1: Possible plist/App ID misconfiguration")
            connectionState = .error("App configuration error. Check MetaAppID in Info.plist.")

        case 3:
            // Network or auth related
            print("[WearablesManager] ❌ Error code 3: Network/auth error")
            connectionState = .notReady(.unknown) // Treat as soft failure

        default:
            // Unknown error code - treat as hard error to be safe
            print("[WearablesManager] ❌ Unknown error code \(error.rawValue)")
            connectionState = .error("SDK error (code \(error.rawValue)): \(error.localizedDescription)")
        }
    }

    /// Attempt to diagnose why glasses aren't ready
    private func diagnoseNotReadyReason() -> NotReadyReason {
        // Check Meta AI app installation via URL schemes
        var metaAIInstalled = false

        for scheme in Self.metaAISchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                metaAIInstalled = true
                break
            }
        }

        if !metaAIInstalled {
            print("[WearablesManager] 🔍 Diagnosis: Meta AI app appears not installed")
            return .metaViewNotInstalled  // Reusing enum case, means "Meta AI not installed"
        }

        // Meta AI is installed but SDK still failed - likely glasses not connected/paired/awake
        print("[WearablesManager] 🔍 Diagnosis: Meta AI installed, but glasses likely not connected/awake")
        return .glassesNotConnected
    }

    // MARK: - Registration State Observation

    private func setupRegistrationStateObserver() {
        guard let wearables = wearables else { return }

        registrationStateTask?.cancel()
        registrationStateTask = Task { [weak self] in
            for await state in wearables.registrationStateStream() {
                await self?.handleRegistrationStateChange(state)
            }
        }
    }

    private func handleRegistrationStateChange(_ state: RegistrationState) {
        print("[WearablesManager] Registration state changed: \(state.description)")

        switch state {
        case .unavailable:
            connectionState = .unavailable
            connectedDevice = nil
            availableDevices = []
            devicesTask?.cancel()

        case .available:
            connectionState = .available
            connectedDevice = nil
            availableDevices = []
            devicesTask?.cancel()

        case .registering:
            connectionState = .registering

        case .registered:
            connectionState = .registered
            setupDevicesObserver()
            onConnectionReady?()
        }
    }

    // MARK: - Device Discovery

    private func setupDevicesObserver() {
        guard let wearables = wearables else { return }

        devicesTask?.cancel()
        devicesTask = Task { [weak self] in
            for await deviceIds in wearables.devicesStream() {
                await self?.handleDevicesUpdate(deviceIds)
            }
        }
    }

    private func handleDevicesUpdate(_ deviceIdentifiers: [DeviceIdentifier]) {
        print("[WearablesManager] Devices updated: \(deviceIdentifiers.count) device(s)")

        // DeviceIdentifier is a String typealias
        availableDevices = deviceIdentifiers.map { deviceId in
            // Try to get device info from SDK
            let device = wearables?.deviceForIdentifier(deviceId)
            let name = device?.nameOrId() ?? deviceId

            return ConnectedGlasses(
                id: deviceId,
                name: name,
                model: mapToGlassesModel(name: name),
                batteryLevel: nil
            )
        }

        // Update connected device if we have devices
        if let firstDevice = availableDevices.first {
            connectedDevice = firstDevice
        } else {
            connectedDevice = nil
        }
    }

    // MARK: - Registration Control

    /// Start the registration process to connect Meta glasses
    func startRegistration() {
        guard let wearables = wearables else {
            handleError("SDK not configured", context: "registration")
            return
        }

        guard connectionState == .available || connectionState.isError else {
            print("[WearablesManager] Cannot start registration in current state: \(connectionState)")
            return
        }

        print("[WearablesManager] Starting registration...")

        do {
            try wearables.startRegistration()
        } catch {
            handleError(error, context: "registration")
        }
    }

    /// Start unregistration to disconnect Meta glasses
    func startUnregistration() {
        guard let wearables = wearables else {
            handleError("SDK not configured", context: "unregistration")
            return
        }

        guard connectionState == .registered else {
            print("[WearablesManager] Not registered, cannot unregister")
            return
        }

        print("[WearablesManager] Starting unregistration...")
        stopAudioStream()

        do {
            try wearables.startUnregistration()
        } catch {
            handleError(error, context: "unregistration")
        }
    }

    /// Handle incoming URL callbacks from Meta app (for OAuth flow)
    func handleURL(_ url: URL) async {
        guard let wearables = wearables else { return }

        print("[WearablesManager] Handling callback URL...")

        do {
            _ = try await wearables.handleUrl(url)
        } catch {
            handleError(error, context: "URL handling")
        }
    }

    // MARK: - Legacy API Compatibility (for existing UI)

    /// Start scanning - maps to startRegistration for legacy compatibility
    func startScanning() {
        startRegistration()
    }

    /// Stop scanning - no-op for SDK-based registration
    func stopScanning() {
        // Registration is handled by the Meta app, no manual stop needed
        print("[WearablesManager] Stopped scanning (no-op)")
    }

    /// Connect to device - already handled by registration flow
    func connect(to device: ConnectedGlasses) {
        // In MWDATCore SDK, connection is automatic after registration
        print("[WearablesManager] Device selection: \(device.name)")
        connectedDevice = device
    }

    /// Disconnect from device - maps to unregistration
    func disconnect() {
        startUnregistration()
    }

    // MARK: - Audio Streaming

    func startAudioStream() {
        guard connectionState == .registered else {
            print("[WearablesManager] Cannot start audio: not registered")
            return
        }

        guard connectedDevice != nil else {
            print("[WearablesManager] Cannot start audio: no connected device")
            return
        }

        isAudioStreaming = true
        print("[WearablesManager] Audio streaming started")

        // TODO: Implement audio streaming when MWDATCore audio APIs are available
        // The current SDK (v0.2.1) focuses on camera streaming; audio may require different approach
    }

    func stopAudioStream() {
        isAudioStreaming = false
        print("[WearablesManager] Audio streaming stopped")
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, context: String) {
        let message = "Error during \(context): \(error.localizedDescription)"
        print("[WearablesManager] \(message)")

        errorMessage = message
        showError = true
        connectionState = .error(message)
    }

    private func handleError(_ message: String, context: String) {
        let fullMessage = "Error during \(context): \(message)"
        print("[WearablesManager] \(fullMessage)")

        errorMessage = fullMessage
        showError = true
        connectionState = .error(fullMessage)
    }

    func dismissError() {
        showError = false
        errorMessage = ""

        // Reset to available state after error if SDK is configured
        if case .error = connectionState {
            connectionState = wearables != nil ? .available : .unavailable
        }
    }

    /// Retry SDK configuration (call after user connects glasses in Meta AI app)
    func retryConfiguration() {
        print("[WearablesManager] 🔄 Retrying SDK configuration...")
        connectionState = .unavailable
        wearables = nil
        configure()
    }

    /// Open Meta AI app if installed
    func openMetaAI() {
        for scheme in Self.metaAISchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                print("[WearablesManager] 📱 Opening Meta AI via \(scheme)")
                UIApplication.shared.open(url)
                return
            }
        }

        // Fallback to App Store
        print("[WearablesManager] 📱 Meta AI not found, opening App Store")
        if let appStoreURL = URL(string: "https://apps.apple.com/app/meta-ai/id6468739428") {
            UIApplication.shared.open(appStoreURL)
        }
    }

    // MARK: - Helpers

    private func mapToGlassesModel(name: String) -> GlassesModel {
        let lowercased = name.lowercased()
        if lowercased.contains("ray-ban") || lowercased.contains("meta") || lowercased.contains("wayfarer") {
            return .rayBanMeta
        }
        return .unknown
    }
}

// MARK: - GlassesConnectionState Extensions

extension GlassesConnectionState {
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
