# 10-DAY DON MILLER STRESS TEST SCRIPT
## Double Lung Transplant | UF Gainesville Pulmonary ICU
## Version 2.0 — Feb 2, 2026

---

## TEST OBJECTIVES

This script tests whether Rounds AI can:
1. ✅ Normalize medical terminology (bronch/Bronx/BAL = same thing)
2. ✅ Remember Day 1 baseline when analyzing Day 10
3. ✅ Detect trends that only appear across 7+ days
4. ✅ Catch minimization language from doctors
5. ✅ Flag buried red flags inside reassuring updates
6. ✅ Track functional status decline
7. ✅ Notice missing information (tests ordered but never reported)

---

## PATIENT SETUP

**Name:** Don Miller  
**Age:** 66  
**Procedure:** Bilateral (double) lung transplant  
**Location:** UF Health Gainesville, Pulmonary ICU  
**Day 1 = 24 hours post-op**

---

## HOW TO USE THIS SCRIPT

1. Open Rounds AI app
2. Tap Record
3. Read the day's script aloud (as if you're overhearing doctors)
4. Tap Stop
5. Review AI response — does it catch the traps?
6. Move to next day

---

## DAY 1 — POST-OP DAY 1 (24 hours after surgery)
### 🎯 BASELINE DAY — AI must remember ALL of this

*[Read this aloud as if doctors are speaking to each other during rounds]*

"Good morning, this is Don Miller, 66-year-old male, post-op day one following bilateral lung transplant. Ten-hour procedure yesterday, went well, no significant intraoperative complications. 

Currently intubated on the vent, PEEP of 8, FiO2 at 40%, sats 94-96%. We'll keep him sedated today, plan to do a bronch later this afternoon to check the anastomoses.

Vitals are stable — temp 37.2, heart rate 88, BP 124 over 78. Creatinine is 1.4, which is a bit elevated but expected post-op given the fluid shifts. Tac level pending, we started him on tacrolimus last night. 

Chest tubes putting out about 200cc over the last 8 hours, sanguineous but that's normal post-op. Chest x-ray shows bilateral infiltrates, again expected. No pneumothorax.

Pain is controlled on fentanyl drip. Foley in place, good urine output at 60cc per hour.

Family is here — his daughter Katie has been great, very involved. Let's keep them updated after the bronch today.

Plan: Continue current vent settings, bronchoscopy this afternoon, daily CXR, trend creatinine, check tac level tomorrow morning. If he does well overnight, we might start weaning sedation tomorrow."

---

### ✅ DAY 1 SUCCESS CRITERIA
- AI captures: intubated, vent settings, baseline vitals (temp 37.2, HR 88, BP 124/78)
- AI captures: Creatinine 1.4 as BASELINE
- AI captures: Bronch planned (even if transcribed as "Bronx")
- AI captures: Chest tube output 200cc/8hr
- AI captures: Tac level pending
- AI flags: Nothing alarming — this is the baseline

---

## DAY 2 — POST-OP DAY 2
### 🎯 TRAP: "Bronx" transcription + first procedure results

"Morning rounds, Don Miller, post-op day two. So we did the bronch yesterday afternoon — anastomoses look great, no evidence of dehiscence, minimal secretions. Very happy with how things look.

Overnight he did well. Still intubated but we're starting to wean. Dropped the FiO2 to 35%, sats holding at 95%. PEEP still at 8.

Temp overnight was 37.8, which is okay. Heart rate in the 90s. BP stable.

Creatinine ticked up a little to 1.6 — we're watching it. Could be the tacrolimus, could be post-op. Tac level came back at 8.2, which is actually a bit low, so we're going to bump his dose slightly.

Chest tube output down to 150cc over 8 hours, good trend. CXR looks similar, maybe slightly improved.

We're going to try lightening sedation this afternoon. If he wakes up nicely and follows commands, we'll think about extubation tomorrow.

PT consulted — once he's extubated, we'll get him sitting up, maybe dangling at bedside."

---

### ✅ DAY 2 SUCCESS CRITERIA  
- AI links "bronch" from Day 2 with "bronch" mentioned Day 1
- AI captures: Creatinine trending UP (1.4 → 1.6) — flags this
- AI captures: Tac level 8.2 (low), dose increased
- AI captures: FiO2 weaned (40% → 35%)
- AI captures: Chest tube output DOWN (200 → 150) — good trend

---

## DAY 3 — POST-OP DAY 3  
### 🎯 TRAP: Extubation + minimization language ("just a little")

"Don Miller, post-op day three. Big day — we extubated him this morning around 6am. He's doing okay on 4 liters nasal cannula, sats 93-94%.

He's a little confused, which is totally normal after being sedated. Following commands but not really oriented to place or time. Just a little ICU delirium, very common, should clear in a day or two.

Temp was 38.1 this morning — just a little post-op fever, nothing to worry about. We'll keep an eye on it. Heart rate is up a bit, 102, but he's working harder to breathe now that he's off the vent, so that's expected.

Creatinine is 1.7 now. Still trending up but again, this is often the tacrolimus. Tac level came back at 11.4 — actually got a little high with that dose bump, so we'll back off slightly.

He's sitting at the edge of the bed with PT. Weak but that's expected after ten hours of surgery and three days sedated.

Chest tubes still in, output is 100cc over 8 hours. We might pull them tomorrow if this continues.

Plan is to continue weaning oxygen, repeat CXR, keep watching that creatinine, adjust tac dosing."

---

### ✅ DAY 3 SUCCESS CRITERIA
- AI catches MINIMIZATION: "just a little confused," "just a little fever"  
- AI flags: Temp trending UP (37.2 → 37.8 → 38.1)
- AI flags: Heart rate trending UP (88 → 90s → 102)
- AI flags: Creatinine trending UP (1.4 → 1.6 → 1.7) — 3 days in a row now
- AI flags: Tac level swinging (pending → 8.2 → 11.4)
- AI captures: Extubated, on nasal cannula 4L
- AI captures: ICU delirium noted


---

## DAY 4 — POST-OP DAY 4
### 🎯 TRAP: Buried concern + terminology variation ("BAL")

"Rounds, Don Miller, POD 4. Overall doing okay. Still on nasal cannula, we tried to wean to 3 liters but he desatted to 89, so we're back at 4 liters.

Confusion is a little better. He knows he's in the hospital now, knows his name. Still thinks it's 2024 but improving.

So we did another bronch yesterday — oh sorry, we did a BAL, bronchoalveolar lavage, to get some cultures because of the persistent low-grade temps. Results are pending. 

Temperature was 38.0 overnight. We're not super worried, but we did send the BAL cultures just to be safe. Could be just post-op inflammation.

Heart rate came down a bit to 96. Creatinine is 1.8 — continuing to creep up. We might need to back off the tac more. Current tac level is 9.1, which is in range, but the kidney function is concerning.

Chest tubes came out this morning. Site looks clean.

He walked 50 feet with PT today. Very deconditioned but making progress.

Oh, and we ordered a CT chest to get a better look at those infiltrates on x-ray — it's scheduled for later today."

---

### ✅ DAY 4 SUCCESS CRITERIA
- AI links "BAL" with previous "bronch" — same procedure family
- AI flags: Oxygen wean FAILED (tried 3L, desatted, back to 4L) — this is concerning
- AI flags: Creatinine STILL rising (1.4 → 1.6 → 1.7 → 1.8) — 4 days straight
- AI catches: CT chest ordered — must track if results reported
- AI captures: Walked 50 feet (functional baseline)
- AI flags: "persistent low-grade temps" — pattern emerging

---

## DAY 5 — POST-OP DAY 5
### 🎯 TRAP: Missing result + functional decline + more minimization

"Morning everyone. Don Miller, post-op day 5. Had a bit of a rough night — he was more confused, trying to pull at his lines, needed some Haldol overnight to calm him down.

Temperature was 38.3 at 2am. We gave him some Tylenol and it came down to 37.9 by morning. Probably still just post-op stuff.

Oxygen requirements are the same, still at 4 liters. Sats 93-94%.

Creatinine is holding at 1.8, which is actually good news — at least it stopped climbing.

No update yet on the BAL cultures, lab says they're still pending. Takes a few days to grow anything.

He was too tired for PT today. They came by but he just wanted to sleep. We'll try again tomorrow.

Heart rate is back up to 104. Could be the delirium, could be pain, could be a lot of things.

The CT from yesterday showed some increased ground-glass opacities bilaterally, which could be rejection, could be infection, could be just fluid. We're going to do a surveillance bronch tomorrow to get a transbronchial biopsy and rule out rejection."

---

### ✅ DAY 5 SUCCESS CRITERIA
- AI flags: Delirium WORSENING (not improving as predicted Day 3)
- AI flags: Temp hit 38.3 — highest yet, trend is UP
- AI flags: BAL cultures STILL pending — missing result, 2 days now  
- AI flags: PT SKIPPED — functional DECLINE (walked Day 4, too tired Day 5)
- AI flags: Heart rate back up (96 → 104)
- AI catches: CT shows ground-glass, bronch + biopsy planned
- AI catches: Rejection now on differential

---

## DAY 6 — POST-OP DAY 6
### 🎯 TRAP: Biopsy result buried + "mild" minimization + trend invisible without Day 1

"Don Miller, post-op day 6. So we did the bronch this morning with transbronchial biopsies.

Preliminary path is back and shows... it's showing A2 rejection. Grade A2. Which is moderate acute cellular rejection. But this is actually not uncommon early post-transplant. We're going to treat him with pulse steroids — solumedrol one gram daily for three days. Very standard.

Temperature was 37.6 this morning, actually trending down a bit. Heart rate 98.

Now, his creatinine did bump up to 2.0 today. We think this might be related to the rejection affecting kidney perfusion, or it could be the tac, or both. We're going to hold the tacrolimus for today and recheck levels.

BAL cultures finally came back — they're showing light growth of pseudomonas. We're going to start him on pip-tazo to cover that.

He's still on 4 liters. Sats okay.

PT got him sitting at the edge of the bed today. He didn't want to walk — said he felt too weak. But sitting is progress.

Family is asking a lot of questions. The daughter especially wants to understand the rejection diagnosis. Can we make sure someone talks to them this afternoon?"

---

### ✅ DAY 6 SUCCESS CRITERIA
- AI flags: A2 REJECTION confirmed — this is a BIG finding
- AI catches: "not uncommon" = minimization of serious diagnosis
- AI flags: Creatinine JUMPED (1.8 → 2.0) — biggest single-day increase
- AI catches: BAL cultures POSITIVE for pseudomonas — INFECTION confirmed
- AI catches: Tacrolimus HELD (significant medication change)
- AI flags: Functional decline continues (walked 50ft Day 4 → too tired Day 5 → only sitting Day 6)
- AI should now show: CREATININE TREND from baseline: 1.4 → 1.6 → 1.7 → 1.8 → 1.8 → 2.0 (43% increase)


---

## DAY 7 — POST-OP DAY 7
### 🎯 TRAP: Treatment started but is it working? Vitals mixed.

"Morning. Don Miller, POD 7, day two of pulse steroids for the A2 rejection.

Clinically he looks about the same. Maybe slightly better? Temperature was 37.4 overnight which is nice. Heart rate in the low 90s, 92ish.

He's still on 4 liters though. We tried weaning again and he still desats. So we're staying at 4L for now.

Creatinine is 1.9 — so it actually came down a little bit from yesterday's 2.0. Could be the steroids helping, could be holding the tac. We restarted tacrolimus at a lower dose this morning. New level pending.

He walked to the door and back with PT today — maybe 20 feet? Better than nothing. Still pretty weak but engaging more.

The pseudomonas, we're on day two of pip-tazo. Repeat cultures not due yet.

Delirium is improving. He knows the month now. Making more sense when he talks.

Repeat bronch scheduled for day 9 to see if the rejection is responding to steroids. If not, we'd consider ATG or other escalation.

Oh, and chest x-ray today looks maybe a tiny bit better. Hard to tell day-to-day but overall trajectory seems okay."

---

### ✅ DAY 7 SUCCESS CRITERIA
- AI tracks: Day 2 of 3 for pulse steroids
- AI notes: Temp DOWN (38.3 peak → 37.4) — responding to treatment?
- AI notes: Creatinine DOWN slightly (2.0 → 1.9) — first reversal
- AI catches: Oxygen still stuck at 4L — hasn't improved
- AI flags: Walking DECREASED (50ft Day 4 → 0 Day 5-6 → 20ft Day 7)
- AI catches: Repeat bronch planned Day 9
- AI catches: Possible ATG escalation mentioned if rejection doesn't respond

---

## DAY 8 — POST-OP DAY 8
### 🎯 TRAP: False reassurance + one bad number buried in good update

"Don Miller, POD 8, last day of pulse steroids today. 

Overall I think he's turning the corner. Temp has been normal, 37.1 this morning. Heart rate 88 — back to baseline actually. He looks more comfortable.

We weaned him to 3 liters! And he's holding sats at 93-94%. Big improvement.

PT had a great session — he walked 100 feet in the hallway. Needed rest breaks but did it. His wife was crying, she was so happy to see him up.

Delirium has basically resolved. Fully oriented.

Creatinine is... let me check... it's 2.1. So it went back up a bit. Could just be lab variation. We'll keep watching it.

Tac level came back at 7.8 — right in range. Perfect.

Repeat BAL cultures are negative so far — looks like the pip-tazo is working for the pseudomonas.

We'll see how the bronch looks tomorrow. Hoping the rejection is downgraded on repeat biopsy."

---

### ✅ DAY 8 SUCCESS CRITERIA
- AI catches: Good news (temp normal, oxygen weaned, walked 100ft, delirium resolved)
- AI ALSO catches: Creatinine went BACK UP (1.9 → 2.1) — bucking the trend
- AI should FLAG: "Could just be lab variation" = minimization of rising kidney marker
- AI tracks: Day 3 of 3 steroids complete
- AI tracks: Repeat bronch tomorrow

---

## DAY 9 — POST-OP DAY 9
### 🎯 TRAP: Biopsy improved but creatinine still concerning

"Morning rounds. Don Miller, POD 9. So we did the repeat bronch this morning.

Great news — biopsy is back and it's showing A1 rejection now, down from A2. So the steroids worked. We're not going to need ATG or anything more aggressive.

He's doing well. Still at 3 liters, sats 94-95%. Walked 150 feet with PT — longest yet. Eating a little bit, which is new.

Temperature normal, heart rate 84.

The creatinine though... it's 2.2 today. Still creeping up despite everything. His baseline pre-transplant was actually around 1.1. So we're double his baseline now. Nephrology is going to see him today just to weigh in on the kidneys.

We're thinking this is chronic tac nephrotoxicity and we might need to adjust his immunosuppression regimen long-term. But for now, we're happy with where the lungs are.

Repeat cultures still negative. We'll finish out the pip-tazo course, seven more days.

Starting to talk about step-down to the floor. Maybe tomorrow if he keeps this up."

---

### ✅ DAY 9 SUCCESS CRITERIA
- AI catches: REJECTION IMPROVED (A2 → A1) — treatment working for lungs
- AI catches: ATG NOT needed — good news
- AI catches: Functional improvement (150ft walk, eating)
- AI FLAGS HARD: Creatinine now 2.2, DOUBLE pre-transplant baseline (1.1)
- AI should show: FULL TREND: 1.4 → 1.6 → 1.7 → 1.8 → 1.8 → 2.0 → 1.9 → 2.1 → 2.2
- AI catches: Nephrology consulted — this is significant
- AI catches: "chronic tac nephrotoxicity" — long-term medication issue flagged
- AI catches: May transfer to floor soon

---

## DAY 10 — POST-OP DAY 10
### 🎯 FINAL TEST: Can AI summarize the full 10-day picture?

"Last ICU rounds for Don Miller, POD 10. He's transferring to the step-down floor this afternoon.

Lungs are doing great. Down to 2 liters nasal cannula now. Walked 200 feet, best yet. Oxygen sats 95-96% at rest.

Rejection-wise, we'll repeat surveillance bronch in two weeks as outpatient. For now, A1 rejection controlled.

Infection — pseudomonas cleared, finishing antibiotics.

The creatinine is still our concern — 2.3 this morning. Nephrology is following. They think it's multifactorial: tacrolimus toxicity plus some post-operative acute kidney injury that never fully resolved. They want to consider switching to a belatacept-based regimen which is easier on the kidneys.

He's eating well, delirium resolved, family feels good.

Plan: Transfer to floor, continue current tac dose with close monitoring, finish antibiotics, outpatient bronch in 2 weeks, nephrology follow-up.

Great work everyone. Nice save with the early rejection catch and treatment."

---

### ✅ DAY 10 SUCCESS CRITERIA
- AI provides FULL 10-DAY SUMMARY with trends
- AI shows: Lung function IMPROVED (intubated → 4L → 3L → 2L)
- AI shows: Rejection treated successfully (A2 → A1)
- AI shows: Infection cleared (pseudomonas → negative cultures)
- AI FLAGS: Kidney function DECLINED THROUGHOUT (1.4 → 2.3, 64% increase)
- AI catches: Immunosuppression regimen change being considered
- AI suggests follow-up questions about kidney trajectory
- AI catches: Outpatient bronch scheduled — must not be forgotten

---

## FINAL SCORING RUBRIC

### Terminology Normalization (BUG #1)
| Test | Pass Criteria |
|------|---------------|
| Bronch variations | "bronch," "Bronx," "BAL," "bronchoalveolar lavage" all linked |
| Rejection variations | "A2 rejection," "acute cellular rejection," "ACR" linked |
| Tac variations | "tacrolimus," "tac," "tac level," "Prograf" linked |

### Memory/Baseline (BUG #2)  
| Test | Pass Criteria |
|------|---------------|
| Day 1 baseline remembered | AI can cite Day 1 creatinine (1.4) on Day 10 |
| 10-day trend visible | AI shows full creatinine curve, not just recent |
| Functional trajectory | AI tracks walking distance across all 10 days |

### Clinical Intelligence
| Test | Pass Criteria |
|------|---------------|
| Minimization detection | AI flags "just a little" language |
| Missing results | AI notices BAL cultures pending for multiple days |
| Concern frequency | AI notices recurring themes (creatinine, oxygen) |
| Follow-up generation | AI suggests relevant questions family should ask |

---

## EXPECTED AI SUMMARY ON DAY 10

A good Rounds AI response should include something like:

> "Over the past 10 days, Don has made excellent progress with his lungs — from being on a ventilator to breathing independently on just 2 liters of oxygen. The rejection episode (A2) was caught early and responded well to steroids, now downgraded to A1.
>
> **However, I'm concerned about his kidney function.** His creatinine has risen steadily from 1.4 on Day 1 to 2.3 today — a 64% increase. The team has consulted nephrology and is considering changing his immunosuppression medications to protect his kidneys long-term.
>
> **Questions to ask before transfer:**
> 1. What creatinine level would trigger more aggressive intervention?
> 2. When will we know if the tacrolimus is causing permanent kidney damage?
> 3. What signs should we watch for on the step-down floor?
> 4. When is the outpatient bronchoscopy scheduled?"
