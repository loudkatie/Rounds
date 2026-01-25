//
//  RootView.swift
//  Rounds
//
//  Navigation controller. Clean, simple state management.
//  
//  States:
//  1. Splash (2 seconds)
//  2. Onboarding (if no profile exists)
//  3. Main app (recording interface)
//

import SwiftUI

struct RootView: View {
    
    // MARK: - State
    
    @ObservedObject private var profileStore = ProfileStore.shared
    @StateObject private var viewModel = TranscriptViewModel()
    
    @State private var showSplash = true
    
    // DEBUG: Set to true to force onboarding even if profile exists
    private let forceShowOnboarding = false
    
    // MARK: - Computed
    
    private var shouldShowOnboarding: Bool {
        forceShowOnboarding || !profileStore.hasCompletedOnboarding
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Base layer: Main app (always rendered for smooth transitions)
            if profileStore.hasCompletedOnboarding && !forceShowOnboarding {
                LandingView(viewModel: viewModel)
                    .transition(.opacity)
            }
            
            // Onboarding (shown if no profile)
            if !showSplash && shouldShowOnboarding {
                OnboardingFlow(profileStore: profileStore) {
                    // Onboarding complete — profile now exists
                    // View will automatically update due to @Published
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .zIndex(1)
            }
            
            // Splash overlay (always on top initially)
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: profileStore.hasCompletedOnboarding)
        .onAppear {
            startSplashTimer()
        }
    }
    
    // MARK: - Splash Timer
    
    private func startSplashTimer() {
        // Show splash for 2 seconds, then fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
        }
    }
}

// MARK: - Preview

#Preview("New User") {
    // Reset profile for preview
    let _ = ProfileStore.shared.resetProfile()
    return RootView()
}

#Preview("Returning User") {
    // Create a test profile
    let _ = ProfileStore.shared.createProfile(
        caregiverName: "Katie",
        patientName: "Don",
        patientSituation: "Stage 4 lymphoma"
    )
    return RootView()
}
