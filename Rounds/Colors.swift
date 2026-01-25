//
//  Colors.swift
//  Rounds AI
//
//  Brand colors - simple and clean
//

import SwiftUI

enum RoundsColor {
    // Primary brand blue (from your splash screen reference)
    static let brandBlue = Color(red: 0/255, green: 172/255, blue: 238/255)
    
    // Alias for compatibility
    static let bluePrimary = brandBlue
    static let blueLight = brandBlue.opacity(0.1)
    
    // Backgrounds
    static let background = Color.white
    static let card = Color(UIColor.systemGray6)
    
    // Text
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
}
