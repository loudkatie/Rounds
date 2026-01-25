//
//  UserProfile.swift
//  Rounds
//
//  The caregiver's identity and their relationship with Rounds AI.
//  This is the foundation of the "growing friendship" model.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    
    // Core identity (set during onboarding)
    var caregiverName: String
    var patientName: String
    var patientSituation: String
    
    // Session history
    var sessionIDs: [UUID]
    
    // AI memory context (grows over time)
    var aiMemory: AIMemoryContext
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        caregiverName: String,
        patientName: String,
        patientSituation: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.caregiverName = caregiverName
        self.patientName = patientName
        self.patientSituation = patientSituation
        self.sessionIDs = []
        self.aiMemory = AIMemoryContext(
            caregiverName: caregiverName,
            patientName: patientName,
            diagnosis: patientSituation
        )
    }
    
    // MARK: - Computed Properties
    
    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    var sessionCount: Int {
        sessionIDs.count
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 0..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default: timeGreeting = "Good evening"
        }
        return "\(timeGreeting), \(caregiverName)"
    }
}
