# Custom bills (Draft a Bill and patron bills): how they work, and an audit (2026-11-02)

Evidence: code and workbook reads, `tools/bill_audit.gd` (vote audit under the real influence gates), `tools/bill_draft_probe.gd` (a full draft lifecycle for 14 mixes), and bot runs (`design/bench/draft_runs.jsonl`, plus 384 earlier runs). No game rule or workbook value was changed by this audit.

## Executive summary

| # | Finding | Severity | Evidence |
|---|---|---|---|
| 1 | **The mechanics are connected and internally consistent.** Components feed the name, vote, effects, level, content and standing; the data has no integrity errors | OK | 180 components, 54 patron bills, 4 templates: no bad IDs, symmetric Excludes, every component has 8 questions, 6 player cues, 6 opponent cues and 3 transition lines |
| 2 | **Draft a Bill cannot be used until the Funds cap is raised twice, and nothing says so** | High | It costs 300,000円 and the default cap is 100,000. The refusal reads "Drafting needs 350 XP and 300,000円" at caps of 100k and 200k, and only clears at 300k |
| 3 | **A drafted bill is a trap without the right standings, and the Draft panel hides that** | High | Realistic bots drafting when allowed passed 4 of 78 drafts (about 5%); a perfectly prepared player passed 8 or 9 of 14 in each run (the rest lapsed at a hearing; none lost the vote). The cost (350 XP and 300,000円) is paid up front and never refunded |
| 4 | **The "winnable" check is idealized.** It opens every influence gate at once, so it says yes to bills that need Reputation 60, BO02 75, BO03 70, plus party-specific standings, and Funds 500,000 for two parties | Medium | Real-gate audit: 0 of 54 patron bills carried at standings 72, 29 to 50 of 54 at 75 to 80 with Funds 100k, 54 of 54 at 80 with Funds 500k |
| 5 | **The hearing is a lottery that can forfeit the whole cost** | Medium | The first part picks the committee. Of 180 components, 72 point to Government Administration (bot win rate 55%), 37 to Finance (31%), 31 to Construction (42%). A lost hearing lapses the draft: 22% of random drafts lapsed, 4% when the first part had an easy committee |
| 6 | **Influence readiness is shown only on the vote screen**, after the money is spent | Medium | `VoteInfluence.status()` is used only by `FloorVoteScreen`; the Request and Draft panels say only "It will not pass unless you can sway other members" |
| 7 | **Tool bugs found and fixed:** the bot only treated "PB" bills as patron bills, so it voted the party line on drafts ("PD"); its `visit_wins` counter was never filled; no bot ever drafted | Fixed | `tools/playtest_optimal.gd` (two lines), `tools/strategy_playtest.gd` (new drafting strategies) |
| 8 | **Stale numbers in docs corrected:** CLAUDE.md said Reputation gate 85 (it is 60) and swing resistance 70 (it is 85); the changelog said a 30-unit draft cooldown (it is 90); the plan said 81 components (there are 180) | Low | `data/vote_influence_triggers.json`, `data/balance.json` |
| 9 | **Playtest history misread:** the earlier 2.5% patron pass rate (574 of 23,342 accepts) mixes bot accept-everything behavior with these gates, so it measures the bot, not the design | Low | The bot accepts every request at once, including ones whose gates are unmet |

## How it is meant to work

| Step | What happens | Where |
|---|---|---|
| 1. Parts | The player picks two or three components (parts) from any organizations. Each has a phrase, tags, gains, loses, a hearing committee, a slot | `data/bill_components.json` |
| 2. Name | "A bill to {a} and {b}" (or three) from the parts' phrases | `ComposedBill.bill_name` |
| 3. Lean | Each part's value tags times each party's salience give party leans; a lean of 30 or more takes a side; seats split by the Supportive / Opposed / Neutral shapes. Yes votes are capped at 48 (51 minus 3) and floored at 44 (34 for three parts), so no bill passes alone | `BillPositions.positions` |
| 4. Effects | Gains and losses of all parts are summed and scaled to 50%; these become the law's standing changes and the bill's "who it helps / hurts" | `ComposedBill.merged_effects` |
| 5. Level | A template (BT03 for two parts, BT04 for three) lists rooms: hearing for the first part, optional member visit, public room, own Party Caucus, optional lobbyist trade, vote | `PatronLevel.level_row`, `data/bill_level_templates.json` |
| 6. Content | Questions, cues and transition lines tagged with the parts' IDs are dealt in, up to 50% of a room's questions | `DataDB.content_keys`, `BattleSetup.bill_questions_for` |
| 7. Cost | 350 XP and 300,000円 on start, nothing back if it lapses; a 90-unit cooldown; one at a time | `GameState.start_draft`, `DraftBill.refusal` |
| 8. Vote | Yes carries only with influence: the influence swing needs the gates in `vote_influence_triggers.json`, and members won over by the visit or lobbyists add seats | `FloorVoteEngine`, `BillAssist` |
| 9. Result | The parts become law, organizations move, the statute book records it. A drafted bill has no patron, so only the parts' own helped and hurt organizations move | `PatronRequests.outcome` |

## Verified correct

| Check | Result |
|---|---|
| Component data: hearing committee exists, gain and loss targets are organizations, Excludes exist and are symmetric, owner exists | 0 problems in 180 |
| Patron bills use real components; each organization has its Favor and Flagship pools | Export checks pass |
| Content tagged to every component | 180 of 180 covered, uniform counts |
| Draft lifecycle for 14 mixes: cost paid, level built, vote, parts made law, standings moved, repeat of the same part refused, cooldown applied | Correct every time |
| The trade drops a part and the bill is recomposed; only the surviving parts become law | Correct |
| Names that begin with "A" read as "this bill to ..." in player lines | Fixed earlier today, verified |
| Unit tests for drafts, patron levels, rules, assists, visit and content | All pass in `tools/verify.sh` |

## Details of the errors and risks

### Real-gate vote audit (patron bills carried with a Yes vote, 54 bills, per protagonist)

| Player profile | PC01 | PC02 | PC03 | PC04 |
|---|---|---|---|---|
| Reputation 80, standings 72, Funds 100k | 0 | 0 | 0 | 0 |
| standings 75 or 80, Funds 100k | 29 | 29 | 50 | 50 |
| standings 80, Funds 500k, Reputation 60 | 54 | 54 | 54 | 54 |

The two unscoped gates (BO02 at 75 and BO03 at 70) switch off all influence for every party when missed, which makes the cliff. The 500,000 Funds gate for PT04 and PT05 needs four cap petitions. Random drafts show the same shape: 0 of 200 carried below the cliff, 195 to 199 of 200 above it.

### Bots drafting when allowed (PC02, Standard, 6 seeds each, cap bought and dues reserved)

| Bot | Drafts started | Passed | Lost the vote | Lapsed at the hearing | Funds at end | Party |
|---|---|---|---|---|---|---|
| No drafting | 0 | | | | 245k | 100 |
| Easy-committee first part | 46 | 3 | 41 | 2 | 68k | 98 |
| Random parts | 32 | 1 | 24 | 7 | 104k | 82 |

A prepared player (standings 80, Reputation 90, Funds 1M at the start) passed 8 or 9 of 14 drafts, and a lost hearing was the only failure. The 300,000円 cost also left Funds under 500,000 at the vote in some earlier runs, which shuts the PT04 and PT05 swing.

## Options for Cameron (nothing has been changed)

| # | Issue | Options |
|---|---|---|
| 1 | The Draft panel hides the real requirements | (a) Show influence readiness (the same "Still needed: ..." list the vote screen has) on the Request and Draft panels; (b) also say when the Funds cap is too low; (c) both |
| 2 | Cost is lost if the draft fails | (a) Refund half on a lapse; (b) refund nothing but warn first; (c) charge only when the vote starts |
| 3 | The hearing committee is a lottery | (a) Show the committee and its difficulty before drafting; (b) let the player pick which part leads; (c) a draft-specific hearing with easier numbers |
| 4 | 300,000円 against a 100,000 cap | (a) Lower the cost to the cap; (b) start the cap higher; (c) keep, and add the hint in option 1 |
| 5 | The "winnable" check | (a) Keep it as an upper bound and say so; (b) replace it with the real gates and the player's current standings |
| 6 | Patron requests appear before the player can win them | (a) Add readiness to the request panel; (b) delay requests until the gates are met; (c) leave |
