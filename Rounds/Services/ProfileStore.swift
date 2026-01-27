//
//  ProfileStore.swift
//  Rounds AI
//
//  Manages the caregiver's profile and initializes AI memory.
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
        
        // Initialize the AI Memory Store with profile data
        let relationship = extractRelationship(from: patientSituation)
        AIMemoryStore.shared.initializeFromProfile(
            caregiver: caregiverName,
            patient: patientName,
            relationship: relationship,
            situation: patientSituation
        )
        
        print("[ProfileStore] Created profile for \(caregiverName) caring for \(patientName)")
    }
    
    /// Extract relationship from situation string
    private func extractRelationship(from situation: String) -> String {
        let lowered = situation.lowercased()
        let relationships = ["father", "mother", "dad", "mom", "spouse", "husband", "wife", 
                            "child", "son", "daughter", "sibling", "brother", "sister", 
                            "friend", "parent", "grandparent", "grandmother", "grandfather"]
        for rel in relationships {
            if lowered.contains(rel) {
                return rel
            }
        }
        return "loved one"
    }
    
    /// Records a completed session
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
        
        // Also reset AI memory
        AIMemoryStore.shared.resetMemory()
        
        print("[ProfileStore] Profile and memory reset")
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
        } catch {
            print("[ProfileStore] Failed to encode profile: \(error)")
        }
    }
}
