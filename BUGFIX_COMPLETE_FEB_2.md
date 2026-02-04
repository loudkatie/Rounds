# ROUNDS AI — COMPLETE BUGFIX PACKAGE
## Feb 2, 2026 — Ready to Apply

---

## THE TWO BUGS

### Bug #1: Medical Term Normalization — MISSING
`normalizeVitalName()` only handles vital signs, NOT:
- Procedures (bronch/bronchoscopy/BAL)
- Diagnoses (A2 rejection/acute rejection/ACR)
- iOS transcription errors ("Bronx" → "bronch")

### Bug #2: Memory Truncation — Loses Day 1 Baseline
```swift
keyMedicalFacts.suffix(15)    // Only last 15 facts
sessions.suffix(7)            // Only last 7 sessions  
vitalTrends[name].suffix(10)  // Only last 10 readings
```
On Day 10, AI can't see Day 1-3 baseline.

---

## PATCH 1: normalizeMedicalTerm()

**WHERE:** Add near `normalizeVitalName()` (around line 200 in OpenAIService.swift)

```swift
/// Normalizes medical terms INCLUDING iOS speech-to-text errors
/// "Bronx" → "bronch" → "bronchoscopy" → "BAL" all become "bronchoscopy"
private func normalizeMedicalTerm(_ term: String) -> String {
    let lowered = term.lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // === iOS TRANSCRIPTION ERRORS + MEDICAL SYNONYMS ===
    
    // Bronchoscopy (iOS often hears "Bronx" for "bronch")
    let bronchTerms = ["bronx", "bronch", "bal", "bronchoscopy", 
                       "bronchoalveolar", "bronchial wash", "bronchoalveolar lavage"]
    if bronchTerms.contains(where: { lowered.contains($0) }) {
        return "bronchoscopy"
    }
    
    // Tacrolimus / Prograf (iOS may hear "tack row" or "pro graph")
    let tacTerms = ["tacrolimus", "prograf", "tacro", "tac level", "tack row",
                    "fk506", "fk-506", "pro graph", "tac ", "tacro level"]
    if tacTerms.contains(where: { lowered.contains($0) }) {
        return "tacrolimus"
    }
    
    // Creatinine (iOS may hear "creat a neen" or "create a nine")
    let creatTerms = ["creatinine", "creat", "cr level", "creat a", 
                      "create a nine", "create a neen", "kidney function"]
    if creatTerms.contains(where: { lowered.contains($0) }) {
        return "creatinine"
    }
    
    // Rejection types
    let rejectionMap: [(terms: [String], canonical: String)] = [
        (["a1 rejection", "a-1", "a 1 rejection", "grade a1", "mild rejection"], "rejection_a1"),
        (["a2 rejection", "a-2", "a 2 rejection", "grade a2", "moderate rejection"], "rejection_a2"),
        (["a3 rejection", "a-3", "a 3 rejection", "grade a3", "severe rejection"], "rejection_a3"),
        (["acute rejection", "acr", "cellular rejection"], "acute_rejection")
    ]
    for (terms, canonical) in rejectionMap {
        if terms.contains(where: { lowered.contains($0) }) {
            return canonical
        }
    }
    
    // Pleural effusion (iOS may split words oddly)
    let effusionTerms = ["pleural effusion", "plural effusion", "effusion", 
                         "fluid in the chest", "fluid in chest", "fluid around lung",
                         "chest fluid", "plural a fusion"]
    if effusionTerms.contains(where: { lowered.contains($0) }) {
        return "pleural_effusion"
    }
    
    // Chest X-ray
    let cxrTerms = ["chest x-ray", "chest xray", "cxr", "chest film", 
                    "chest radiograph", "chest x ray"]
    if cxrTerms.contains(where: { lowered.contains($0) }) {
        return "chest_xray"
    }
    
    // CT scan
    let ctTerms = ["ct scan", "ct chest", "cat scan", "computed tomography", 
                   "ct imaging", "c t scan", "cat's can"]
    if ctTerms.contains(where: { lowered.contains($0) }) {
        return "ct_scan"
    }
    
    // Pneumonia (iOS may hear "new moan ya")
    let pneumoniaTerms = ["pneumonia", "pna", "lung infection", 
                          "pulmonary infection", "new moan", "new monia"]
    if pneumoniaTerms.contains(where: { lowered.contains($0) }) {
        return "pneumonia"
    }
    
    // Ventilation / Intubation
    let ventTerms = ["intubated", "intubation", "on the vent", "ventilator", 
                     "mechanical ventilation", "in tube", "vent settings"]
    if ventTerms.contains(where: { lowered.contains($0) }) {
        return "mechanical_ventilation"
    }
    
    let extubationTerms = ["extubated", "extubation", "off the vent", 
                           "breathing on own", "ex tube"]
    if extubationTerms.contains(where: { lowered.contains($0) }) {
        return "extubation"
    }
    
    // Immunosuppression
    let immunoTerms = ["immunosuppression", "immune suppression", 
                       "anti-rejection", "antirejection", "immuno suppression"]
    if immunoTerms.contains(where: { lowered.contains($0) }) {
        return "immunosuppression"
    }
    
    // WBC / White blood cell count
    let wbcTerms = ["wbc", "white count", "white blood cell", "white cell count",
                    "w b c", "leukocyte"]
    if wbcTerms.contains(where: { lowered.contains($0) }) {
        return "wbc"
    }
    
    // FiO2 / Oxygen
    let o2Terms = ["fio2", "f i o 2", "oxygen", "o2 sat", "saturation", 
                   "sats", "pulse ox"]
    if o2Terms.contains(where: { lowered.contains($0) }) {
        return "oxygen_status"
    }
    
    // Pseudomonas (iOS nightmare)
    let pseudoTerms = ["pseudomonas", "pseudo monas", "sue dough monas",
                       "gram negative rods", "gram-negative"]
    if pseudoTerms.contains(where: { lowered.contains($0) }) {
        return "pseudomonas"
    }
    
    // Methylprednisolone / Steroids
    let steroidTerms = ["methylprednisolone", "methyl pred", "solumedrol",
                        "steroid pulse", "iv steroids", "prednisone"]
    if steroidTerms.contains(where: { lowered.contains($0) }) {
        return "steroids"
    }
    
    // Return normalized (lowercase, spaces to underscores)
    return lowered.replacingOccurrences(of: " ", with: "_")
}
```

---

## PATCH 2: Fix Memory Truncation in buildSystemContext()

**WHERE:** Find `buildSystemContext()` function in OpenAIService.swift

**FIND THESE LINES AND CHANGE:**

```swift
// BEFORE (BROKEN):
let recentFacts = keyMedicalFacts.suffix(15)
let recentSessions = sessions.suffix(7)
// ... later: session.keyPoints.prefix(3)
// ... later: vitalTrends[name].suffix(10)

// AFTER (FIXED):
// Use ALL facts, normalized and deduped
let normalizedFacts = keyMedicalFacts.map { normalizeMedicalTerm($0) }
let uniqueFacts = Array(Set(normalizedFacts))

// Use ALL sessions (or at minimum suffix(10) for 10-day coverage)
let allSessions = sessions  // Don't truncate!

// Use ALL keyPoints (or prefix(5) minimum)
// ... session.keyPoints.prefix(5)

// Use ALL vital readings for trend detection
// ... vitalTrends[name]  // Don't suffix!
```

---

## PATCH 3: Normalize on STORAGE (not just retrieval)

**WHERE:** Wherever you APPEND to `keyMedicalFacts` or `concerns`

```swift
// BEFORE:
keyMedicalFacts.append(fact)
concerns.append(concern)

// AFTER:
keyMedicalFacts.append(normalizeMedicalTerm(fact))
concerns.append(normalizeMedicalTerm(concern))
```

---

## INTEGRATION STEPS

1. Open `Rounds/Services/OpenAIService.swift`

2. Find `normalizeVitalName()` (around line 200)
   - Add `normalizeMedicalTerm()` RIGHT AFTER IT

3. Find `buildSystemContext()` function
   - Replace `.suffix(7)` with `.suffix(10)` minimum OR remove truncation
   - Replace `.suffix(15)` with full array
   - Replace `.prefix(3)` with `.prefix(5)` minimum

4. Search for `keyMedicalFacts.append` and `concerns.append`
   - Wrap the value in `normalizeMedicalTerm()`

5. Build and run the 10-day Don Miller test

---

## VALIDATION CHECKLIST

After applying patches, run the 10-day test and verify:

- [ ] Day 10 response shows creatinine trajectory from 1.1 (Day 1 baseline)
- [ ] "bronch" on Day 3 connects to "BAL" on Day 5 connects to "bronchoscopy" on Day 7
- [ ] "tacro" / "tacrolimus" / "FK506" all recognized as same drug
- [ ] AI asks "What happened to the cultures mentioned on Day 3?"
- [ ] AI shows FULL vital trends, not just "compared to yesterday"
