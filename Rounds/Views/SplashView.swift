//
//  SplashView.swift
//  Rounds
//
//  Solid blue background, white logo. Clean and calm.
//  Based on Katie's reference design.
//

import SwiftUI

struct SplashView: View {
    // The friendly blue from Katie's reference design
    private let splashBlue = Color(red: 32/255, green: 150/255, blue: 243/255)
    
    var body: some View {
        ZStack {
            // Solid blue background
            splashBlue
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Heart in white circle (like reference)
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(splashBlue)
                }

                // Wordmark
                Text("Rounds")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Tagline - AI focused
                Text("Your AI medical assistant")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    SplashView()
}
