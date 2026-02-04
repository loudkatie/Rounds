//
//  FullHistoryContextBuilder.swift
//  Rounds AI
//
//  BUG FIX: Builds COMPLETE patient context without truncation.
//  The old buildSystemContext() used .suffix() which lost Day 1 baseline.
//  This version ensures GPT always sees the full patient journey.
//

import Foundation

/// Builds complete patient context for GPT without any truncation
/// Key principle: Day 1 baseline must ALWAYS be visible for trend detection
class FullHistoryContextBuilder {
    
    static let shared = FullHistoryContextBuilder()
    private let normalizer = MedicalTermNormalizer.shared
    
    /// Builds full context string with ALL sessions and ALL data points
    /// - Parameters:
    ///   - sessions: All recorded sessions (not truncated)
    ///   - keyMedicalFacts: All learned facts (normalized)
    ///   - vitalTrends: All vital readings (not truncated)
    ///   - concerns: All ongoing concerns
    ///   - patientCondition: Current patient condition summary
    /// - Returns: Complete context string for GPT system prompt
    func buildContext(
        sessions: [SessionMemory],
        keyMedicalFacts: [String],
        vitalTrends: [String: [VitalReading]],
        concerns: [String],
        patientCondition: String?
    ) -> String {
        
        var context = ""
        
        // SECTION 1: Day 1 Baseline (ALWAYS FIRST)
        if let firstSession = sessions.first {
            context += "🏥 DAY 1 BASELINE — ANCHOR POINT FOR ALL COMPARISONS:\n"
            context += "Date: \(firstSession.dateFormatted)\n"
            
            for point in firstSession.keyPoints {
                context += "  • \(normalizer.normalize(point))\n"
            }
            
            if !firstSession.medicalValues.isEmpty {
                context += "  📊 Baseline Values:\n"
                for (key, value) in firstSession.medicalValues {
                    context += "    - \(normalizer.normalize(key)): \(value)\n"
                }
            }
            context += "\n"
        }
        
        // SECTION 2: Full Vital Trends with % Change from Baseline
        if !vitalTrends.isEmpty {
            context += "📈 VITAL SIGN TRENDS (FULL HISTORY):\n"
            
            for (name, readings) in vitalTrends.sorted(by: { $0.key < $1.key }) {
                guard !readings.isEmpty else { continue }
                
                let normalizedName = normalizer.normalize(name)
                
                if readings.count == 1 {
                    let r = readings[0]
                    context += "- \(normalizedName): \(format(r.value))\(r.unit ?? "") (baseline, single reading)\n"
                } else {
                    // Show full trend: value1 → value2 → value3...
                    let trendStr = readings.map { format($0.value) + ($0.unit ?? "") }.joined(separator: " → ")
                    
                    // Calculate % change from Day 1 baseline
                    let baseline = readings.first!.value
                    let current = readings.last!.value
                    let pctChange = ((current - baseline) / baseline) * 100
                    let changeStr = pctChange >= 0 ? "+\(Int(pctChange))%" : "\(Int(pctChange))%"
                    
                    // Severity indicator
                    let severity = severityIndicator(for: normalizedName, baseline: baseline, current: current, pctChange: pctChange)
                    
                    context += "- \(normalizedName): \(trendStr) (\(changeStr) from Day 1)\(severity)\n"
                }
            }
            context += "\n"
        }
        
        // SECTION 3: All Medical Facts (Normalized, Deduped)
        if !keyMedicalFacts.isEmpty {
            let normalizedFacts = normalizer.normalizeAndDedupe(keyMedicalFacts)
            context += "📋 ALL MEDICAL FACTS LEARNED (\(normalizedFacts.count) total):\n"
            for fact in normalizedFacts {
                context += "- \(fact)\n"
            }
            context += "\n"
        }
        
        // SECTION 4: Recurring Concerns (flagged if mentioned 2+ times)
        let concernCounts = countOccurrences(concerns.map { normalizer.normalize($0) })
        let recurring = concernCounts.filter { $0.value >= 2 }.sorted { $0.value > $1.value }
        
        if !recurring.isEmpty {
            context += "🔴 RECURRING CONCERNS (mentioned multiple times):\n"
            for (concern, count) in recurring {
                let flag = count >= 3 ? "🚨" : "⚠️"
                context += "\(flag) \(concern) — mentioned \(count)x\n"
            }
            context += "\n"
        }
        
        // SECTION 5: All Session Summaries (excluding Day 1 already shown)
        if sessions.count > 1 {
            context += "📅 SESSION HISTORY (Days 2-\(sessions.count)):\n"
            
            for session in sessions.dropFirst() {
                context += "\n[\(session.dateFormatted)"
                if let day = session.dayNumber {
                    context += " - Day \(day)"
                }
                context += "]\n"
                
                // ALL key points (not truncated)
                for point in session.keyPoints {
                    context += "  • \(normalizer.normalize(point))\n"
                }
                
                // Medical values from this session
                if !session.medicalValues.isEmpty {
                    let valuesStr = session.medicalValues.map { "\(normalizer.normalize($0.key)): \($0.value)" }.joined(separator: ", ")
                    context += "  📊 \(valuesStr)\n"
                }
                
                // Concerns from this session
                if !session.concerns.isEmpty {
                    context += "  ⚠️ \(session.concerns.map { normalizer.normalize($0) }.joined(separator: "; "))\n"
                }
            }
            context += "\n"
        }
        
        // SECTION 6: Current Condition Summary
        if let condition = patientCondition, !condition.isEmpty {
            context += "🩺 CURRENT STATUS: \(condition)\n\n"
        }
        
        return context
    }
    
    // MARK: - Helpers
    
    private func format(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
    
    private func countOccurrences(_ items: [String]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for item in items {
            counts[item, default: 0] += 1
        }
        return counts
    }
    
    private func severityIndicator(for vital: String, baseline: Double, current: Double, pctChange: Double) -> String {
        let name = vital.lowercased()
        
        if name.contains("creatinine") {
            if pctChange > 50 { return " 🚨 CRITICAL" }
            if pctChange > 25 { return " ⚠️ CONCERNING" }
            if pctChange > 10 { return " 📈 Watch" }
        } else if name.contains("oxygen") {
            if current >= 4 { return " 🚨 HIGH SUPPORT" }
            if current > baseline { return " ⚠️ INCREASING" }
        } else if name.contains("temp") {
            if current >= 100.5 { return " 🚨 FEVER" }
            if current >= 99.5 { return " ⚠️ LOW-GRADE" }
        } else if name.contains("wbc") || name.contains("white") {
            if current > 12 { return " 🚨 ELEVATED" }
            if current > 10 { return " ⚠️ Watch" }
        }
        
        return ""
    }
}
