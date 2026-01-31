# Rounds AI

**A caregiver's companion for understanding medical conversations.**

> 🤖 **Claude Cofounder?** Start here: [COFOUNDER_README.md](./COFOUNDER_README.md)  
> 📚 **Framework Docs:** See `/Users/katiemacair-2025/04_Developer/LOUD_LABS_PRODUCT_FRAMEWORK_V2.md` and `LOUD_LABS_COMPANION_FRAMEWORK.md`

Rounds helps caregivers capture, translate, and understand what doctors say during hospital rounds and medical appointments. Think of it as having a med-school friend in the room who can explain everything in plain English.

---

## 🩺 What Is Rounds?

When your loved one is in the ICU, you get maybe 5 minutes a day with the doctors during morning rounds. They speak fast, use terminology you've never heard, and then they're gone for another 24 hours.

Rounds is your second set of ears. It:
- **Transcribes** exactly what was said
- **Translates** medical jargon into plain English
- **Suggests** follow-up questions while you still have the doctors
- **Summarizes** everything so you can share with family

**This is not medical advice.** Rounds is a translator, not a doctor. It helps you understand and remember — nothing more, nothing less.

---

## 👥 Who Is This For?

**Caregivers** — the family members sitting in hospital rooms, trying to process what's happening to someone they love.

- Parents in the pediatric ICU
- Adult children caring for aging parents
- Spouses navigating a cancer diagnosis
- Anyone who's ever left a doctor's appointment thinking "wait, what did they just say?"

**Not for:**
- Medical professionals (they don't need translation)
- Diagnosis or treatment decisions (talk to your doctors)
- Replacing human medical judgment (impossible and dangerous)

---

## ✨ Core Features

### 1. Record
Giant button. Tap to start. Tap to stop. That's it.

Real-time transcription streams as the doctors speak, so you can verify it's capturing everything.

### 2. Understand
After you stop recording, Rounds AI explains what was discussed:
- Plain English summary
- Key points highlighted
- Medical terms defined

### 3. Ask
While you're still with the doctors (or after), Rounds suggests follow-up questions based on what was said. These are the questions you'd think of at 2am — but now you have them in the moment.

### 4. Share
One tap to send a summary to family members. Formatted perfectly for texting. No copying and pasting, no trying to remember what was said.

---

## 🧠 The AI Memory Model

Rounds AI **remembers**. Unlike a generic chatbot that starts fresh every time, Rounds builds a relationship with you:

- It knows your name and your patient's name
- It remembers previous sessions and what was discussed
- It tracks medications, care team members, and ongoing concerns
- It notices patterns across days and weeks

**This is intentional.** When you're living in a hospital for weeks, you need an AI that feels like a friend who's been following along — not a stranger you have to re-explain everything to.

---

## 🏥 The Vision

**Phase 1 (Now):** A free app that caregivers can download and use on their own.

**Phase 2 (Soon):** Hospitals can brand and distribute Rounds to patients at admission. "Here's something to help you keep track of what we discuss."

**Phase 3 (Future):** Integration with hospital systems, so the AI can access (with permission) relevant medical records and provide even more context.

The goal is to make this **free for caregivers, forever.** Healthcare is hard enough without adding a subscription fee to understanding what's happening to your loved one.

---

## 🛠 Technical Overview

### Stack
- **Platform:** iOS 17+ (iPhone only for now)
- **Language:** Swift 5.9, SwiftUI
- **Speech-to-Text:** Apple Speech Framework
- **AI:** OpenAI GPT-4o-mini
- **Storage:** Local (UserDefaults/JSON), no backend required

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                         RoundsApp                           │
├─────────────────────────────────────────────────────────────┤
│  Views/           │  Services/          │  Models/          │
│  ├─ RootView      │  ├─ STTService      │  ├─ UserProfile   │
│  ├─ Onboarding/   │  ├─ OpenAIService   │  ├─ AIMemoryCtx   │
│  ├─ Recording/    │  ├─ ProfileStore    │  ├─ RoundsSession │
│  └─ Results/      │  └─ SessionStore    │  └─ Analysis      │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **No backend.** All data stays on device. This is both a privacy feature (HIPAA-friendly) and a simplicity feature (no servers to maintain).

2. **Memory lives locally.** The AI context is stored on-device and sent with each API call. The AI doesn't "remember" on OpenAI's servers — we manage memory ourselves.

3. **Budget-conscious API usage.** GPT-4o-mini costs ~$0.002 per session. With a $35 budget, we can run ~17,000 sessions.

4. **Jitterbug simplicity.** Two buttons: Record and Stop. Everything else is secondary.

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator
- OpenAI API key

### Setup
1. Clone the repo:
   ```bash
   git clone https://github.com/loudkatie/Rounds.git
   cd Rounds
   ```

2. Add your API key to `Rounds/Config.plist`:
   ```xml
   <key>OPENAI_API_KEY</key>
   <string>your-key-here</string>
   ```

3. Open `Rounds.xcodeproj` in Xcode

4. Build and run on device (microphone requires real device)

### First Run
1. Complete the 3-step onboarding (your name, patient's name, situation)
2. Tap the big blue Record button
3. Speak (or play audio of someone speaking)
4. Tap Stop
5. See the AI translation and summary

---

## 📁 Project Structure

```
Rounds/
├── RoundsApp.swift              # App entry point
├── Models/
│   ├── UserProfile.swift        # Caregiver identity
│   ├── AIMemoryContext.swift    # Persistent AI memory
│   ├── RecordingSession.swift   # Single recording session
│   └── RoundsAnalysis.swift     # AI analysis results
├── Services/
│   ├── STTService.swift         # Speech-to-text
│   ├── OpenAIService.swift      # GPT integration
│   ├── ProfileStore.swift       # User persistence
│   └── SessionStore.swift       # Session persistence
├── Views/
│   ├── RootView.swift           # Navigation controller
│   ├── Onboarding/
│   │   └── OnboardingFlow.swift # 3-step setup
│   ├── LandingView.swift        # Main recording interface
│   ├── SummaryView.swift        # AI results display
│   └── PreviousRoundsView.swift # Session history
├── ViewModels/
│   └── TranscriptViewModel.swift
└── Resources/
    ├── Colors.swift             # Design system
    ├── Config.plist             # API keys
    └── Assets.xcassets          # Images and colors
```

---

## 🎨 Design Principles

1. **Guided, not open-ended.** We take users by the hand. Every interaction feels like a typeahead form, not a blank canvas.

2. **Stupid-simple, but elegant.** Like the Jitterbug phone — big buttons, clear labels, no learning curve. But it should still feel like an Apple product.

3. **Fast.** No spinners. No waiting. Transcription streams in real-time. AI responds in seconds.

4. **Warm.** The AI has a personality: calm, competent, never condescending. Like a friend who happens to know medicine.

5. **Trustworthy.** We never forget what we've been told. We never give medical advice. We're always honest about what we can and can't do.

---

## 🔐 Privacy & Compliance

- **All data stays on device.** No server, no cloud storage (except iCloud if user enables).
- **No PHI transmitted.** Transcripts go to OpenAI for processing but are not stored by them (per their API data policy).
- **Recording consent.** Users are responsible for complying with local recording laws.
- **Not a medical device.** This is an information tool, not a diagnostic or treatment tool.

*Full legal review pending. This is a hackathon MVP.*

---

## 🗺 Roadmap

### v1.0 — MVP (Hackathon)
- [x] Basic transcription
- [x] AI translation/summary
- [ ] New 3-step onboarding
- [ ] Jitterbug-style UI
- [ ] AI memory persistence
- [ ] One-tap sharing

### v1.1 — Polish
- [ ] Speaker diarization ("Dr. Smith said...")
- [ ] Session threading (AI remembers across days)
- [ ] "Add Context" feature for between-session learning
- [ ] Improved error handling

### v2.0 — Hospital Ready
- [ ] White-label branding
- [ ] Admin dashboard for hospitals
- [ ] Onboarding customization
- [ ] Usage analytics (anonymized)

### Future
- [ ] Apple Watch companion (tap to record)
- [ ] Siri integration ("Hey Siri, start Rounds")
- [ ] Android version
- [ ] Integration with EHR systems

---

## 👩‍💻 Contributing

This is currently a private project by Loud Labs. If you're interested in contributing or partnering, reach out to Katie.

---

## 📜 License

TBD — likely open source for the core app, with commercial licensing for hospital deployments.

---

## 💙 Why We Built This

> "Speaking from the heart after living through my dad's double lung transplant process at UF Gainesville Pulmonary ICU hour by hour, day after day, week after week."
> 
> — Katie, Founder

Rounds exists because caregivers deserve better than frantically scribbling notes while doctors talk too fast, then trying to explain it all to family members who couldn't be there.

**For Don. For every caregiver sitting in an ICU waiting room right now.**

---

## 🤝 The Team

**Katie** — Product & Vision (CEO)  
**Claude** — Technical Cofounder & Engineering

Built with love during a January 2026 hackathon.
