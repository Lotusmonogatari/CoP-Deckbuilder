# P15 plan, version 2: the CPTPP Decision! sequence, two whipping scenes and two votes (draft for Cameron, 2026-11-23)

Nothing in this plan is built. It folds in Cameron's eight design changes and the corrected `Story_Votes.xlsx`. **It waits for the four answers in section 6 and a "Go".**

## 1. Executive summary

| Question | Answer |
|---|---|
| What the sequence is | DS02 opens **Monday 18.10.22**; two whipping scenes (the party whip, and **OP29 Imekanu Resu**, a unique whip for every player); an amendment vote and a final vote; all votes **done by Monday 18.10.29** (before Tuesday 18.10.30). |
| New game rules asked for | (a) a Decision! on a weekday keeps levels from running over it; (b) the evening before a Mandatory Decision!, staff bring a player who is in the wrong office back, at 100 XP; (c) a chain may exceed 5 follow-ups when Cameron approves it; (d) two whips, three outcomes (free, locked to the winner, abstain). |
| Already done | DS01 moved to **18.10.15** (parliament opens); OP74 is **Yun-hee Seong** (branch `fix/ds01-oct15-and-yun-hee`, pushed, not merged). |
| Worksheet | Corrected: the right-hand ID block matches the data; all 101 members and parties match. It is the source for both Floor Votes rows. |
| Size | Very large: about 1,000 lines of code and tests, ten data tabs, about 60 Text rows, in eight commits on `feature/p15-cptpp-whip`, one full check at the end. |

## 2. The worksheet, verified

| Check | Result |
|---|---|
| Layout | Votes in columns A to E (name, committee, party, amendment, final); an ID lookup block in F to H. I match each name to an ID through that block. |
| IDs and parties | All 101 IDs are in the data; every party matches the data. |
| Small name variants (no problem) | "Ayala" is "Ayala Taiyounokage" (OP01) and "Han Hee-seop" is "Hee-seop Han" (OP21) in the data. The lookup block still lists OP74 as "Seong Yun-hee"; the vote block has "Yun-hee Seong". |
| Absent | 9 members on both votes. I count Absent as abstain. |

| Party (seats) | Amendment Yes / No / Absent | Final Yes / No / Absent |
|---|---|---|
| Butsutou (19) | 4 / 14 / 1 | 13 / 5 / 1 |
| Yezo Heritage Party (14) | 7 / 7 / 0 | 9 / 5 / 0 |
| Frontier Party (27) | 9 / 16 / 2 | 16 / 9 / 2 |
| Five Point Independents (5) | 0 / 4 / 1 | 4 / 0 / 1 |
| Keizaijiyuutou (25) | 4 / 17 / 4 | 21 / 0 / 4 |
| Country Initiative (11) | 10 / 0 / 1 | 0 / 10 / 1 |
| **Total** | **34 / 58 / 9: the amendment fails** | **63 / 29 / 9: the final passes** |

## 3. Cameron's decisions, as I will build them

| # | Decision | Build |
|---|---|---|
| 1 | Parliament opens 15 October; DS01 then. A weekday Decision! must not be run over by a level (Mandatory: prevent; Optional: alert). | DS01 moved (done). The level rule is section 4A. |
| 2 | The day before a Decision!, staff bring the player to the right office at day's end. 100 XP (or all the XP they have, up to 100); no work hours. | Section 4B. |
| 3 | All CPTPP floor votes done before Tuesday 18.10.30. | Exporter check that the chain's last vote day (Opens plus every Mandatory delay) is **18.10.29 or earlier**; section 4C. |
| 4 | A chain may exceed 5 scenes if Cameron approves. | A **Max Follow-Ups** column on a first scene's row: blank means 5; Cameron's number overrides it for that chain. The CPTPP chain is approved at 8 (see section 5). |
| 5 | OP29 Imekanu Resu whips every player, regardless of party, in her own scene, separate from the standard whip scene. Win both: free vote. Lose one: locked to whoever they lost to. Lose both: abstain, penalties from both sides. | Section 4D. |
| 6 | Reorder "Seong Yun-hee" to "Yun-hee Seong". | Done. |
| 7 | Cameron fixes Story Votes first. | Done: re-read, matches. |
| 8 | Floor Votes holds each party's votes and position, filled from Story Votes; a **Decision Scene** column there names the parent scene; a **Vote Bill** column on Decision Scenes. No duplicated numbers. | Section 4E. |

## 4. The build

IDs to use today: opponents **OP132 to OP134**, visitors **VI175 and VI176**, the whip stage **ST290**, Floor Votes **BI51** (the amendment) and **BI52** (the final), Decision Scenes **DS02 onward**.

**4A. A weekday Decision! and levels.** A level is checked when chosen: if starting it now would carry the clock to the start of a Mandatory scene's day (it would not finish by the end of the day before), the level is refused with a reason ("This level would run past the Decision! on Monday 18.10.22"). For an Optional scene the player gets a popup before the level starts: the level would finish after the window closes on 18.10.26, with **Start anyway** and **Back**. Pure rules (`DecisionClash.gd`) and tests.

**4B. Evening travel.** At the end of the work day before a Mandatory scene, if the player's office is not the scene's, a popup from their primary staff member says the staff arranged the trip back; the player is moved at once, no work hours are spent, and 100 XP (or all they have) is spent. Pure rule for the cost; the card reuses the MOVED FOR YOU card with a new line.

**4C. The deadline.** A **Must End By** column on a first scene (YY.MM.DD). The exporter works out the latest day any Mandatory scene in the chain can happen (Opens plus delays) and refuses a chain that passes it. 4A is what makes that arithmetic true in play.

**4D. Two whips.**

| Part | Build |
|---|---|
| The party whip | As in the brief: Party support picks who whips (0 to 30 Assistant Whip, 31 to 71 Deputy, 72 to 89 Chief, 90 to 97 the minister **OP82 Tama Tsujikonou** if in the player's party else the Chief, 98 to 100 the party leader). Winning the whip stage means no lock from the party; losing locks the vote to the **party line**. |
| OP29's whip | Her own scene and the same whip stage with her as the opponent, shown to every player. Winning means no lock from her; losing locks the votes to **her ask**: Aye on the amendment (which stops the Prime Minister signing if Australia signs first) and Nay on the final. |
| The outcomes | Both won: both votes are free. One lost: locked to the party who won. Both lost: both votes are **abstain** and the player takes both whips' penalties. |
| The lock | Greys the other buttons with "You gave the whip your word."; an abstain lock leaves only Abstain. |

**4E. Workbook.** Floor Votes gets **Decision Scene**; Decision Scenes gets **Whip Bill**, **Minister**, **Vote Bill**, **Max Follow-Ups**, **Must End By**; Parties gets three whip columns; Rules gets `whip_bands` and `training`-style rows for the bands; a **Story Votes** tab is imported by name from your sheet and BI51 and BI52's party counts are computed from it (no duplicate numbers).

**Commits:** 1 data and exporter; 2 pure rules (`WhipPick`, `DecisionClash`, lock and outcomes); 3 level clash guard and alert; 4 evening travel; 5 whip card and stage ST290 (Resolve bar: I read the Survival model and propose numbers before changing it); 6 lock and abstain on the Floor Vote; 7 scenes, cues and votes; 8 tests, screenshots in three styles, docs. One full check, then push `feature/p15-cptpp-whip`. **No merge.**

## 5. The timetable I propose (weekdays only; all votes by Monday 18.10.29)

| Date | Scene | Kind | Follows |
|---|---|---|---|
| Mon 18.10.22 | DS02 The Government Tables the CPTPP Motion | Mandatory, Capitol | first scene |
| Wed 18.10.24 | DS03 The Home Front Wants Answers (window to Fri 18.10.26) | Optional, District | DS02 +2 |
| Wed 18.10.24 | DS04 The Business Lobby Comes Calling (window to Fri 18.10.26) | Optional, Capitol | DS02 +2 |
| Thu 18.10.25 | DS05 OP29: the Minister of Agriculture's appeal | Mandatory, Capitol | DS02 +3 |
| Thu 18.10.25 | DS06 The Whip Counts Heads (standard whip) | Mandatory, Capitol | DS02 +3 |
| Fri 18.10.26 | DS07 Floor Vote: the Australia amendment | Mandatory, Capitol | DS02 +4 |
| Mon 18.10.29 | DS08 Floor Vote: Joining the CPTPP | Mandatory, Capitol | DS02 +7 |
| Wed 18.10.31 | DS09 After the Vote, Back Home | Optional, District | DS08 +2 |

That is 8 follow-ups under DS02 (the approved limit), and the last vote is on the last day allowed.

## 6. Questions for Cameron (the next popup)

1. **What "runs over" means** (4A): refuse a level that cannot finish by the end of the day before the scene, and alert for an Optional scene when the level would end after the window closes.
2. **The evening travel** (4B): no staff hired; which scenes; the exact moment.
3. **The party line on the amendment** (4D): use the party's majority in Story Votes (BU, FP, FPI and KJT No; CI Yes; Yezo Heritage Party split 7 to 7).
4. **The timetable** (section 5).

## 7. Risks I will check first and stop on

| Risk | Plan |
|---|---|
| A blank party on a whip opponent row | Test before relying on it; report if a place fails. |
| Two IDs sharing one portrait | `art.json` maps by prefix; copy or map the picture; a labelled placeholder shows until drawn. |
| The cue "side" for a party line | If the cue columns cannot say "the party's line", report and propose; no change to the cue engine without asking. |
| The Resolve bar numbers | Propose, do not change the Survival model. |
| New canon | The amendment and Australia come from Cameron's wording only, marked "Claude's draft". |
