# Audit: what is hard-coded but could live in the workbook (2026-10-27)

## Executive summary
| Area | Result |
|---|---|
| Sentences, cues, questions, terms shown to the player | **Clean.** No English sentence is typed into a script outside the Text tab (checked every label, line, button and message call). |
| Game numbers | **Mostly in the workbook** (about 165 levers read with a code fallback). 20 or so design numbers are still typed into scripts (table B). |
| Silent bug found | Three Balance levers were misspelt in code, so editing them in the workbook did nothing. **Fixed** and a test added. |
| Lists of IDs and names | A few fixed lists in code (table C). Mostly structural, three are worth moving. |

## A. Fixed in this pass
| Workbook row | Code asked for | Effect before |
|---|---|---|
| `draft_bill_xp_cost` (350) | `draft_bill_cost_xp` | Workbook value ignored; code default 350 used |
| `draft_bill_funds_cost` (300,000) | `draft_bill_cost_funds` | Same |
| `supermajority_percent_of_house` (67) | `supermajority_percent` | Same, in three screens |

New test `tests/test_balance_keys.gd` fails if any script reads a Balance or Rules key the workbook does not have.

## B. Design numbers typed into scripts
| Where | Number | Suggested home |
|---|---|---|
| `BarModel.gd` OPPONENT_COST_ODDS | Winning over an opposed person costs 1 (60%), 2 (30%), 3 (10%) | Balance rows (or one small tab); it is a headline rule in the brief |
| `MetaRules.press_start_adjustment` | Reputation gives +5 or -5 to a press stage's start | Balance: `press_start_reputation_bonus` |
| `MetaRules.party_support_modifiers` | Allied buff default 75 (the row exists; the code default repeats it) | Remove the fallback |
| `PatronVisit.gd` | Choice deltas for patron +4/+2/-2/-4, friend +1, rival -2/+1/+2 | Balance rows (six) |
| `PatronRequests.gd` | Flagship discount 5 after a failed Favor (code comment already says "a lever later") | Balance |
| `BoosterSuitTendency.gd` | Minimum score 0.4, 5 questions, max 4 organizations per suit; S/M/W = +1/0/-1 | Balance (affects How to Play text) |
| `PartyAllies.gd` | Neutral band 0.5 | Balance |
| `HostedEvent.gd` | Own-organization share of a guest list 60% | Balance |
| `SpecialEffects.gd` | Audience scale capped at 5 steps | Balance (card power) |
| `GameState.gd` | Segment favorability starts at 50 and clamps 0-100; booster standing 50 default | Balance or Sanban |
| `LevelTemplate.gd` | Slot cap 10; public room by tier (Constituency ST05, National ST04) | Levels/Stages data |
| `FloorVoteEngine.gd` | Default influence threshold 85 and resistance 70 repeated as code defaults | Remove the fallbacks (rows exist) |
| `Ledger.gd` | `LEVEL_UNLOCK_MAX_TIER` 2 | Derive from levels data |
| `Audio.gd` | 6 simultaneous effect voices | Technical; keep, or `rules.json` |

## C. Fixed lists and IDs in code
| Where | What | Verdict |
|---|---|---|
| `Ledger.STAFF_ROLES`, `LEVEL_UNLOCK_ROLE` | The three staff role names | Move: derive from the Staff tab so a new role needs no code |
| `MpVisit.STYLES` | The six suit names | Move: read `suits.json` |
| `CardView` / `CardBackView` | Card frame picture per suit | Move to `suits.json` or `art.json` |
| `BattleSetup.QUESTION_POOL_BY_STAGE`, `REPUTATION_START_STAGE_IDS` | Fallbacks for stage columns that now exist on every row | Dead fallback; delete |
| `LevelTemplate.FIXED`, `MpVisit`/`LobbyistTrade`/`PatronVisit` stage IDs (ST260-263), `MetaRules` M09/M32 | Which room or modifier a mechanic uses | Acceptable (structural), but a stage-role column would remove them |
| `VoteInfluenceCues` flip labels, `FloorVoteEngine.BUCKETS` | Yes/No/Abstain and "Flipped to Pass/Fail" keys | Keep: they are data keys, not display text |
| UI sample IDs (BootCheck, ArtLoader, PlaceholderArt) | Example IDs in comments and the boot check | Keep |

## D. Smaller observations
- About 165 levers are read with a typed fallback number that repeats the workbook value. Harmless today but the two can drift; a boot warning for a missing row would be safer than a silent fallback.
- Balance rows nothing reads: `xp_tiers` (empty). The `trade_*_seats` rows are used through a built key, so they are live.
- Layout, timing, colour and font numbers in the UI are presentation, not content, and stay in code.

## E. Follow-up applied (2026-10-27, Cameron: "Go")
| Item | Result |
|---|---|
| Table B numbers (opposed-cost odds and Undecided cost, press reputation bonus, patron visit deltas, Flagship discount, tendency cutoffs and grade points, ally neutral band, hosted guest share, audience scale cap) | 29 new Balance rows; scripts read them through the new `Levers` class (no fallback number in code). |
| Staff role names | Read from the Staff tab (`Ledger.staff_roles()`); the level-unlock role is the first role listed. |
| Suit names in the member visit | Read from `suits.json`. |
| Card frames per suit | Moved to `data/art.json` ("card_frames"). |
| BattleSetup fallback tables | Removed. The fallback was **not** dead for ST05 (its Question Pool cell was blank), so ST05 now says "town_hall" in the Stages tab. |
| Left alone | Segment and standing starts of 50 (engine-wide defaults), slot cap 10, public room per tier, `LEVEL_UNLOCK_MAX_TIER`, FloorVote influence defaults (already fed from Balance), allied-buff default 75. |
