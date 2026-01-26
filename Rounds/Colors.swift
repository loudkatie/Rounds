//
//  Colors.swift
//  Rounds AI
//
//  Centralized color definitions for consistent branding
//

import SwiftUI

struct RoundsColor {
    // MARK: - Brand Blues (Gradient)
    
    /// Lighter blue for gradient top
    static let brandBlueLight = Color(red: 65/255, green: 190/255, blue: 255/255)
    
    /// Standard brand blue for gradient bottom / solid use
    static let brandBlue = Color(red: 56/255, green: 152/255, blue: 224/255)
    
    /// Darker navy for buttons (ready state)
    static let navyBlue = Color(red: 30/255, green: 100/255, blue: 180/255)
    
    /// Brand gradient
    static let brandGradient = LinearGradient(
        colors: [brandBlueLight, brandBlue],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Semantic Colors
    
    /// Recording state - red
    static let recording = Color.red
    
    /// Success/positive - green (used sparingly)
    static let success = Color(red: 52/255, green: 199/255, blue: 89/255)
    
    /// Background for cards
    static let cardBackground = Color(UIColor.systemGray6)
    
    /// Subtle background for transcript box
    static let transcriptBackground = Color(red: 56/255, green: 152/255, blue: 224/255).opacity(0.08)
}

// MARK: - Gradient Heart+Cross Icon

struct GradientHeartPlusIcon: View {
    var size: CGFloat = 32
    var useGradient: Bool = true
    
    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(
                    useGradient 
                        ? AnyShapeStyle(RoundsColor.brandGradient)
                        : AnyShapeStyle(RoundsColor.brandBlue)
                )
            
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
                .offset(y: -size * 0.02)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientHeartPlusIcon(size: 60)
        GradientHeartPlusIcon(size: 40)
        GradientHeartPlusIcon(size: 24)
    }
    .padding()
}
