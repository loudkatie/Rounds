# Rounds AI - Development Documentation

> **Last Updated**: January 26, 2026, 9:30 PM PST  
> **Current Build**: ✅ Working, pushed to GitHub (commit 48d4493)  
> **Sprint Status**: Sprint A COMPLETE, Sprint B ready

---

## 🚀 Quick Start for Next Session

```bash
cd /Users/katiemacair-2025/04_Developer/Rounds
open Rounds.xcodeproj
# Cmd+R to build and run on device
```

**To see new app icon**: Delete app from iPhone, then reinstall.

---

## 🎨 DESIGN SYSTEM (Locked In!)

### Color Palette (from splash gradient)
```swift
brandBlueLight = #41BAFF  // Gradient top (65, 186, 255)
brandBlue      = #3898E0  // Gradient bottom, primary (56, 152, 224)
navyBlue       = #1E64B4  // Buttons (30, 100, 180)
cardBackground = #F2F2F7  // Light gray cards
```

### Typography
| Style | Usage | Specs |
|-------|-------|-------|
| H1 | Report titles | Bold, 22pt |
| H2 | Section headers | Semibold, 17pt, Blue |
| Body | Content text | Regular, 16pt |
| Caption | Secondary text | Regular, 14pt, Gray |

### Icons
- **RoundsHeartIcon**: Heart with BIG cross (45% of size)
  - `.gradient` - Blue gradient heart, white cross (splash, headers)
  - `.solid` - Solid blue heart, white cross
  - `.reversed` - White heart, blue cross (for buttons)

### Section Emojis
- 📋 Report header
- 🔑 Key Points
- 💬 What We Discussed
- ❓ Consider Asking
- 💭 Follow-up Q&A

### Component Library
- `SectionCard` - Gray card with blue title + emoji
- `ActionRow` - Tappable row with icon + chevron
- `RoundsHeartIcon` - Reusable heart+cross icon

---

## 📱 Current App State

### ✅ WORKING FEATURES

| Feature | Status | Notes |
|---------|--------|-------|
| Splash screen | ✅ | Gradient blue, new tagline |
| Recording | ✅ | Brand blue button (132px), red when recording |
| Transcription | ✅ | Auto-scroll, placeholder text |
| Session chaining | ✅ | Multiple record/stop = same session |
| AI Analysis | ✅ | OpenAI GPT-4o-mini |
| Results page | ✅ | Card-based with emoji headers |
| Key Points | ✅ | "🔑 Monday's Key Points" |
| Discussion | ✅ | "💬 What We Discussed" - scrollable, paragraphs |
| Questions | ✅ | "❓ Consider Asking..." |
| Follow-up Q&A | ✅ | Chat bubbles |
| Share | ✅ | Email subject, formatted headers |
| Archive | ✅ | View/load previous sessions |
| Onboarding | ✅ | 5-step flow |

### 🐛 Known Issues (Sprint B)
1. **App icon on home screen** - Still showing old version (need to replace PNG file)
2. **Setup flow** - No back button
3. **Onboarding copy** - Needs updating per Katie's spec
4. **Bold text** - `**text**` not rendering as bold in chat

---

## 📂 KEY FILES

```
Rounds/
├── Colors.swift              ⭐ DESIGN SYSTEM (colors, fonts, components)
├── Views/
│   ├── LandingView.swift     ⭐ Main recording + results (728 lines)
│   ├── SplashView.swift      ⭐ Launch screen
│   ├── PreviousRoundsView.swift
│   └── Onboarding/
│       └── OnboardingFlow.swift
├── ViewModels/
│   └── TranscriptViewModel.swift
├── Services/
│   ├── OpenAIService.swift
│   └── STTService.swift
├── Models/
│   ├── RecordingSession.swift
│   └── RoundsAnalysis.swift
├── Stores/
│   ├── ProfileStore.swift
│   └── SessionStore.swift
└── Config.plist              🔒 API key (GITIGNORED)
```

---

## 📋 Sprint B - TODO List

### 🔧 Immediate Fixes
- [ ] Replace app icon PNG with Katie's Canva version (big cross)
- [ ] Bold text rendering in chat bubbles

### Setup Flow (5 pages)
- [ ] Add back button on all pages
- [ ] Page 1: "You don't have to remember everything."
- [ ] Page 2: "Patient's First Name" (not "Their")
- [ ] Page 2: Privacy note in italics, pushed lower
- [ ] Page 3/4: Combine mic + speech permissions
- [ ] Updated permission copy

### Results Page Polish
- [ ] "Monday Discussion Breakdown" - more comprehensive, paragraphs
- [ ] "Follow-Ups" module (next steps for team)
- [ ] Medical term definitions inline (GPT prompt)

### GPT Prompt Updates
- [ ] Auto-explain medical terms (12th grade level)
- [ ] More detailed "What We Discussed" section
- [ ] Trend detection across days

---

## 🧠 Sprint C - Architecture

### Persistent Memory System
```
LOCAL STORAGE:
├── UserProfile (caregiver, patient)
├── PatientContext (diagnosis, meds, team)
├── SessionHistory[] (summaries, not full transcripts)
└── AIMemory (key facts GPT has learned)

EACH API CALL:
├── Full patient context
├── Past session summaries
├── Today's transcript
└── Conversation history
```

### Future Features
- Sign in with Apple
- Profile builder ("Add Info" flow)
- Facebook Group integration
- Apple Watch companion

---

## 🔑 API Key

**File**: `Rounds/Config.plist` (GITIGNORED)

```xml
<dict>
    <key>OPENAI_API_KEY</key>
    <string>sk-proj-xxxxx</string>
</dict>
```

---

## 🧪 Test Script

```
"Good morning, this is day 5 for Mr. Don Miller, 67-year-old male, 
status post bilateral sequential lung transplant for end-stage IPF. 
Heart rate 82, BP 118/72, SpO2 94-96% on 4 liters nasal cannula. 
Tacrolimus level 11.2, targeting 10-15. Creatinine trending down 
from 1.8 to 1.4. Chest x-ray shows expected post-op changes..."
```

---

## 📊 Git History

```
48d4493 - Complete design system overhaul - Sprint A final
a60d98d - Fix app icon filename, add DEV_NOTES.md
4bae602 - Fix share formatting: email subject, headers
e6ff102 - Sprint A: Visual polish and UX improvements
```

---

## 💡 Katie's Key Design Decisions

1. **Colors**: All blues must match splash gradient spectrum
2. **Emojis**: One per section header (📋🔑💬❓💭)
3. **Cards**: Light gray background, NOT white on white
4. **Headers**: Bold, blue, clearly distinct from content
5. **Share**: Must match in-app report formatting exactly
6. **Button**: Large (132px), brand blue, centered instruction below

---

## 👥 Team

- **Katie** - CEO, Product, Design Direction
- **Claude** - Technical Cofounder, Engineering
- **Aru (ChatGPT)** - CTO, Architecture

---

*All changes saved and pushed to GitHub!* 🚀💙
