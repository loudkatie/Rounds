# Rounds AI — Product Overview

**Last Updated:** January 23, 2026  
**Authors:** Katie (Product/CEO), Claude (Tech Cofounder)

---

## Executive Summary

Rounds is a mobile-first iOS app that helps caregivers capture, translate, and understand medical conversations during hospital rounds and doctor appointments.

**The Problem:** Caregivers in high-stakes medical situations (ICU, cancer wards, transplant units) get 5 minutes a day with doctors who speak fast, use complex terminology, and then disappear for 24 hours. They're left trying to remember, understand, and explain what happened to family members who couldn't be there.

**The Solution:** An app that acts as a "second set of ears" — transcribing in real-time, translating medical jargon to plain English, suggesting follow-up questions while doctors are still present, and generating shareable summaries.

**The Differentiator:** Unlike generic transcription apps, Rounds builds a relationship. It remembers the patient's name, diagnosis, medications, and care team. It threads sessions together across days and weeks. It feels like a friend who's been following along — not a stranger you have to re-explain everything to.

---

## Target Users

### Primary: Caregivers
- Family members of hospitalized patients
- Adult children caring for aging parents
- Parents in pediatric ICUs
- Spouses navigating serious diagnoses

**Characteristics:**
- Stressed, overwhelmed, often sleep-deprived
- NOT tech-savvy or AI-curious — they just need something that works
- Own iPhones (we're targeting iPhone 17+ users)
- Familiar with basic apps and voice transcription
- Need guidance, not a blank canvas

### Secondary: Patients
- Patients who attend their own appointments
- Those managing chronic conditions
- Anyone who's ever forgotten what their doctor said

### Tertiary: Hospital Systems
- Could distribute to patients at admission
- White-label opportunity
- Shows care and differentiation

---

## Core User Journey

### First Time Use

1. **Download & Open**
   - App Store download
   - Clean splash screen with Rounds branding

2. **Guided Onboarding (3 steps)**
   - "What's your first name?" → Katie
   - "What's your patient's first name?" → Don
   - "In a sentence or two, what's Don's situation?" → "Stage 4 lymphoma, currently in chemo"

3. **Ready State**
   - "Hit Record when the doctors start. I'll be your second set of ears."
   - Giant blue Record button dominates the screen

### Recording Flow

1. **Start Recording**
   - Tap giant Record button
   - Button transforms to red Stop button
   - Live transcription streams below
   - Timer shows duration

2. **During Recording**
   - User can see words appearing in real-time
   - Verification that it's capturing audio
   - Minimal UI — focus is on the conversation

3. **Stop Recording**
   - Tap Stop button
   - Brief processing moment
   - Transition to Results view

### Results Flow

1. **Immediate Summary**
   - AI-generated plain English explanation
   - Key points highlighted
   - Suggested follow-up questions

2. **Share**
   - One-tap share button
   - Pre-formatted for iMessage/text
   - Includes summary, not raw transcript

3. **Ask Follow-ups**
   - Text input for questions
   - AI responds conversationally
   - Can continue dialogue

### Returning User

1. **Personalized Greeting**
   - "Good morning, Katie"
   - Remembers context

2. **Quick Access to Record**
   - Same giant button
   - No re-onboarding

3. **Session History**
   - Previous recordings accessible
   - AI remembers across sessions

---

## The AI Memory Model

### Philosophy

> "Once they share their first name and patient's name, that's a relationship. We cannot forget things between sessions."

The AI should feel like a friend who's been following the whole story — not a chatbot that starts fresh every time.

### What We Remember

**Permanent (set during onboarding):**
- Caregiver's name
- Patient's name
- Initial diagnosis/situation

**Evolving (updated each session):**
- Key medical facts mentioned
- Current medications
- Care team members (by name)
- Ongoing concerns being monitored
- Recent session summaries (rolling window of 5)

**Emotional (noted when relevant):**
- Caregiver's emotional state
- Stressors mentioned
- Support needs

### Technical Implementation

Memory is stored locally on device as `AIMemoryContext`. Each API call includes a compressed context summary (~800 tokens) that gives the AI full awareness without re-sending complete history.

The AI never "forgets" — but we manage memory ourselves, not relying on OpenAI's conversation state.

---

## Design Principles

### 1. Guided, Not Open-Ended
Like a typeahead form, we take users by the hand. Every screen has a clear next action. We never present a blank canvas and expect users to figure it out.

**Anti-pattern:** Google's search box with blinking cursor  
**Our pattern:** "Here's what to do next. Tap here."

### 2. Jitterbug Simplicity
The Jitterbug phone had two buttons: Call and End Call. That's our inspiration.

**Main screen:** One giant Record button  
**Recording:** One giant Stop button  
**Everything else:** Secondary, discoverable, not in the way

### 3. Fast
No loading spinners that make you wait. Transcription streams in real-time. AI responds in 2-3 seconds. Every interaction feels instant.

### 4. Warm, Not Clinical
The AI has a personality: calm, competent, kind. Never condescending. Never cold. Like a friend who happens to understand medicine.

**Wrong:** "The physician indicated elevated creatinine levels."  
**Right:** "The doctor mentioned Don's kidney numbers are a bit high — they're watching this closely."

### 5. Trustworthy
We never give medical advice. We never pretend to be doctors. We're honest about what we can and can't do. We never forget what we've been told.

---

## UI/UX Specifications

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Blue Primary | #1E88E5 | Buttons, accents, Record button |
| Blue Light | #EAF4FF | Card backgrounds, input fields |
| Blue Deep | #154789 | Headers, gradient end |
| White | #FFFFFF | Background |
| Text Primary | #1C1C1E | Main text |
| Text Secondary | #8E8E93 | Helper text |
| Red (Stop) | System Red | Stop button, recording indicator |

### Typography
- Headlines: SF Pro Display, Bold
- Body: SF Pro Text, Regular
- Monospace (timer): SF Mono

### Key Components

**Record Button:**
- 140pt diameter
- Blue primary background
- White microphone icon
- Subtle shadow
- Breathing animation when ready

**Stop Button:**
- Same size
- Red background
- White square icon (not circle)
- Pulsing animation while recording

**Transcript Card:**
- Light blue background
- 16pt padding
- 16pt corner radius
- Auto-scrolls as text appears

**AI Response Bubbles:**
- Left-aligned (AI)
- Right-aligned (User)
- Distinct styling per speaker

---

## Technical Architecture

### Stack
- **Platform:** iOS 17+
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Speech-to-Text:** Apple Speech Framework
- **AI Backend:** OpenAI GPT-4o-mini
- **Storage:** Local (UserDefaults + JSON files)

### No Backend Required
All data stays on device. API calls go directly to OpenAI. No server to maintain, no database to manage, no HIPAA infrastructure needed (for MVP).

### Budget
- **OpenAI Credits:** $35.63
- **Cost per session:** ~$0.002
- **Runway:** ~17,000 sessions

### Key Services

| Service | Purpose |
|---------|---------|
| `STTService` | Apple Speech → text transcription |
| `OpenAIService` | GPT-4o-mini API calls |
| `ProfileStore` | User identity persistence |
| `SessionStore` | Recording session persistence |

---

## AI Prompt Design

### System Prompt (Core Identity)

```
You are Rounds AI. You're like a med-school friend who happens to be in the room.

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

### Context Injection

Each API call includes the compressed memory context:
```
Caregiver: Katie
Patient: Don
Diagnosis: Stage 4 lymphoma, currently in chemo
Key facts: Platelets low; scheduled for PET scan Friday
Medications: Prednisone 40mg daily, Ondansetron PRN
Care team: Dr. Patel (oncology), Nurse Maria (day shift)
Recent: 1/22: Nausea better, discussed scan | 1/21: Blood counts reviewed
```

---

## Competitive Landscape

| Product | What It Does | Why Rounds Is Different |
|---------|--------------|------------------------|
| Otter.ai | General transcription | Not medical-focused, no translation |
| Rev | Professional transcription | Expensive, not real-time, no AI |
| Generic ChatGPT | Q&A | No memory, no transcription, not guided |
| Hospital portals | After-visit summaries | Doctor-written, delayed, jargon-heavy |

**Rounds' unique position:** Real-time transcription + medical translation + persistent memory + caregiver-first design.

---

## Roadmap

### Phase 1: MVP (Hackathon — January 2026)
- ✅ Basic transcription
- ✅ AI translation/summary
- 🔄 New 3-step onboarding
- 🔄 Jitterbug-style UI
- 🔄 AI memory persistence
- 🔄 One-tap sharing

### Phase 2: Polish (February 2026)
- Speaker diarization
- Session threading
- "Add Context" feature
- Improved accuracy
- App Store submission

### Phase 3: Hospital Ready (Q2 2026)
- White-label branding
- Hospital admin dashboard
- Distribution partnerships
- Usage analytics

### Phase 4: Expansion (Q3-Q4 2026)
- Apple Watch companion
- Android version
- EHR integration pilots
- International/translation

---

## Business Model

### Current: Free
MVP is free. No subscriptions, no paywalls. We want to prove value first.

### Future Options

1. **Hospital B2B**
   - Hospitals pay to offer Rounds to patients
   - White-label customization
   - Analytics and insights

2. **Freemium**
   - Basic features free forever
   - Premium: longer recordings, advanced AI, family sharing

3. **Grant Funding**
   - Patient advocacy organizations
   - Healthcare innovation grants
   - Research partnerships

**Core principle:** Caregivers should never have to pay for basic functionality. The stress of a loved one's illness is enough.

---

## Legal Considerations (Future)

*Not addressed in hackathon MVP — requires legal review*

- HIPAA compliance requirements
- Recording consent by state
- Medical device classification
- Liability disclaimers
- Data retention policies
- International privacy laws (GDPR)

---

## Success Metrics

### MVP Success
- Complete a recording session
- Generate an AI summary
- Share via text message
- Return for a second session

### Product-Market Fit Indicators
- Session frequency (daily use during hospitalization)
- Share rate (% of sessions shared with family)
- Retention (return after initial use)
- Word-of-mouth referrals

### Impact Metrics (Long-term)
- Caregiver reported stress reduction
- Improved family communication
- Follow-up question utilization
- Hospital partner satisfaction

---

## The Origin Story

> "Speaking from the heart after living through my dad's double lung transplant process at UF Gainesville Pulmonary ICU hour by hour, day after day, week after week."

Katie built Rounds because she lived the problem. The frantic note-taking, the medical jargon, the 23 hours of waiting punctuated by 5 minutes of information overload, the impossible task of explaining it all to family members who couldn't be there.

This isn't a startup looking for a problem. This is a solution built from pain.

**For Don. For every caregiver sitting in an ICU waiting room right now.**

---

## Team

**Katie** — Founder, CEO, Product  
- Lived the caregiver experience
- Background in location-based iOS apps (Loud Labs)
- Vision for screenless, audio-first interfaces

**Claude** — Technical Cofounder, Engineering  
- Senior iOS expertise (Swift, SwiftUI, AVFoundation)
- AI/ML integration experience
- Hackathon partner and implementation lead

---

## Contact

- **GitHub:** github.com/loudkatie/Rounds
- **Company:** Loud Labs

---

*Document version 1.0 — Hackathon Edition*
