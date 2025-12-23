# Rounds

**AI-powered medical conversation companion for patients and caregivers.**

Rounds listens during medical conversations, creates real-time transcripts, and uses AI to help explain complex medical information in plain language.

---

## Current State (Dec 23, 2025)

### Completed
- [x] **Splash Screen** — Calm gradient, outlined heart, "I'm here when you're ready"
- [x] **Landing Screen** — Bold header, 160pt mic button, transcript placeholder, status pill
- [x] **Onboarding Overlay** — 4-screen first-time user flow with progress dots
- [x] **App Icon** — Gradient with outlined heart (1024x1024)
- [x] **Color System** — `Colors.swift` with semantic naming
- [x] **Meta Wearables SDK** — Integrated for Ray-Ban glasses audio streaming

### In Progress
- [ ] Audio recording and real-time transcription
- [ ] Sign in with Apple authentication
- [ ] ChatGPT API integration

---

## Planned Features

### Phase 1: Authentication & Setup Flow
1. **Sign in with Apple** — Only auth method, keeps it simple
2. **User Profile Model** — Store:
   - Name
   - Role (patient / caregiver / other)
   - Diagnosis/situation (200 char summary)
3. **Setup Flow** — Conversational typeahead screens:
   - "Hi, I'm Rounds AI. Let's get started..."
   - What's your name?
   - Are you the patient or caregiver?
   - Brief description of the medical situation
4. **ChatGPT Permission** — Explicit consent for AI integration

### Phase 2: Recording & Transcription
5. **Audio Recording** — `AVAudioEngine` via `AudioCaptureSession.swift`
6. **Real-time Transcription** — Apple `Speech` framework via `STTService.swift`
7. **Live Transcript UI** — Words appear on screen as spoken
8. **Share/Copy Transcript** — Action buttons after recording stops

### Phase 3: ChatGPT Integration
9. **OpenAI API Service** — Use `gpt-3.5-turbo` (cheapest model for testing)
10. **User Context Memory** — System prompt includes:
    - User profile (name, role)
    - Medical situation summary
    - Instruction to explain medical terms simply
11. **"Loop in Rounds AI" Button** — Appears after recording, sends transcript
12. **Session Persistence** — Conversation history saved per user
13. **Memory Between Sessions** — ChatGPT remembers user context

### Phase 4: Polish
14. **Permission Flows** — Mic, Speech Recognition, OpenAI consent
15. **Error Handling** — Network failures, API rate limits
16. **Production Flags** — Remove `forceShowOnboarding` debug flag

---

## Project Structure

```
Rounds/
├── RoundsApp.swift              # App entry point
├── Colors.swift                 # Design system colors
├── Views/
│   ├── RootView.swift           # Navigation controller
│   ├── SplashView.swift         # Launch screen
│   ├── LandingView.swift        # Main recording screen
│   ├── OnboardingOverlay.swift  # First-time user flow (4 screens)
│   ├── ConnectView.swift        # Glasses connection
│   ├── TranscriptView.swift     # Transcript display
│   └── SummaryView.swift        # AI summary view
├── ViewModels/
│   └── TranscriptViewModel.swift
├── Services/
│   ├── STTService.swift         # Speech-to-text
│   └── LlamaAgentService.swift  # AI agent (to be replaced with OpenAI)
├── DeviceManagers/
│   ├── AudioCaptureSession.swift
│   └── WearablesManager.swift   # Meta glasses SDK
├── Models/
│   └── RoundsEpisode.swift
└── Assets.xcassets/
    └── AppIcon.appiconset/      # App icon (gradient + heart)
```

---

## Design System

### Colors (`Colors.swift`)
| Name | Usage |
|------|-------|
| `blueLight` | Cards, soft backgrounds |
| `bluePrimary` | Record button, primary CTAs |
| `blueDeep` | Headers, emphasis, gradient end |
| `blueMidnight` | Darkest accent |
| `textPrimary` | Main text |
| `textSecondary` | Helper text |
| `overlayBackground` | Translucent overlay (95% white) |
| `overlayDim` | Dim behind overlays (40% black) |

### Typography
- SF Pro only (system font)
- Headlines: `.title` / `.title2` with semibold
- Body: `.body` regular
- Helper: `.footnote` / `.caption`

### Principles
- Apple-level restraint and clarity
- Emotionally safe for stressed users
- Senior-friendly (large tap targets, simple flows)
- "Jitterbug-simple but Apple-polished"

---

## Dependencies

- **MetaWearablesDAT** (0.2.1) — Meta Ray-Ban glasses SDK
- **AuthenticationServices** — Sign in with Apple (planned)
- **Speech** — Apple speech recognition
- **AVFoundation** — Audio capture

---

## Build

```bash
# Generate Xcode project (if using XcodeGen)
xcodegen generate

# Build
xcodebuild -project Rounds.xcodeproj -scheme Rounds -destination 'platform=iOS Simulator,name=iPhone 17' build
```

---

## Notes

- `forceShowOnboarding = true` in `RootView.swift` for testing (set to `false` for production)
- OpenAI API key will be needed for Phase 3 (store securely, not in code)
- Target: iOS 17.0+

---

## License

Private — © 2025 Rounds
