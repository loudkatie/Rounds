# 🧠 CLAUDE HANDOFF — ROUNDS AI DEBUGGING
**Date:** February 1, 2026  
**Status:** v0.3.1 prompt testing — regression investigation

---

## QUICK START

**You are the technical cofounder of Loud Labs. Read these docs first:**

1. **Framework Docs (the philosophy):**
   - `/Users/katiemacair-2025/04_Developer/LOUD_LABS_PRODUCT_FRAMEWORK_V2.md`
   - `/Users/katiemacair-2025/04_Developer/LOUD_LABS_COMPANION_FRAMEWORK.md`

2. **Rounds-Specific Docs:**
   - `/Users/katiemacair-2025/04_Developer/Rounds/README.md`
   - `/Users/katiemacair-2025/04_Developer/Rounds/COFOUNDER_README.md`
   - `/Users/katiemacair-2025/04_Developer/Rounds/MEMORY_LOOP_AUDIT.md`

3. **Key Code Files:**
   - `/Users/katiemacair-2025/04_Developer/Rounds/Rounds/Services/OpenAIService.swift` (THE PROMPT)
   - `/Users/katiemacair-2025/04_Developer/Rounds/Rounds/Models/AIMemoryContext.swift` (memory system)

---

## WHAT ROUNDS AI IS

Rounds is a **medical translator for caregivers**. When your father is in the ICU and doctors speak fast in jargon during 5-minute morning rounds, Rounds is your second set of ears.

**Core capabilities:**
1. **Transcribes** what doctors say (via Apple Speech)
2. **Translates** medical jargon to plain English (via GPT-4o-mini)
3. **Suggests** follow-up questions while doctors are still there
4. **Remembers** everything across days and weeks (this is the secret sauce)

**The vision:** The AI acts like a "brilliant human who is in the room because this is their soul mate as the patient" — it remembers EVERYTHING, notices patterns, and has continuity that rotating medical staff don't have.

---

## THE CURRENT PROBLEM

### Context

We successfully tested v0.3.0 last night (transcript: `/mnt/transcripts/2026-02-01-03-31-55-rounds-v1-dogfooding-test-results-fixes.txt`). The 6-day Don Miller stress test worked perfectly — the AI tracked multi-day trends and caught all the red flags.

Then today I rewrote the prompt for v0.3.1 (transcript: `/mnt/transcripts/2026-02-01-16-28-40-v0-3-1-prompt-rewrite-universal-logic.txt`), and now we need to validate it still works.

### What We Changed in v0.3.1

1. **Added "Thinking Scaffold"** — GPT now has explicit steps: EXTRACT → COMPARE → NOTICE FUNCTIONAL STATUS → PRIORITIZE
2. **Added functional status tracking** — eating, mobility, mental status (often the earliest warning sign)
3. **Added "todayInOneWord"** — severity signal: stable/improving/watch/concerning/urgent/uncertain
4. **Added "uncertainties" array** — honest gaps like "I heard 'BAL' mentioned but couldn't tell if results were positive or negative"
5. **Added "Cut Through Minimization"** — flag when "just a speed bump" contradicts ICU transfer
6. **Changed temperature from 0.7 → 0.3** — more consistent medical analysis
7. **Removed transplant-specific language** — Rounds learns FROM THE DOCTORS, doesn't have hardcoded medical knowledge

### What Needs Testing

Run the 6-day Don Miller stress test (below) and verify:

1. **Day 5 baseline** is captured cleanly
2. **Day 6** flags 25% creatinine increase
3. **Day 7** catches oxygen going BACKWARDS, multiple concerning trends
4. **Day 8** shows full trajectory "1.2 → 1.5 → 1.8 → 1.9" and asks about MISSING bronch results
5. **Day 9** leads with A2 REJECTION as the headline (not buried)
6. **Day 10** catches BAL infection findings, functional decline (not eating, no PT, confusion)

---

## THE 6-DAY STRESS TEST SCRIPT

Location: `/Users/katiemacair-2025/04_Developer/Rounds/Scripts/TEST_SCRIPTS_ANOMALY_DETECTION.md`

**RUN IN SEQUENCE** — the AI needs Day 5 baseline to catch Day 6+ anomalies.

### Day 5 (BASELINE - establishes "normal")

> Good morning everyone. This is day five post bilateral lung transplant for Don Miller.
>
> Overnight, Don did well. No significant events. His vital signs have been stable with temperature at 98.4, heart rate in the 70s, blood pressure running 118 over 72.
>
> Lab work from this morning: His creatinine is stable at 1.2, which is right where we want it. Tacrolimus level came back at 9.8, nicely within our target range of 8 to 12. White blood cell count is 8.2, trending down appropriately as expected post-transplant.
>
> His chest tubes are putting out about 150 cc over the last 24 hours, which is a nice decrease from yesterday. Chest X-ray this morning looks good - no infiltrates, no effusions, the new lungs are expanding well.
>
> He's been working with physical therapy and walked 200 feet yesterday. Tolerating his diet well, no nausea. Pain is well controlled on his current regimen.
>
> The plan today is to continue weaning oxygen - he's currently on 2 liters. We'll keep the chest tubes in one more day and reassess tomorrow. Continue current immunosuppression, continue physical therapy, and if he continues to progress like this, we're looking at stepping down to the regular floor in the next day or two.
>
> Any questions from the family? Okay, we'll see you tomorrow morning.

**Expected:** Clean baseline captured. Values: Creatinine 1.2, Tac 9.8, WBC 8.2, O2 2L, Temp 98.4

---

### Day 6 (SUBTLE LAB SHIFT)

> Morning rounds, day six for Don Miller, post bilateral lung transplant.
>
> So Don had a pretty good night overall. Temperature was 98.6 this morning, vitals otherwise stable.
>
> Labs this morning: Creatinine is 1.5, tacrolimus level is 10.2. White count is 7.8.
>
> His chest X-ray looks essentially unchanged from yesterday which is reassuring. Chest tube output decreased again, down to about 80 cc, so we're going to pull those today.
>
> He walked 250 feet with PT yesterday which is great progress. We're going to continue weaning his oxygen, he's down to 1 liter now.
>
> Plan is to pull chest tubes this morning, repeat chest X-ray after, continue current meds, and hopefully transfer him to the step-down unit this afternoon.
>
> Everything's looking good. See you tomorrow.

**AI SHOULD CATCH:**
- ⚠️ Creatinine 1.2 → 1.5 (25% increase!)
- Tacrolimus 9.8 → 10.2 (trending up)
- Doctors said "looking good" but didn't address the creatinine change
- Should ask: "Is the creatinine increase concerning?"

---

### Day 7 (HIDDEN CONCERNS IN JARGON)

> Day seven post-transplant for Don Miller.
>
> So he's on the step-down unit now. Night was okay, though nursing noted he was a bit more restless than usual. Temperature this morning was 99.1.
>
> Labs: Creatinine is 1.8 now. We're watching that. Tacrolimus came back at 11.4 - it's creeping up so we may need to adjust the dose. White count ticked up slightly to 9.2.
>
> Chest X-ray shows some new basilar atelectasis on the right which isn't unexpected given he's been less mobile. We also noted a small pleural effusion that wasn't there yesterday but it's probably just post-procedural from pulling the chest tubes. Nothing to be too worried about.
>
> His oxygen requirements bumped back up a bit - he's back on 2 liters when he had been on 1. He's still walking but he's been a little more fatigued the last day or so.
>
> We're going to get a bronchoscopy scheduled for tomorrow just to take a look, do some washings, make sure there's no early rejection. Fairly routine at this stage. We'll add some Lasix to help with the fluid.
>
> The plan is supportive care for now. We'll reassess after the bronch tomorrow.

**AI SHOULD CATCH:**
- 🚨 Creatinine 1.2 → 1.5 → 1.8 (50% increase from baseline!)
- 🚨 Temperature trending: 98.4 → 98.6 → 99.1
- 🚨 NEW pleural effusion (downplayed as "post-procedural")
- 🚨 Oxygen INCREASING (was weaning, now back up)
- 🚨 More fatigued, restless
- Why is bronchoscopy "routine" if they suddenly need one?
- Should ask: "Is Don showing early signs of rejection?"

---

### Day 8 (MISSING INFO)

> Day eight, Don Miller, post lung transplant.
>
> We did the bronchoscopy yesterday afternoon. Don tolerated it well. We're waiting on some of the culture results but preliminary findings were... the airways looked okay, some mild erythema in the anastomosis but that can be normal healing.
>
> Temperature overnight got up to 100.2, we gave him some Tylenol and it came back down. This morning it's 99.4.
>
> Creatinine today is 1.9. We've consulted nephrology and they're going to take a look. Tacrolimus is 11.8 so we're decreasing the dose. His white count is 10.4.
>
> He's on 3 liters of oxygen now. The effusion on the right looks about the same on imaging, maybe slightly larger but hard to tell.
>
> We're going to continue watching closely. He's still eating, still doing some PT though shorter distances. We're holding off on the floor transfer for now until things stabilize.
>
> I think he just needs a few more days to turn the corner. These little bumps are not unexpected in the first couple weeks.

**AI SHOULD CATCH:**
- 🚨 WHERE ARE THE BRONCH WASH RESULTS? They said they'd check for rejection!
- 🚨 Temperature hit 100.2 (fever!)
- 🚨 Creatinine: 1.2 → 1.5 → 1.8 → 1.9 (58% increase, nearly doubled)
- 🚨 Oxygen TRIPLED: 2L → 1L → 2L → 3L
- 🚨 Effusion "maybe slightly larger"
- 🚨 WBC climbing: 8.2 → 7.8 → 9.2 → 10.4
- Should ask FIRST: "What did the bronch washings show?"

---

### Day 9 (THE BURIED BOMBSHELL)

> Morning everyone, day nine for Don Miller.
>
> So we got some results back. The transbronchial biopsy is showing A2 rejection. The good news is it's not A3 or A4 so it's moderate, not severe. We're going to pulse him with methylprednisolone, three days of IV steroids, and that usually does the trick.
>
> His temperature has been up and down, 99 to 100 range. We started empiric antibiotics yesterday as a precaution given the immunosuppression and fever. The BAL cultures are still pending.
>
> Creatinine is at 2.1 this morning. Nephrology thinks it's likely tacrolimus toxicity compounded by the stress on his system. We're holding the tacrolimus for now and they may want to do a renal ultrasound.
>
> The effusion has definitely increased - we're discussing whether to tap it for both diagnostic and therapeutic purposes.
>
> He's requiring 4 liters of oxygen to maintain sats above 92. He's pretty tired, not walking much the last couple days. Understandably so.
>
> We're moving him back to the ICU for closer monitoring during the steroid pulse. This is all very manageable, just needs more intensive monitoring. Hopefully this is just a speed bump and we'll have him back on track in a few days.

**AI SHOULD CATCH:**
- 🚨🚨🚨 **A2 REJECTION CONFIRMED** — this should be the HEADLINE, not buried
- 🚨 Moving BACK TO ICU — not a "speed bump"
- 🚨 Creatinine now 2.1 (nearly DOUBLE baseline)
- 🚨 4L oxygen, struggling to keep sats above 92
- 🚨 HOLDING tacrolimus — the anti-rejection med!
- Should ask: "How serious is A2 rejection? What if steroids don't work?"
- Should ask: "If you're holding tacrolimus, how do you prevent MORE rejection?"

---

### Day 10 (MIXED SIGNALS)

> Day ten, ICU day two for Don Miller, status post bilateral lung transplant now with acute cellular rejection undergoing treatment.
>
> So we're midway through the steroid pulse. His temperature has been better, hovering around 99, occasionally touching 100 but not sustained. The repeat chest X-ray shows the effusion is stable, maybe a tiny bit improved. We decided to hold off on thoracentesis for now.
>
> Creatinine ticked down to 1.95 from 2.1 so that's encouraging, nephrology is cautiously optimistic. We restarted a lower dose of tacrolimus this morning - 1 mg instead of 2 mg BID. Level was subtherapeutic at 5.2 but we had to balance that against the kidney injury.
>
> The bad news is his oxygen requirements haven't really improved - still on 4 liters, sats running 91 to 93. He's also been having some episodes of confusion overnight which can happen with high-dose steroids but we did get a head CT just to be safe and that was negative.
>
> We added meropenen to his antibiotic coverage because the BAL grew out some gram negative rods, we're waiting on final speciation. Could be pseudomonas.
>
> He's not really eating much, very fatigued. No PT today. We'll plan for a repeat bronch in a day or two to assess response to treatment.
>
> Family, I know this is scary but we're throwing everything at this. He's fighting. The next 48 hours will tell us a lot.

**AI SHOULD CATCH:**
- Mixed signals: some improving (creatinine down, effusion stable)
- STILL CONCERNING:
  - 🚨 4L oxygen unchanged — lungs not responding
  - 🚨 Sats 91-93 still borderline
  - 🚨 CONFUSION — new neurological symptom!
  - 🚨 BAL grew INFECTION (gram negative rods) — ON TOP of rejection
  - 🚨 Tacrolimus subtherapeutic (5.2)
  - 🚨 NOT EATING, no PT, very fatigued — functional decline
  - 🚨 "Next 48 hours" — they're worried
- Should ask: "Is confusion just steroids or something else?"
- Should ask: "He has rejection AND infection — how do you treat both?"

---

## SUCCESS CRITERIA

The AI passes if it:

1. ✅ Catches ALL red flags listed above
2. ✅ Shows FULL trajectory with percentages (e.g., "Creatinine: 1.2 → 1.5 → 1.8 → 1.9 → 2.1, a 75% increase from baseline")
3. ✅ Leads with the MOST IMPORTANT thing (A2 rejection on Day 9, not buried)
4. ✅ Asks about MISSING info first (bronch results on Day 8)
5. ✅ Escalates urgency appropriately (Day 9 should feel MUCH more urgent than Day 6)
6. ✅ Explains medical terms inline ("A2 rejection — moderate immune attack on the new lungs")
7. ✅ Notes functional decline (eating, mobility, mental status)
8. ✅ Calls out minimization ("They called it a 'speed bump' but he's going back to ICU")

---

## GIT HISTORY

```
756cb0a fix: Wire up v0.3.1 model fields - build now succeeds
5c1e11c v0.3.1: Universal prompt rewrite - thinking scaffold, functional status, speakable questions
c8ec9c0 v0.3.0-backup: Pre-prompt-rewrite state - SAFE ROLLBACK POINT
9e944f0 docs: Update changelog for v0.3.0 - trend detection
0d0af5c 🚨 CRITICAL: Enhanced trend detection + urgency escalation
```

**Rollback point:** `c8ec9c0` if v0.3.1 breaks trend tracking

---

## IMPORTANT PHILOSOPHY

**Rounds learns FROM THE DOCTORS, not from hardcoded medical knowledge.**

Katie rejected my earlier suggestion to add specific thresholds (creatinine 0.7-1.3 mg/dL, tacrolimus 8-12 ng/mL). That's wrong.

Rounds doesn't know what's "normal" for any patient. It learns what's normal for THIS patient based on what the doctors say. The superpower is CONTINUITY and MEMORY across sessions — noticing that creatinine started at 1.2 (doctors said "right where we want it") and is now 2.1 (75% increase).

**Five Pillars:** Proactive AI, Chat-First UI, Guided Flows, Persistent Memory, Vertical Focus.

The AI should feel like a "brilliant human who is in the room because this is their soul mate as the patient" — caring, attentive, remembers everything.

---

## PUNCHLIST (AFTER PROMPT IS VALIDATED)

**P0 Critical:**
- [ ] Email dark mode bug (white background)
- [ ] Bold markdown (`**text**`) not rendering

**P1 High:**
- [ ] Add timestamp to email header
- [ ] "Plan for Today" → "Next Steps"
- [ ] Line breaks between key points

**App Store (9 items remaining):**
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Marketing screenshots
- [ ] App description
- [ ] Category selection
- [ ] Age rating
- [ ] Content rights
- [ ] Advertising ID declaration
- [ ] Export compliance

---

## HOW TO TEST

1. Open Xcode: `open /Users/katiemacair-2025/04_Developer/Rounds/Rounds.xcodeproj`
2. Build and run on simulator or device
3. Complete onboarding (name: "Katie", patient: "Don", relationship: "father")
4. Record each day's script in sequence
5. Verify AI output matches success criteria above

Or use the app on TestFlight if already installed.

---

**For Don. For every caregiver in an ICU waiting room right now.**
