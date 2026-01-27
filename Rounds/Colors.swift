//
//  Colors.swift
//  Rounds AI
//
//  DESIGN SYSTEM - Bright, clean, accessible
//  Reference: IMG_9459 - the GOOD design
//

import SwiftUI

struct RoundsColor {
    // MARK: - Brand Blues (Bright & Vibrant)
    
    /// Bright blue for buttons - THE BIG RECORD BUTTON
    static let buttonBlue = Color(red: 56/255, green: 152/255, blue: 224/255)  // #3898E0
    
    /// Light blue for module backgrounds
    static let moduleBackground = Color(red: 56/255, green: 152/255, blue: 224/255).opacity(0.08)
    
    /// Card background - very light gray
    static let cardBackground = Color(red: 245/255, green: 247/255, blue: 250/255)
    
    /// Brand gradient for splash
    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 65/255, green: 186/255, blue: 255/255),
            Color(red: 56/255, green: 152/255, blue: 224/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Text Colors - DARK for readability
    
    static let textDark = Color(red: 40/255, green: 40/255, blue: 50/255)      // Near black
    static let textMedium = Color(red: 80/255, green: 80/255, blue: 90/255)    // Dark gray
    static let textMuted = Color.gray
    
    // MARK: - Section Header Blue
    static let headerBlue = Color(red: 56/255, green: 152/255, blue: 224/255)
}

// MARK: - Heart+Cross Icon

struct RoundsHeartIcon: View {
    var size: CGFloat = 32
    var filled: Bool = true
    var color: Color = RoundsColor.buttonBlue
    
    var body: some View {
        ZStack {
            Image(systemName: filled ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
            
            Image(systemName: "plus")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
                .offset(y: -size * 0.02)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundsHeartIcon(size: 50)
        RoundsHeartIcon(size: 30, filled: false)
    }
}
