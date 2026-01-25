//
//  OnboardingFlow.swift
//  Rounds
//
//  5-step onboarding that establishes the relationship and gets permissions.
//
//  Flow:
//  1. Welcome - "Hi. I'm Rounds AI..."
//  2. Your name
//  3. Patient name + relationship
//  4. Patient situation
//  5. Microphone permission
//

import SwiftUI
import AVFoundation

struct OnboardingFlow: View {
    @ObservedObject var profileStore: ProfileStore
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var caregiverName = ""
    @State private var patientName = ""
    @State private var relationship = ""
    @State private var patientSituation = ""
    @State private var micPermissionGranted = false
    @FocusState private var isInputFocused: Bool
    
    private let totalSteps = 5
    
    private let relationshipOptions = ["Parent", "Spouse", "Child", "Sibling", "Friend", "Other"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (except welcome screen)
            if currentStep > 0 {
                OnboardingHeader()
                    .padding(.top, 60)
            }
            
            Spacer()
            
            // Content
            Group {
                switch currentStep {
                case 0:
                    WelcomeStep()
                case 1:
                    NameStep(name: $caregiverName, isFocused: $isInputFocused)
                case 2:
                    PatientStep(
                        patientName: $patientName,
                        relationship: $relationship,
                        relationshipOptions: relationshipOptions,
                        isFocused: $isInputFocused
                    )
                case 3:
                    SituationStep(
                        patientName: patientName,
                        situation: $patientSituation,
                        isFocused: $isInputFocused
                    )
                case 4:
                    PermissionsStep(
                        permissionGranted: $micPermissionGranted,
                        onRequestPermission: requestMicPermission
                    )
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Progress + Button
            VStack(spacing: 24) {
                // Progress bar
                ProgressIndicator(current: currentStep, total: totalSteps)
                
                // Next/Get Started button
                Button(action: handleNext) {
                    Text(buttonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canProceed ? RoundsColor.bluePrimary : RoundsColor.bluePrimary.opacity(0.4))
                        .cornerRadius(16)
                }
                .disabled(!canProceed)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            checkMicPermission()
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonText: String {
        switch currentStep {
        case 0: return "Next"
        case 4: return micPermissionGranted ? "Get Started" : "Enable Microphone"
        default: return "Next"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !caregiverName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !patientName.trimmingCharacters(in: .whitespaces).isEmpty && !relationship.isEmpty
        case 3: return !patientSituation.trimmingCharacters(in: .whitespaces).isEmpty
        case 4: return true // Can always proceed, but button text changes
        default: return false
        }
    }
    
    // MARK: - Actions
    
    private func handleNext() {
        isInputFocused = false
        
        if currentStep == 4 {
            if micPermissionGranted {
                completeOnboarding()
            } else {
                requestMicPermission()
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
        
        // Re-focus input after transition
        if currentStep >= 1 && currentStep <= 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isInputFocused = true
            }
        }
    }
    
    private func completeOnboarding() {
        profileStore.createProfile(
            caregiverName: caregiverName.trimmingCharacters(in: .whitespaces),
            patientName: patientName.trimmingCharacters(in: .whitespaces),
            patientSituation: "\(patientName) is my \(relationship.lowercased()). \(patientSituation.trimmingCharacters(in: .whitespaces))"
        )
        onComplete()
    }
    
    private func checkMicPermission() {
        micPermissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
    }
    
    private func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                micPermissionGranted = granted
                if granted && currentStep == 4 {
                    completeOnboarding()
                }
            }
        }
    }
}

// MARK: - Header

private struct OnboardingHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            // Heart + cross icon
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(RoundsColor.bluePrimary)
                
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 0, y: -1)
            }
            
            // Wordmark
            Text("Rounds AI")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(RoundsColor.textPrimary)
        }
    }
}

// MARK: - Progress Indicator

private struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Dots
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index <= current ? RoundsColor.bluePrimary : RoundsColor.blueLight)
                        .frame(width: index == current ? 12 : 8, height: index == current ? 12 : 8)
                        .animation(.easeInOut(duration: 0.2), value: current)
                }
            }
            
            // Text
            Text("\(current + 1) of \(total)")
                .font(.caption)
                .foregroundColor(RoundsColor.textSecondary)
        }
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            // Large icon
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundColor(RoundsColor.bluePrimary)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 0, y: -2)
            }
            
            VStack(spacing: 16) {
                Text("Hi. I'm Rounds AI.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(RoundsColor.textPrimary)
                
                Text("I'm your AI assistant here to help you talk to doctors and medical teams.")
                    .font(.body)
                    .foregroundColor(RoundsColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("I'll listen during appointments, translate the medical speak, and help you remember what matters.")
                    .font(.body)
                    .foregroundColor(RoundsColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Step 2: Your Name

private struct NameStep: View {
    @Binding var name: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("What's your first name?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textPrimary)
                
                Text("I'll use this to personalize your experience.")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textSecondary)
            }
            
            TextField("Your first name", text: $name)
                .font(.title3)
                .padding(16)
                .background(RoundsColor.blueLight)
                .cornerRadius(12)
                .focused(isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
        }
    }
}

// MARK: - Step 3: Patient Name + Relationship

private struct PatientStep: View {
    @Binding var patientName: String
    @Binding var relationship: String
    let relationshipOptions: [String]
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Who are you caring for?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textPrimary)
            }
            
            VStack(spacing: 20) {
                // Patient name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Their first name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(RoundsColor.textSecondary)
                    
                    TextField("First name", text: $patientName)
                        .font(.title3)
                        .padding(16)
                        .background(RoundsColor.blueLight)
                        .cornerRadius(12)
                        .focused(isFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                
                // Relationship picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(patientName.isEmpty ? "They are" : patientName + " is") my...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(RoundsColor.textSecondary)
                    
                    // Pill buttons for relationship
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(relationshipOptions, id: \.self) { option in
                            Button {
                                relationship = option
                            } label: {
                                Text(option)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(relationship == option ? .white : RoundsColor.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(relationship == option ? RoundsColor.bluePrimary : RoundsColor.blueLight)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: Situation

private struct SituationStep: View {
    let patientName: String
    @Binding var situation: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Tell me about \(patientName)'s situation")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("In 1-2 sentences, what's the medical situation?")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textSecondary)
            }
            
            TextField("e.g., recovering from heart surgery, undergoing chemo for lymphoma...", text: $situation, axis: .vertical)
                .font(.body)
                .lineLimit(3...5)
                .padding(16)
                .background(RoundsColor.blueLight)
                .cornerRadius(12)
                .focused(isFocused)
        }
    }
}

// MARK: - Step 5: Permissions

private struct PermissionsStep: View {
    @Binding var permissionGranted: Bool
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Mic icon
            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(permissionGranted ? .green : RoundsColor.bluePrimary)
            
            VStack(spacing: 16) {
                Text(permissionGranted ? "You're all set!" : "One more thing")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textPrimary)
                
                if permissionGranted {
                    Text("Microphone access enabled. You're ready to start recording appointments.")
                        .font(.body)
                        .foregroundColor(RoundsColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                } else {
                    Text("To capture appointment transcripts for you, Rounds AI needs permission to access your microphone.")
                        .font(.body)
                        .foregroundColor(RoundsColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Text("Your recordings stay on your device and are never shared without your permission.")
                        .font(.caption)
                        .foregroundColor(RoundsColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(profileStore: ProfileStore.shared) {
        print("Onboarding complete!")
    }
}
