import SwiftUI

@main
struct RoundsApp: App {

    init() {
        // Configure MWDATCore SDK at app launch via WearablesManager
        WearablesManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    // Handle OAuth callback from Meta app (for glasses pairing)
                    Task { @MainActor in
                        await WearablesManager.shared.handleURL(url)
                    }
                }
        }
    }
}
