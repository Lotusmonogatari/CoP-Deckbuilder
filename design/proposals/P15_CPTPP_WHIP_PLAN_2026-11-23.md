# P15 plan, version 3: the CPTPP Decision! sequence, two whipping scenes and two votes (draft for Cameron, 2026-11-23)

Nothing in this plan is built. It folds in Cameron's eight design changes, the corrected `Story_Votes.xlsx` and his answers to the second popup (level clash, staff travel, free amendment vote, both votes the same day). **It waits for one last answer (section 6) and a "Go".**

## 1. Executive summary

| Question | Answer |
|---|---|
| What the sequence is | DS02 opens **Monday 18.10.22**; two whipping scenes (the party whip, and **OP29 Imekanu Resu**, a unique whip for every player); an amendment vote and a final vote **on the same day, Monday 18.10.29** (before Tuesday 18.10.30). |
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
| 3 | All CPTPP floor votes done before Tuesday 18.10.30. | Exporter check that the chain's last vote day (Opens plus every Mandatory delay) is **18.10.29 or earlier**; section 4C. Both votes are on 18.10.29. |
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

**4D. Two whips (Cameron's final rules).**

| Step | What happens |
|---|---|
| 1. Resu's scene (DS05, Thu 18.10.25), amendment | Her ask is **Aye** on the amendment. The text screen offers: side with her (moves on, no battle) or not (the Resolve stage starts with her as the opponent). Win: the amendment is free. Lose: the amendment is locked to Aye. |
| 2. Resu's scene, final vote (back to back, same scene sequence) | Her ask on the final vote is **Nay** (my reading: she is the Frontier Party's agriculture voice; Cameron to confirm). Same choice: side with her or fight a second Resolve stage. Win: free. Lose: locked to Nay. |
| 3. The party whip's scene (DS06, Fri 18.10.26), final vote only | The standard whip by Party support bands; no amendment whipping. Side with the party line (moves on) or fight a Resolve stage. Win: free. Lose: locked to the party line. |
| The final vote, three cases | Won both whips (Resu's final stage and the party's): your choice. Lost one: locked to whoever won. **Lost both: you abstain** and take the penalties from both. |
| The amendment | Only Resu can lock it. The party never does. |
| Lock text | Greys the other buttons with "You gave the whip your word." An abstain lock leaves only Abstain. |

Up to three Resolve battles are possible (Resu on the amendment, Resu on the final, the party whip on the final). Penalties and rewards are the brief's: a win gives Reputation +1 and Party support −2; a loss gives Party support +1 and Constituency support −1 plus the lock.

**4E. Workbook.** Floor Votes gets **Decision Scene**; Decision Scenes gets **Whip Bill**, **Minister**, **Vote Bill**, **Max Follow-Ups**, **Must End By**; Parties gets three whip columns; Rules gets `whip_bands` and `training`-style rows for the bands; a **Story Votes** tab is imported by name from your sheet and BI51 and BI52's party counts are computed from it (no duplicate numbers).

**Commits:** 1 data and exporter; 2 pure rules (`WhipPick`, `DecisionClash`, lock and outcomes); 3 level clash guard and alert; 4 evening travel; 5 whip card and stage ST290 (Resolve bar: I read the Survival model and propose numbers before changing it); 6 lock and abstain on the Floor Vote; 7 scenes, cues and votes; 8 tests, screenshots in three styles, docs. One full check, then push `feature/p15-cptpp-whip`. **No merge.**

## 5. The timetable I propose (weekdays only; both votes Monday 18.10.29)

| Date | Scene | Kind | Follows |
|---|---|---|---|
| Mon 18.10.22 | DS02 The Government Tables the CPTPP Motion | Mandatory, Capitol | first scene |
| Wed 18.10.24 | DS03 The Home Front Wants Answers (window to Fri 18.10.26) | Optional, District | DS02 +2 |
| Wed 18.10.24 | DS04 The Business Lobby Comes Calling (window to Fri 18.10.26) | Optional, Capitol | DS02 +2 |
| Thu 18.10.25 | DS05 The Minister of Agriculture's Appeal (OP29, asks for the amendment) | Mandatory, Capitol | DS02 +3 |
| Fri 18.10.26 | DS06 The Whip Counts Heads (standard whip, final vote) | Mandatory, Capitol | DS02 +4 |
| Mon 18.10.29 | DS07 Floor Vote: the amendment | Mandatory, Capitol | DS02 +7 |
| Mon 18.10.29 | DS08 Floor Vote: Joining the CPTPP (the same sitting, straight after DS07) | Mandatory, Capitol | DS07 +0 |
| Wed 18.10.31 | DS09 After the Vote, Back Home (window to Mon 18.11.05) | Optional, District | DS08 +2 |

That is 7 follow-ups under DS02 (the approved limit is 8). DS08 needs a delay of 0 (follows the earlier scene the same day); I will check the engine accepts that and, if not, add it as part of this build. Both votes sit on 18.10.29, the last day allowed.

## 6. Cameron's answers, and what is left

| Question | Answer (Cameron, 2026-11-23) |
|---|---|
| A level "running over" a Decision! | Refuse a level that cannot finish by the end of the day before a Mandatory scene (reason shown); for an Optional scene alert with Start anyway / Back. |
| Evening travel | Mandatory scenes only; with or without staff; 100 XP or all the XP the player has. |
| Party line on the amendment | **There is none.** Minister Resu asks for the amendment; the party does not whip it; it is a free vote. |
| Timetable | The amendment and the final vote happen on the same day. I put them on Monday 18.10.29, the last day allowed. |

**Whip scope (Cameron, 2026-11-23):** Resu whips two items back to back, the amendment and the final vote. If the player sides with her on the text screen it moves on; if not, the Resolve stage plays for each item. The party whip comes after and only for the final vote. Losing both final-vote battles forces an abstain and both penalties.

**Still my assumption, to be corrected:** Resu's ask on the final vote is Nay (the amendment is Aye).

## 7. Risks I will check first and stop on

| Risk | Plan |
|---|---|
| A blank party on a whip opponent row | Test before relying on it; report if a place fails. |
| Two IDs sharing one portrait | `art.json` maps by prefix; copy or map the picture; a labelled placeholder shows until drawn. |
| The cue "side" for a party line | If the cue columns cannot say "the party's line", report and propose; no change to the cue engine without asking. |
| The Resolve bar numbers | Propose, do not change the Survival model. |
| New canon | The amendment and Australia come from Cameron's wording only, marked "Claude's draft". |
