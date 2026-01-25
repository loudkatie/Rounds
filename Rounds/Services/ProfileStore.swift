//
//  ProfileStore.swift
//  Rounds
//
//  Manages the caregiver's profile and persistent AI memory.
//  Single source of truth for user identity across the app.
//

import Foundation

@MainActor
final class ProfileStore: ObservableObject {
    
    static let shared = ProfileStore()
    
    // MARK: - Published State
    
    @Published private(set) var currentProfile: UserProfile?
    @Published private(set) var isLoading = false
    
    // MARK: - Computed Properties
    
    var hasCompletedOnboarding: Bool {
        currentProfile != nil
    }
    
    var caregiverName: String {
        currentProfile?.caregiverName ?? "there"
    }
    
    var patientName: String {
        currentProfile?.patientName ?? "your loved one"
    }
    
    var aiMemory: AIMemoryContext? {
        currentProfile?.aiMemory
    }
    
    // MARK: - Private
    
    private let storageKey = "rounds_user_profile"
    
    // MARK: - Initialization
    
    private init() {
        loadProfile()
    }
    
    // MARK: - Profile Management
    
    /// Creates a new profile after onboarding
    func createProfile(
        caregiverName: String,
        patientName: String,
        patientSituation: String
    ) {
        let profile = UserProfile(
            caregiverName: caregiverName,
            patientName: patientName,
            patientSituation: patientSituation
        )
        
        currentProfile = profile
        saveProfile()
        
        print("[ProfileStore] Created new profile for \(caregiverName)")
    }
    
    /// Updates the AI memory context after a session
    func updateAIMemory(_ updates: (inout AIMemoryContext) -> Void) {
        guard var profile = currentProfile else { return }
        
        updates(&profile.aiMemory)
        currentProfile = profile
        saveProfile()
        
        print("[ProfileStore] Updated AI memory")
    }
    
    /// Adds a session ID to the profile
    func recordSession(_ sessionID: UUID) {
        guard var profile = currentProfile else { return }
        
        profile.sessionIDs.append(sessionID)
        currentProfile = profile
        saveProfile()
        
        print("[ProfileStore] Recorded session \(sessionID)")
    }
    
    /// Resets the profile (for testing or user request)
    func resetProfile() {
        currentProfile = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("[ProfileStore] Profile reset")
    }
    
    // MARK: - Persistence
    
    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("[ProfileStore] No saved profile found")
            return
        }
        
        do {
            currentProfile = try JSONDecoder().decode(UserProfile.self, from: data)
            print("[ProfileStore] Loaded profile for \(currentProfile?.caregiverName ?? "unknown")")
        } catch {
            print("[ProfileStore] Failed to decode profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let profile = currentProfile else { return }
        
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("[ProfileStore] Saved profile")
        } catch {
            print("[ProfileStore] Failed to encode profile: \(error)")
        }
    }
}
