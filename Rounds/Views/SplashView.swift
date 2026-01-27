//
//  SplashView.swift
//  Rounds AI
//
//  Launch screen - gradient blue with white circle containing heart+cross
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Gradient background matching brand colors
            RoundsColor.brandGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // White circle with large heart+cross
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    
                    // Heart+cross icon - BIG, fills the circle
                    RoundsHeartIcon(size: 70, style: .gradient)
                }

                // App name
                Text("Rounds AI")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Tagline
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
