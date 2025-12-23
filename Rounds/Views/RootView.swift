//
//  RootView.swift
//  Rounds
//
//  Navigation controller. Calm transitions.
//

import SwiftUI

struct RootView: View {

    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var onboardingStep = 1
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // DEBUG: Set to true to always show onboarding (for testing)
    private let forceShowOnboarding = true

    var body: some View {
        ZStack {
            // Base layer: Landing (always rendered for smooth transitions)
            LandingView(onRecordTapped: {
                // Record action - to be wired later
            })

            // Splash overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            // Onboarding overlay
            if showOnboarding {
                OnboardingOverlay(step: $onboardingStep) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showOnboarding = false
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onAppear {
            triggerSplashToLanding()
        }
    }

    private func triggerSplashToLanding() {
        // Splash duration: 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSplash = false
            }

            // Show onboarding after splash fades
            let shouldShowOnboarding = forceShowOnboarding || !hasSeenOnboarding

            if shouldShowOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showOnboarding = true
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
