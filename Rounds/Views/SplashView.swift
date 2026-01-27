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
                // White circle with heart
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    
                    RoundsHeartIcon(size: 70)
                }

                Text("Rounds AI")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
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
