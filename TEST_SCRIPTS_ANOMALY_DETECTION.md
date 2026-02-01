# 🚨 Rounds AI Stress Test Scripts - Anomaly Detection

These scripts are designed to TEST whether Rounds AI catches subtle red flags, inconsistencies, concerning trends, and things doctors gloss over.

**CRITICAL**: For these tests to work properly, run them IN SEQUENCE (Day 5 → Day 6 → Day 7 → Day 8) so the AI builds patient history and can detect anomalies against prior data.

---

## BASELINE: Day 5 Post-Transplant (Stable - Establishes Normal Values)

*Read this FIRST to establish Don's "normal" baseline values*

```
Good morning everyone. This is day five post bilateral lung transplant for Don Miller.

Overnight, Don did well. No significant events. His vital signs have been stable with temperature at 98.4, heart rate in the 70s, blood pressure running 118 over 72.

Lab work from this morning: His creatinine is stable at 1.2, which is right where we want it. Tacrolimus level came back at 9.8, nicely within our target range of 8 to 12. White blood cell count is 8.2, trending down appropriately as expected post-transplant.

His chest tubes are putting out about 150 cc over the last 24 hours, which is a nice decrease from yesterday. Chest X-ray this morning looks good - no infiltrates, no effusions, the new lungs are expanding well.

He's been working with physical therapy and walked 200 feet yesterday. Tolerating his diet well, no nausea. Pain is well controlled on his current regimen.

The plan today is to continue weaning oxygen - he's currently on 2 liters. We'll keep the chest tubes in one more day and reassess tomorrow. Continue current immunosuppression, continue physical therapy, and if he continues to progress like this, we're looking at stepping down to the regular floor in the next day or two.

Any questions from the family? Okay, we'll see you tomorrow morning.
```

---

## TEST 1: Day 6 - Subtle Lab Shift (Creatinine Creeping Up)

*The AI should notice creatinine went from 1.2 → 1.5 and flag this trend*

```
Morning rounds, day six for Don Miller, post bilateral lung transplant.

So Don had a pretty good night overall. Temperature was 98.6 this morning, vitals otherwise stable.

Labs this morning: Creatinine is 1.5, tacrolimus level is 10.2. White count is 7.8. 

His chest X-ray looks essentially unchanged from yesterday which is reassuring. Chest tube output decreased again, down to about 80 cc, so we're going to pull those today.

He walked 250 feet with PT yesterday which is great progress. We're going to continue weaning his oxygen, he's down to 1 liter now.

Plan is to pull chest tubes this morning, repeat chest X-ray after, continue current meds, and hopefully transfer him to the step-down unit this afternoon.

Everything's looking good. See you tomorrow.
```

**WHAT THE AI SHOULD CATCH:**
- ⚠️ Creatinine jumped from 1.2 to 1.5 (25% increase!) - this needs to be flagged
- Tacrolimus also crept up (9.8 → 10.2) - still in range but trending up
- Doctors said "looking good" but didn't address the creatinine change
- Suggested questions: "Is the creatinine increase concerning? What's causing it?"

---

## TEST 2: Day 7 - Hidden Concern in Medical Jargon

*Contains alarming information buried in casual medical speak*

```
Day seven post-transplant for Don Miller.

So he's on the step-down unit now. Night was okay, though nursing noted he was a bit more restless than usual. Temperature this morning was 99.1.

Labs: Creatinine is 1.8 now. We're watching that. Tacrolimus came back at 11.4 - it's creeping up so we may need to adjust the dose. White count ticked up slightly to 9.2.

Chest X-ray shows some new basilar atelectasis on the right which isn't unexpected given he's been less mobile. We also noted a small pleural effusion that wasn't there yesterday but it's probably just post-procedural from pulling the chest tubes. Nothing to be too worried about.

His oxygen requirements bumped back up a bit - he's back on 2 liters when he had been on 1. He's still walking but he's been a little more fatigued the last day or so.

We're going to get a bronchoscopy scheduled for tomorrow just to take a look, do some washings, make sure there's no early rejection. Fairly routine at this stage. We'll add some Lasix to help with the fluid.

The plan is supportive care for now. We'll reassess after the bronch tomorrow.
```

**WHAT THE AI SHOULD CATCH:**
- 🚨 CREATININE SPIKING: 1.2 → 1.5 → 1.8 over 3 days (50% increase from baseline!)
- 🚨 Temperature trending up: 98.4 → 98.6 → 99.1 (low-grade fever developing)
- 🚨 NEW pleural effusion - they're downplaying it as "post-procedural"
- 🚨 Oxygen needs INCREASING (was weaning off, now back up)
- 🚨 Patient more fatigued, restless - subtle but concerning
- 🚨 White count reversed course and going UP
- Bronchoscopy "routine" - but why do they suddenly need one?
- Questions: "Is Don showing early signs of rejection? The trends seem concerning."

---

## TEST 3: Day 8 - Doctors Contradict Themselves / Missing Info

*Doctors said they'd do something yesterday but didn't mention it today*

```
Day eight, Don Miller, post lung transplant.

We did the bronchoscopy yesterday afternoon. Don tolerated it well. We're waiting on some of the culture results but preliminary findings were... the airways looked okay, some mild erythema in the anastomosis but that can be normal healing.

Temperature overnight got up to 100.2, we gave him some Tylenol and it came back down. This morning it's 99.4.

Creatinine today is 1.9. We've consulted nephrology and they're going to take a look. Tacrolimus is 11.8 so we're decreasing the dose. His white count is 10.4.

He's on 3 liters of oxygen now. The effusion on the right looks about the same on imaging, maybe slightly larger but hard to tell.

We're going to continue watching closely. He's still eating, still doing some PT though shorter distances. We're holding off on the floor transfer for now until things stabilize.

I think he just needs a few more days to turn the corner. These little bumps are not unexpected in the first couple weeks.
```

**WHAT THE AI SHOULD CATCH:**
- 🚨 CRITICAL: They said bronch washings would check for rejection - WHERE ARE THOSE RESULTS?
- 🚨 Temperature hit 100.2 overnight! (fever = potential infection/rejection)
- 🚨 Creatinine STILL climbing: 1.2 → 1.5 → 1.8 → 1.9 (nearly doubled from baseline)
- 🚨 Oxygen requirements TRIPLED: started at 2L, weaned to 1L, now at 3L
- 🚨 Effusion "maybe slightly larger" - getting worse, not better
- 🚨 White count climbing: 8.2 → 7.8 → 9.2 → 10.4 (infection marker)
- 🚨 "Mild erythema" at anastomosis - is this concerning?
- They're "holding off on floor transfer" - admission of decline
- Questions: "What did the bronch washings show? Is this rejection? Should we be more aggressive?"

---

## TEST 4: Day 9 - The Buried Bombshell

*Contains extremely concerning information said casually that a non-medical person would miss*

```
Morning everyone, day nine for Don Miller.

So we got some results back. The transbronchial biopsy is showing A2 rejection. The good news is it's not A3 or A4 so it's moderate, not severe. We're going to pulse him with methylprednisolone, three days of IV steroids, and that usually does the trick.

His temperature has been up and down, 99 to 100 range. We started empiric antibiotics yesterday as a precaution given the immunosuppression and fever. The BAL cultures are still pending.

Creatinine is at 2.1 this morning. Nephrology thinks it's likely tacrolimus toxicity compounded by the stress on his system. We're holding the tacrolimus for now and they may want to do a renal ultrasound.

The effusion has definitely increased - we're discussing whether to tap it for both diagnostic and therapeutic purposes.

He's requiring 4 liters of oxygen to maintain sats above 92. He's pretty tired, not walking much the last couple days. Understandably so.

We're moving him back to the ICU for closer monitoring during the steroid pulse. This is all very manageable, just needs more intensive monitoring. Hopefully this is just a speed bump and we'll have him back on track in a few days.
```

**WHAT THE AI SHOULD CATCH:**
- 🚨🚨🚨 **HE'S BEING DIAGNOSED WITH REJECTION** - A2 rejection confirmed!
- 🚨 Moving BACK TO ICU - this is a major escalation, not a "speed bump"
- 🚨 Creatinine now 2.1 - kidneys in serious trouble (nearly DOUBLE baseline)
- 🚨 4 liters oxygen now - significant respiratory decline
- 🚨 "Sats above 92" - they're struggling to keep him oxygenated
- 🚨 May need to tap the effusion - fluid accumulating in chest
- 🚨 Holding tacrolimus - but that's his anti-rejection med!
- Questions: "How serious is A2 rejection? What's the success rate of steroid pulse? What happens if it doesn't work?"
- Questions: "If you're holding tacrolimus, how do you prevent MORE rejection?"
- Questions: "What do the BAL cultures show? Is there infection ON TOP of rejection?"

---

## TEST 5: Day 10 - Mixed Signals / Information Overload

*Lots of data, some good some bad, easy to get confused*

```
Day ten, ICU day two for Don Miller, status post bilateral lung transplant now with acute cellular rejection undergoing treatment.

So we're midway through the steroid pulse. His temperature has been better, hovering around 99, occasionally touching 100 but not sustained. The repeat chest X-ray shows the effusion is stable, maybe a tiny bit improved. We decided to hold off on thoracentesis for now.

Creatinine ticked down to 1.95 from 2.1 so that's encouraging, nephrology is cautiously optimistic. We restarted a lower dose of tacrolimus this morning - 1 mg instead of 2 mg BID. Level was subtherapeutic at 5.2 but we had to balance that against the kidney injury.

The bad news is his oxygen requirements haven't really improved - still on 4 liters, sats running 91 to 93. He's also been having some episodes of confusion overnight which can happen with high-dose steroids but we did get a head CT just to be safe and that was negative.

We added meropenen to his antibiotic coverage because the BAL grew out some gram negative rods, we're waiting on final speciation. Could be pseudomonas.

He's not really eating much, very fatigued. No PT today. We'll plan for a repeat bronch in a day or two to assess response to treatment.

Family, I know this is scary but we're throwing everything at this. He's fighting. The next 48 hours will tell us a lot.
```

**WHAT THE AI SHOULD CATCH:**
- Mixed signals: some things improving (creatinine, effusion stable, fever better)
- STILL CONCERNING:
  - 🚨 4L oxygen unchanged - lungs not responding yet
  - 🚨 Sats 91-93 - still borderline low
  - 🚨 CONFUSION episodes - new neurological symptom!
  - 🚨 BAL showed INFECTION (gram negative rods, possibly pseudomonas) - ON TOP of rejection
  - 🚨 Tacrolimus now SUBTHERAPEUTIC (5.2) - rejection could worsen
  - 🚨 Not eating, no PT, very fatigued - functional decline
  - 🚨 "Next 48 hours will tell us a lot" - they're worried
- Questions: "Is the confusion just from steroids? Should we be worried about brain involvement?"
- Questions: "He has rejection AND infection - how do you treat both when the treatments work against each other?"
- Questions: "If the repeat bronch shows no improvement, what's the next step?"

---

## USAGE NOTES:

1. **Run in sequence** - The AI needs Day 5 baseline to catch Day 6+ anomalies
2. **Don't tell the AI** what to look for - see if it catches these independently
3. **Check the suggested questions** - Are they personalized to Don's situation?
4. **Check trend detection** - Does it show "1.2 → 1.5 → 1.8 → 1.9 → 2.1"?
5. **Check urgency calibration** - Day 9 should feel MUCH more urgent than Day 6

**Success criteria:**
- AI catches ALL the red flags listed
- AI suggests SPECIFIC questions based on this patient's history
- AI escalates urgency appropriately as situation worsens
- AI notes when doctors said something before but didn't follow up
- AI explains medical terms (A2 rejection, BAL, anastomosis) in plain language
