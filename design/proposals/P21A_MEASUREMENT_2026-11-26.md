# P21 phase A measurement: where the meters settle

2026-11-26 · written by Claude · a draft for Cameron. The weekly gains are the economy map's draft week (Party support about +12, District awareness +2, National awareness +5), not bot-measured.

## Summary

| Meter | Gain a week | Decay | Settles at | Verdict |
|---|---|---|---|---|
| Party support | +12 | 5 (50 to 74), 8 (75 and up) | about 92, reaching 75 in 6 weeks | **Still runs away.** The free backing M09 (above 75) stays on. |
| Party support | +8 | the same | about 69 | Held below 75. The decay bites when rooms give 8 or less. |
| District awareness | +2 | 2% of the distance above 20, at least 1 | about 99 after four years | **Still runs away**, only slower. |
| National awareness | +5 | 2% of the distance above 10, at least 1 | about 99 | **Still runs away.** |
| Political Capital | 620 earned | 15% above 300 | about 3,813 | Bounded, as designed. |

## What it means

| Question | Answer |
|---|---|
| Why does awareness still reach 100? | The loss is 2% of the distance, which is 1 point near the top, and the gains are 2 and 5. A gain above the loss always wins. |
| What would hold it? | A higher awareness percent (about 6 to 8%), or a flat step as Party support has. With a gain of 2 a week, a decay of 5% settles District near 60. |
| Party support | The 5 and 8 steps hold it only if rooms give about 8 a week or less. The bot should say what rooms really give. |
| What I did | Built the numbers as specified and changed nothing. These are Balance rows (`awareness_decay_percent`, `party_support_decay_at_50`, `party_support_decay_at_75`) you can retune without code. |
