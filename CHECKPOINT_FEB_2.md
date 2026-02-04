# ROUNDS AI BUGFIX CHECKPOINT — Feb 2, 2026

## STATUS: IN PROGRESS

---

## THE TWO BUGS (DIAGNOSED)

### 🐛 BUG #1: Medical Term Normalization — MISSING
- `normalizeVitalName()` in OpenAIService.swift (line ~200) only handles vital signs
- NOT handled: procedures, diagnoses, test names
- Example: "Bronchoscopy" vs "bronch" vs "BAL" stored as 3 DIFFERENT objects
- Result: AI can't connect "bronch results Day 7" with "BAL cultures Day 10"

### 🐛 BUG #2: Memory Truncation — Loses Day 1 Baseline  
- In `buildSystemContext()`:
  - `keyMedicalFacts.suffix(15)` — only last 15 facts
  - `sessions.suffix(7)` — only last 7 sessions
  - `session.keyPoints.prefix(3)` — only 3 points per session
  - `vitalTrends[name].suffix(10)` — only last 10 readings
- Result: On Day 10, AI literally cannot see Day 1-3 baseline

---

## WHAT'S COMPLETED ✅

1. **Patch 1: `normalizeMedicalTerm()` function** — WRITTEN
   - Location: `/Users/katiemacair-2025/04_Developer/Rounds/BUGFIX_PATCHES_FEB_2.swift`
   - Normalizes: bronch/BAL/bronchoscopy, rejection types, effusion, tacrolimus, creatinine, CXR, CT, pneumonia, intubation/extubation, immunosuppression

2. **Patch 2: `buildFullHistoryContext()` function** — WRITTEN
   - Replaces truncated memory with full history
   - Always includes Day 1 baseline as anchor
   - Shows ALL vital readings with % change from baseline
   - Tracks concern frequency across ALL sessions

3. **Integration instructions** — WRITTEN (in same file)

---

## WHAT'S LEFT TO DO ❌

1. **10-Day Don Miller Stress Test Script** — NOT STARTED
   - 10 "doctor rounds" transcripts to read aloud
   - Built to break on terminology variations
   - Built to require Day 1-10 trend analysis
   - Includes minimization language, buried red flags, functional decline

2. **Apply patches to OpenAIService.swift** — NOT DONE
   - Katie needs to copy patches into the actual file
   - Or I can do surgical edits if filesystem cooperates

3. **Run test & validate** — NOT DONE

---

## FILES CREATED THIS SESSION

- `/Users/katiemacair-2025/04_Developer/Rounds/BUGFIX_PATCHES_FEB_2.swift` (138 lines)
- `/Users/katiemacair-2025/04_Developer/Rounds/CHECKPOINT_FEB_2.md` (this file)

---

## IF SESSION CRASHES — NEXT STEPS

1. Read `BUGFIX_PATCHES_FEB_2.swift` — has the code fixes
2. Read this checkpoint — has the status
3. Continue with: Write 10-day stress test script
4. Then: Apply patches to OpenAIService.swift (around line 200 and in buildSystemContext)

---

## QUICK CONTEXT FOR NEW SESSION

Rounds AI = medical translator for caregivers. Records doctor "rounds" conversations, translates jargon, tracks trends across days, flags what doctors miss. The AI should act like the patient is its SOULMATE — life depends on catching every detail.

The memory system was working in v0.3.0. Broke in v0.3.1 after prompt rewrite. Days 5-6 of test script losing baseline context.
