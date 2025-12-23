//
//  LandingView.swift
//  Rounds
//
//  Instant clarity for stressed users. One obvious action.
//

import SwiftUI

struct LandingView: View {

    let onRecordTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header (Bold, Wall-to-Wall)
            VStack(spacing: 12) {
                // Heart as visual anchor
                Image(systemName: "heart")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(RoundsColor.bluePrimary)

                // "ROUNDS" - wide, confident, wall-to-wall feel
                Text("ROUNDS")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .tracking(12)
                    .foregroundColor(RoundsColor.textPrimary)
            }
            .padding(.top, 48)

            Spacer()

            // MARK: - Record Button (Visual Anchor)
            Button(action: onRecordTapped) {
                ZStack {
                    Circle()
                        .fill(RoundsColor.bluePrimary)
                        .frame(width: 160, height: 160)
                        .shadow(color: RoundsColor.bluePrimary.opacity(0.3), radius: 20, y: 8)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start recording")

            Spacer()
                .frame(height: 40)

            // MARK: - Transcript Placeholder Card
            RoundedRectangle(cornerRadius: 16)
                .fill(RoundsColor.card)
                .frame(height: 100)
                .overlay(
                    Text("Live transcript will appear here...")
                        .font(.body)
                        .foregroundColor(RoundsColor.textSecondary)
                )
                .padding(.horizontal, 24)

            Spacer()

            // MARK: - Status Pill (Button-like)
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

                Text("Ready")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(RoundsColor.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(RoundsColor.card)
            .cornerRadius(24)
            .padding(.bottom, 32)
        }
        .background(RoundsColor.background.ignoresSafeArea())
    }
}

#Preview {
    LandingView(onRecordTapped: {})
}
