# Writing visitor dilemmas (Visitor Questions tab)

Since 2026-10-16 a visitor question has no "right" answer. Each of the four choices carries its own **Effects**, **Response** and **Reaction** (columns M-X of the Visitor Questions tab). A choice whose cells are blank falls back to the old way: the visitor's Reward if it is the Correct Choice, the Penalty otherwise.

| Column | What goes in it |
|---|---|
| Effects A-D | A target list like `BO06 +3; BO04 -1`. Organizations (BOxx), a pool (`BO01\|BO02 +1`), a tier (`TIER:Party +1`), a shop item (SHxx) or a modifier. A range is written `BO06 +1-3`, the same way the Visitors tab writes it. Sanban variables (Reputation and so on) are **not** supported here. |
| Response A-D | What the visitor says back. 14 words or fewer; no time words (always, again, already, still, before, never, ever). |
| Reaction A-D | A short stage direction. |

## Budget rules (checked by the audit that built batch 1)

| Rule | Value |
|---|---|
| Size of one choice | 2 to 7 points in total, counting minus signs as plus |
| Every choice that gains more than 1 | must also cost something somewhere |
| At least one choice per question | pleases someone by +3 or more |
| No more than two choices | that net 2 or more |
| Typical mix | a friend-pleaser (visitor's organization +3, a rival -1 or -2), a rival-pleaser, a middle path (+1), and a refusal (-2 to -4) |

Standing changes from visitors are flat: they are not scaled by the standing bands that scale a question answer in battle.

Status: batch 1 (the 39 questions VI01-VI15 ask) is written. The other 95 questions still use the fallback until their effects are drafted.
