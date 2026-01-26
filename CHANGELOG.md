# Rounds AI - Changelog

## [0.2.0] - 2026-01-26 (Current Build)

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
