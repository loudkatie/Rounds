# Claude's Engineering Notes

**For:** Claude (that's me)  
**Purpose:** Quick context reload for hackathon and future sessions  
**Last Updated:** January 23, 2026

---

## 🧠 Quick Context Reload

**What is Rounds?**  
iOS app that helps caregivers understand medical conversations. Transcribe → Translate → Share.

**Who is Katie?**  
Founder/CEO. Lived the caregiver experience (dad's double lung transplant at UF Gainesville). Vision-driven, not technical. Knows exactly what the product should *feel* like.

**My Role:**  
Technical cofounder. I write the code. Katie makes product decisions. I don't invent architecture — I execute the spec precisely.

**Current State:**  
Working TestFlight build exists. Needs optimization (transcription lag), UI simplification (Jitterbug style), and new onboarding flow.

---

## 📁 Project Location

```
/Users/katiemacair-2025/04_Developer/Rounds/
├── Rounds.xcodeproj          # Xcode project
├── Rounds/                   # Source code
├── docs/                     # Documentation
├── HACKATHON_PLAN.md         # Sprint plan for tomorrow
└── README.md                 # Public-facing docs
```

**GitHub:** https://github.com/loudkatie/Rounds

---

## 🔑 Key Files I Created/Modified

| File | Purpose | Status |
|------|---------|--------|
| `Models/UserProfile.swift` | Caregiver identity | ✅ Created |
| `Models/AIMemoryContext.swift` | Persistent AI memory | ✅ Created |
| `Services/ProfileStore.swift` | Profile persistence | ✅ Created |
| `Views/Onboarding/OnboardingFlow.swift` | 3-step setup | ✅ Created |
| `Config.plist` | API key updated | ✅ Updated |
| `HACKATHON_PLAN.md` | Sprint plan | ✅ Created |
| `README.md` | Project docs | ✅ Created |
| `docs/PRODUCT_OVERVIEW.md` | Full product spec | ✅ Created |

---

## 🎯 Tomorrow's Priorities

### Sprint 1: Foundation (9-11am)
- Wire `OnboardingFlow` into `RootView`
- Test profile creation and persistence
- Ensure returning users skip onboarding

### Sprint 2: Jitterbug UI (11am-1pm)
- Strip `LandingView` to essentials
- Giant Record button (140pt, blue, mic icon)
- Giant Stop button (red, square icon)
- Live transcript below, nothing else

### Sprint 3: AI Integration (1-3pm)
- Update `OpenAIService` to include memory context
- Optimize for speed (streaming if possible)
- Test with real transcripts

### Sprint 4: Share & Polish (3-5pm)
- One-tap share button
- Pre-formatted for iMessage
- Session history access
- Error handling

### Sprint 5: TestFlight (5-6pm)
- Version bump
- Archive and upload
- Smoke test

---

## 🔧 Technical Decisions

### Speech-to-Text: Apple Speech Framework
- Free
- Good enough for MVP
- Already integrated
- **TODO:** Remove 3-second timeout in `STTService.finishTranscription()`

### AI: GPT-4o-mini
- Cheapest quality model
- ~$0.002 per session
- Budget: $35.63 = ~17,000 sessions
- **API Key:** In `Config.plist` (hackathon key, will rotate after)

### Storage: Local Only
- UserDefaults for profile
- JSON files for sessions
- No backend = no HIPAA infrastructure needed

### Memory: Client-Managed
- `AIMemoryContext` stored locally
- Compressed to ~800 tokens for API calls
- We control memory, not OpenAI

---

## 🎨 Design System

### Colors (from `Colors.swift`)
```swift
bluePrimary = Color(red: 30/255, green: 136/255, blue: 229/255)  // #1E88E5
blueLight = Color(red: 234/255, green: 244/255, blue: 255/255)   // #EAF4FF
blueDeep = Color(red: 21/255, green: 71/255, blue: 137/255)      // #154789
textPrimary = Color(red: 28/255, green: 28/255, blue: 30/255)    // #1C1C1E
textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255) // #8E8E93
```

### Key UI Specs
- Record button: 140pt diameter
- Corner radius: 16pt (cards, buttons)
- Padding: 24pt horizontal, 16pt vertical
- Font: System default (SF Pro)

---

## 🐛 Known Issues to Fix

1. **Transcription Lag**
   - `STTService.finishTranscription()` has 3-second timeout
   - Should return immediately when audio ends
   - Location: `Rounds/Services/STTService.swift:85`

2. **UI Complexity**
   - `LandingView.swift` is 600+ lines
   - Too many states and components
   - Need to strip to essentials

3. **No Memory Integration**
   - `OpenAIService` doesn't use `AIMemoryContext` yet
   - Need to inject context into system prompt

4. **Onboarding Not Wired**
   - New `OnboardingFlow` created but not integrated
   - `RootView` still uses old `OnboardingOverlay`

---

## 💬 Katie's Key Phrases (Product Vision)

> "Like the Jitterbug phone — two buttons."

> "Once they share their first name and patient's name, that's a relationship."

> "We cannot forget things between sessions."

> "WE are hosting them. WE are earning their trust."

> "It's not for the hospital. It's for the caregiver."

> "Stupid-simple but elegant."

> "If we can bootstrap it, we can give it away. The world needs this."

---

## 🚫 Things I Should NOT Do

- Invent new architecture without Katie's approval
- Add features beyond the sprint plan
- Make it complicated
- Use deprecated APIs
- Forget the emotional context of this app

---

## ✅ Things I SHOULD Do

- Keep it simple (Jitterbug)
- Make it fast (no spinners)
- Make it warm (AI personality)
- Test on real device
- Document changes
- Commit frequently

---

## 📞 Communication Style with Katie

- She's CEO/product, I'm engineering
- She says "this feels wrong" → I translate to technical fix
- She focuses on UX/emotion → I focus on implementation
- Ask clarifying questions before coding if ambiguous
- Show progress frequently, don't disappear for hours

---

## 🔗 Quick Links

- **Codebase:** `/Users/katiemacair-2025/04_Developer/Rounds/`
- **GitHub:** https://github.com/loudkatie/Rounds
- **Sprint Plan:** `HACKATHON_PLAN.md`
- **Product Spec:** `docs/PRODUCT_OVERVIEW.md`

---

## 🏁 Ready State Checklist

- [x] Codebase access confirmed
- [x] API key updated
- [x] New models created
- [x] Onboarding flow created
- [x] Documentation complete
- [x] Sprint plan ready
- [ ] Katie says "let's go" → START

---

*Last updated: January 23, 2026, pre-hackathon prep*
