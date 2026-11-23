# P15 report: the CPTPP Decision! sequence, two whips and two votes (draft for Cameron, 2026-11-23)

Branch `feature/p15-cptpp-whip`. **Not merged.** All writing is Claude's draft (marked in the Notes column and the Text rows' notes).

## Executive summary

| Question | Answer |
|---|---|
| Built | Nine Decision! scenes (DS02 to DS10), both votes, the whips, the lock, the level guard, the after-hours trip, the exporter checks, cues, tests and a click test. |
| Pictures | 21 screenshots in this folder: the whip card at five Party support bands, the whip stage's first turn and the locked Floor Vote, in each of the three styles. |
| Decided (Cameron, 2026-11-23) | (1) Whip difficulty stays as briefed (Resolve 12). (2) DS03's window now closes mid-week (Thu 18.10.25) so the Optional alert can fire. (3) The after-hours trip happens when the scene opens: accepted. |
| Not run | The full gate (`tools/verify.sh`); only the unit tests, the click tests for scenes, events, votes and travel, and the new click test were run. Run the gate before any merge. |

## Your answers, as built

| Answer | Built as |
|---|---|
| DS02 opens Monday 18.10.22 | Yes. |
| Party positions in workbook columns | Floor Votes holds each party's votes and line per bill; BI51 and BI52 are filled from your Story Votes sheet (Absent counted as abstain; no member-level copy). |
| Two whipping scenes, Resu a unique whip | DS05 and DS06 are Resu's, shown to every player, back to back. The party whip is DS07. |
| Resu asks Aye on the amendment, Nay on the final | Yes. The party whip covers only the final vote; the amendment is a free vote for the party. |
| Both votes the same day | Both on Monday 18.10.29, the last day before the 30th. |
| Level guard and after-hours trip | Built (see below). |
| Chain over five | DS02 has Max Follow-Ups 8 (approved by you). |
| Draft text marked "Claude's draft" | In every new scene's Notes. |

## IDs used

| Kind | IDs |
|---|---|
| Scenes and events | DS02 to DS10, EV111 to EV119 (EV105 to EV110 were already taken) |
| Votes | BI51 (amendment), BI52 (Joining the CPTPP) |
| Whip stage | ST290 "Whipped into Line" (党議拘束 Tōgi Kōsoku), Affinity column added |
| Opponents | OP132 Tomoe Sakamoto, OP133 Isamu Takaoka, OP134 Nobuko Ezaki (party blank; the whip wears the player's party when fought) |
| Visitors | VI175 Isamu Takaoka (高岡勇), VI176 Nobuko Ezaki (江崎信子); they ask the existing whip questions VQ62 to VQ64 |
| Cues | Opponent Cues OC3864 to OC3873, Player Cues PL3697 to PL3714 |

## The Resolve numbers, as fitted

Stage row, no change to the Survival model: Resolve starts at **12** (Player start 12, Opponent start 12, Bar max 24, no undecided), the line is **1** (Win threshold 1, Threshold rise 0 to 0), **3** turns, energy **pool of 6** never refilled, hand 5, gaffe limit 5, 1 hour, picture ST08. Win: Reputation +1, Party support −2. Loss: Party support +1, Constituency support −1 (the lock is the Floor Vote's). Affinity: Appeal 1.5, Earnest and Divisive 1.3, Data Driven 0.7, Duplicitous 0.5, Emotional 1.0 (my draft).

**Flag.** The whips attack for 4 to 6 each turn, but the third turn's attack does not land before the turn limit ends the fight, so a player who only passes survives with 1 or 2 Resolve about two times in three (three trial runs). Playing cards makes it easy. If you want passing to lose, lower Resolve to 10 or raise the attack range; I did not change your numbers.

## Intent ranges (attack, gain, block)

| Person | Ranges |
|---|---|
| The three whips | attack 4 to 6, gain 0, block 0 to 2 (as in the brief) |
| OP82 Tama Tsujikonou (minister) | 4 to 8, 4 to 6, 2 to 4 |
| OP29 Imekanu Resu | 2 to 5, 4 to 6, 0 to 5 |
| Leaders: OP91 BU | 0 to 4, 5 to 8, 1 to 4 |
| OP10 YHP | 0 to 3, 3 to 7, 3 to 8 |
| OP27 FP | 2 to 6, 3 to 10, 0 to 3 |
| OP80 FPI | 3 to 7, 4 to 7, 3 to 10 |
| OP83 KJT | 2 to 4, 3 to 5, 1 to 3 |
| OP67 CI | 4 to 6, 4 to 6, 1 to 4 |

A minister or leader keeps their own row's ranges, so they hit softer or harder than the whips. Resu's attack is lighter than the whips' (2 to 5) but she gains more and blocks up to 5.

## What differs from the brief or your later changes

| Item | What I did and why |
|---|---|
| Party blank on the whip opponents | Works. The battle fills the player's party in at fight time so the cue "sides" (For, Against) read the player's party's line; no change to the cue engine. |
| Two whips on one bill | The lock is per bill: one lock holds the vote to that whip's ask, two locks force Abstain. Resu's ask on the final is Nay (you confirmed). |
| Optional alert | Levels never carry into the next week, so only a window that closes mid-week can be outlasted. DS03 now closes on Thursday 18.10.25 (you approved); a level of 33 hours or more started on the Monday asks "Start anyway or Back". DS04 and DS10 still close on Fridays. |
| After-hours trip | It happens when a Mandatory scene opens and the player is at the other office (the staff "arranged it last evening"), not as a separate popup at the end of the previous day, because the calendar counts pooled hours, not a day's end. The existing MOVED FOR YOU card carries the staff's line, the text and the XP cost. |
| The amendment | Generic name and one-line description ("Amendment to the CPTPP Motion"). I wrote no detail of what it does; that is yours to supply. |
| Follow-up order | A follow-up now waits until the fight or vote its earlier scene started has been played, so the final vote scene cannot open before the amendment vote. |
| Story vote bills and the content tests | `test_every_real_bill_has_questions_cues_and_transition_lines` skips bills a scene votes on (BI51, BI52); they are voted in scenes, not fought level by level. |
| Visitor questions | VI175 and VI176 reuse VQ62 to VQ64 (the whip questions); you may want their own. |
| Pictures | The three whips have no pictures. OP132 uses VI29's through `art.json` `character_aliases`; OP133 and OP134 show placeholders until VI175 and VI176 are drawn (they will share them). |
| Draft content | Scene text, result lines, choices' organization effects (small, plus or minus 1 to 3), Resu's cues and the position cue lines. The appendix cues for the party whip and the player are yours, as written. |
| Not run | The full `tools/verify.sh`. |

## Pictures

`living_office_`, `broadcast_` and `woodblock_` each have: `whip_card_assistant_support_10`, `..._deputy_support_50`, `..._chief_support_80`, `..._minister_support_93`, `..._leader_support_99` (Frontier Party, so the minister is OP82), `whip_stage_first_turn`, `floor_vote_locked`. Made with `tools/p15_shots.tscn`.
