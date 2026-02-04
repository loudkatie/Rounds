# 🔧 CODE FIXES: Memory Regression Bugs

**Date:** February 2, 2026  
**Issue:** v0.3.1 losing baseline context, medical terms not normalized

---

## BUG #1: Medical Term Normalization

### Problem
`normalizeVitalName()` only handles vital signs (creatinine, tacrolimus, etc.)
Medical procedures and diagnoses get stored as raw strings:
- "bronch" vs "bronchoscopy" vs "BAL" → stored as 3 different things
- AI can't connect "bronch results pending" with "BAL grew pseudomonas"

### Fix: Add `normalizeMedicalTerm()` to OpenAIService.swift

Add this function around line 270 (after `normalizeVitalName`):

```swift
// MARK: - Medical Term Normalization

/// Normalizes medical procedures, diagnoses, and test names to canonical forms.
/// "bronch", "bronchoscopy", "BAL" → "Bronchoscopy"
private func normalizeMedicalTerm(_ term: String) -> String {
    let lowercased = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Bronchoscopy variants
    if lowercased.contains("bronch") || lowercased == "bal" || 
       lowercased.contains("bronchoalveolar") || lowercased.contains("airway wash") {
        return "Bronchoscopy"
    }
    
    // Rejection variants
    if lowercased.contains("rejection") || lowercased.hasPrefix("a1") || 
       lowercased.hasPrefix("a2") || lowercased.hasPrefix("a3") || 
       lowercased.contains("acr") || lowercased.contains("acute cellular") {
        // Preserve grade if present
        if lowercased.contains("a1") { return "Rejection_A1" }
        if lowercased.contains("a2") { return "Rejection_A2" }
        if lowercased.contains("a3") { return "Rejection_A3" }
        if lowercased.contains("a4") { return "Rejection_A4" }
        return "Rejection"
    }
    
    // Effusion variants
    if lowercased.contains("effusion") || lowercased.contains("fluid in") && 
       (lowercased.contains("chest") || lowercased.contains("lung") || lowercased.contains("pleura")) {
        return "PleuralEffusion"
    }
    
    // Biopsy variants
    if lowercased.contains("biopsy") || lowercased.contains("tbx") || 
       lowercased.contains("transbronchial") {
        return "Biopsy"
    }
    
    // X-ray variants
    if lowercased.contains("x-ray") || lowercased.contains("xray") || 
       lowercased.contains("cxr") || lowercased.contains("chest film") ||
       lowercased.contains("chest x") {
        return "ChestXRay"
    }
    
    // CT variants
    if lowercased.contains("ct scan") || lowercased.contains("cat scan") ||
       lowercased == "ct" {
        return "CTScan"
    }
    
    // Intubation/extubation
    if lowercased.contains("intubat") || lowercased.contains("on the vent") ||
       lowercased.contains("ventilator") {
        return "Intubation"
    }
    if lowercased.contains("extubat") {
        return "Extubation"
    }
    
    // Thoracentesis
    if lowercased.contains("thoracentesis") || lowercased.contains("tap") && 
       lowercased.contains("chest") || lowercased.contains("tapping") && 
       lowercased.contains("fluid") {
        return "Thoracentesis"
    }
    
    // Dialysis
    if lowercased.contains("dialysis") || lowercased.contains("hemodialysis") ||
       lowercased == "hd" {
        return "Dialysis"
    }
    
    // Physical therapy
    if lowercased.contains("pt ") || lowercased.contains("physical therapy") ||
       lowercased == "pt" {
        return "PhysicalTherapy"
    }
    
    // Feeding tube
    if lowercased.contains("feeding tube") || lowercased.contains("ng tube") ||
       lowercased.contains("dobhoff") || lowercased.contains("peg") {
        return "FeedingTube"
    }
    
    // Pseudomonas
    if lowercased.contains("pseudomonas") || lowercased.contains("gram negative rod") {
        return "Pseudomonas"
    }
    
    // Default: return original with first letter capitalized
    return term.prefix(1).uppercased() + term.dropFirst()
}
```

### Where to Apply Normalization

In `saveLearnedKnowledge()`, normalize medical facts before storing:

```swift
private func saveLearnedKnowledge(from analysis: ExtendedAnalysis) async {
    let memoryStore = AIMemoryStore.shared
    
    if let facts = analysis.newFactsLearned {
        let normalizedFacts = facts.map { fact -> String in
            // Extract and normalize any medical terms in the fact
            var normalizedFact = fact
            let termsToNormalize = ["bronch", "bal", "biopsy", "rejection", "effusion", 
                                     "x-ray", "xray", "ct scan", "pt ", "dialysis"]
            for term in termsToNormalize {
                if fact.lowercased().contains(term) {
                    let normalized = normalizeMedicalTerm(fact)
                    // Don't replace whole fact, just log that we recognized it
                    print("[Memory] Recognized medical term in fact")
                    break
                }
            }
            return normalizedFact
        }
        memoryStore.learnFacts(normalizedFacts)
        print("[Memory] Learned \(facts.count) new facts")
    }
    
    // ... rest of function unchanged
}
```

---

## BUG #2: Session History Truncation

### Problem
`buildSystemContext()` in AIMemoryContext.swift:
- `sessions.suffix(7)` → Only shows last 7 days
- On Day 10, AI literally cannot see Days 1-3 baseline
- `keyMedicalFacts.suffix(15)` → Early facts get lost

### Fix: Update AIMemoryContext.swift

Replace the truncation with dynamic limits:

```swift
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
    
    // Patient context - unchanged
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
    
    // Learned facts - INCREASED LIMIT
    if !keyMedicalFacts.isEmpty {
        context += "MEDICAL FACTS YOU'VE LEARNED:\n"
        // Show up to 30 facts (was 15)
        for fact in keyMedicalFacts.suffix(30) {
            context += "- \(fact)\n"
        }
        context += "\n"
    }
    
    // Vital trends - SHOW ALL READINGS FOR TRAJECTORY
    if !vitalTrends.isEmpty {
        context += "🔴 VITAL SIGN TRENDS — FULL TRAJECTORY FROM DAY 1:\n"
        for (name, readings) in vitalTrends {
            if readings.count >= 2 {
                // Show ALL readings (up to 20), not just last 10
                let values = readings.map { 
                    String(format: "%.1f", $0.value) + ($0.unit ?? "")
                }.joined(separator: " → ")
                
                // Calculate % change from BASELINE (first reading)
                let baseline = readings.first!.value
                let current = readings.last!.value
                let percentChange = ((current - baseline) / baseline) * 100
                
                // Determine severity (unchanged logic)
                var severity = ""
                
                if name.lowercased().contains("creatinine") {
                    if percentChange > 50 { severity = "🚨 CRITICAL" }
                    else if percentChange > 25 { severity = "⚠️ CONCERNING" }
                    else if percentChange > 10 { severity = "📈 Watch closely" }
                } else if name.lowercased().contains("oxygen") && name.lowercased().contains("liter") {
                    if current >= 4 { severity = "🚨 HIGH SUPPORT" }
                    else if current > baseline { severity = "⚠️ INCREASING" }
                } else if name.lowercased().contains("temp") {
                    if current >= 100.5 { severity = "🚨 FEVER" }
                    else if current >= 99.5 { severity = "⚠️ LOW-GRADE FEVER" }
                    else if current > baseline && current > 98.6 { severity = "📈 Trending up" }
                } else if name.lowercased().contains("white") || name.lowercased().contains("wbc") {
                    if current > 12 { severity = "🚨 ELEVATED" }
                    else if current > 10 { severity = "⚠️ Watch for infection" }
                }
                
                // Build the output line
                var line = "- \(name): \(values)"
                if readings.count >= 2 {
                    let changeStr = percentChange >= 0 ? "+\(String(format: "%.0f", percentChange))%" : "\(String(format: "%.0f", percentChange))%"
                    line += " (\(changeStr) from Day 1 baseline)"
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
    
    // Patterns - unchanged
    if !observedPatterns.isEmpty {
        context += "PATTERNS YOU'VE NOTICED:\n"
        for pattern in observedPatterns {
            context += "- \(pattern)\n"
        }
        context += "\n"
    }
    
    // Ongoing concerns - unchanged
    if !ongoingConcerns.isEmpty {
        context += "THINGS BEING MONITORED:\n"
        for concern in ongoingConcerns {
            context += "- \(concern)\n"
        }
        context += "\n"
    }
    
    // Session history - INCREASED TO SHOW ALL RECENT SESSIONS
    if !sessions.isEmpty {
        context += "📋 COMPLETE SESSION HISTORY (Day 1 to present):\n"
        
        // Dynamic limit: show up to 14 sessions (2 weeks)
        // But ALWAYS include Day 1 if we have it
        let maxSessions = min(sessions.count, 14)
        let sessionsToShow: [SessionMemory]
        
        if sessions.count <= maxSessions {
            // Show all sessions if we have fewer than max
            sessionsToShow = sessions
        } else {
            // Show first session (baseline) + most recent sessions
            var selected = [sessions[0]]  // Day 1 baseline
            selected.append(contentsOf: sessions.suffix(maxSessions - 1))
            sessionsToShow = selected
            
            // Note the gap if sessions were skipped
            if sessions.count > maxSessions {
                context += "(Showing Day 1 baseline + most recent \(maxSessions - 1) sessions)\n"
            }
        }
        
        for session in sessionsToShow {
            context += "\n[\(session.dateFormatted)"
            if let day = session.dayNumber {
                context += " - Day \(day)"
            }
            context += "]\n"
            
            // Show ALL key points (was prefix(3))
            for point in session.keyPoints.prefix(5) {
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
    
    // Caregiver info - unchanged
    if !caregiverConcerns.isEmpty {
        context += "\(caregiverName.uppercased())'S MAIN CONCERNS:\n"
        for concern in caregiverConcerns {
            context += "- \(concern)\n"
        }
        context += "\n"
    }
    
    return context
}
```

---

## BUG #3: Pending Items Not Tracked

### Problem
When doctors say "we'll check cultures tomorrow" — this isn't stored as a trackable item.
AI can't proactively ask "what happened to the cultures?"

### Fix: Add PendingItem tracking

Add to AIMemoryContext.swift:

```swift
// MARK: - Pending Items (things doctors said they'd do)

struct PendingItem: Codable, Identifiable {
    let id: UUID
    let dayMentioned: Int
    let description: String  // "Check cultures"
    var resolved: Bool
    var resolvedDay: Int?
    var resolution: String?  // "Cultures grew Pseudomonas"
}

// Add to AIMemoryContext struct:
var pendingItems: [PendingItem]

// In buildSystemContext(), add section:
if !pendingItems.isEmpty {
    let unresolved = pendingItems.filter { !$0.resolved }
    if !unresolved.isEmpty {
        context += "⏳ THINGS DOCTORS SAID THEY'D CHECK (still pending):\n"
        for item in unresolved {
            context += "- Day \(item.dayMentioned): \"\(item.description)\" — NOT YET MENTIONED\n"
        }
        context += "\n"
    }
}
```

Then update the prompt to ask GPT to extract pending items:

```json
"pendingItems": [
    {
        "description": "Check cultures",
        "isNewPending": true
    },
    {
        "description": "Bronch results",
        "isResolved": true,
        "resolution": "A1 rejection"
    }
]
```

---

## SUMMARY OF CHANGES

| File | Change | Lines |
|------|--------|-------|
| OpenAIService.swift | Add `normalizeMedicalTerm()` | ~270 |
| OpenAIService.swift | Apply normalization in `saveLearnedKnowledge()` | ~295 |
| AIMemoryContext.swift | Increase `keyMedicalFacts.suffix(15)` → `suffix(30)` | ~195 |
| AIMemoryContext.swift | Show ALL vital readings, not `suffix(10)` | ~210 |
| AIMemoryContext.swift | Change `sessions.suffix(7)` → dynamic with Day 1 always included | ~245 |
| AIMemoryContext.swift | Increase `session.keyPoints.prefix(3)` → `prefix(5)` | ~265 |
| AIMemoryContext.swift | (Optional) Add `PendingItem` tracking | New struct |

---

## TESTING AFTER FIXES

1. Reset memory: In app, go to settings → "Reset Memory"
2. Run 10-day test script: `/Users/katiemacair-2025/04_Developer/Rounds/Scripts & Results/TEST_10DAY_DONMILLER_STRESS.md`
3. Verify:
   - Day 10 shows creatinine trajectory from Day 1 (1.1 → ... → 2.0)
   - "bronch" / "BAL" / "bronchoscopy" are recognized as related
   - AI asks about pending cultures before Day 9

---

## ROLLBACK

If these changes break something, git commit hash for safe rollback:
```
c8ec9c0 v0.3.0-backup: Pre-prompt-rewrite state — SAFE ROLLBACK POINT
```
