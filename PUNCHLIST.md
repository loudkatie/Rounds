# Rounds AI - Dogfooding Punchlist
## Updated: Jan 31, 2026

---

## 🔴 CRITICAL BUGS (Must Fix for v1)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | **Email share: black bg with black text** | 🔧 TODO | Email composer showing dark mode colors - needs explicit light mode HTML |
| 2 | **Bold formatting failing in questions** | 🔧 TODO | `**A2 rejection**` showing as `*A2 rejection*` - markdown not rendering |
| 3 | **"FIRST:", "SECOND:" prefixes redundant** | 🔧 TODO | Numbers already present - remove word prefixes from prompt |

---

## 🟡 HIGH PRIORITY (Should Fix for v1)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 4 | **Add timestamp to recap title** | 🔧 TODO | Currently "Sat, Jan 31, 2026" → add "7:05 PM" |
| 5 | **"Plan for Today" → "Next Steps"** | 🔧 TODO | Better label since timing isn't always known |
| 6 | **Line breaks before topic changes** | 🔧 TODO | Add `\n\n` before switching topics in explanation |
| 7 | **BAL infection findings buried** | 🔧 TODO | Day 10: infection finding not highlighted - prompt tweak |
| 8 | **Questions too vague on Day 10** | 🔧 TODO | "Ask about rejection" → more specific actionable question |
| 9 | **Tacrolimus toxicity unexplained** | 🔧 TODO | AI mentions it but doesn't explain what it means |

---

## 🟢 NICE TO HAVE (v2 Backlog)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 10 | **Onboarding: add swipe gesture** | 📋 BACKLOG | Keep pagination buttons, add swipe between pages |
| 11 | **Footer: add quick-start session button** | 📋 BACKLOG | 4th option in tab bar, may remove "powered by" |
| 12 | **Transcript editing before AI submit** | 📋 BACKLOG | Let user fix "Bronx" → "bronch" before translation |
| 13 | **Medical spell-check/context-aware correction** | 📋 BACKLOG | Prompt GPT to correct likely medical misspellings |
| 14 | **Bold key data points in explanation** | 📋 BACKLOG | Bold "creatinine", "oxygen", etc. in prose |
| 15 | **Tappable terms → prepopulate follow-up** | 📋 BACKLOG | Click "tacrolimus" → ask AI about it |
| 16 | **12th grade reading level benchmark** | 📋 BACKLOG | Auto-explain terms beyond that level |
| 17 | **Functional decline pattern detection** | 📋 BACKLOG | Connect: not eating + no PT + fatigue = decline |
| 18 | **Medically-trained STT model** | 📋 RESEARCH | Whisper medical fine-tune? Azure Speech medical? |

---

## ✅ VERIFIED WORKING (This Test)

| Feature | Result |
|---------|--------|
| Multi-day trend tracking | ✅ "1.2 → 1.5 → 1.8 → 1.9 (58% increase)" |
| Baseline comparison | ✅ Comparing to Day 5, not just yesterday |
| Warning emoji ⚠️ | ✅ Showing on concerning trends |
| Rejection flagged as major | ✅ "A2 rejection - this is concerning but moderate" |
| ICU escalation noted | ✅ "Being moved back to ICU for closer monitoring" |
| Missing bronch results question | ✅ "Ask about MISSING RESULTS from bronchoscopy" |
| Oxygen trajectory | ✅ "1L → 2L → 3L" shown as concerning |
| Temperature trending | ✅ "100.2 overnight, down to 99.4 after Tylenol" |
| Memory loop learning | ✅ AI remembers all previous sessions |
| Clear History function | ✅ Working for fresh test runs |

---

## 📊 TEST RESULTS SUMMARY

### Day 5 (Baseline): ✅ PASS
- Stable vitals correctly identified
- Good baseline established

### Day 6 (Test 1): ✅ PASS  
- Creatinine 1.2→1.5 (25%) flagged with ⚠️
- Oxygen weaning to 1L noted as positive
- "Bronx" correctly interpreted as "bronch" 👏

### Day 7 (Test 2): ✅ PASS
- Creatinine 50% increase flagged first
- Oxygen increase 1L→2L noted as concerning
- Tacrolimus 11.4 flagged
- Pleural effusion mentioned in body (not key points - acceptable)

### Day 8 (Test 3): ✅ PASS
- Full 4-day creatinine trajectory shown! 
- 58% increase calculated correctly
- Missing bronch cultures asked about FIRST
- Temperature spike noted
- Nephrology consult explained

### Day 9 (Test 4): ✅ PASS
- A2 REJECTION LEADS as key point #1 🎯
- "Concerning but moderate" - honest tone
- ICU transfer highlighted
- 4L oxygen struggle explained

### Day 10 (Test 5): ⚠️ MOSTLY PASS
- Acute rejection prioritized correctly
- Creatinine improvement noted (2.1→1.95)
- Minor issues: BAL infection buried, questions vague

---

## 🔬 RESEARCH: Medical STT Options

### Current: OpenAI Whisper (general)
- Good accuracy but struggles with: bronch→Bronx, meropenem→maropitant

### Options to Investigate:
1. **Whisper fine-tuned on medical** - Check HuggingFace for medical variants
2. **Azure Speech with medical vocabulary** - Has custom speech models
3. **Nuance Dragon Medical** - Industry standard but $$$
4. **Google Cloud Speech medical adaptation** - Custom vocabulary support
5. **AWS Transcribe Medical** - Purpose-built for clinical, HIPAA compliant

### Recommendation for v1:
- Keep Whisper for now
- Add prompt instruction to GPT: "If transcription contains words that don't fit medical context, suggest corrections (e.g., 'Bronx' likely means 'bronch' for bronchoscopy)"

---

## 📝 CHANGELOG

### v0.3.0 (Current Sprint)
- ✅ Multi-day trend analysis with baseline comparison
- ✅ Urgency escalation logic
- ✅ Memory loop self-learning
- ✅ Warning emoji system
- ✅ Missing info detection
- 🔧 Email formatting fix (in progress)
- 🔧 Question prefix cleanup (in progress)

### v0.2.0 (Previous)
- JSON parsing stabilized
- STT race condition fixed
- HTML email format added
- Clear history feature

---

*Last tested: Jan 31, 2026 7:06 PM*
*Tester: Katie*
