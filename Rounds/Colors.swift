//
//  Colors.swift
//  Rounds AI
//
//  DESIGN SYSTEM - Centralized colors matching splash page gradient
//  Last updated: Jan 26, 2026
//

import SwiftUI

struct RoundsColor {
    // MARK: - Brand Blues (from Splash Gradient)
    
    /// Lighter blue - gradient top
    static let brandBlueLight = Color(red: 65/255, green: 186/255, blue: 255/255)  // #41BAFF
    
    /// Primary brand blue - gradient bottom, main accent
    static let brandBlue = Color(red: 56/255, green: 152/255, blue: 224/255)       // #3898E0
    
    /// Navy blue - buttons, interactive elements
    static let navyBlue = Color(red: 30/255, green: 100/255, blue: 180/255)        // #1E64B4
    
    /// Brand gradient (top to bottom)
    static let brandGradient = LinearGradient(
        colors: [brandBlueLight, brandBlue],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - UI Colors
    
    /// Card/module background - light gray
    static let cardBackground = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    
    /// Transcript box background - subtle blue tint
    static let transcriptBackground = Color(red: 56/255, green: 152/255, blue: 224/255).opacity(0.08)
    
    /// Recording state - red
    static let recording = Color.red
    
    // MARK: - Text Colors
    
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textMuted = Color.gray
}

// MARK: - Typography Styles

struct RoundsFont {
    /// H1 - Report titles: "Don's Appointment Recap"
    static func h1() -> Font {
        .system(size: 22, weight: .bold)
    }
    
    /// H2 - Section headers: "Key Points", "What We Discussed"
    static func h2() -> Font {
        .system(size: 17, weight: .semibold)
    }
    
    /// Body text
    static func body() -> Font {
        .system(size: 16, weight: .regular)
    }
    
    /// Caption/secondary text
    static func caption() -> Font {
        .system(size: 14, weight: .regular)
    }
    
    /// Small labels
    static func small() -> Font {
        .system(size: 12, weight: .medium)
    }
}

// MARK: - Heart+Cross Icon (matches Katie's Canva design)

struct RoundsHeartIcon: View {
    var size: CGFloat = 32
    var style: IconStyle = .gradient
    
    enum IconStyle {
        case gradient      // Blue gradient heart, white cross
        case solid         // Solid blue heart, white cross  
        case reversed      // White heart, blue cross (for buttons)
        case white         // All white (for dark backgrounds)
    }
    
    var body: some View {
        ZStack {
            // Heart
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(heartColor)
            
            // Cross - BIG and prominent (40% of heart size)
            Image(systemName: "plus")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(crossColor)
                .offset(y: -size * 0.02)
        }
    }
    
    private var heartColor: AnyShapeStyle {
        switch style {
        case .gradient:
            return AnyShapeStyle(RoundsColor.brandGradient)
        case .solid:
            return AnyShapeStyle(RoundsColor.brandBlue)
        case .reversed:
            return AnyShapeStyle(Color.white)
        case .white:
            return AnyShapeStyle(Color.white)
        }
    }
    
    private var crossColor: Color {
        switch style {
        case .gradient, .solid, .white:
            return .white
        case .reversed:
            return RoundsColor.brandBlue
        }
    }
}

// MARK: - Section Card Component

struct SectionCard<Content: View>: View {
    let title: String
    let emoji: String
    let showChevron: Bool
    @ViewBuilder let content: Content
    
    init(title: String, emoji: String = "", showChevron: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.emoji = emoji
        self.showChevron = showChevron
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 18))
                }
                Text(title)
                    .font(RoundsFont.h2())
                    .foregroundColor(RoundsColor.brandBlue)
                
                if showChevron {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RoundsColor.brandBlue)
                }
            }
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundsColor.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Action Row Component (for Continue Recording, View Transcript, etc.)

struct ActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(RoundsColor.brandBlue)
                
                Text(title)
                    .font(RoundsFont.body())
                    .fontWeight(.medium)
                    .foregroundColor(RoundsColor.brandBlue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RoundsColor.brandBlue.opacity(0.6))
            }
            .padding(14)
            .background(RoundsColor.cardBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Icons
        HStack(spacing: 20) {
            RoundsHeartIcon(size: 40, style: .gradient)
            RoundsHeartIcon(size: 40, style: .solid)
            RoundsHeartIcon(size: 40, style: .reversed)
        }
        
        // Section Card
        SectionCard(title: "Key Points", emoji: "🔑") {
            Text("• Don's heart rate is stable at 82 bpm")
                .font(RoundsFont.body())
        }
        
        // Action Row
        ActionRow(title: "View Full Transcript", icon: "doc.text") {
            print("Tapped")
        }
    }
    .padding()
}
