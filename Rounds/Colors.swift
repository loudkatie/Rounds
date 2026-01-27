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

// MARK: - Rounds Icon: Two Hearts (Caregiver + Patient)
// Design: Larger heart "supporting" smaller heart - symbolizes caregiving relationship

struct RoundsHeartIcon: View {
    var size: CGFloat = 32
    var color: Color = RoundsColor.buttonBlue
    
    var body: some View {
        ZStack {
            // Main heart (caregiver) - larger, positioned slightly left/back
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
            
            // Small heart (patient) - smaller, nested inside, slightly offset
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.4, weight: .regular))
                .foregroundColor(.white)
                .offset(x: size * 0.02, y: size * 0.05)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        RoundsHeartIcon(size: 80)
        RoundsHeartIcon(size: 50)
        RoundsHeartIcon(size: 30)
        
        // Show how it looks on blue background
        ZStack {
            Circle()
                .fill(RoundsColor.buttonBlue)
                .frame(width: 100, height: 100)
            RoundsHeartIcon(size: 50, color: .white)
        }
    }
    .padding()
}

#Preview {
    VStack(spacing: 20) {
        RoundsHeartIcon(size: 50)
        RoundsHeartIcon(size: 30)
    }
}
