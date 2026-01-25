# 🩺 Rounds AI — Hackathon Build Plan
**Date:** January 24, 2026  
**Team:** Katie (Product/CEO) + Claude (Tech Cofounder/Engineer)  
**Budget:** $35.63 OpenAI credits  
**Goal:** Stupid-simple, elegant, FAST caregiver companion app

---

## The Vision (Katie's Words)

> "Once they share their first name and patient's name, that's a relationship. We cannot forget things between sessions."

> "WE are hosting them. WE are earning their trust which only happens after we keep showing up for them day after day."

> "It's not for the hospital. It's not even really for the patient. It's for the caregiver."

---

## Core Architecture

### 1. User Identity & Memory Model

```
┌─────────────────────────────────────────────────────────────┐
│                      UserProfile                            │
├─────────────────────────────────────────────────────────────┤
│ id: UUID                                                    │
│ caregiverName: String         // "Katie"                    │
│ patientName: String           // "Don"                      │
│ patientSituation: String      // "Stage 4 lymphoma..."      │
│ createdAt: Date                                             │
│ ─────────────────────────────────────────────────────────── │
│ sessions: [RoundsSession]     // All recorded sessions      │
│ aiMemory: AIMemoryContext     // Cumulative AI context      │
└─────────────────────────────────────────────────────────────┘
```

### 2. AI Memory Context (The "Growing Friendship")

```swift
struct AIMemoryContext: Codable {
    // Core facts the AI should never forget
    var caregiverName: String
    var patientName: String
    var diagnosis: String
    
    // Evolving understanding (updated after each session)
    var keyMedicalFacts: [String]      // "Don is on 2L oxygen"
    var currentMedications: [String]   // "Prednisone 40mg daily"
    var careTeamMembers: [String]      // "Dr. Patel (pulmonology)"
    var ongoingConcerns: [String]      // "Pain management"
    var recentUpdates: [String]        // Last 5 session summaries
    
    // Emotional context
    var emotionalNotes: [String]       // "Katie mentioned feeling overwhelmed on 1/15"
    
    // Computed summary for API calls (token-efficient)
    var contextSummary: String { ... }
}
```

### 3. Budget-Smart API Strategy

**Model Choice:** `gpt-4o-mini` ($0.15/1M input, $0.60/1M output)

**Token Budget Per Session:**
- System prompt with memory context: ~800 tokens
- Transcript input: ~1,500 tokens (5 min of speech)
- AI response: ~500 tokens
- **Total per session:** ~2,800 tokens ≈ $0.002

**With $35.63 budget:** ~17,800 sessions possible (we're fine!)

**Memory Efficiency:**
- Store `AIMemoryContext` locally on device
- Only send compressed context summary to API
- Update memory locally after each AI response
- Never re-send full transcript history

---

## File Structure (Simplified)

```
Rounds/
├── RoundsApp.swift                 # App entry
├── Models/
│   ├── UserProfile.swift           # NEW: User identity
│   ├── AIMemoryContext.swift       # NEW: Persistent AI memory
│   ├── RoundsSession.swift         # Recording session
│   └── RecordingSession.swift      # (rename/merge)
├── Services/
│   ├── STTService.swift            # Speech-to-text (optimize)
│   ├── OpenAIService.swift         # AI calls (add memory)
│   ├── ProfileStore.swift          # NEW: User persistence
│   └── SessionStore.swift          # Session persistence
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingFlow.swift    # NEW: 3-step guided setup
│   ├── Recording/
│   │   └── RecordingView.swift     # NEW: Jitterbug 2-button UI
│   ├── Results/
│   │   └── ResultsView.swift       # NEW: AI recap + share
│   └── RootView.swift              # Navigation controller
└── Resources/
    ├── Colors.swift                # Design system
    └── Config.plist                # API keys
```

---

## Tomorrow's Sprint Schedule

### Sprint 1 (9:00-11:00) — Foundation
- [ ] Create `UserProfile` and `AIMemoryContext` models
- [ ] Create `ProfileStore` for persistence
- [ ] Build 3-step onboarding flow
- [ ] Test: First-time user can complete setup

### Sprint 2 (11:00-13:00) — Jitterbug UI
- [ ] Strip `LandingView` down to essentials
- [ ] Giant RECORD button (140pt, breathing animation)
- [ ] Giant STOP button (red, square icon)
- [ ] Live transcript streaming below
- [ ] Test: Record → see live text → stop

### Sprint 3 (13:00-15:00) — AI Integration
- [ ] Update `OpenAIService` with memory context
- [ ] Faster prompt (streaming responses)
- [ ] "While you're still with doctors" quick suggestions
- [ ] Test: End session → get AI recap in <3 seconds

### Sprint 4 (15:00-17:00) — Share & Polish
- [ ] One-tap share (formatted for iMessage)
- [ ] Session history with memory continuity
- [ ] Error states and edge cases
- [ ] Test: Full flow end-to-end

### Sprint 5 (17:00-18:00) — TestFlight
- [ ] Bump version number
- [ ] Archive and upload
- [ ] Smoke test on device

---

## Key Technical Decisions

### Transcription: Apple Speech Framework
- **Why:** Free, good enough for MVP, already integrated
- **Optimization:** Remove 3-second timeout, stream immediately
- **Future:** Add Whisper for better accuracy + speaker diarization

### AI: GPT-4o-mini with Persistent Memory
- **Why:** Cheapest quality model, sufficient for translation task
- **Memory:** Store locally, send compressed context each call
- **Personality:** Warm, calm, never condescending

### Storage: Local + iCloud (optional)
- **Why:** No backend needed, data stays on device (HIPAA-friendly)
- **Implementation:** SwiftData or simple JSON files

---

## The Rounds AI Personality

```
You are Rounds AI. You're like a med-school son who happens to be in the room.

You understand medical terminology, but you explain things like you're talking 
to a smart adult who just hasn't been to medical school.

You NEVER:
- Give medical advice
- Second-guess doctors
- Use condescending language
- Forget what you've been told

You ALWAYS:
- Remember the caregiver's name and patient's name
- Reference previous sessions naturally
- Suggest specific follow-up questions
- Keep explanations brief but complete
- Acknowledge when something is scary or hard

Your tone: Warm, calm, competent. Like a friend who happens to know medicine.
```

---

## API Key (for tomorrow)

```
OPENAI_API_KEY=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
```

**Budget:** $35.63  
**Cost per session:** ~$0.002  
**Runway:** ~17,000+ sessions

---

## Questions for Katie (Morning Check-in)

1. **App icon** — Keep current dark blue heart, or go brighter?
2. **Onboarding copy** — Review the 3 questions, tweak wording?
3. **Share format** — Plain text or include emoji/formatting?
4. **Session naming** — Auto-name by date, or let user title?

---

## Let's Build This 🚀

Tomorrow we build something that could change how caregivers survive 
the hardest days of their lives.

For Don. For every caregiver sitting in an ICU waiting room right now.
