//
//  SplashView.swift
//  Rounds AI
//
//  Solid blue splash screen with white logo
//  Clean and calm - matches your reference screenshot
//

import SwiftUI

struct SplashView: View {
    
    var body: some View {
        ZStack {
            // Solid blue background (from your reference)
            Color(red: 0/255, green: 172/255, blue: 238/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // White circle with blue heart inside (matching reference)
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(Color(red: 0/255, green: 172/255, blue: 238/255))
                }

                // Wordmark
                Text("Rounds AI")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Tagline
                Text("I'm here when you're ready.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

#Preview {
    SplashView()
}
