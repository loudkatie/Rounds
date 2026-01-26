# Rounds AI - Development Documentation

> **Last Updated**: January 26, 2026, 3:15 PM PST  
> **Current Build**: Working, pushed to GitHub  
> **Sprint Status**: Sprint A complete, Sprint B ready to start

---

## 🚀 Quick Start for Next Session

```bash
cd /Users/katiemacair-2025/04_Developer/Rounds
open Rounds.xcodeproj
# Cmd+R to build and run on device
```

**To see new app icon**: Delete app from iPhone first, then reinstall.

---

## 📱 Current App State

### ✅ WORKING FEATURES

| Feature | Status | Notes |
|---------|--------|-------|
| Recording | ✅ | Navy blue mic → Red stop button |
| Real-time transcription | ✅ | Apple Speech Recognition, auto-scrolls |
| Session chaining | ✅ | Multiple record/stop within 1 hour = same session |
| AI Analysis | ✅ | OpenAI GPT-4o-mini translation |
| Key Points | ✅ | Card-based with icons |
| Discussion section | ✅ | Scrollable with paragraph breaks |
| Suggested Questions | ✅ | Numbered list in card |
| Follow-up Q&A | ✅ | Chat thread with bubbles |
| Share (SMS/Email) | ✅ | Email subject line, formatted headers |
| Session Archive | ✅ | View/load previous recordings |
| 5-step Onboarding | ✅ | Collects caregiver/patient names |
| Profile persistence | ✅ | UserDefaults |

### 🎨 VISUAL DESIGN

- **App Icon**: Blue heart + white cross (Katie's Canva design)
- **Brand Color**: `#3898E0` (gradient: lighter top → brand blue bottom)
- **Button States**: Navy blue (ready) → Red (recording)
- **Transcript Box**: Always blue tint, never red

### 📂 KEY FILES

```
Rounds/
├── Views/
│   ├── LandingView.swift      # Main recording + results screen (860 lines)
│   ├── SplashView.swift       # Launch screen with gradient
│   ├── PreviousRoundsView.swift
│   └── Onboarding/
│       └── OnboardingFlow.swift
├── ViewModels/
│   └── TranscriptViewModel.swift  # Core state + session chaining logic
├── Services/
│   ├── OpenAIService.swift    # GPT API calls
│   └── STTService.swift       # Apple Speech Recognition
├── Models/
│   ├── RecordingSession.swift
│   └── RoundsAnalysis.swift
├── Stores/
│   ├── ProfileStore.swift     # User profile persistence
│   └── SessionStore.swift     # Recording history
├── Colors.swift               # Centralized brand colors
└── Config.plist              # OpenAI API key (GITIGNORED!)
```

---

## 🔧 Sprint B - TODO List

### Setup Flow Improvements
- [ ] **Back button** on all 5 onboarding pages
- [ ] **Page 1 copy**: "You don't have to remember everything."
- [ ] **Page 2**: Change "Their" → "Patient's First Name"
- [ ] **Page 2**: Privacy note in italics, pushed lower
- [ ] **Page 3/4**: Combine mic + speech recognition permissions
- [ ] **Permission copy**: Don't say "one thing" then ask for two

### Recording Flow UX
- [ ] **Append behavior**: Update full transcript before AI analysis
- [ ] **Clear CTA flow**: Record → Stop → (optional) Record More → Translate
- [ ] **Re-analysis**: When user records more, update AI understanding

### Results Page Polish
- [ ] **Fix bold text**: `**text**` should render as bold in chat bubbles
- [ ] **Compact header**: Move title higher, remove transcript preview box
- [ ] **Share button position**: Only at bottom, not top
- [ ] **Medical term definitions**: Auto-explain inline (GPT prompt update)

---

## 🧠 Sprint C - Architecture Decisions Needed

### Persistent Memory System
```
GOAL: GPT should "remember" the patient across days

APPROACH:
1. Store patient context locally (diagnosis, meds, care team)
2. Store session summaries (not full transcripts) 
3. Each API call includes: context + history + new transcript
4. GPT returns: analysis + NEW facts to remember
5. Over time: spot trends, flag patterns
```

### Sign in with Apple
- Required for TestFlight/App Store
- Use for: account creation only (fast!)
- Gather more profile info in "Add Info" flow later

### Profile Builder ("Add Info" button)
- 3-5 questions per session
- Optional but encouraged
- Feeds into GPT context
- Located in footer nav

---

## 🔑 API Key Location

**File**: `Rounds/Config.plist` (GITIGNORED - never commit!)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>OPENAI_API_KEY</key>
    <string>sk-proj-xxxxx</string>
</dict>
</plist>
```

**Template**: `Config.plist.template` shows placeholder only.

---

## 🧪 Test Script (ICU Lung Transplant)

Use this for testing - read aloud while recording:

> "Good morning, this is day 5 for Mr. Don Miller, 67-year-old male, status post bilateral sequential lung transplant for end-stage IPF. Overnight he remained hemodynamically stable, weaned off norepinephrine yesterday, currently on no pressors. Heart rate 82, BP 118/72, SpO2 94-96% on 4 liters nasal cannula. Vent was weaned and he was extubated yesterday afternoon, tolerating the transition well. Morning ABG shows pH 7.38, PaCO2 42, PaO2 78 on current oxygen. Tacrolimus level this morning is 11.2, we're targeting 10-15 for this early post-op period..."

---

## 📊 Git History

```
e6ff102 - Sprint A: Visual polish and UX improvements
4bae602 - Fix share formatting: email subject, headers
061032f - App icon: bigger cross matching Canva reference
7f4dffa - Major UX improvements: session chaining, auto-scroll
9691573 - Add CHANGELOG.md - checkpoint
8ae760f - UX improvements: red stop button, follow-up chat
```

---

## 🚨 Known Issues

1. **Bold text in chat**: `**text**` markers showing instead of bold
   - Need to parse markdown in SwiftUI Text views
   - Current workaround: strip markers for display

2. **Onboarding permissions**: Asks for speech recognition during recording
   - Should ask upfront in onboarding flow

3. **No back button**: Can't go back in setup flow

---

## 💡 Future Ideas (Katie's Notes)

- Facebook Group integration for patient updates
- Apple Watch companion app
- AirPod audio-first experience
- Trend detection across multiple days
- Auto-explain medical terms (12th grade reading level)
- Attach full transcript as .txt file in email

---

## 👥 Team

- **Katie** - CEO, Product Vision, Testing
- **Claude** - Technical Cofounder, Engineering
- **Aru (ChatGPT)** - CTO, Architecture

---

*Drive safe to SJ! This doc + git has everything saved.* 🚗💙
