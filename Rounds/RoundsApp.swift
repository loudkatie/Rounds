import SwiftUI

@main
struct RoundsApp: App {

    init() {
        // Configure MWDATCore SDK at app launch via WearablesManager
        WearablesManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle OAuth callback from Meta app
                    Task { @MainActor in
                        await WearablesManager.shared.handleURL(url)
                    }
                }
        }
    }
}
