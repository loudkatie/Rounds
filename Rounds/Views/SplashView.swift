//
//  SplashView.swift
//  Rounds AI
//
//  Solid blue splash screen with white heart+cross logo
//

import SwiftUI

struct SplashView: View {
    // Brand blue from reference
    private let brandBlue = Color(red: 0/255, green: 172/255, blue: 238/255)
    
    var body: some View {
        ZStack {
            // Solid blue background
            brandBlue
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // White circle with blue heart+cross inside
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    // Heart with cross - matches app icon
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundColor(brandBlue)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: -1)
                    }
                }

                // Wordmark
                Text("Rounds AI")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Simple, descriptive tagline
                Text("Your medical AI assistant")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

#Preview {
    SplashView()
}
