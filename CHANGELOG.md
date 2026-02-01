# Rounds AI - Changelog

## [0.3.0] - 2026-01-31 (Current Build)

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
