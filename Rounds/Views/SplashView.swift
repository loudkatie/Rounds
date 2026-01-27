//
//  SplashView.swift
//  Rounds AI
//
//  Launch screen - gradient blue background
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            RoundsColor.brandGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // White circle with two hearts icon
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    
                    RoundsHeartIcon(size: 70)
                }

                // ROUNDS AI wordmark - spaced letters
                VStack(spacing: 4) {
                    Text("R O U N D S")
                        .font(.system(size: 36, weight: .bold))
                        .tracking(6)
                    Text("A I")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(10)
                }
                .foregroundColor(.white)

                Text("Helping caregivers navigate\nmedical conversations.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

#Preview {
    SplashView()
}
