# 🔍 Rounds AI Memory Loop - Complete Audit

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DAY 5: User Records Transcript                                             │
│  "Day five post-transplant... creatinine is 1.2... tacrolimus 9.8..."       │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  OpenAIService.analyzeTranscript()                                          │
│  1. Gets memoryContext = memoryStore.memory.buildSystemContext()            │
│  2. Sends to GPT with full patient history (empty on Day 5)                │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GPT Returns ExtendedAnalysis JSON:                                         │
│  {                                                                          │
│    "explanation": "...",                                                    │
│    "summaryPoints": ["..."],                                                │
│    "followUpQuestions": ["..."],                                            │
│    "newFactsLearned": ["Don had bilateral lung transplant"],                │
│    "vitalValues": {"Creatinine": 1.2, "Tacrolimus": 9.8, ...},              │
│    "concerns": ["..."],                                                     │
│    "patterns": ["..."],                                                     │
│    "dayNumber": 5                                                           │
│  }                                                                          │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  saveLearnedKnowledge(from: analysis)                                       │
│                                                                             │
│  ✅ memoryStore.learnFacts(facts)         → keyMedicalFacts[]               │
│  ✅ memoryStore.recordVital(name, value)  → vitalTrends[name].append()      │
│  ✅ memoryStore.learnPattern(pattern)     → observedPatterns[]              │
│  ✅ memoryStore.addSessionMemory(...)     → sessions[] with:                │
│       - keyPoints                                                           │
│       - medicalValues (dict)                                                │
│       - concerns                                                            │
│       - dayNumber (from transcript!)                                        │
│  ✅ memoryStore.save()                    → UserDefaults persistence        │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  DAY 6: User Records Next Transcript                                        │
│  "Day six... creatinine is 1.5... tacrolimus 10.2..."                       │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  buildSystemContext() generates:                                            │
│                                                                             │
│  PATIENT INFORMATION:                                                       │
│  - Name: Don                                                                │
│  - Relationship: Katie's father                                             │
│  - Diagnosis: Lung transplant                                               │
│                                                                             │
│  VITAL SIGN TRENDS (oldest → newest):                                       │
│  - Creatinine: 1.2 (first reading)                                          │
│  - Tacrolimus: 9.8 (first reading)                                          │
│  - Temperature: 98.4 (first reading)                                        │
│  - OxygenLiters: 2.0 (first reading)                                        │
│                                                                             │
│  PAST SESSION SUMMARIES:                                                    │
│  [Fri, Jan 31 - Day 5]                                                      │
│    • Stable overnight, vitals good                                          │
│    • Chest X-ray clear, walking 200 feet                                    │
│    📊 Values: Creatinine: 1.2, Tacrolimus: 9.8                              │
│    ⚠️ Concerns: None noted                                                  │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GPT Receives Full Context + Day 6 Transcript                               │
│                                                                             │
│  Prompt Instructions:                                                       │
│  🔴 USE PATIENT HISTORY - THIS IS CRUCIAL:                                  │
│  - COMPARE today's values to previous values                                │
│  - NOTE TRENDS: improving, stable, or concerning                            │
│  - FLAG INCONSISTENCIES                                                     │
│                                                                             │
│  🚨 RED FLAG DETECTION - BE VIGILANT:                                       │
│  - CREATININE: Rising = kidney stress. Flag ANY increase.                   │
│  - OXYGEN: Should be DECREASING. If going UP, that's bad.                   │
│  - TEMPERATURE: 99+ needs attention. 100+ is urgent.                        │
│                                                                             │
│  🔍 CATCH THE BURIED BOMBSHELL:                                             │
│  - "A2 rejection" = MAJOR NEWS even if they say "moderate"                  │
│  - "Back to ICU" = situation worsening                                      │
│  - "We consulted nephrology" = KIDNEYS ARE CONCERNING                       │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GPT Response for Day 6 Should Include:                                     │
│                                                                             │
│  explanation: "⚠️ Creatinine went UP from 1.2 to 1.5 (25% increase).        │
│               This needs watching. Tacrolimus also crept up..."             │
│                                                                             │
│  followUpQuestions:                                                         │
│    - "The creatinine jumped from 1.2 to 1.5. Is this concerning?"           │
│    - "Yesterday's plan was to wean oxygen. Did that happen?"                │
│                                                                             │
│  vitalValues: {"Creatinine": 1.5, "Tacrolimus": 10.2, ...}                  │
│                                                                             │
│  concerns: ["Creatinine rising - was 1.2, now 1.5"]                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ✅ Verification Checklist

### 1. Data Extraction from GPT
| Field | Extracted? | Stored Where? | Persisted? |
|-------|------------|---------------|------------|
| explanation | ✅ | RoundsAnalysis → UI | Session only |
| summaryPoints | ✅ | Session.keyPoints | ✅ UserDefaults |
| followUpQuestions | ✅ | RoundsAnalysis → UI | Session only |
| newFactsLearned | ✅ | keyMedicalFacts[] | ✅ UserDefaults |
| vitalValues | ✅ | vitalTrends[name][] | ✅ UserDefaults |
| concerns | ✅ | Session.concerns | ✅ UserDefaults |
| patterns | ✅ | observedPatterns[] | ✅ UserDefaults |
| dayNumber | ✅ | Session.dayNumber | ✅ UserDefaults |

### 2. Memory Context Sent to GPT
| Data | Included in Prompt? |
|------|---------------------|
| Patient name & relationship | ✅ |
| Diagnosis | ✅ |
| Key medical facts | ✅ (last 15) |
| Vital trends with arrows | ✅ (last 7 readings per vital) |
| Observed patterns | ✅ |
| Ongoing concerns | ✅ |
| Session history with values | ✅ (last 7 sessions) |

### 3. Red Flag Instructions
| Scenario | Instruction Given? |
|----------|-------------------|
| Temperature rise | ✅ "99+ needs attention, 100+ urgent" |
| Creatinine increase | ✅ "Rising = kidney stress, flag ANY increase" |
| Oxygen going UP | ✅ "Should be DECREASING, if UP that's bad" |
| Back to ICU | ✅ "= situation worsening" |
| A2 rejection | ✅ "= MAJOR NEWS even if 'moderate'" |
| Consult added | ✅ "= that organ is concerning" |

### 4. Clear History Feature
- ✅ `AIMemoryStore.resetMemory()` exists
- ✅ Account sheet has "Clear Medical History" button
- ✅ Confirmation dialog before clear
- ✅ Shows session count in Account sheet

## Files Modified in This Session

| File | Changes |
|------|---------|
| OpenAIService.swift | Added dayNumber to ExtendedAnalysis, fixed decoder, enhanced vitalValues extraction, added red flag detection |
| AIMemoryContext.swift | Enhanced vital trends display with arrows, added medical values to session display |
| LandingView.swift | Added Clear History button, HTML email formatting |

## Known Limitations

1. **Surgery date not auto-set**: `daysSinceSurgery` requires manual surgery date entry. GPT now extracts `dayNumber` from transcript as fallback.

2. **First session has no history**: Day 5 baseline will show "(first reading)" for all vitals.

3. **Vital name normalization**: GPT might say "WBC" vs "WhiteBloodCell" - we should consider normalizing these.

## Testing Recommendation

1. Clear history via Account > Clear Medical History
2. Run through Day 5 → Day 10 scripts sequentially  
3. After each session, verify:
   - Did GPT compare to previous values?
   - Did GPT flag concerning trends?
   - Are follow-up questions personalized to Don's history?
   - Does urgency escalate appropriately?
