# Rounds AI - Changelog

## [0.3.1] - 2026-01-31 (Current Build)

### 🧠 UNIVERSAL PROMPT REWRITE - "Genius Logic" Update

**Goal:** Make the AI smarter without being transplant-specific. Works for ANY patient scenario.

**What Changed:**

#### OpenAIService.swift - Complete Prompt Overhaul
- **THINKING SCAFFOLD**: AI now works through Extract → Compare → Prioritize → Write
  - Prevents buried findings (like Day 10 BAL infection)
  - Forces structured reasoning before writing response
- **FUNCTIONAL STATUS TRACKING**: Now notices eating, mobility, mental status
  - "Patient refusing PT + not eating + sleepy = declining overall"
  - Often earliest warning sign before vitals change
- **SPEAKABLE QUESTIONS**: Follow-ups are complete sentences caregiver can read aloud
  - OLD: "Ask about the rejection"
  - NEW: "The creatinine went from 1.2 to 1.9 over four days — is that causing the kidney stress, or is something else going on?"
- **DOCTOR MINIMIZATION DETECTOR**: Flags when soft language contradicts facts
  - "They're calling it a 'speed bump,' but transferring to ICU suggests they're taking it seriously"
- **UNCERTAINTIES FIELD**: AI is honest about what it couldn't fully understand
  - Builds trust, gives caregiver specific things to clarify
- **SEVERITY SCORE**: `todayInOneWord` field for instant gut check
  - Values: stable, improving, watch, concerning, urgent, uncertain

#### RoundsAnalysis.swift - New Model Fields
- `todayInOneWord`: Severity at a glance
- `uncertainties`: What AI couldn't fully parse
- `functionalStatus`: eating/mobility/mental/overallTrend
- `newFactsLearned`, `concerns`, `patterns`, `dayNumber`

#### Temperature: 0.7 → 0.3
- More consistent outputs for medical analysis
- Less creative variance, more reliability

### 🔙 Safe Rollback Point
If issues arise: `git checkout c8ec9c0` (v0.3.0-backup)

---

## [0.3.0] - 2026-01-31

### 🚨 CRITICAL: Multi-Day Trend Detection + Urgency Escalation

**Problem Fixed:** AI was doing ONE-DAY comparisons, not showing full patient trajectory

**What Changed:**

#### AIMemoryContext.swift - Enhanced Vital Trend Display
- Calculates **% change from BASELINE** (first reading), not just yesterday
- Adds severity flags: 🚨 CRITICAL, ⚠️ CONCERNING, 📈 Watch closely
- Different thresholds per vital type:
  - Creatinine: ANY increase flagged, >25% = serious, >50% = critical
  - Oxygen liters: INCREASING is bad (patient needs more support)
  - Temperature: 99.5+ = low-grade fever, 100.5+ = fever
  - WBC: Rising after decline = possible infection
- Shows full trajectory: `1.2 → 1.5 → 1.8 → 1.9 (+58% from baseline) ⚠️ CONCERNING`

#### OpenAIService.swift - Rewrote Analysis Prompt
- **MULTI-DAY TREND ANALYSIS** is now #1 priority
- Must report FULL trajectory (X → Y → Z), not just "up from yesterday"
- **URGENCY ESCALATION** rules:
  - ONE vital slightly off → Note calmly
  - ONE vital >25% from baseline → Flag with ⚠️
  - MULTIPLE vitals trending wrong → Urgent language, call out pattern
  - ICU transfer or REJECTION → LEAD WITH IT, this is major news
- **MISSING INFORMATION DETECTION**: If bronch was ordered but results not mentioned, ASK
- **RED FLAG TRIGGERS**: A2 rejection, ICU transfer, fever, nephrology consult
- Questions prioritized: Missing results FIRST, then concerning trends

### 🧪 Test Scripts Created
- `TEST_SCRIPTS_ANOMALY_DETECTION.md` - Days 5-10 stress test sequence
- Tests: subtle lab shifts, hidden concerns, missing info, buried bombshells
- Success criteria: AI must catch ALL red flags, escalate urgency appropriately

### 📝 Documentation
- `MEMORY_LOOP_AUDIT.md` - 5 bugs found and fixed in learning loop

---

## [0.2.0] - 2026-01-26

### ✅ Working Features
- **Recording**: Tap mic to record, tap stop (red button) to end
- **Real-time Transcription**: Apple Speech Recognition streams text as you speak
- **AI Analysis**: OpenAI GPT-4o-mini translates medical jargon to plain English
- **Key Points**: Extracts 3-5 bullet points from the conversation
- **Suggested Questions**: Context-aware follow-up questions to ask doctors
- **Follow-up Chat**: Ask Rounds AI clarifying questions, see chat thread
- **Share Summary**: SMS/email formatted output with emojis
- **Session Archive**: View previous recordings
- **5-Step Onboarding**: Collects caregiver name, patient name, situation
- **Profile Persistence**: Remembers user across sessions

### 🎨 UI/UX
- Brand blue (#00ACEE) throughout
- Heart+cross medical logo
- Splash screen with tagline
- Card-based analysis results
- "Ready" pill indicator when idle
- Red stop button during recording (with pulse animation)

### 🐛 Known Issues (To Fix)
- App icon low resolution on device
- Transcript box doesn't auto-scroll during recording
- Mic button flashes red after stopping (should be green/ready state)
- Sessions don't persist across multiple record/stop cycles
- "Monday Discussion" section needs paragraph breaks
- Share formatting needs work (subject line, spacing)
- Follow-up responses too long, need bullet formatting

### 📋 TODO (Next Sprint)
- [ ] Fix app icon (high-res, match splash screen)
- [ ] Auto-scroll transcript during recording
- [ ] Green "ready" state for mic button
- [ ] Session chaining (append recordings within 1 hour)
- [ ] Better share formatting (bold headers, paragraphs)
- [ ] Email subject line generation
- [ ] Shorter, bulleted AI responses
- [ ] Share button at top AND bottom of recap
- [ ] Include full conversation in share output

---

## [0.1.0] - 2026-01-24

### Initial MVP
- Basic recording with Apple Speech Recognition
- OpenAI integration for analysis
- Simple onboarding flow
- Session storage

---

## Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 5.9, SwiftUI
- **Speech-to-Text**: Apple Speech Framework (on-device)
- **AI**: OpenAI GPT-4o-mini
- **Storage**: UserDefaults (local, no backend)

## Team
- **Katie** - Product & Vision (CEO)
- **Claude** - Technical Cofounder & Engineering
