//
//  MedicalTermNormalizer.swift
//  Rounds
//
//  Created: Feb 2, 2026
//  BUG FIX #1: Normalizes medical terminology
//  "bronch" = "BAL" = "bronchoscopy" (all stored as same term)
//
//  INSTALLATION: Add this file to Rounds/Services/ folder in Xcode
//

import Foundation

class MedicalTermNormalizer {
    
    static let shared = MedicalTermNormalizer()
    private init() {}
    
    /// Normalizes medical terms so variations are stored consistently
    /// Example: "bronch", "BAL", "Bronchoscopy" all become "bronchoscopy"
    func normalize(_ term: String) -> String {
        let lowered = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Bronchoscopy variants
        if ["bronch", "bal", "bronchoscopy", "bronchoalveolar lavage", "bronchoalveolar", "bronchial wash"].contains(where: { lowered.contains($0) }) {
            return "bronchoscopy"
        }
        
        // Rejection variants (preserve grade level)
        if ["rejection", "acr", "cellular rejection", "grade a"].contains(where: { lowered.contains($0) }) {
            if lowered.contains("a1") || lowered.contains("grade 1") { return "acute_rejection_a1" }
            if lowered.contains("a2") || lowered.contains("grade 2") { return "acute_rejection_a2" }
            if lowered.contains("a3") || lowered.contains("grade 3") { return "acute_rejection_a3" }
            return "acute_rejection"
        }
        
        // Pleural effusion variants
        if ["pleural effusion", "effusion", "fluid in lung", "fluid around lung", "chest fluid"].contains(where: { lowered.contains($0) }) {
            return "pleural_effusion"
        }
        
        // Tacrolimus/Prograf variants
        if ["tacrolimus", "prograf", "tac level", "tac ", "fk506", "fk-506"].contains(where: { lowered.contains($0) }) {
            return "tacrolimus"
        }
        
        // Creatinine variants
        if ["creatinine", "creat", "cr level", "kidney function"].contains(where: { lowered.contains($0) }) {
            return "creatinine"
        }
        
        // Chest X-ray variants
        if ["chest x-ray", "chest xray", "cxr", "chest film", "chest radiograph"].contains(where: { lowered.contains($0) }) {
            return "chest_xray"
        }
        
        // CT scan variants
        if ["ct scan", "ct chest", "cat scan", "computed tomography"].contains(where: { lowered.contains($0) }) {
            return "ct_scan"
        }
        
        // Pneumonia variants
        if ["pneumonia", "pna", "lung infection", "pulmonary infection"].contains(where: { lowered.contains($0) }) {
            return "pneumonia"
        }
        
        // Mechanical ventilation
        if ["intubated", "intubation", "on the vent", "ventilator", "mechanical ventilation"].contains(where: { lowered.contains($0) }) {
            return "mechanical_ventilation"
        }
        
        // Extubation
        if ["extubated", "extubation", "off the vent", "breathing on own"].contains(where: { lowered.contains($0) }) {
            return "extubation"
        }
        
        // Immunosuppression
        if ["immunosuppression", "immune suppression", "anti-rejection", "antirejection"].contains(where: { lowered.contains($0) }) {
            return "immunosuppression"
        }
        
        // Oxygen therapy
        if ["nasal cannula", "high flow", "bipap", "cpap", "supplemental oxygen"].contains(where: { lowered.contains($0) }) {
            if lowered.contains("high flow") { return "high_flow_oxygen" }
            if lowered.contains("bipap") { return "bipap" }
            if lowered.contains("cpap") { return "cpap" }
            return "supplemental_oxygen"
        }
        
        if lowered.contains("room air") { return "room_air" }
        
        // Default: clean up whitespace
        return lowered.replacingOccurrences(of: " ", with: "_")
    }
    
    /// Normalize array and remove duplicates
    func normalizeAndDedupe(_ terms: [String]) -> [String] {
        let normalized = terms.map { normalize($0) }
        return Array(Set(normalized))
    }
}
