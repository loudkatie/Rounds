# 🧪 10-DAY STRESS TEST: Don Miller
## Double Lung Transplant Patient — Pulmonary ICU

**Patient:** Don Miller, 66 years old  
**Surgery:** Bilateral lung transplant  
**Start:** Day 1 post-surgery  
**Location:** Pulmonary ICU → Step-down → ICU (return)

---

## 🎯 WHAT THIS TEST VALIDATES

### Bug #1: Medical Term Normalization
The script uses different terms for the same thing:
- Day 3: "bronch" / Day 7: "bronchoscopy" / Day 10: "BAL"
- Day 6: "tacro level" / Day 8: "FK506 level" / Day 9: "tacrolimus"
- Day 4: "fluid in the chest" / Day 7: "pleural effusion" / Day 8: "effusion"

**PASS CRITERIA:** AI connects these as the SAME thing across days

### Bug #2: Full History Recall  
Critical trends only visible across ALL 10 days:
- Creatinine: 1.1 → 1.2 → 1.2 → 1.3 → 1.5 → 1.6 → 1.8 → 1.9 → 2.1 → 2.0
- Temperature baseline 98.2 slowly creeping → fever by Day 8
- Oxygen: improving Days 1-4, then REVERSING Days 5-10

**PASS CRITERIA:** AI shows FULL trajectory from Day 1, not just "yesterday"

### Bug #3: Missing Information Detection
- Day 3: "We'll check cultures tomorrow" — never mentioned again until Day 9
- Day 7: Bronchoscopy done — results "pending" for 3 days
- Day 6: "PT will work with him" — but Days 8-10 no PT mentioned

**PASS CRITERIA:** AI asks "What happened to [X]?" proactively

---

## 📋 THE 10-DAY SCRIPT

Record each day IN ORDER. Wait for AI response before next day.

---

### DAY 1 — POST-OP RECOVERY (Baseline)

> Good morning everyone. This is Don Miller, 66-year-old male, this is post-op day one from bilateral lung transplant.
>
> Surgery went well, no complications. He's intubated, sedated, on the vent. Hemodynamically stable overnight, minimal pressor support, we'll probably wean those off today.
>
> Labs from this morning look good. Creatinine is 1.1, which is excellent post-operatively. We started tacrolimus, level pending but we dosed at 2 mg BID. White count is 12.4 which is expected post-surgery.
>
> Chest tubes are in place, putting out about 400 cc over the last 12 hours, mostly serosanguinous which is normal. Chest X-ray shows the new lungs are expanded, no pneumothorax, ET tube in good position.
>
> He's on 60% FiO2 with good sats, 96 to 97%. Temperature has been stable at 98.2.
>
> Plan: Continue current support, start weaning sedation this afternoon, trial spontaneous breathing tomorrow if he looks ready. Continue immunosuppression per protocol.
>
> This is exactly where we want him at this stage. Good start.

**BASELINE VALUES TO CAPTURE:**
- Creatinine: 1.1 ⭐ (REMEMBER THIS NUMBER)
- WBC: 12.4 (expected post-op)
- Temperature: 98.2
- FiO2: 60%
- Chest tube: 400cc/12hr

---

### DAY 2 — WEANING BEGINS

> Day two post bilateral lung transplant for Don Miller.
>
> Great night. We weaned sedation, he woke up nicely, following commands. We did a spontaneous breathing trial this morning and he passed, so we extubated him about an hour ago. He's doing well on a high-flow nasal cannula at 40 liters, 50% FiO2.
>
> Labs: Creatinine stable at 1.2, tacro level came back at 8.2 which is right in our target range. White count down to 10.8, trending nicely.
>
> Chest tubes still in, output decreased to about 250 cc, still serosanguinous. Chest X-ray looks stable.
>
> He's alert, oriented, a little hoarse from the tube but that's expected. Temperature 98.4.
>
> We'll advance his diet today, clear liquids, and get PT in to see him. If he tolerates the high-flow well, we'll start weaning it down.
>
> Really pleased with his progress.

**AI SHOULD NOTE:**
- Creatinine 1.1 → 1.2 (tiny increase, but TRACK IT)
- WBC 12.4 → 10.8 (good trend down)
- Major milestone: extubated!
- Functional: alert, oriented

---

### DAY 3 — ROUTINE PROGRESS (Seeds planted)

> Morning rounds, day three post-transplant for Don Miller.
>
> Another good night. He's down to 6 liters nasal cannula now, saturating well at 95-96%. 
>
> Labs: Creatinine holding at 1.2. Tacro level 9.1. White count 9.4, continuing to trend down.
>
> His chest tubes are really slowing down, about 100 cc overnight, so we'll probably pull those tomorrow. Chest film looks good.
>
> Temperature was 98.6 overnight which we're watching but not concerning yet.
>
> He ate breakfast this morning, tolerated it well. PT had him up in the chair yesterday, today they're going to try walking. He's eager to get moving which is great.
>
> We'll get a bronch in the next couple days, that's routine after transplant, just to take a look at the anastomoses and check for rejection. We'll check cultures too since he's immunosuppressed.
>
> Everything on track. If he keeps this up, might move to step-down by day five or six.

**⚠️ SEEDS PLANTED:**
- "We'll check cultures" — follow up on this
- Temperature 98.6 — started creeping
- Bronch mentioned as "routine" — remember this

---

### DAY 4 — SUBTLE SHIFT BEGINS

> Day four for Don Miller, bilateral lung transplant.
>
> So overnight he had a little bit of a rough patch. Temperature got up to 99.2 around 2 AM, we gave him some Tylenol and it came back down. Nursing said he was a bit restless.
>
> He's on 4 liters now, sats okay at 94-95%. Not quite as good as yesterday but still acceptable.
>
> Labs: Creatinine ticked up slightly to 1.3. Tacro level is 10.4, a little higher than we'd like so we'll decrease the dose slightly. White count 8.9.
>
> We pulled the chest tubes this morning, he tolerated that well. Post-pull X-ray shows a small amount of fluid in the chest on the right side, probably just post-procedural, nothing to drain.
>
> He walked about 50 feet with PT, got tired pretty quickly but that's not unusual at this stage.
>
> Plan is bronchoscopy tomorrow morning. Continue monitoring, we'll recheck tacro level in the morning.

**AI SHOULD CATCH:**
- ⚠️ Temperature now 99.2 (was 98.2 baseline — trending UP)
- ⚠️ Creatinine 1.1 → 1.2 → 1.2 → 1.3 (slow climb starting)
- ⚠️ Oxygen going BACKWARDS: 6L → 4L sounds like improvement but sats dropped 95-96% → 94-95%
- ⚠️ "Fluid in the chest" — first mention of effusion
- ⚠️ Walked 50 feet, got tired quickly

---

### DAY 5 — BRONCHOSCOPY (Appears stable)

> Day five post-transplant, Don Miller.
>
> We did the bronchoscopy this morning. The anastomoses look good, nice healthy tissue, no ischemia. Airways are clear. We did a BAL for cultures and a transbronchial biopsy just to check for any early rejection. Results will be back in a couple days.
>
> He tolerated the procedure well, had a little oxygen bump up to 5 liters during recovery but we're back down to 4 liters now.
>
> Temperature has been 98.8 to 99.0 range today. Labs: Creatinine 1.5 which is up a bit, probably just from the contrast and mild dehydration pre-procedure. We'll push some fluids. Tacro level 9.8. White count 9.0.
>
> The effusion on the right looks about the same on today's film, maybe tiny bit bigger.
>
> He didn't do PT today given the bronch, but he's been in the chair. Appetite okay but he said he's not very hungry.
>
> Plan: Continue supportive care, await bronch results, probably still on track to step down tomorrow or day after.
>
> Family, the bronch looked great, no red flags. Just being thorough.

**AI SHOULD CATCH:**
- 🚨 Creatinine jumped: 1.3 → 1.5 (15% increase from yesterday, 36% from baseline!)
- Doctor minimized: "probably just contrast and dehydration"
- ⚠️ Temperature consistently elevated now (98.8-99.0)
- ⚠️ Effusion "maybe tiny bit bigger"
- ⚠️ "Not very hungry" — functional decline signal
- Note: BAL results PENDING — follow up

---

### DAY 6 — TRANSFER TO STEP-DOWN (False calm)

> Good morning, day six for Don Miller post bilateral lung transplant.
>
> He had a good night actually. Slept well, temperature stayed under 99, vitals stable.
>
> We're going to transfer him to the step-down unit today. He's on 3 liters nasal cannula, sats 94%.
>
> Labs: Creatinine 1.6, still a little elevated but nephrology isn't too worried yet. Tacro — we call it FK506 level — that was 10.2. White count 9.6, pretty stable.
>
> PT had him walk 100 feet yesterday evening, he did okay. A little winded at the end but no desaturation.
>
> The bronch culture and biopsy results aren't back yet, sometimes takes a couple days. No news is good news though.
>
> Effusion stable. He's eating a little better today, had some soup at lunch.
>
> This is a good step forward. Step-down means less intensive monitoring, which means we think he's ready for it. See you tomorrow.

**AI SHOULD CATCH:**
- 🚨 Creatinine: 1.1 → 1.2 → 1.2 → 1.3 → 1.5 → 1.6 (SHOW FULL TRAJECTORY)
- ⚠️ Oxygen crept from 4L → 3L but sats STILL only 94% (not improving proportionally)
- ⚠️ WBC 9.0 → 9.6 (started ticking back UP)
- ⚠️ Bronch results STILL pending — "no news is good news" is not an answer
- Note: "FK506" = tacrolimus (terminology test)

---

### DAY 7 — THE PIVOT (Things go wrong)

> Day seven post-transplant for Don Miller. He's on the step-down unit now.
>
> So, overnight he had some issues. Temperature spiked to 100.4 around midnight, came down to 99.6 with Tylenol by morning. He was more confused overnight, nursing said he was asking where he was a couple times. That settled down but we're watching it.
>
> His oxygen needs went back up — he's on 4 liters now to keep sats above 92. That's a step backwards.
>
> Labs are concerning. Creatinine jumped to 1.8. We've consulted nephrology to take a look. Tacrolimus level is 11.8, definitely elevated, so we're holding the morning dose. White count is 10.8, creeping up.
>
> Chest X-ray shows the pleural effusion is definitely larger now, and there's some new haziness in the right lower lobe. Could be atelectasis, could be something else.
>
> The bronchoscopy results from day five — the cultures are still pending but the biopsy showed some mild inflammation. The pathologist is still reviewing it for rejection grading.
>
> He's been too tired for PT, barely ate anything yesterday. His wife is concerned, and honestly we share some of that concern.
>
> Plan: We're going to repeat the bronchoscopy tomorrow to get a better look, start empiric antibiotics just in case, increase his monitoring. If he doesn't stabilize we may need to move him back to the ICU.
>
> This is a rough patch but not unexpected. Transplant recovery isn't always linear.

**AI MUST CATCH:**
- 🚨 Temperature HIT 100.4 (FEVER!)
- 🚨 Creatinine: 1.1 → 1.8 (64% increase from baseline!) — SHOW FULL CHAIN
- 🚨 CONFUSION — new neuro symptom!
- 🚨 Oxygen BACKWARDS again: 3L → 4L, struggling for 92%
- 🚨 Pleural effusion LARGER + new infiltrate
- 🚨 WBC trending UP: 8.9 → 9.0 → 9.6 → 10.8 (infection signal)
- 🚨 Biopsy shows "mild inflammation" — what does that mean for rejection?
- 🚨 NOT EATING, no PT — functional crash
- 🚨 Cultures STILL pending from Day 5!
- Doctor minimized: "rough patch but not unexpected"
- Ask: "Is this rejection? Is this infection? Both?"

---

### DAY 8 — DETERIORATION

> Day eight, Don Miller, status post bilateral lung transplant.
>
> So we did the repeat bronchoscopy yesterday afternoon. Airways still look okay structurally but there's more secretions than we'd like. We did another BAL and biopsy.
>
> Overnight was rough. Temperature has been 99.5 to 100.8 range, we've started him on broad spectrum antibiotics — vanc and zosyn. He's confused on and off, mostly oriented but slow.
>
> Oxygen is now 5 liters, sats 91 to 93. We've moved him back to the ICU for closer monitoring. Not intubating, hopefully won't need to.
>
> Labs: Creatinine 1.9. Nephrology is following, they think it's a combination of the tacro toxicity and the overall stress. We've held tacrolimus for now. White count 11.4, trending wrong direction.
>
> The original bronch biopsy from day five — it finally came back as A1 rejection, which is minimal. But with everything else going on, they're going to re-grade the new biopsy to see if it's progressing.
>
> The effusion is bigger, we're discussing whether to tap it.
>
> He hasn't eaten in two days. We'll put in a feeding tube if this continues.
>
> I know this is scary. We're watching him very closely. The next 24-48 hours will tell us a lot.

**AI MUST CATCH:**
- 🚨🚨 BACK IN ICU — this is escalation
- 🚨 Creatinine: 1.1 → 1.9 (73% increase!) — FULL TRAJECTORY
- 🚨 5L oxygen, sats barely 91-93
- 🚨 Temperature 100.8 (definite fever, not "low-grade")
- 🚨 A1 rejection on Day 5 biopsy — NOW checking if progressed
- 🚨 WBC 11.4 — infection pattern
- 🚨 CONFUSION persistent
- 🚨 NOT EATEN IN 2 DAYS — severe functional decline
- 🚨 TACROLIMUS HELD — how do you prevent rejection without it?!
- Ask: "What did the repeat bronch cultures show?"
- Ask: "If rejection is progressing, what's the treatment?"

---

### DAY 9 — THE DIAGNOSIS

> Day nine, ICU day two for Don Miller.
>
> Okay, so we got results back. The repeat biopsy is showing A2 rejection now, moderate acute cellular rejection. That's worse than the A1 from a few days ago, so it is progressing.
>
> We're starting a steroid pulse — IV methylprednisolone for three days. That's the standard treatment for A2.
>
> The BAL from the repeat bronch grew out gram-negative rods, likely Pseudomonas. We've tailored the antibiotics appropriately. So he has both rejection AND infection going on, which is challenging because steroids suppress the immune system further.
>
> Creatinine this morning is 2.1. Nephrology is talking about whether he needs dialysis, but we're trying to avoid that. We restarted tacrolimus at a lower dose — 1 mg BID — because we have to balance kidney protection against rejection progression.
>
> He's on 6 liters now, sats hovering around 90-91. If he drops further we'll need BiPAP or intubation.
>
> Temperature better with the antibiotics, 99.2 this morning. White count 12.1.
>
> He's very weak, hasn't been out of bed in three days. The confusion comes and goes — when he's awake he knows his wife's name but he's asking about things from twenty years ago.
>
> This is the critical period. We're fighting on two fronts — rejection and infection. The steroids should help the rejection, the antibiotics should help the infection. We just need to support him through this.
>
> Please know we're doing everything we can.

**AI MUST LEAD WITH:**
- 🚨🚨🚨 **A2 REJECTION CONFIRMED** — progressed from A1
- 🚨🚨 **PSEUDOMONAS INFECTION** — on top of rejection!
- 🚨 Creatinine: 1.1 → 2.1 (91% increase — nearly DOUBLED)
- 🚨 6L oxygen, sats 90-91 — worst yet
- 🚨 WBC 12.1 — highest since Day 1
- 🚨 Tacrolimus restarted while kidney failing — delicate balance
- 🚨 3 days without mobility, intermittent confusion
- Ask: "If the steroids don't stop the rejection, what's next?"
- Ask: "Can you fight both infection AND rejection at the same time safely?"

---

### DAY 10 — THE CROSSROADS

> Day ten, ICU day three for Don Miller, status post bilateral lung transplant, now with acute cellular rejection A2 on treatment day two of steroid pulse, also treating hospital-acquired Pseudomonas pneumonia.
>
> Mixed picture today. Some things better, some things I'm still worried about.
>
> The good news: his creatinine came down to 2.0 from 2.1. Nephrology is cautiously optimistic we can avoid dialysis. Temperature has been well controlled, highest was 99.4 overnight. White count actually ticked down to 11.2, so maybe the antibiotics are working.
>
> The concerning stuff: His oxygen needs haven't improved at all. Still 6 liters, sats 90-92. His lungs just aren't responding yet, either to the steroids or the antibiotics. The effusion is stable but we did end up tapping it yesterday — got off about 400 cc of fluid which was mildly inflammatory but not infected, so that's one less concern.
>
> His tacrolimus level came back at 5.4 on the reduced dose, which is subtherapeutic, but we're stuck between a rock and a hard place with the kidney.
>
> Mentally he's a little better today — more awake, recognized his daughter when she visited. But he's very weak. No PT still, he can barely sit up in bed. Not eating, we put the feeding tube in yesterday.
>
> We'll repeat the bronchoscopy in two days to see if the rejection is responding to steroids. That's the moment of truth.
>
> He's fighting. We're fighting. The next few days are critical.
>
> I want to be honest with you — we're not out of the woods. But I've seen patients turn the corner from worse situations than this. Don has a lot going for him. We're going to keep pushing.

**AI MUST SYNTHESIZE FULL 10-DAY PICTURE:**

**Positive signals:**
- Creatinine 2.1 → 2.0 (first improvement in days)
- Temperature controlled
- WBC 12.1 → 11.2 (trending down)
- Effusion tapped, not infected
- Mental status slightly improved

**Still critical:**
- 🚨 6L oxygen UNCHANGED — lungs not responding
- 🚨 Sats 90-92 — borderline
- 🚨 Tacrolimus 5.4 — subtherapeutic (rejection could worsen)
- 🚨 Can't sit up, no PT, on feeding tube — severe functional decline
- 🚨 "Next few days are critical" — they're worried
- Awaiting repeat bronch to assess rejection response

**FULL TRAJECTORIES TO SHOW:**
- Creatinine: 1.1 → 1.2 → 1.2 → 1.3 → 1.5 → 1.6 → 1.8 → 1.9 → 2.1 → 2.0 (82% above baseline, slight improvement)
- Temperature: 98.2 → 98.4 → 98.6 → 99.2 → 99.0 → 99.0 → 100.4 → 100.8 → 99.2 → 99.4 (controlled but still elevated)
- Oxygen: 60% vent → 40L high-flow → 6L → 4L → 5L → 3L → 4L → 5L → 6L → 6L (WENT BACKWARDS)
- WBC: 12.4 → 10.8 → 9.4 → 8.9 → 9.0 → 9.6 → 10.8 → 11.4 → 12.1 → 11.2 (V-shaped, now improving)

**KEY QUESTIONS:**
1. "If the steroids don't work for the A2 rejection, what's the backup treatment?"
2. "The tacrolimus is too low to prevent rejection but too high for his kidneys — how do you thread that needle?"
3. "He's been declining physically for days — when can PT start again?"
4. "What specifically are you looking for on the repeat bronchoscopy?"

---

## ✅ PASS CRITERIA

### Memory & History
- [ ] Shows COMPLETE vital trajectories from Day 1 baseline (not just "yesterday")
- [ ] Percentages calculated from FIRST reading, not recent readings
- [ ] Connects events across days ("cultures mentioned on Day 3, still pending Day 6")

### Term Normalization  
- [ ] Recognizes "bronch" / "bronchoscopy" / "BAL" as related
- [ ] Recognizes "tacro" / "tacrolimus" / "FK506" as the same drug
- [ ] Recognizes "fluid in chest" / "effusion" / "pleural effusion" as same finding

### Trend Detection
- [ ] Catches creatinine creeping upward even when doctors minimize
- [ ] Catches oxygen going BACKWARDS (improving then worsening)
- [ ] Catches WBC V-shape (infection signal)
- [ ] Catches temperature trending before it hits "fever"

### Functional Status
- [ ] Tracks eating: tolerating → not hungry → not eating → feeding tube
- [ ] Tracks mobility: walking 100ft → 50ft → chair only → bed only
- [ ] Tracks mental: alert → slow → confused → intermittent confusion

### Missing Information
- [ ] Asks about pending cultures/results proactively
- [ ] Notes when "we'll check X" was said but X wasn't mentioned again
- [ ] Asks what "mild inflammation" means for rejection

### Urgency Escalation
- [ ] Day 1-3 tone: optimistic, reassuring
- [ ] Day 5-6 tone: noting concerns, watchful
- [ ] Day 7-8 tone: clearly concerned, urgent language
- [ ] Day 9-10 tone: serious, fighting on multiple fronts

### Cut Through Minimization
- [ ] Notes when "just dehydration" doesn't explain creatinine trend
- [ ] Notes when "not unexpected" contradicts ICU transfer
- [ ] Notes when "rough patch" is actually multi-system decline

---

## 🔧 IF TEST FAILS

### If AI loses Day 1-3 context:
→ Bug is in `buildSystemContext()` — `sessions.suffix(7)` truncation
→ Fix: Increase to `suffix(10)` or dynamic based on actual session count

### If AI doesn't connect bronch/BAL/bronchoscopy:
→ Bug is missing medical term normalization
→ Fix: Add `normalizeMedicalTerm()` function similar to `normalizeVitalName()`

### If AI doesn't show full trajectory:
→ Bug is prompt not being followed OR context too truncated
→ Fix: Check that vital trends include ALL readings, not just `suffix(10)`

### If AI misses functional decline:
→ Bug is `functionalStatus` not being persisted/recalled properly
→ Fix: Verify functional status is saved to memory and injected into context
