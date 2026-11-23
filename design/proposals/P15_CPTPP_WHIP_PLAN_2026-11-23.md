# P15 plan: the CPTPP Decision! sequence, two whips and two votes (draft for Cameron, 2026-11-23)

Nothing is built. This plan folds in Cameron's answers and `Story_Votes.xlsx`. **It waits for "Go" and for the four questions in section 4.**

## 1. Executive summary

| Question | Answer |
|---|---|
| What changed from the brief | The brief had one whip and one Floor Vote. Cameron's answers make it **two whips** (OP82 the lead minister for joining, OP29 an FP minister against joining and for an amendment) and **two Floor Votes** (an amendment, then the final bill). The date is **18.10.22**. The draft text is marked "Claude's draft". |
| What the worksheet gives | A vote by every one of the 101 seats on both votes, which fixes both Floor Votes rows (party counts) and gives the final-vote party positions you listed. |
| What blocks "Go" | Four decisions (section 4): the follow-up limit, what OP29's scene is, how to use the worksheet (its IDs are shifted for 27 members), and where the party positions and parent ID go in the workbook. |
| Size | Large: about 600 to 900 lines of code and tests, 10 data tabs and 40 or so new Text rows, in six commits on one branch `feature/p15-cptpp-whip`, one full check at the end. |

## 2. What the worksheet says (read, not yet used)

101 rows, one per seat, with an amendment vote and a final vote (`Yes`, `No` or `Absent`). **Absent counts as abstain** in the party counts below (to confirm).

| Party | Seats | Amendment (Yes / No / Absent) | Final (Yes / No / Absent) | Majority |
|---|---|---|---|---|
| Butsutou (BU) | 19 | 4 / 14 / 1 | 13 / 5 / 1 | Amendment No, Final Yes |
| Yezo Heritage Party (YHP) | 14 | 7 / 7 / 0 | 9 / 5 / 0 | Amendment split, Final Yes |
| Frontier Party (FP) | 27 | 9 / 16 / 2 | 16 / 9 / 2 | Amendment No, Final Yes |
| Five Point Independents (FPI) | 5 | 0 / 4 / 1 | 4 / 0 / 1 | Amendment No, Final Yes |
| Keizaijiyuutou (KJT) | 25 | 4 / 17 / 4 | 21 / 0 / 4 | Amendment No, Final Yes |
| Country Initiative (CI) | 11 | 10 / 0 / 1 | 0 / 10 / 1 | Amendment Yes, Final No |
| **Total** | **101** | **34 / 58 / 9: the amendment fails** | **63 / 29 / 9: the final passes** | |

The final-vote majorities match your list (YHP, KJT, FPI, FP and BU aye, CI no). Party seat counts match the Parties tab exactly.

**Problems found in the worksheet (they need your answers, section 4 question 3):**

| Finding | Detail |
|---|---|
| **27 member IDs are shifted** | From OP74 to OP100 the sheet's IDs are one off from `opponents.json` while the **names match**: for example the sheet's OP82 is Teinei Macmillan, the data's OP83 is, and the data's OP82 is **Tama Tsujikonou** (the sheet's OP81). I would key every row by **name** and use the data's IDs. |
| One name written the other way round | The sheet's "Yun-hee Seong" is "Seong Yun-hee" in the data (OP99/OP100 region). |
| **Two parties differ** | Harumi Asato: sheet FP, data Keizaijiyuutou. Hee-seop Han: sheet KJT, data Frontier Party. Swapping them keeps every party's seat count, so one of the two is stale. |
| Who is who | The sheet has OP29 Imekanu Resu (Agriculture, Chair, FP; amendment Yes, final No), as you describe. **OP82 Tama Tsujikonou (the lead minister, Foreign Affairs, FP) voted Amendment No, Final Yes** by the sheet's OP81 row. |

## 3. The build, in order

IDs to use today: opponents **OP132 to OP134**, visitors **VI175 and VI176** (VI174 is taken), the whip stage **ST290**, Floor Votes **BI51** (the amendment) and **BI52** (the final bill), scenes **DS02 onward**. Names are checked unused.

| # | Commit | What |
|---|---|---|
| 1 | **Data and exporter** | New columns: Parties (`assistant_whip_opp_id`, `deputy_whip_opp_id`, `chief_whip_opp_id`); Decision Scenes (**Whip Bill**, **Minister**, plus the party-position and parent columns from question 4); Rules `whip_bands` (0-30, 31-71, 72-89, 90-97, 98-100, checked gap-free); a **Story Votes** tab if you agree (question 3). The three whips as opponents (Tomoe Sakamoto, Isamu Takaoka, Nobuko Ezaki) and Takaoka and Ezaki as visitors, sharing portraits; BI51 and BI52 with party counts from the worksheet; the new Text rows. Exporter checks for each. |
| 2 | **Pure rules** | `WhipPick.gd`: the band pick (30/31, 71/72, 89/90, 97/98 edges), the minister-must-be-in-your-party rule, a blank Minister, the party line, "no line means the scene never opens", and the lock check. Headless tests. |
| 3 | **The whip scene card** | A whip scene shows the picked whip as its speaker; the pick is saved with the run so the card, the stage and a reloaded game agree. |
| 4 | **The whip stage ST290** | "Whipped into Line" (党議拘束 Tōgi Kōsoku): Survival bar with a new unit **Resolve**, 3 turns, 6 energy never refilled, win Reputation +1 and Party support -2, loss Party support +1, Constituency support -1 and the lock, 1 hour. **I will read the Survival model and propose the Resolve numbers before changing anything** (brief section D). |
| 5 | **The Floor Vote lock** | A lost whip stage records the lock; the Floor Vote on that bill greys the other two buttons with "You gave the whip your word." |
| 6 | **Scenes, cues and votes** | The six or more scenes with their Events and Event Choices rows (draft text, marked "Claude's draft"), the opponent and player cue rows from the brief's appendix, and the two votes wired through `vote:` activations. |

Then: unit tests, one real-click test (DS05 at Party support 50 shows the Deputy Party Whip, choose C, lose the stage, and the final vote has only the party-line button live), screenshots in the three styles in `design/review/p15_cptpp_whip_2026-11-23/` with a REPORT.md, the docs, one full check, push `feature/p15-cptpp-whip`, **no merge**.

## 4. Decisions I need before "Go"

| # | Question | Why | My recommendation |
|---|---|---|---|
| 1 | **The follow-up limit.** One first scene may have at most 5 follow-ups (your rule, 2026-11-21). This chain has DS02 (first) then the home front, the business lobby, two whips, the amendment vote, the final vote and the aftermath: **7 follow-ups**. | The exporter would refuse it. | Raise the limit to a Rules row (`Decision Scene Max Follow-Ups`) set to 8, so the rule stays yours to change. |
| 2 | **What is OP29's scene?** You said OP29 (Frontier Party) appears to **all** player characters and whips against the CPTPP and for the amendment. Your other rule: a minister from another party never whips the player. | A non-FP player cannot be whipped by an FP minister; and the lock means "your party line", not OP29's ask. | An **appeal**, not a whip: OP29 asks every player; choices move organization standing and the vote cues; no stage and no lock. The party whips and the lock stay as designed. |
| 3 | **How to use the worksheet.** | See section 2: shifted IDs, two parties, Absent. | Import it as a new **Story Votes** tab keyed by **name**, mapped to the data's IDs, with **Absent as abstain**; Floor Votes party counts for BI51 and BI52 are computed from it, and you decide the two party swaps (Harumi Asato, Hee-seop Han). |
| 4 | **The workbook columns you asked for.** | "A column to receive the party position" and "the parent ID". | Floor Votes already holds each party's votes and position per bill: add a **Decision Scene** column there (the parent scene's ID) and a **Vote Bill** column on Decision Scenes; positions stay in Floor Votes, filled from Story Votes. |

## 5. Risks I will check first and stop on

| Risk | Plan |
|---|---|
| A blank party on a whip opponent row | The pick needs "the player's own party's whip". I found `party` read in three places (patron levels, member stance, party display); I will test a blank before relying on it and report if one fails. |
| Two IDs sharing one portrait | `art.json` maps by ID prefix; the three new whips need their picture copied or mapped. The art is not drawn yet, so a labelled placeholder shows. |
| The cue "side" for a party line | If the side columns cannot say "the party's line", I report and propose; I do not change the cue engine. |
| New canon | The amendment text and Australia's role come from your answer only. I write them as drafts and mark them. |
