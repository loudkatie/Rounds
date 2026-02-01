//
//  AIMemoryContext.swift
//  Rounds AI
//
//  THE BRAIN: Persistent memory that makes GPT "remember" the patient.
//  This grows over time as sessions accumulate.
//  
//  Design principle: GPT should feel like it KNOWS you,
//  like a medical expert friend who's been following along the whole journey.
//

import Foundation

// MARK: - Session Summary (stored after each recording)

struct SessionMemory: Codable, Identifiable {
    let id: UUID
    let date: Date
    var dayNumber: Int?  // e.g., "Day 5 post-transplant"
    let keyPoints: [String]  // 3-5 main takeaways
    let medicalValues: [String: String]  // "Creatinine": "1.4", "Tacrolimus": "11.2"
    let concerns: [String]  // Things to watch
    let nextSteps: [String]  // Follow-ups mentioned
    let questionsAsked: [String]  // What caregiver asked about
    
    var dateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
    
    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

// MARK: - The Full Memory Context

struct AIMemoryContext: Codable {
    
    // MARK: - Core Identity
    
    var caregiverName: String
    var patientName: String
    var relationship: String  // "father", "mother", "spouse"
    var diagnosis: String
    
    // MARK: - Patient Details
    
    var surgeryDate: Date?
    var admissionDate: Date?
    var hospitalInfo: String?
    var careTeamMembers: [String]  // "Dr. Patel (Pulmonology)"
    var currentMedications: [String]
    var allergies: [String]
    
    // MARK: - Learned Knowledge (Grows Over Time)
    
    var keyMedicalFacts: [String]  // Facts GPT has learned
    var vitalTrends: [String: [VitalReading]]  // Track numbers: "Creatinine" -> [readings]
    var observedPatterns: [String]  // "Temperature spikes in evening"
    var ongoingConcerns: [String]  // Active issues being monitored
    
    // MARK: - Session History
    
    var sessions: [SessionMemory]
    
    // MARK: - Caregiver Preferences
    
    var caregiverConcerns: [String]  // What they worry about
    var communicationStyle: String?  // "detailed", "concise"
    var frequentQuestions: [String]  // Topics they ask about often
    
    // MARK: - Initialization
    
    init(caregiverName: String = "", patientName: String = "", relationship: String = "", diagnosis: String = "") {
        self.caregiverName = caregiverName
        self.patientName = patientName
        self.relationship = relationship
        self.diagnosis = diagnosis
        self.careTeamMembers = []
        self.currentMedications = []
        self.allergies = []
        self.keyMedicalFacts = []
        self.vitalTrends = [:]
        self.observedPatterns = []
        self.ongoingConcerns = []
        self.sessions = []
        self.caregiverConcerns = []
        self.frequentQuestions = []
    }
    
    // MARK: - Computed Properties
    
    var daysSinceSurgery: Int? {
        guard let surgery = surgeryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: surgery, to: Date()).day
    }
    
    var daysSinceAdmission: Int? {
        guard let admission = admissionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: admission, to: Date()).day
    }
    
    // MARK: - Update Methods
    
    mutating func addSession(_ session: SessionMemory) {
        sessions.append(session)
        // Keep last 30 sessions
        if sessions.count > 30 {
            sessions = Array(sessions.suffix(30))
        }
    }
    
    mutating func addMedicalFact(_ fact: String) {
        let normalized = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty && !keyMedicalFacts.contains(normalized) {
            keyMedicalFacts.append(normalized)
            // Keep last 50 facts
            if keyMedicalFacts.count > 50 {
                keyMedicalFacts = Array(keyMedicalFacts.suffix(50))
            }
        }
    }
    
    mutating func addPattern(_ pattern: String) {
        let normalized = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty && !observedPatterns.contains(normalized) {
            observedPatterns.append(normalized)
        }
    }
    
    mutating func trackVital(_ name: String, value: Double, unit: String? = nil) {
        let reading = VitalReading(date: Date(), value: value, unit: unit)
        if var existing = vitalTrends[name] {
            existing.append(reading)
            // Keep last 20 readings per vital
            if existing.count > 20 {
                existing = Array(existing.suffix(20))
            }
            vitalTrends[name] = existing
        } else {
            vitalTrends[name] = [reading]
        }
    }
    
    mutating func recordQuestion(_ question: String) {
        frequentQuestions.append(question)
        if frequentQuestions.count > 30 {
            frequentQuestions = Array(frequentQuestions.suffix(30))
        }
    }
    
    // MARK: - Generate Context for API
    
    /// Builds the full context string to include in every GPT call
    func buildSystemContext() -> String {
        var context = """
        You are Rounds AI, \(caregiverName)'s dedicated medical translation assistant.
        You've been helping \(caregiverName) care for their \(relationship) \(patientName).
        
        YOUR ROLE:
        - Translate complex medical conversations into plain language
        - Remember everything about \(patientName)'s medical journey
        - Provide context and explain medical terms at a 12th-grade reading level
        - Be warm, supportive, and thorough
        
        """
        
        // Patient context
        context += "PATIENT INFORMATION:\n"
        context += "- Name: \(patientName)\n"
        context += "- Relationship: \(caregiverName)'s \(relationship)\n"
        
        if !diagnosis.isEmpty {
            context += "- Diagnosis: \(diagnosis)\n"
        }
        if let days = daysSinceSurgery {
            context += "- Day \(days) post-surgery\n"
        }
        if let days = daysSinceAdmission {
            context += "- Day \(days) since admission\n"
        }
        if let hospital = hospitalInfo, !hospital.isEmpty {
            context += "- Location: \(hospital)\n"
        }
        if !currentMedications.isEmpty {
            context += "- Medications: \(currentMedications.joined(separator: ", "))\n"
        }
        if !careTeamMembers.isEmpty {
            context += "- Care team: \(careTeamMembers.joined(separator: ", "))\n"
        }
        context += "\n"
        
        // Learned facts
        if !keyMedicalFacts.isEmpty {
            context += "MEDICAL FACTS YOU'VE LEARNED:\n"
            for fact in keyMedicalFacts.suffix(15) {
                context += "- \(fact)\n"
            }
            context += "\n"
        }
        
        // Vital trends - CRITICAL for detecting anomalies
        if !vitalTrends.isEmpty {
            context += "🔴 VITAL SIGN TRENDS - COMPARE CURRENT TO BASELINE:\n"
            for (name, readings) in vitalTrends {
                if readings.count >= 2 {
                    // Show full trend with arrow notation
                    let values = readings.suffix(10).map { 
                        String(format: "%.1f", $0.value) + ($0.unit ?? "")
                    }.joined(separator: " → ")
                    
                    // Calculate % change from BASELINE (first reading)
                    let baseline = readings.first!.value
                    let current = readings.last!.value
                    let percentChange = ((current - baseline) / baseline) * 100
                    
                    // Determine severity
                    var severity = ""
                    let absChange = abs(percentChange)
                    
                    // Different thresholds for different vitals
                    let isConcerning: Bool
                    if name.lowercased().contains("creatinine") {
                        // Creatinine: ANY increase is concerning, >25% is serious
                        isConcerning = current > baseline
                        if percentChange > 50 { severity = "🚨 CRITICAL" }
                        else if percentChange > 25 { severity = "⚠️ CONCERNING" }
                        else if percentChange > 10 { severity = "📈 Watch closely" }
                    } else if name.lowercased().contains("oxygen") && name.lowercased().contains("liter") {
                        // Oxygen: INCREASING liters is BAD (means patient needs more support)
                        isConcerning = current > baseline
                        if current >= 4 { severity = "🚨 HIGH SUPPORT" }
                        else if current > baseline { severity = "⚠️ INCREASING" }
                    } else if name.lowercased().contains("temp") {
                        // Temperature: Rising toward fever is concerning
                        isConcerning = current > 99.0
                        if current >= 100.5 { severity = "🚨 FEVER" }
                        else if current >= 99.5 { severity = "⚠️ LOW-GRADE FEVER" }
                        else if current > baseline && current > 98.6 { severity = "📈 Trending up" }
                    } else if name.lowercased().contains("white") || name.lowercased().contains("wbc") {
                        // WBC: Rising after initial decline = infection
                        isConcerning = current > 10.0 || (readings.count > 2 && current > readings[readings.count - 2].value)
                        if current > 12 { severity = "🚨 ELEVATED" }
                        else if current > 10 { severity = "⚠️ Watch for infection" }
                    } else {
                        isConcerning = absChange > 20
                    }
                    
                    // Build the output line
                    var line = "- \(name): \(values)"
                    if readings.count >= 2 {
                        let changeStr = percentChange >= 0 ? "+\(String(format: "%.0f", percentChange))%" : "\(String(format: "%.0f", percentChange))%"
                        line += " (\(changeStr) from baseline)"
                    }
                    if !severity.isEmpty {
                        line += " \(severity)"
                    }
                    context += "\(line)\n"
                    
                } else if readings.count == 1 {
                    let reading = readings[0]
                    context += "- \(name): \(String(format: "%.1f", reading.value))\(reading.unit ?? "") (BASELINE - first reading)\n"
                }
            }
            context += "\n"
        }
        
        // Patterns
        if !observedPatterns.isEmpty {
            context += "PATTERNS YOU'VE NOTICED:\n"
            for pattern in observedPatterns {
                context += "- \(pattern)\n"
            }
            context += "\n"
        }
        
        // Ongoing concerns
        if !ongoingConcerns.isEmpty {
            context += "THINGS BEING MONITORED:\n"
            for concern in ongoingConcerns {
                context += "- \(concern)\n"
            }
            context += "\n"
        }
        
        // Session history
        if !sessions.isEmpty {
            context += "PAST SESSION SUMMARIES:\n"
            for session in sessions.suffix(7) {
                context += "\n[\(session.dateFormatted)"
                if let day = session.dayNumber {
                    context += " - Day \(day)"
                }
                context += "]\n"
                
                // Show key points
                for point in session.keyPoints.prefix(3) {
                    context += "  • \(point)\n"
                }
                
                // Show medical values from this session (CRITICAL for trend detection)
                if !session.medicalValues.isEmpty {
                    let valuesStr = session.medicalValues.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    context += "  📊 Values: \(valuesStr)\n"
                }
                
                // Show concerns from this session
                if !session.concerns.isEmpty {
                    context += "  ⚠️ Concerns: \(session.concerns.joined(separator: "; "))\n"
                }
            }
            context += "\n"
        }
        
        // Caregiver info
        if !caregiverConcerns.isEmpty {
            context += "\(caregiverName.uppercased())'S MAIN CONCERNS:\n"
            for concern in caregiverConcerns {
                context += "- \(concern)\n"
            }
            context += "\n"
        }
        
        return context
    }
    
    /// Token-efficient summary for shorter calls
    var shortSummary: String {
        var parts: [String] = []
        parts.append("Patient: \(patientName) (\(caregiverName)'s \(relationship))")
        if !diagnosis.isEmpty { parts.append("Dx: \(diagnosis)") }
        if let days = daysSinceSurgery { parts.append("Day \(days) post-op") }
        if !keyMedicalFacts.isEmpty {
            parts.append("Key facts: \(keyMedicalFacts.suffix(5).joined(separator: "; "))")
        }
        return parts.joined(separator: " | ")
    }
}

// MARK: - Vital Reading

struct VitalReading: Codable {
    let date: Date
    let value: Double
    let unit: String?
}

// MARK: - Memory Store (Singleton)

@MainActor
class AIMemoryStore: ObservableObject {
    static let shared = AIMemoryStore()
    
    @Published var memory: AIMemoryContext
    
    private let storageKey = "rounds_ai_memory_v2"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "rounds_ai_memory_v2"),
           let decoded = try? JSONDecoder().decode(AIMemoryContext.self, from: data) {
            self.memory = decoded
        } else {
            self.memory = AIMemoryContext()
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(memory) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func initializeFromProfile(caregiver: String, patient: String, relationship: String, situation: String) {
        memory.caregiverName = caregiver
        memory.patientName = patient
        memory.relationship = relationship
        memory.diagnosis = situation
        save()
    }
    
    func addSessionMemory(keyPoints: [String], medicalValues: [String: String] = [:], concerns: [String] = [], nextSteps: [String] = [], questionsAsked: [String] = [], dayNumber: Int? = nil) {
        let session = SessionMemory(
            id: UUID(),
            date: Date(),
            dayNumber: dayNumber,
            keyPoints: keyPoints,
            medicalValues: medicalValues,
            concerns: concerns,
            nextSteps: nextSteps,
            questionsAsked: questionsAsked
        )
        memory.addSession(session)
        save()
    }
    
    func learnFacts(_ facts: [String]) {
        for fact in facts {
            memory.addMedicalFact(fact)
        }
        save()
    }
    
    func learnPattern(_ pattern: String) {
        memory.addPattern(pattern)
        save()
    }
    
    func recordVital(_ name: String, value: Double, unit: String? = nil) {
        memory.trackVital(name, value: value, unit: unit)
        save()
    }
    
    func resetMemory() {
        memory = AIMemoryContext()
        save()
    }
}
