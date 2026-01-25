//
//  AIMemoryContext.swift
//  Rounds
//
//  The AI's persistent memory of the patient's journey.
//  This grows over time as the caregiver shares more context.
//  
//  Design principle: The AI should feel like it KNOWS you,
//  like a friend who's been following along the whole time.
//

import Foundation

struct AIMemoryContext: Codable {
    
    // MARK: - Core Identity (Never Forgotten)
    
    var caregiverName: String
    var patientName: String
    var diagnosis: String
    
    // MARK: - Medical Facts (Updated Each Session)
    
    /// Key medical facts mentioned across sessions
    /// e.g., "Don is on 2L supplemental oxygen", "Creatinine trending down"
    var keyMedicalFacts: [String]
    
    /// Current medications mentioned
    /// e.g., "Prednisone 40mg daily", "Tacrolimus 2mg BID"
    var currentMedications: [String]
    
    /// Care team members mentioned by name
    /// e.g., "Dr. Patel (pulmonology)", "Nurse Sarah (day shift)"
    var careTeamMembers: [String]
    
    /// Ongoing concerns or things being monitored
    /// e.g., "Pain management", "Kidney function", "Infection risk"
    var ongoingConcerns: [String]
    
    // MARK: - Session Summaries (Rolling Window)
    
    /// Brief summaries of recent sessions (keep last 5)
    var recentSessionSummaries: [SessionSummary]
    
    // MARK: - Emotional Context
    
    /// Notes about caregiver's emotional state or needs
    /// e.g., "Katie mentioned feeling overwhelmed on 1/15"
    var emotionalNotes: [String]
    
    // MARK: - Initialization
    
    init(
        caregiverName: String,
        patientName: String,
        diagnosis: String
    ) {
        self.caregiverName = caregiverName
        self.patientName = patientName
        self.diagnosis = diagnosis
        self.keyMedicalFacts = []
        self.currentMedications = []
        self.careTeamMembers = []
        self.ongoingConcerns = []
        self.recentSessionSummaries = []
        self.emotionalNotes = []
    }
    
    // MARK: - Memory Updates
    
    /// Add a new session summary, keeping only the last 5
    mutating func addSessionSummary(_ summary: SessionSummary) {
        recentSessionSummaries.append(summary)
        if recentSessionSummaries.count > 5 {
            recentSessionSummaries.removeFirst()
        }
    }
    
    /// Add a medical fact if not already present
    mutating func addMedicalFact(_ fact: String) {
        let normalized = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty && !keyMedicalFacts.contains(normalized) {
            keyMedicalFacts.append(normalized)
        }
    }
    
    /// Add a medication if not already present
    mutating func addMedication(_ med: String) {
        let normalized = med.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty && !currentMedications.contains(normalized) {
            currentMedications.append(normalized)
        }
    }
    
    /// Add a care team member if not already present
    mutating func addCareTeamMember(_ member: String) {
        let normalized = member.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty && !careTeamMembers.contains(normalized) {
            careTeamMembers.append(normalized)
        }
    }
    
    // MARK: - Context for API Calls
    
    /// Generates a token-efficient summary for the AI system prompt
    /// This is what gets sent to GPT each time — must be concise!
    var contextSummary: String {
        var parts: [String] = []
        
        // Core identity
        parts.append("Caregiver: \(caregiverName)")
        parts.append("Patient: \(patientName)")
        parts.append("Diagnosis: \(diagnosis)")
        
        // Medical facts (limit to 5 most recent)
        if !keyMedicalFacts.isEmpty {
            let facts = keyMedicalFacts.suffix(5).joined(separator: "; ")
            parts.append("Key facts: \(facts)")
        }
        
        // Medications
        if !currentMedications.isEmpty {
            let meds = currentMedications.joined(separator: ", ")
            parts.append("Medications: \(meds)")
        }
        
        // Care team
        if !careTeamMembers.isEmpty {
            let team = careTeamMembers.joined(separator: ", ")
            parts.append("Care team: \(team)")
        }
        
        // Concerns
        if !ongoingConcerns.isEmpty {
            let concerns = ongoingConcerns.joined(separator: ", ")
            parts.append("Monitoring: \(concerns)")
        }
        
        // Recent sessions (just dates and one-liners)
        if !recentSessionSummaries.isEmpty {
            let recents = recentSessionSummaries.suffix(3).map { summary in
                "\(summary.dateString): \(summary.oneLiner)"
            }.joined(separator: " | ")
            parts.append("Recent: \(recents)")
        }
        
        return parts.joined(separator: "\n")
    }
    
    /// Estimated token count for the context summary
    var estimatedTokens: Int {
        // Rough estimate: 1 token ≈ 4 characters
        return contextSummary.count / 4
    }
}

// MARK: - Session Summary

struct SessionSummary: Codable {
    let date: Date
    let oneLiner: String  // e.g., "Oxygen stable, starting PT tomorrow"
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
