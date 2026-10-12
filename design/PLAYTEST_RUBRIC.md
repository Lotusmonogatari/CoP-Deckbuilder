# Playtest rubric: backing, influence and laws (2026-10-12)

Question: starting from a new game, do **backing and organisation standing** really change what happens, can the player's **influence flip a Floor Vote**, and do **passed and failed bills** switch on and last the way the workbook says?

**How it is scored.** `tools/rubric_playtest.gd` (run: `xvfb-run .tools/godot --path . tools/rubric_playtest.tscn`) plays through the same game calls the screens use, from a fresh run, and checks each line below against the **workbook data read separately** (never against a number typed into the test). Weights: **Critical 3**, **Major 2**, **Minor 1**. A line is all-or-nothing; a NOTE scores nothing and records something Cameron should know. The score is points earned out of points possible.

| ID | Wt | What passes |
|---|---|---|
| **A. New game** | | |
| A1 | 3 | Each of the 4 protagonists opens at their own workbook meta and XP |
| A2 | 2 | Every organisation opens at its workbook starting standing (own cell, else the flat 30) |
| A3 | 3 | No backing owned; statute book, flip record and clears all empty |
| A4 | 2 | The influence gate is shut for every party on day one |
| **B. Backing and organisations** | | |
| B1 | 3 | Backing is refused below the required standing (60), bought at it, charged the workbook costs, never sold twice |
| B2 | 3 | Every stage-start / hand-size / gaffe-limit backing adds exactly its workbook amount at its stage when its trigger is met (audience share, or an organisation's standing at or above the number) and nothing when not |
| B3 | 3 | Every pay-on-win backing pays exactly its workbook amount; organisation-triggered ones pay only while that organisation stands at or above the number |
| B4 | 2 | A real level win with a backing pays exactly its amount more than the identical win without it (same dice) |
| B5 | 2 | Question results move standing by the workbook amounts (please +5, annoy -1, set back -3, argue out -2), capped per stage, clamped 0-100, shown in Your Record |
| B6 | 2 | A real battle with real cards: every organisation pleased or annoyed has its standing changed afterwards |
| B7 | 1 | Party Backing (M09) turns on by itself above the party-support line and off below it |
| B8 | 1 | Standing and owned backing survive a finished level and a save/reload |
| **C. Vote influence** | | |
| C1 | 3 | New-game tallies equal the workbook seat splits (plus the player's one seat), with no swing and no flip, for 4 protagonists x 30 bills x 3 choices |
| C1b | 2 | Every bill's splits add up to each party's real seat count, so every chamber is 101 |
| C2 | 3 | The gate is an AND: any one unscoped requirement one point short keeps it shut; all met opens it |
| C3 | 3 | Meeting the common requirements plus one party's own swings that party and no other |
| C4 | 3 | A full-strength player flips real bills; every flip is flagged correctly, seats are conserved, no party gives up more than its resistance allows |
| C5 | 2 | Voting with your own party's majority never moves that party's seats |
| C6 | 2 | **Real clicks** on the Floor Vote screen: a full-strength player flips a bill, the screen shows the swung totals, the statute book and flip record agree |
| C7 | 2 | Every enabled requirement is below the ceiling of the thing it measures |
| C8 | 1 | The influence bonus columns do nothing blank and apply exactly their numbers when filled |
| **D. Laws activate and last** | | |
| D1 | 3 | All 30 bills x Passed/Failed: exactly the organisations, meta values and XP in that bill's **Once** row change, nothing else, and the book records the outcome |
| D2 | 3 | An **Each level** law pays nothing on the level that passed it, then exactly its amount at the end of each later level (3 watched, against an identical run without the law) |
| D3 | 2 | A bill with only Once rows keeps nothing running |
| D4 | 3 | Recording the same bill twice changes nothing |
| D5 | 2 | Save, reload, carry on: the book and the running payouts are exactly as if you never quit |
| D6 | 2 | A new game wipes the statute book and the flip record |
| D7 | 1 | Office notices and the ticker switch on only after the named bill has passed |
| D8 | 2 | Every organisation is pleased by at least one bill outcome and annoyed by at least one |

Not scored (recorded as NOTEs): how long the requirements take to earn (C7b), whether a flip cutscene line is written for the bill (C6b), and how many notice/ticker rows use the law condition (D7b).

---

## Result: 62 / 64 (97%), run 2026-10-12 after the fixes below

| Section | Points | Notes |
|---|---|---|
| A. New game | 10 / 10 | All four protagonists open clean; the gate is shut for everyone |
| B. Backing and organisations | 17 / 17 | 36 stage cases and 22 pay-on-win cases match the workbook; a real level win pays exactly the backing's amount |
| C. Vote influence | 19 / 21 | **C1b fails: Bill BI25 has a data error** (below). Everything else passes, including the real-click flip |
| D. Laws | 16 / 16 | All 60 bill outcomes apply exactly their workbook rows; the 3 "each level" laws pay on schedule, survive a save/reload and clear on a new game |

**What the playtest found (all fixed unless marked)**

| # | Finding | Status |
|---|---|---|
| 1 | **A flip crashed the Floor Vote screen.** The blank "Influence Bonus" cells are `null`, and `int(null)` aborted the vote the instant the player's influence flipped a bill: no result panel, no way out. Only a real click on a full-strength player shows it | **Fixed** (`FloorVoteEngine.influence_bonus()`, two new tests) |
| 2 | **Organisation-triggered backing never switched on** (the 26 modifiers M05-M08, M11, M13, M15-M31). Cameron: a BOxx trigger means "that organisation's standing is at or above the number" | **Built** (`MetaRules.booster_trigger_met()`); B2/B3 now prove it |
| 3 | **BI25 Integrated Resort Act adds up to 105 seats**: PT02's split is 16 (holds 14) and PT06's is 13 (holds 11) | **Open for Cameron** (workbook data). The exporter now warns about it |
| 4 | The Modifiers header notes still said a BOxx trigger was ignored | Fixed |

**Things worth knowing (no score)**

- **Influence is hard but reachable.** At full strength a player flips 23-24 of 60 yes/no votes per protagonist. The slowest requirement is an organisation at 75 (BO02): at most +5 a stage from a start of 30, so at least 9 stages of pleasing it. The two Funds-gated parties (PT04, PT05) need Funds 500,000, which takes four "raise the Funds cap" purchases (it starts at 100,000).
- **A BOxx trigger is almost always on by default.** Buying a backing needs standing 60, and the trigger numbers are 15-30, so the trigger only matters if standing later falls below it.
- **No flip cutscene line is written for most bills** (BI01 has one). No Office notice or ticker row uses the law condition yet.
- **Not covered:** the bot's choice of cards in a real battle (B6 used a simple greedy hand), and whether the numbers *feel* balanced to a person.

Re-run any time: `xvfb-run .tools/godot --path . tools/rubric_playtest.tscn` (about 90 seconds; under `--headless` the click line C6 is skipped). It exits 1 while any line fails, so it stays a check, not part of `verify.sh`.

### Update, same day: 66 / 66 (100%)

BI25's data error is fixed (Cameron's rule: take surplus seats from Abstain first, Yes second, No third, so PT02 went 8-8-0 to 6-8-0 and PT06 8-5-0 to 6-5-0), so C1b now passes. New line D8 (every organisation pleased by one bill outcome and annoyed by another) found one gap, Neighborhood Associations (BO06), now covered by BI14 and BI25 (below).
