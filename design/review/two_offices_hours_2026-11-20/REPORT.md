# Two offices: what travel takes of the week (slice 7, 2026-11-20)

A measurement, not a change: **no number, price or rating was changed by this report.** **Cameron's answers (2026-11-20, after reading it):** the labels stay (PC01 Easy, PC04 Very Hard); PC01 starts with four Plane Tickets and PC04 gets nothing (option B for PC01 only); the ticket prices are now 10,000 / 30,000 / 60,000円 (the ticket figures below use them; the bot runs never bought tickets, so they are unaffected); and the spellings Daikoku and Akeno Shinmachi. Decision 14 ("is Kenshin still Easy?") is therefore closed: yes. Generated tables: `hours_resim.md` (the log replay), `bench_comparison.md` (the live bot, all pressures); raw bot runs are in `design/bench/offices/`.

## Executive summary

| Question | Answer |
|---|---|
| How much of the 40-hour week does travel take? | **PC02 and PC03: 2 to 5%. PC01 and PC04: 10% if the player stays put, 18 to 19% if they cross whenever the next level is at the other office.** |
| What does that cost the two long-trip protagonists? | By week 10 about **16% less XP for PC01 and 23% less for PC04** (7% for PC02 and PC03); over 30 weeks about 19 to 23% less Funds earned and 3 fewer laws for PC01. |
| Do the fights get harder? | **No.** Stage win rates move by about a point or less: the rooms are unchanged, the player simply has fewer hours. |
| Is Kenshin (PC01) still Easy? | He keeps the easiest *start* (35 / 25 / 100,000円 / 40, 60 XP) but **ends level with Jyurou (PC04, Very Hard)**: Election Strength at week 30 is 65.0 for PC01, 64.8 for PC04, 69.7 for PC02, 70.6 for PC03 (all four were about 71 without offices). Options below; my recommendation is to **keep the labels and soften the first weeks with starting tickets**. |
| A surprise | A player who **never leaves the Capitol** never meets District levels (the Capitol list never runs out) and ends with District awareness 56 to 69 instead of 100, losing about 6 Election Strength. Nothing in the game tells them to go home. |
| Does the plane or car fix it? | The plane cuts PC01's travel from about 14 to about 4 hours a week for about 118,000円 a week at the new 60,000円 price (about 12,000円 for each hour saved). PC04's car saves about 4 hours for about 57,000円. **PC02's and PC03's car saves no hours at all** (1 h either way): it only skips the train encounters. |

## How it was measured

| Method | What it does | What it cannot do |
|---|---|---|
| **Live bot** (`tools/strategy_playtest.gd`, 48 runs per protagonist per policy at standard pressure, 30 weeks) | The same bot that plays real fights, now in the two offices on the rail pass, paying a mixed level's built-in trips. Three policies: **no offices** (the old way), **stays** (plays everything at its office first and crosses only when nothing is left) and **crosses** (follows its own level order, crossing whenever the best level is at the other office; the pessimistic order). | It never buys a ticket, plays no train encounters, and does not choose levels like a person (it ranks levels by a fixed rule). 4-seed samples at harder and relaxed pressure are noisy (one protagonist's win rate moved 7 points on no rule change): standard is the evidence. |
| **Log replay** (`tools/two_offices_hours.py`, 144 old bot runs of 2026-11-02) | Replays what the bot played then through today's offices, hours and trips: an upper bound on travel for a player who plays the same levels in the same order. | The bot would play different levels if only one office's list were shown; the logs predate staff wages and the new levels; "worst week" figures above 40 hours are replay artefacts (a real week stops at 40). |

## The live bot, standard pressure (each cell: no offices → stays → crosses)

| Metric | PC01 Kenshin (Easy) | PC02 Haru (Normal) | PC03 Arata (Hard) | PC04 Jyurou (Very Hard) |
|---|---|---|---|---|
| Stage win rate | 97.0% → 96.6% → 97.0% | 97.1% → 97.0% → 96.3% | 97.7% → 96.0% → 96.9% | 95.5% → 93.9% → 94.5% |
| Election Strength at week 30 | 71.2 → 61.5 → **65.0** | 71.7 → 65.6 → **69.7** | 71.3 → 65.5 → **70.6** | 70.6 → 62.9 → **64.8** |
| District awareness at week 30 | 100 → 56 → 79 | 100 → 69 → 100 | 100 → 69 → 100 | 100 → 62 → 87 |
| Funds earned over 30 weeks (millions) | 7.9 → 7.5 → 6.4 | 8.1 → 8.4 → 7.4 | 7.8 → 8.4 → 7.5 | 7.9 → 7.4 → 6.1 |
| Laws passed | 7.5 → 4.2 → 4.2 | 7.7 → 7.0 → 5.5 | 8.2 → 7.7 → 6.9 | 7.2 → 5.8 → 4.8 |
| Trips over 30 weeks (stays / crosses) | 17.5 / 30.6 | 22.5 / 56.8 | 22.8 / 56.0 | 20.2 / 38.0 |
| Travel hours over 30 weeks (stays / crosses) | 122 / 214 | 22 / 57 | 23 / 56 | 121 / 228 |
| Share of the 40-hour week travelling (stays / crosses) | 10% / 18% | 2% / 5% | 2% / 5% | 10% / 19% |
| XP gained by week 10 (no offices → crosses) | 9,198 → 7,734 (−16%) | 9,122 → 8,511 (−7%) | 8,934 → 8,277 (−7%) | 8,339 → 6,413 (−23%) |

Reading it: the same trips cost PC02 and PC03 one hour and PC01 and PC04 six or seven, so the long-trip protagonists lose three to four times as much of the week. Election Strength is a slow measure (it rises by a fixed step a week for the first 20 weeks, so only the end shows), which is why XP, Funds and laws are shown too.

## The log replay: upper bound on hours a week (batched order, rail pass)

| Protagonist | Travel h/week | Share of 40 h | By plane or car | Funds for those tickets a week |
|---|---|---|---|---|
| PC01 Kenshin (Aomori, Noheji) | 13.8 | 35% | 3.9 (plane) | 118,333円 |
| PC02 Haru (Tomakomai, Akeno Shinmachi) | 2.0 | 5% | 2.0 (car) | 58,777円 |
| PC03 Arata (Teine Ward) | 2.0 | 5% | 2.0 (car) | 58,750円 |
| PC04 Jyurou (Wakkanai, Daikoku) | 11.4 | 28% | 7.6 (car) | 56,972円 |

The replay is harsher than the live bot because the live bot, shown only one office's list, chooses levels that need fewer crossings (it plays far more of the five "Either" levels). The truth for a person lies between the two.

A mixed level (17 of the 24 appear in the old logs) takes a median **14 hours** of rooms. On the rail pass that becomes **28 h for PC01 and 26 h for PC04** (a round trip is 14 and 12 hours) and 16 h for PC02 and PC03; by plane PC01's falls to 18 h. None passes 40 hours.

## What this says about decision 14 (PC01 and PC04's rating)

| Option | What changes | Effect (from the tables) | Cost to build |
|---|---|---|---|
| **A. Keep the labels, change nothing** | Nothing. | PC01 ends level with PC04 at week 30 and behind PC02 and PC03; the Easy label holds only for the first weeks. | None |
| **B. Keep the labels; start PC01 with four Plane Tickets and PC04 with four Private Car Trips (recommended)** | Starting-item cells in the Player tab. | A small early cushion at no Funds cost: four plane trips save PC01 20 hours (half a work week), four car trips save PC04 8 hours. Does not change the late game. | Workbook cells only |
| **C. Change the two ticket prices** | One Shop cell each (the car is shared by PC02, PC03 and PC04). | Not taken as a cut: **Cameron set the prices to 10,000 / 30,000 / 60,000円** instead of the drafts, which makes the plane a deliberate spend (about 12,000円 for each hour it saves). | Done |
| **D. Relabel PC01 "Normal"** | The New Game blurb. | Matches where PC01 ends up, but two protagonists would share a label and the strong start would no longer be described. | Text only |
| **E. Fewer built-in trips for PC01 and PC04** (for example one trip on a mixed level, not two) | A per-protagonist rule for `Travel Trips`. | Halves the mixed-level cost (14 h to 7 h for PC01). | New mechanic: needs its own proposal |

**Recommendation (made before Cameron's answer):** A now, with **B**. **Cameron's decision:** A, and B for PC01 only (four plane tickets; PC04 gets nothing), with the new prices above.

## Things the numbers surfaced for Cameron

| # | Finding | Why it matters | Suggested next step |
|---|---|---|---|
| 1 | The Capitol list never runs out, so nothing pulls the player to the District. A bot that stays gets District awareness 56 to 69 (15 of Election Strength's points) and never plays a District level in 30 weeks. | A player may not discover that the District is where District awareness comes from. | A proposal for a visible nudge (a District notice, an Office line, or awareness shown on the trip strip): new UI, so not built. |
| 2 | PC02 and PC03 pay 30,000円 for a car trip that takes the same single hour as the train. | It buys only the skipped encounter (1 in 8). | Lower the price, or leave it as a luxury; Cameron's call. |
| 3 | LV10 (27 h) needs the plane ticket for PC01 (41 h on the pass). | A fixed rule makes one level unreachable without a purchase. | Already documented in `GAME_SYSTEMS.md` section 3.1; keep, or give PC01 a plane ticket at the start (option B does). |
| 4 | The bot never plays the train encounters or buys tickets. | The real cost of travel to a person includes the encounters (a gain, sometimes) and the ticket spend. | A real-phone playtest (milestone M6) is the true test. |

## Not measured

Weekend play (no travel then), promises and events that need an office, the eight protagonist levels (the old logs do not contain them), and any bot that buys tickets. A re-run is cheap: `PLAYTEST_OFFICES=0|1|2 tools/strategy_runs.sh ...` then `python3 tools/offices_bench_report.py`.
