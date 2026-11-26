# Selection score spread (P20 checkpoint)

2026-11-26 · written by Claude · a draft for Cameron

## Summary

| Question | Answer |
|---|---|
| Does a typical player reach the 40 line? | Not on campaign actions alone. The scripted steady run (Party support 70, two to four campaign actions a week, three office staff) ended at strength 32, score 37: **Not Selected**. |
| What lifts the score most? | Strength carries half the score, so awareness, Constituency support, organizations, the fund and capital all count. A player who also wins rooms (the strong run: Party support 90, committee standing 80, awareness 70 and 60, Constituency 75) reached strength 55 and score 61: **Single-Member District**. |
| Is the top outcome reachable? | The 75 line (District with the list as a safety net) needs strength near 95 even with high alignment and influence. It is practically out of reach as set. |
| What I did not do | The real bot does not know the campaign actions, so I did not run it to Campaign Open. These numbers come from the formula and the two scripted runs. Not Selected is a game over, so the thresholds (40, 60, 75) are yours to confirm; I changed nothing. |

## Score = 0.5 x strength + 0.25 x alignment + 0.25 x influence (influence = average of Party support and committee standing)

| Strength | Alignment | Party support | Committee standing | Score | Outcome |
|---|---|---|---|---|---|
| 20 | 50 | 50 | 30 | 32 | Not selected |
| 32 | 50 | 70 | 30 | 41 | List |
| 40 | 50 | 70 | 50 | 48 | List |
| 50 | 50 | 70 | 50 | 52 | List |
| 55 | 50 | 90 | 80 | 61 | District |
| 60 | 50 | 80 | 60 | 60 | District |
| 70 | 60 | 80 | 70 | 69 | District |
| 80 | 70 | 90 | 80 | 79 | District + net |
| 100 | 100 | 100 | 100 | 100 | District + net |

## What I would ask you

| Question | Options |
|---|---|
| Is a steady player meant to be turned down? | Keep 40, lower it to 30, or lower the strength weight so Party support and alignment carry more. |
| Should the safety-net line be reachable? | Lower it from 75 to about 70, or keep it as a rare prize. |
