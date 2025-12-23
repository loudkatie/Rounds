//
//  SplashView.swift
//  Rounds
//
//  A moment of calm. Not a loading screen.
//

import SwiftUI

struct SplashView: View {

    var body: some View {
        ZStack {
            RoundsColor.splashGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Large outlined heart - bigger, more presence
                Image(systemName: "heart")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)

                // App name - large and confident
                Text("Rounds")
                    .font(.system(size: 48, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .tracking(1)

                // Tagline - softer, supportive
                Text("I'm here when you're ready.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    SplashView()
}
