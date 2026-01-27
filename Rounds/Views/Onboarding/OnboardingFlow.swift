//
//  OnboardingFlow.swift
//  Rounds AI
//
//  5-step onboarding with DARK TEXT on light backgrounds
//  Step 5: Both mic AND speech recognition permissions
//

import SwiftUI
import AVFoundation
import Speech

struct OnboardingFlow: View {
    @ObservedObject var profileStore: ProfileStore
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var caregiverName = ""
    @State private var patientName = ""
    @State private var relationship = ""
    @State private var patientSituation = ""
    @State private var micPermissionGranted = false
    @State private var speechPermissionGranted = false
    @FocusState private var isInputFocused: Bool
    
    private let totalSteps = 5
    private let relationshipOptions = ["Parent", "Spouse", "Child", "Sibling", "Friend", "Other"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button (steps 2-5)
            if currentStep > 0 {
                HStack {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.body)
                        .foregroundColor(RoundsColor.buttonBlue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            
            // Header (except welcome)
            if currentStep > 0 {
                VStack(spacing: 6) {
                    RoundsHeartIcon(size: 28)
                    Text("Rounds AI")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(RoundsColor.textDark)
                }
                .padding(.top, currentStep > 0 ? 20 : 60)
            }
            
            Spacer()
            
            // Content - ALL TEXT IS DARK
            Group {
                switch currentStep {
                case 0: WelcomeStep()
                case 1: NameStep(name: $caregiverName, isFocused: $isInputFocused)
                case 2: PatientStep(patientName: $patientName, relationship: $relationship, options: relationshipOptions, isFocused: $isInputFocused)
                case 3: SituationStep(patientName: patientName, situation: $patientSituation, isFocused: $isInputFocused)
                case 4: PermissionsStep(micGranted: $micPermissionGranted, speechGranted: $speechPermissionGranted, onRequest: requestPermissions)
                default: EmptyView()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Progress + Button
            VStack(spacing: 24) {
                // Progress dots
                HStack(spacing: 10) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i <= currentStep ? RoundsColor.buttonBlue : RoundsColor.buttonBlue.opacity(0.3))
                            .frame(width: i == currentStep ? 14 : 10, height: i == currentStep ? 14 : 10)
                    }
                }
                
                Text("\(currentStep + 1) of \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMuted)
                
                // Next button
                Button(action: handleNext) {
                    Text(buttonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canProceed ? RoundsColor.buttonBlue : RoundsColor.buttonBlue.opacity(0.4))
                        .cornerRadius(16)
                }
                .disabled(!canProceed)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .onAppear { checkPermissions() }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !caregiverName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !patientName.trimmingCharacters(in: .whitespaces).isEmpty && !relationship.isEmpty
        case 3: return true
        case 4: return micPermissionGranted && speechPermissionGranted
        default: return false
        }
    }
    
    private var buttonText: String {
        switch currentStep {
        case 0: return "Get Started"
        case 4: return (micPermissionGranted && speechPermissionGranted) ? "Let's Go!" : "Enable Permissions"
        default: return "Continue"
        }
    }
    
    private func handleNext() {
        isInputFocused = false
        
        if currentStep == 4 {
            if micPermissionGranted && speechPermissionGranted {
                completeOnboarding()
            } else {
                requestPermissions()
            }
            return
        }
        
        withAnimation { currentStep += 1 }
        
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
            patientSituation: "\(patientName) is my \(relationship.lowercased()). \(patientSituation)"
        )
        onComplete()
    }
    
    private func checkPermissions() {
        micPermissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        speechPermissionGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    private func requestPermissions() {
        // Request mic
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                micPermissionGranted = granted
                // Then request speech
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        speechPermissionGranted = (status == .authorized)
                        if micPermissionGranted && speechPermissionGranted {
                            completeOnboarding()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(RoundsColor.buttonBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                RoundsHeartIcon(size: 56)
            }
            
            VStack(spacing: 16) {
                Text("Hi. I'm Rounds AI.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(RoundsColor.textDark)
                
                Text("I'm your AI assistant here to help you talk to doctors and medical teams.")
                    .font(.body)
                    .foregroundColor(RoundsColor.textMedium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("I listen during appointments and translate medical speak into plain language you can understand and share.")
                    .font(.body)
                    .foregroundColor(RoundsColor.textMedium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Step 2: Your Name

private struct NameStep: View {
    @Binding var name: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What's your name?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textDark)
                
                Text("I'll use this to personalize our conversations.")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMedium)
            }
            
            TextField("Your name", text: $name)
                .font(.title3)
                .padding(16)
                .background(RoundsColor.moduleBackground)
                .cornerRadius(12)
                .focused(isFocused)
        }
    }
}

// MARK: - Step 3: Patient

private struct PatientStep: View {
    @Binding var patientName: String
    @Binding var relationship: String
    let options: [String]
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Who are you caring for?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textDark)
                
                Text("I use names to personalize our conversation.")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMedium)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Patient's First Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(RoundsColor.textMedium)
                
                TextField("First name", text: $patientName)
                    .font(.title3)
                    .padding(16)
                    .background(RoundsColor.moduleBackground)
                    .cornerRadius(12)
                    .focused(isFocused)
                
                Text("\(patientName.isEmpty ? "They are" : patientName + " is") my...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(RoundsColor.textMedium)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                    ForEach(options, id: \.self) { opt in
                        Button {
                            relationship = opt
                        } label: {
                            Text(opt)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(relationship == opt ? .white : RoundsColor.textDark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(relationship == opt ? RoundsColor.buttonBlue : RoundsColor.moduleBackground)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            Text("Recordings stay on your device.")
                .font(.caption)
                .italic()
                .foregroundColor(RoundsColor.textMuted)
                .padding(.top, 16)
        }
    }
}

// MARK: - Step 4: Situation

private struct SituationStep: View {
    let patientName: String
    @Binding var situation: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Tell me about \(patientName)'s situation")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textDark)
                    .multilineTextAlignment(.center)
                
                Text("In 1-2 sentences, what's the medical situation?")
                    .font(.subheadline)
                    .foregroundColor(RoundsColor.textMedium)
            }
            
            TextField("e.g., recovering from surgery, undergoing treatment...", text: $situation, axis: .vertical)
                .font(.body)
                .lineLimit(3...5)
                .padding(16)
                .background(RoundsColor.moduleBackground)
                .cornerRadius(12)
                .focused(isFocused)
        }
    }
}

// MARK: - Step 5: Permissions (BOTH!)

private struct PermissionsStep: View {
    @Binding var micGranted: Bool
    @Binding var speechGranted: Bool
    let onRequest: () -> Void
    
    private var allGranted: Bool { micGranted && speechGranted }
    
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: allGranted ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(allGranted ? .green : RoundsColor.buttonBlue)
            
            VStack(spacing: 16) {
                Text(allGranted ? "You're all set!" : "Two quick things")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(RoundsColor.textDark)
                
                if allGranted {
                    Text("Permissions enabled. You're ready to start recording appointments.")
                        .font(.body)
                        .foregroundColor(RoundsColor.textMedium)
                        .multilineTextAlignment(.center)
                } else {
                    Text("To capture and transcribe appointments, Rounds AI needs access to your microphone and speech recognition.")
                        .font(.body)
                        .foregroundColor(RoundsColor.textMedium)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    // Permission status
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: micGranted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(micGranted ? .green : RoundsColor.textMuted)
                            Text("Microphone")
                                .foregroundColor(RoundsColor.textDark)
                            Spacer()
                        }
                        HStack {
                            Image(systemName: speechGranted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(speechGranted ? .green : RoundsColor.textMuted)
                            Text("Speech Recognition")
                                .foregroundColor(RoundsColor.textDark)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(RoundsColor.moduleBackground)
                    .cornerRadius(12)
                    
                    Text("Your recordings stay on your device and are never shared without your permission.")
                        .font(.caption)
                        .italic()
                        .foregroundColor(RoundsColor.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

#Preview {
    OnboardingFlow(profileStore: ProfileStore.shared) {
        print("Done!")
    }
}
