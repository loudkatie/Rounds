//
//  RootView.swift
//  Rounds AI
//
//  Root navigation - handles splash, onboarding, and main app flow
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = TranscriptViewModel()
    @StateObject private var profileStore = ProfileStore.shared
    
    @State private var showSplash = true
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if showOnboarding {
                OnboardingFlow(profileStore: profileStore) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                LandingView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Show splash for 2.5 seconds (extended for readability)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                    // Check if user has completed onboarding
                    if !profileStore.hasCompletedOnboarding {
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
