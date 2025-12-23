//
//  Colors.swift
//  Rounds
//
//  Design System: Apple-grade medical app palette
//  Calm, trustworthy, emotionally safe
//

import SwiftUI

enum RoundsColor {

    // MARK: - Primary Palette

    /// Very light pastel blue - cards, soft backgrounds
    static let blueLight = Color(red: 234/255, green: 244/255, blue: 255/255)

    /// Calm medical blue - record button, primary CTAs
    static let bluePrimary = Color(red: 30/255, green: 136/255, blue: 229/255)

    /// Deep navy - headers, emphasis, gradient end
    static let blueDeep = Color(red: 21/255, green: 71/255, blue: 137/255)

    /// Midnight - darkest accent
    static let blueMidnight = Color(red: 8/255, green: 33/255, blue: 77/255)

    // MARK: - Semantic Colors

    /// Default canvas
    static let background = Color.white

    /// Card backgrounds
    static let card = blueLight

    /// Primary text
    static let textPrimary = Color(red: 28/255, green: 28/255, blue: 30/255)

    /// Secondary/helper text
    static let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)

    // MARK: - Gradients

    /// Splash screen gradient - light top to deep bottom
    static let splashGradient = LinearGradient(
        colors: [blueLight, blueDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Overlay

    /// Translucent overlay background
    static let overlayBackground = Color.white.opacity(0.95)

    /// Dim behind overlay
    static let overlayDim = Color.black.opacity(0.4)
}
