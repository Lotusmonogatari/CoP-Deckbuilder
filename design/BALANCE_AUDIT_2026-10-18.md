# Balance audit: results and recommendations (2026-10-18)

Process: `design/BALANCE_AUDIT_PROCESS.md`. Raw tables and every flag: `design/BALANCE_AUDIT_2026-10-18_data.md` (69 flags: 6 High, 59 Medium, 4 Low, with room families grouped). Logs: `design/bench/balance/`. Re-run: `tools/balance_audit.sh` then `python3 tools/balance_audit.py`.

What was run: 97 combat rooms x 100 starter-kit fights and 50 full-kit fights each (about 14,500 fights), four full 80-level runs (one per protagonist), plus 16 what-if trials on the four worst rooms. All results are the **bot's**: read them as relative (room against room), not as the rate a person will see.

## Executive summary

| # | Finding | Severity | Evidence |
|---|---|---|---|
| 1 | **Difficulty is lopsided by room family.** Hearings, Committees and Policy Studies (34 rooms) are close to automatic for a new player (92-98%); Party Caucus (21 rooms, 3%), Town Hall (12, 9%), Steering Committee and Media Ambush (0%) are walls | High | starter-kit win rate by family |
| 2 | **The first levels are a wall.** 12 levels open with a Town Hall; a starter-kit player wins 9% of them | High | Town Hall 1-23% starter, 80% full |
| 3 | **Reward runs backwards.** Harder rooms pay less (correlation of difficulty with reward is -0.21): Lobbyist and Press pay least, trivial Hearings and Committees pay more | Medium | reward index by family |
| 4 | **Meta values saturate by mid-run.** Reputation and Constituency support reach 100 around level 40 for all four protagonists and stay there; Party opinion sits near 75 | Medium | economy table, 12 of 12 meta flags |
| 5 | **Card progression finishes early and is flat.** All 54 cards are owned by about the 10th level; tiers are not stronger per energy (0: 2.79, 1: 2.44, 2: 2.59, 3: 2.40) | High | economy table, tier table |
| 6 | **Rhetorical styles are structurally unequal.** Divisive is favored in 8 rooms and resisted in 82; Earnest and Appeal are favored in 69 and 67. Question grading nets Earnest +250 against Divisive -54 and Duplicitous -24. Divisive is the best answer in 3 of 97 rooms, Duplicitous in 1 | Medium | affinity and question tables |
| 7 | **A few cards dominate and many are dead.** Appeal draw engines (C12, C38) are played 6-7x an average card; Appeal is 33% of all plays; 15 cards were never played; C21 (cost 0, guard 5, gain 3) is a 5.6-sigma outlier | Medium | card tables |
| 8 | **Consumables are free power.** The bot bought 680-830 items in a run; Funds sit at the 100,000 starting cap | Medium | economy table |
| 9 | **Organizations are mostly reachable but uneven.** Local Kōenkai averages 71 while eight organizations never reach the 60 a backing needs (Agricultural Cooperatives peaks at 50, Urban Neighborhood Alliance 48) | Medium | standing table |
| 10 | **The new Party Bodies behave.** Activists peak 63-66, Committee 51-57: no ceiling, no floor | OK | standing table |

What passed: bills and parties are fairly even (no party proposes more than a quarter of bills; the two Low flags are small); the static difficulty model predicts the sweeps (correlation -0.91), so rooms can be retuned from the table.

## What the evidence says, by lens

**1. Difficulty and progression (starter -> full kit)**

| Family (rooms) | Need per energy | Starter | Full | Reading |
|---|---|---|---|---|
| Hearing (17) | 0.68 | 98% | 100% | trivial, never a decision |
| Committee (9) | 0.73 | 92% | 100% | trivial |
| Policy Study (7+1) | 1.4 | 97% | 100% | trivial |
| TV Debate (7) | 0.20 | 86% | 100% | easy |
| Special Committee / Cabinet | 0.9 / 1.15 | 77% / 62% | 98% / 92% | healthy |
| Floor Debate (1) | 1.7 | 70% | 100% | healthy |
| Lobbyist Meeting (6) | 1.7 | 59% | 71% | **kit barely helps** (+12) |
| Press Conference (11) | 2.0 | 44% | 91% | healthy, wide spread (5-69%) |
| Town Hall (12) | 2.7 | 9% | 80% | wall, then fine |
| Party Caucus (21) | 2.7-2.8 | 3% | 44% | wall, and still hard at full kit |
| Media Ambush (2) | 3.3 | 0% | 0% | unwinnable (losing is allowed by design) |
| Party Steering Committee (1) | 5.0 | 0% | 0% | unwinnable |

Need per energy is the points the player must add per point of energy. It predicts the order of the sweep almost perfectly, which is why the recommendations below are expressed as threshold changes.

**What-if trials** (starter kit, 100 fights each; decks differ between runs, so read as indicative, plus or minus 20 points):

| Room | As tuned | Variants tried |
|---|---|---|
| Town Hall ST05 (threshold 60) | 3% | threshold 50: 99%; threshold 45: 79%; energy 4: 58% |
| Party Caucus ST03 (threshold 60) | 0% | threshold 50: 18%; threshold 45: 56%; energy 4: 4% |
| Steering Committee ST08 (threshold 60) | 0% | threshold 50: 1%; threshold 40: 61%; energy 12: 0% |
| Media Ambush ST19 (threshold 30) | 0% | threshold 20: 5%; threshold 15: 81% |

Energy changes barely help; thresholds do. Rooms with several opponents (stream and continuous) ask the player to pay the gap once per opponent from one budget, which is why they are the hard ones.

**2. Rewards and economy** (median of the four protagonists)

| Level-end # | XP | Funds | Reputation | Constituency | Party opinion | Cards | Backings | Items bought |
|---|---|---|---|---|---|---|---|---|
| 5 | 110 | 65,000 | 15 | 21 | 26 | 39 | 0 | 6 |
| 10 | 184 | 55,000 | 22 | 26 | 38 | 52 | 0 | 36 |
| 20 | 382 | 62,500 | 67 | 79 | 70 | 54 | 10 | 143 |
| 40 | 426 | 100,000 | 100 | 100 | 76 | 54 | 22 | 344 |
| 80 | 443 | 99,500 | 100 | 100 | 75 | 54 | 32 | 786 |

The economy has no sink once cards are owned: XP has nothing left to buy (it hovers around 400), Funds are capped and spent on cheap consumables, and two of the four meta values hit their ceiling and stay there. Reward index by family: Cabinet 70, TV Debate 22, Town Hall 18, Steering 18, Hearing 17, Committee 16, Media Ambush 16, Policy Study 13, Caucus 12, Press 10, Floor Debate 9, Special Committee 7, Lobbyist 7.

**3. Choice diversity.** Gini of card use is 0.71 (a few cards do most of the work), but this partly reflects a bot that builds the strongest deck by one measure; the static findings (tiers flat, C21 outlier, three strictly-dominated cards C05<C32, C43<C13, C45<C20) are independent of the bot.

## Recommendations (ranked; every number is a first draft for you to set)

Each is a workbook edit or one lever, so nothing needs code unless noted.

| Rank | Recommendation | Why | Expected effect | Risk |
|---|---|---|---|---|
| 1 | **Lower the Town Hall threshold from 60 to about 50** (the 12 rooms with `Win threshold` 60) | Level 1 is a Town Hall; today a new player loses it | starter win rate from about 9% to about 60-80% | the full-kit rate goes near 100%, so Town Hall becomes easy later; keep a per-level Town Hall variant at 60 for tier 2+ if you want it to stay hard |
| 2 | **Lower the Party Caucus threshold from 60 to about 46** (21 rooms), and the Steering Committee from 60 to about 40 | The two rooms that favor the gaffe-costly styles are walls even with the full kit | caucus about 55% starter, steering about 60% | caucus becomes about 90% for full-kit players |
| 3 | **Make progression visible in the easy rooms.** Raise Hearing, Committee and Policy Study thresholds or opponent counts so a starter-kit player wins about 60-75% and a full kit about 90% (34 rooms) | A third of the game is automatic wins | gives the new cards and backings something to do | longer fights; do it room by room from the need/energy table |
| 4 | **Move reward toward difficulty.** Reward index should rise with need per energy: raise Lobbyist, Press and Floor Debate rewards and trim Hearing and Committee | Hard rooms pay least today | a reason to take hard rooms | small economy inflation; offset by item 6 |
| 5 | **Give the meta values a sink or a slower climb.** Options: halve `win_delta_jiban` and `win_delta_reputation` after the first 20 levels' worth; or add meta decay (like organization Decay Percent) so Reputation and Constituency settle; or add costs that spend Reputation (some backings already do) | Two meta values sit at 100 from level 40; nothing depends on them after that | meta keeps mattering across 80 levels | needs your design call on which |
| 6 | **Slow card collection and give tiers meaning.** Raise `xp_to_unlock` for Tier 2-3 cards (about 2x) or gate more cards behind Rhetoric Training; make Tier 2-3 cards stronger per energy (tier 3 today is the weakest at 2.40) | All 54 owned by about level 10; tiers add variety, not power | a collection arc across the run | check the starter-kit sweep again afterwards |
| 7 | **Raise consumable prices or add purchase limits** (SH04-SH08 at 10,000 yen, stack cap 5): about 10x their present income share, or limit per level | The bot bought 680-830 items a run | consumables become choices | the bot over-buys; a person may not, so re-test with a person |
| 8 | **Even out the styles.** (a) Raise Divisive and Duplicitous affinity in 10-15 more rooms (they are favored in 8 and 13 of 97); (b) grade Divisive strong in more questions (net -54 today); (c) buff C21's cost or gaffe, and fix C05, C43 and C45 (dominated); (d) trim Appeal draw engines (C12, C38) by one card or one cost | Divisive and Duplicitous are 18 of 54 cards but the best answer in 4 of 97 rooms | styles within about 8-28% of plays | the Party Activists (who like Divisive) become easier to please; check M47 value |
| 9 | **Reach the unreachable organizations.** Eight organizations never reached 60 in four runs (BO10 Agricultural Cooperatives peaks 50, BO27 48, BO12 52, BO13 54, BO17 54, BO20 52, BO21 54, BO32 57). Add themes that please them, or lower the backing's required standing for those, or lower their Decay Percent | Their backings can never be bought | every backing reachable | decay is global (5%); consider 3% |
| 10 | **Keep Media Ambush as designed**, or set its threshold near 15 (81% at threshold 15) | 0% for every kit | an optional room that can be won | you said losing it is fine; this is only if you want it winnable |

Quick wins that fit one sitting: items 1, 2, 4 and the dominated-card fixes in 8(c). Larger design calls: 5, 6, 8.

## Method notes and limits

* **Bot bias.** The bot never misreads a card, plays the strongest deck by its own score, and over-buys consumables. It under-uses gaffe budget on risky styles, which may overstate how hard the caucus rooms are. Re-test rooms 1-3 with a person before final numbers.
* **Deck variance.** Starter-kit runs deal a random opening deck per process; four processes were averaged, but the what-if trials ran one deck each (plus or minus 20 points).
* **No test of the influence swing or Floor Vote difficulty beyond data**: votes have no win rate. Bills were audited for evenness only.
* **Not covered:** visitor dilemmas (each choice was budgeted when written), cosmetic packages, staff costs against income, transitions and content depth (`tools/content_depth.py` covers the last).
* Tooling added: `tools/balance_audit.sh`, `tools/balance_audit.py`, bot sweep mode (`PLAYTEST_TRIAL_SWEEP`, `PLAYTEST_TRIAL_KIT=starter|full`), economy trace (`ECON` lines) and card tally.

## Re-run after the quick wins (2026-10-18)

Applied: Town Hall threshold 60 to 50, Party Caucus 60 to 46, Steering Committee 60 to 40; rewards moved toward difficulty (Lobbyist XP 30 to 75 and 20,000 to 50,000 yen, Press XP 60, Floor Debate XP 80, Special Committee XP 70; Hearing, Committee, Policy Study and TV Debate trimmed); four card fixes (C05 loses its gaffe; C43 gains 1 guard; C20 gaffe 2 to 3; C21 cost 0 to 1, and its text now matches its numbers). Builder: `tools/workbook/archive/batch6_balance_quickwins_2026-10-18.py`. Full tables: `design/BALANCE_AUDIT_2026-10-18_after.md`.

| Family | Starter before | Starter after | Full before | Full after |
|---|---|---|---|---|
| Town Hall (12) | 9% | 54% | 80% | 100% |
| Party Caucus (21) | 3% | 71% | 44% | 100% |
| Party Steering Committee | 0% | 41% | 0% | 58% |
| Lobbyist Meeting (6) | 59% | 66% | 71% | 74% |
| Press Conference (11) | 44% | 61% | 91% | 93% |
| Floor Debate | 70% | 90% | 100% | 100% |
| Committee of the Cabinet | 62% | 89% | 92% | 92% |
| Hearing / Committee / Policy Study | 92-98% | 97-99% | 100% | 100% |
| Media Ambush (left as designed) | 0% | 0% | 0% | 0% |
| **All combat rooms, starter** | **52%** | **77%** | | |

High flags fell from 6 to 3. The three walls are gone, but the fix **overshot the average**: the game is now easier overall (77% for a first-time player), and Hearings, Committees, Policy Studies and TV Debates are still automatic (item 3 of the recommendations was not applied). Two side effects to know about:
* **Richer rewards made the economy saturate earlier.** All 54 cards are owned by about the 5th level (was about the 10th), Funds sit at the 100,000 cap from the start, Reputation and Constituency support hit 100 by about level 20 (was 40), and the bot bought 912 items.
* **Reward still does not follow difficulty** (correlation -0.10, was -0.21): the hardest rooms are now the multi-opponent ones, and their rewards were not raised.

Suggested next step (not applied): keep the three lower thresholds but raise them about 3 points each (Town Hall 53, Caucus 49, Steering 43) to bring the first-time average toward 65%; apply recommendations 3, 5 and 6 together (harder trivial rooms, a meta sink or slower climb, costlier cards) so the saturation does not move earlier; and raise Town Hall and Caucus rewards, since they are now the multi-opponent rooms.

## Round 2 (2026-10-18): what was applied and what it did

Applied (builders `batch7` and `batch8` in `tools/workbook/archive/`, plus code): Town Hall 50 to 53, Party Caucus 46 to 49, Steering Committee 40 to 43, with higher rewards (Town Hall 70 XP and 45,000 yen, Caucus 90 XP and 20,000 yen, Steering 90 XP); Hearing and Committee thresholds x1.3 (60 to 78, and so on); Policy Study +8 (35 to 43); **meta decay** (new Sanban "Decay Percent" column: Reputation settles back 6% and Constituency support 10% of the distance to their starting value each level); Tier 3 cards +2 on their main number (C04, C08, C16, C29, C37, C39, C44, C49, C53, with text updated); and the bot now buys cards through Rhetoric Training like a player (it used to buy them directly, which is why all 54 were owned by level 5; that was a bot artifact, the real game already paces cards by Rhetoric Training prices). Floor Debate stays at 51 (canon). Full tables: `design/BALANCE_AUDIT_2026-10-18_round2.md`.

| Family | Starter original | Round 1 | Round 2 | Full kit (round 2) |
|---|---|---|---|---|
| Town Hall (12) | 9% | 54% | 48% | 100% |
| Party Caucus (21) | 3% | 71% | 48% | 100% |
| Party Steering Committee | 0% | 41% | 16% | 40% |
| Hearing (17) | 98% | 98% | 88% | 100% |
| Committee (9) | 92% | 97% | 75% | 98% |
| Policy Study (7) | 97% | 99% | 99% | 100% |
| TV Debate (7) | 86% | 96% | 65% | 100% |
| Press Conference (11) | 44% | 61% | 39% | 98% |
| Lobbyist Meeting (6) | 59% | 66% | 74% | 74% |
| **All combat rooms, starter** | **52%** | **77%** | **63%** | |

Result: the first-time average is now 63% (target about 65%), the walls stay gone, the full kit still helps a lot (97-100% in most families), and High flags are down to 3 (Media Ambush by design, plus Steering Committee at 40% even with the full kit). Card collection is paced across the run (19 cards at level 5, 28 at 20, 42 at 80), Reputation no longer sits at its ceiling (88 late), and the economy no longer saturates by level 20.

Still lopsided (not changed):
* **Constituency support still hits its ceiling** in three of four runs, and stored **Party support** sits at 95 or more for 63-72 of 80 level-ends (Party opinion, which the rules read, stays near 73). Option: give Constituency support a higher decay (10%) and Party support its own.
* **Policy Study** (7 rooms, 99%) and about half of the Hearings stay trivial: threshold alone does not work on a 50-point bar; change turns or opponent count instead.
* **Lobbyist Meeting** is flat across kits (74% to 74%): its rewards and cards do not reflect progression.
* **Press Conference** ranges 2%-75% by room: some topic rooms are walls (check the 2% room).
* **Steering Committee** (one room) is 16% starter and 40% full: threshold 43 is a little high; 40 was 41%.
* **Items** are still bought 670-760 times per run.
* The static difficulty model's fit fell to -0.57 now that thresholds differ by family; the sweeps are the better guide.
