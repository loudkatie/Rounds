# Rounds AI - Dogfooding Punchlist
**Version:** 0.3.1  
**Last Updated:** Jan 31, 2026

---

## ✅ COMPLETED IN v0.3.1

| # | Change | Status |
|---|--------|--------|
| 1 | **Universal prompt rewrite** - Thinking scaffold (Extract → Compare → Prioritize → Write) | ✅ DONE |
| 2 | **Speakable questions** - Follow-ups are now complete sentences caregivers can read aloud | ✅ DONE |
| 3 | **Functional status tracking** - Eating, mobility, mental status, overall trend | ✅ DONE |
| 4 | **Temperature 0.7 → 0.3** - More consistent medical analysis | ✅ DONE |
| 5 | **"todayInOneWord" severity** - stable/improving/watch/concerning/urgent/uncertain | ✅ DONE |
| 6 | **"uncertainties" field** - Honest about what AI couldn't fully understand | ✅ DONE |
| 7 | **Doctor minimization detector** - Flags when soft language contradicts facts | ✅ DONE |
| 8 | **Removed transplant-specific language** - Now universal for ANY patient scenario | ✅ DONE |
| 9 | **Removed FIRST:/SECOND: prefixes** - Questions are natural sentences | ✅ DONE |

---

## 🔴 P0 - CRITICAL (Still TODO)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | **Email share: dark mode bug** | 🔧 TODO | Black background with black text |
| 2 | **Bold markdown in questions** | 🔧 TODO | `**text**` showing asterisks |

---

## 🟡 P1 - HIGH (v1.1)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 3 | Add TIME to date header | 📋 BACKLOG | "Sat, Jan 31, 2026 at 7:05 PM" |
| 4 | "Plan for Today" → "Next Steps" | 📋 BACKLOG | Better label |
| 5 | Line breaks between topics | 📋 BACKLOG | May be fixed by new prompt |

---

## 🟢 NICE TO HAVE (v2+)

| # | Feature | Notes |
|---|---------|-------|
| 6 | Onboarding swipe gestures | Add finger swipe between pages |
| 7 | Quick-start session button | 4th footer option |
| 8 | Transcript editing before AI | Fix "Bronx" → "bronch" |
| 9 | Medical spell-check | Context-aware correction |
| 10 | Tappable terms → follow-up | Click term to ask about it |
| 11 | Medical STT model | Research Whisper medical variants |

---

## 📊 TEST RESULTS (v0.3.0)

| Day | Result | Highlights |
|-----|--------|------------|
| 5 (Baseline) | ✅ PASS | Clean baseline established |
| 6 | ✅ PASS | 25% creatinine increase flagged with ⚠️ |
| 7 | ✅ PASS | 50% increase flagged, oxygen concerns noted |
| 8 | ✅ PASS | Full 4-day trajectory shown, missing bronch asked FIRST |
| 9 | ✅ PASS | A2 rejection LED as key point #1 |
| 10 | ⚠️ MOSTLY | Minor: BAL findings buried, questions vague |

**v0.3.1 prompt improvements should address Day 10 issues.**

---

## 📱 APP STORE CHECKLIST

| Requirement | Status |
|-------------|--------|
| Core functionality | ✅ Working |
| Onboarding flow | ✅ Complete |
| History/Archive | ✅ Working |
| Share via email | 🔧 Bug fix needed |
| Error handling | ✅ Implemented |
| Privacy policy | ❓ TODO |
| App icons | ❓ Verify |
| Screenshots | ❓ Create |
| App description | ❓ Write |
| TestFlight build | ❓ TODO |

---

## 🔄 VERSION HISTORY

- **v0.3.1** (Jan 31): Universal prompt rewrite, thinking scaffold, functional status, severity score
- **v0.3.0** (Jan 31): Multi-day trend detection, urgency escalation, memory loop audit
- **v0.2.0** (Jan 30): JSON parsing, STT race condition, HTML email

---

## 🔙 ROLLBACK

If v0.3.1 causes issues, revert to: `git checkout c8ec9c0`
