//
//  SplashView.swift
//  Rounds AI
//
//  Gradient blue splash with new tagline
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Gradient background - lighter blue at top, brand blue at bottom
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 65/255, green: 190/255, blue: 255/255),  // Lighter cyan-blue
                    Color(red: 56/255, green: 152/255, blue: 224/255)   // Brand blue
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // White circle with gradient heart+cross inside
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                    
                    // Heart with cross - gradient version
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 54, weight: .regular))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 65/255, green: 190/255, blue: 255/255),
                                        Color(red: 56/255, green: 152/255, blue: 224/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: -1)
                    }
                }

                // App name
                Text("Rounds AI")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // New tagline
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
