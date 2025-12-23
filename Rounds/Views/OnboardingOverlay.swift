//
//  OnboardingOverlay.swift
//  Rounds
//
//  First-time user experience. Conversational, calm, human.
//

import SwiftUI

struct OnboardingOverlay: View {

    @Binding var step: Int
    let dismiss: () -> Void

    private let totalSteps = 4

    var body: some View {
        ZStack {
            // Dimmed background
            RoundsColor.overlayDim
                .ignoresSafeArea()
                .onTapGesture { }  // Prevent tap-through

            // Overlay card
            VStack(spacing: 0) {

                // MARK: - Brand Header
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RoundsColor.bluePrimary)

                    Text("Rounds")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RoundsColor.textSecondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // MARK: - Content
                VStack(spacing: 16) {
                    // Title
                    Text(titleForStep)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(RoundsColor.textPrimary)
                        .multilineTextAlignment(.center)

                    // Body
                    Text(bodyForStep)
                        .font(.body)
                        .foregroundColor(RoundsColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)

                // MARK: - Visual
                visualForStep
                    .padding(.top, 24)

                Spacer()

                // MARK: - Primary Button
                Button(action: handleNext) {
                    Text(step == totalSteps ? "Get started" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundsColor.bluePrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                // MARK: - Progress Indicator
                VStack(spacing: 8) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(1...totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index == step ? RoundsColor.bluePrimary : RoundsColor.textSecondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Step counter
                    Text("\(step) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(RoundsColor.textSecondary)
                }
                .padding(.bottom, 24)
            }
            .frame(width: 320)
            .frame(minHeight: 420)
            .background(RoundsColor.overlayBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
        }
    }

    // MARK: - Actions

    private func handleNext() {
        if step == totalSteps {
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                step += 1
            }
        }
    }

    // MARK: - Content Data

    private var titleForStep: String {
        switch step {
        case 1: return "Welcome to Rounds"
        case 2: return "Press record"
        case 3: return "See words live"
        case 4: return "We'll help explain"
        default: return ""
        }
    }

    private var bodyForStep: String {
        switch step {
        case 1:
            return "Rounds listens during medical conversations and turns what's said into clear, shareable notes.\n\nYou don't need to remember everything."
        case 2:
            return "When your doctor arrives, tap the microphone.\n\nRounds records in the background while you focus on the conversation."
        case 3:
            return "Spoken words appear on screen as they're said.\n\nNo typing. No note-taking."
        case 4:
            return "Afterward, Rounds can summarize what happened, answer questions, and help you share updates with family."
        default:
            return ""
        }
    }

    @ViewBuilder
    private var visualForStep: some View {
        switch step {
        case 1:
            // Subtle heart
            Image(systemName: "heart")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(RoundsColor.bluePrimary.opacity(0.6))
                .frame(height: 60)

        case 2:
            // Mic icon (same as landing)
            ZStack {
                Circle()
                    .fill(RoundsColor.bluePrimary)
                    .frame(width: 80, height: 80)

                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(height: 80)

        case 3:
            // Mock transcript card
            RoundedRectangle(cornerRadius: 12)
                .fill(RoundsColor.card)
                .frame(width: 200, height: 60)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(RoundsColor.textSecondary.opacity(0.3))
                            .frame(width: 140, height: 8)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(RoundsColor.textSecondary.opacity(0.2))
                            .frame(width: 100, height: 8)
                    }
                )
                .frame(height: 60)

        case 4:
            // Summary/share icon
            Image(systemName: "text.badge.checkmark")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(RoundsColor.bluePrimary.opacity(0.6))
                .frame(height: 60)

        default:
            EmptyView()
        }
    }
}

#Preview {
    OnboardingOverlay(step: .constant(1), dismiss: {})
}
