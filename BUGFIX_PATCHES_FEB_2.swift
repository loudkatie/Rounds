// BUGFIX PATCHES FOR ROUNDS AI v0.3.1
// Created: Feb 2, 2026
// Apply these patches to OpenAIService.swift
// 
// BUG #1: Medical terms not normalized (bronch vs Bronchoscopy vs BAL = 3 different objects)
// BUG #2: Memory truncation loses Day 1-3 baseline when patient is on Day 10+

// ============================================
// PATCH 1: ADD THIS FUNCTION (near normalizeVitalName around line 200)
// ============================================

/// Normalizes medical terms, procedures, and diagnoses to canonical forms
/// so "bronch", "BAL", "Bronchoscopy", "bronchoalveolar lavage" all match
private func normalizeMedicalTerm(_ term: String) -> String {
    let lowered = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Bronchoscopy variants
    let bronchTerms = ["bronch", "bal", "bronchoscopy", "bronchoalveolar lavage", "bronchoalveolar", "bronchial wash"]
    if bronchTerms.contains(where: { lowered.contains($0) }) {
        return "bronchoscopy"
    }
    
    // Rejection variants
    let rejectionTerms = ["a2 rejection", "acute rejection", "acr", "cellular rejection", "grade a2", "a1 rejection", "a3 rejection"]
    if rejectionTerms.contains(where: { lowered.contains($0) }) {
        if lowered.contains("a1") { return "acute_rejection_a1" }
        if lowered.contains("a2") { return "acute_rejection_a2" }
        if lowered.contains("a3") { return "acute_rejection_a3" }
        return "acute_rejection"
    }
    
    // Pleural effusion variants
    let effusionTerms = ["pleural effusion", "effusion", "fluid in lung", "fluid around lung", "chest fluid"]
    if effusionTerms.contains(where: { lowered.contains($0) }) {
        return "pleural_effusion"
    }
    
    // Tacrolimus/Prograf variants
    let tacTerms = ["tacrolimus", "prograf", "tac level", "tac", "fk506", "fk-506"]
    if tacTerms.contains(where: { lowered.contains($0) }) {
        return "tacrolimus"
    }
    
    // Creatinine variants
    let creatTerms = ["creatinine", "creat", "cr level", "kidney function"]
    if creatTerms.contains(where: { lowered.contains($0) }) {
        return "creatinine"
    }
    
    // Chest X-ray variants
    let cxrTerms = ["chest x-ray", "chest xray", "cxr", "chest film", "chest radiograph"]
    if cxrTerms.contains(where: { lowered.contains($0) }) {
        return "chest_xray"
    }
    
    // CT scan variants
    let ctTerms = ["ct scan", "ct chest", "cat scan", "computed tomography", "ct imaging"]
    if ctTerms.contains(where: { lowered.contains($0) }) {
        return "ct_scan"
    }
    
    // Pneumonia variants
    let pneumoniaTerms = ["pneumonia", "pna", "lung infection", "pulmonary infection"]
    if pneumoniaTerms.contains(where: { lowered.contains($0) }) {
        return "pneumonia"
    }
    
    // Intubation/extubation
    let intubationTerms = ["intubated", "intubation", "on the vent", "ventilator", "mechanical ventilation"]
    if intubationTerms.contains(where: { lowered.contains($0) }) {
        return "mechanical_ventilation"
    }
    
    let extubationTerms = ["extubated", "extubation", "off the vent", "breathing on own"]
    if extubationTerms.contains(where: { lowered.contains($0) }) {
        return "extubation"
    }
    
    // Immunosuppression
    let immunoTerms = ["immunosuppression", "immune suppression", "anti-rejection", "antirejection"]
    if immunoTerms.contains(where: { lowered.contains($0) }) {
        return "immunosuppression"
    }
    
    // Return original if no match (preserves specificity for unknown terms)
    return lowered.replacingOccurrences(of: " ", with: "_")
}


// ============================================
// PATCH 2: FIX buildSystemContext() MEMORY TRUNCATION
// Location: OpenAIService.swift, find buildSystemContext function
// REPLACE the truncation logic with this approach
// ============================================

/*
CURRENT BROKEN CODE (find and replace these lines):

let recentFacts = patient.keyMedicalFacts.suffix(15)
let recentSessions = patient.sessions.suffix(7)
// ... session.keyPoints.prefix(3)
// ... vitalTrends[name].suffix(10)

REPLACE WITH THE LOGIC BELOW:
*/

// In buildSystemContext(), replace truncation with smart baseline preservation:

private func buildFullHistoryContext(for patient: Patient) -> String {
    var context = ""
    
    // CRITICAL: Always start with Day 1 baseline
    context += "=== DAY 1 BASELINE (ANCHOR POINT) ===\n"
    if let firstSession = patient.sessions.first {
        context += "Date: \(firstSession.date.formatted())\n"
        context += "Initial condition: \(patient.condition)\n"
        context += "Baseline keypoints: \(firstSession.keyPoints.joined(separator: "; "))\n"
    }
    
    // ALL medical facts, normalized and deduped
    context += "\n=== ALL MEDICAL FACTS (NORMALIZED) ===\n"
    let normalizedFacts = patient.keyMedicalFacts.map { normalizeMedicalTerm($0) }
    let uniqueFacts = Array(Set(normalizedFacts))
    context += uniqueFacts.joined(separator: "\n")
    
    // FULL vital history with Day 1 baseline comparison
    context += "\n\n=== VITAL TRENDS (FROM DAY 1 BASELINE) ===\n"
    for (name, readings) in patient.vitalTrends {
        guard let baseline = readings.first, let current = readings.last else { continue }
        let change = ((current.value - baseline.value) / baseline.value) * 100
        let arrow = change > 5 ? "📈" : change < -5 ? "📉" : "→"
        context += "\(normalizeVitalName(name)): "
        context += "Day1=\(baseline.value) → Now=\(current.value) "
        context += "(\(String(format: "%+.1f", change))%) \(arrow)\n"
        // Include ALL readings for trend detection
        context += "  History: \(readings.map { String(format: "%.1f", $0.value) }.joined(separator: "→"))\n"
    }


// ============================================
// PATCH 1B: iOS AUTOCORRECT HANDLING
// Add these to the bronchTerms array in normalizeMedicalTerm()
// ============================================

// UPDATED bronch handling (iOS autocorrects "bronch" to "Bronx"):
let bronchTerms = [
    "bronch", "bal", "bronchoscopy", "bronchoalveolar lavage", 
    "bronchoalveolar", "bronchial wash",
    // iOS AUTOCORRECT FIXES:
    "bronx",      // iOS autocorrects "bronch" → "Bronx"
    "the bronx",  // Sometimes captures as "the Bronx"
    "broncs",     // Plural mishear
    "bronk",      // Phonetic mishear
    "bronco"      // Another autocorrect variant
]

// Similarly for heart rate (iOS splits or mishears):
let heartRateTerms = [
    "heart rate", "heartrate", "hr", "pulse", "bpm",
    // iOS MISHEARS:
    "hard rate",   // Mishear
    "art rate",    // Mishear  
    "heart right"  // Mishear
]

// Tacrolimus (complex drug name, often mangled):
let tacTerms = [
    "tacrolimus", "prograf", "tac level", "tac", "fk506", "fk-506",
    // iOS MISHEARS:
    "tack", "tack level", "tack row", "tacro", "program"  // Prograf → "program"
]
