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

/// Reasons why Wearables.configure() failed (WearablesError codes)
enum NotReadyReason: Equatable {
    case authorizationMissing  // Error(2): App not authorized in Wearables Developer Center / tester not on release channel
    case configurationError    // Error(1): Plist misconfiguration or missing App ID
    case networkError          // Error(3): Network or auth related
    case unknown

    var userMessage: String {
        switch self {
        case .authorizationMissing:
            return "App not authorized for Device Access. Verify in Wearables Developer Center that:\n• App is linked to a DAT project\n• Your Meta account is added as a tester\n• Device Access is enabled"
        case .configurationError:
            return "App configuration error. Check MetaAppID and bundle ID in Info.plist match the Meta App Console."
        case .networkError:
            return "Network or authentication error. Make sure glasses are paired in Meta AI and awake, then try again."
        case .unknown:
            return "Make sure glasses are paired in Meta AI and awake, then try again."
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
        logAppConfiguration()

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

    /// Log app configuration for debugging portal issues
    private func logAppConfiguration() {
        let bundleId = Bundle.main.bundleIdentifier ?? "UNKNOWN"
        let mwdatConfig = Bundle.main.object(forInfoDictionaryKey: "MWDAT") as? [String: Any]
        let metaAppID = mwdatConfig?["MetaAppID"] as? String ?? "NOT SET"
        let appLinkScheme = mwdatConfig?["AppLinkURLScheme"] as? String ?? "NOT SET"

        print("[WearablesManager] 📋 App Configuration:")
        print("[WearablesManager]    Bundle ID: \(bundleId)")
        print("[WearablesManager]    MetaAppID: \(metaAppID)")
        print("[WearablesManager]    AppLinkURLScheme: \(appLinkScheme)")
        print("[WearablesManager]    (Compare these values against Meta App Console & Wearables Developer Center)")
    }

    /// Handle WearablesError during configuration
    /// Error code 2 typically means: app not authorized in Wearables Developer Center,
    /// tester not added to release channel, or account mismatch.
    private func handleWearablesConfigError(_ error: WearablesError) {
        print("[WearablesManager] === WearablesError Analysis ===")
        print("[WearablesManager] rawValue: \(error.rawValue)")
        print("[WearablesManager] localizedDescription: \(error.localizedDescription)")

        // Re-log config for easy comparison in console
        logAppConfiguration()

        switch error.rawValue {
        case 2:
            // configurationError (2) - Authorization / release channel issue
            // NOT "glasses not ready" - this is a portal configuration problem
            print("[WearablesManager] ❌ Error(2): AUTHORIZATION MISSING")
            print("[WearablesManager] 🔍 Likely causes:")
            print("[WearablesManager]    • App not linked to DAT project in Wearables Developer Center")
            print("[WearablesManager]    • Your Meta account not added as tester on release channel")
            print("[WearablesManager]    • Device Access not enabled for the project")
            print("[WearablesManager]    • Bundle ID mismatch with Meta App Console iOS platform")
            print("[WearablesManager]    • MetaAppID mismatch")
            connectionState = .notReady(.authorizationMissing)

        case 1:
            // Plist misconfiguration or missing App ID
            print("[WearablesManager] ❌ Error(1): Configuration error (plist/AppID)")
            connectionState = .notReady(.configurationError)

        case 3:
            // Network or auth related
            print("[WearablesManager] ❌ Error(3): Network/auth error")
            connectionState = .notReady(.networkError)

        default:
            // Unknown error code
            print("[WearablesManager] ❌ Unknown error code \(error.rawValue)")
            connectionState = .notReady(.unknown)
        }
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

    /// Open Meta AI App Store page
    /// Note: We don't try to deep-link to Meta AI via URL schemes - the SDK/OS handles companion flow.
    /// This is just a convenience for users who need to install/open Meta AI.
    func openMetaAIAppStore() {
        print("[WearablesManager] 📱 Opening Meta AI in App Store")
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
