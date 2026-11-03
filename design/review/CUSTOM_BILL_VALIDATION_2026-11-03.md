# Custom bill validation after the revision (2026-11-03)

Phase 5 of `design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md`. This is a report only; no rules were changed. Every number below comes from a **bot**, not a human. The bot accepts every request and drafts whenever the game allows it. It never reads the readiness line before committing; a human would.

## Executive summary

| Question | Answer |
|---|---|
| Do drafted bills now pass? | More often. Bots passed **37 of 233 drafts (16%)**, against 4 of 78 (5%) before. A fully prepared player passed **27 of 42 (64%)** across three probes; the baseline was 8 or 9 of 14. |
| What stops them? | **The vote, not the hearing.** Only 25 of 233 bot drafts lapsed at the hearing. 171 reached the vote and failed, because the bots never meet the influence gates. |
| What stops drafting at all? | **Money.** Of 4,771 refusals (out of 5,004 times a bot wanted to draft), 3,263 (68%) were on cost ("Drafting needs 350 XP and 300,000円"), 1,152 (24%) the cooldown, and 356 (7%) a chosen part already being law. |
| Does drafting pay for bots? | **No.** Every drafting strategy ended with less Funds than `cap_dues`, which never drafts. On Standard: 92,540円 against 165,996円. Election Strength and Party support were equal or lower. |
| Does it pay for a prepared player? | **Yes in standing and Party support.** A passed draft gave on average +11 Party support and +41 organization standing summed, for 223 XP and 229,815円 net. |

## 1. Strategy runs (54 runs)

Command (run once per tier):

```
PLAYTEST_DIFFICULTY=<tier> tools/strategy_runs.sh design/bench/custom_bill_validation.jsonl "1 2 3 4 5 6" PC02 cap_dues drafter_easy drafter_random
```

Each run is 30 weeks with protagonist PC02. The figures are totals over 6 seeds (Funds, Party support, Election Strength and Laws are means).

| Tier | Strategy | Looks | Drafted | Lapsed at hearing | Voted | Passed | Visits won | Funds at end | Party support | Election Str. | Laws |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Relaxed | cap_dues | 0 | 0 | 0 | 0 | 0 | 0 of 0 | 607,252 | 100.0 | 90.0 | 20.0 |
| Relaxed | drafter_easy | 649 | 56 | 2 | 54 | 15 | 33 of 33 | 469,904 | 100.0 | 89.1 | 20.8 |
| Relaxed | drafter_random | 676 | 53 | 7 | 46 | 10 | 18 of 18 | 577,694 | 100.0 | 90.0 | 20.3 |
| Standard | cap_dues | 0 | 0 | 0 | 0 | 0 | 0 of 0 | 165,996 | 100.0 | 73.3 | 16.2 |
| Standard | drafter_easy | 780 | 38 | 0 | 38 | 4 | 19 of 19 | 92,540 | 96.3 | 73.6 | 13.0 |
| Standard | drafter_random | 973 | 28 | 2 | 26 | 1 | 17 of 17 | 91,866 | 66.7 | 61.1 | 11.7 |
| Harder | cap_dues | 0 | 0 | 0 | 0 | 0 | 0 of 0 | 60,307 | 100.0 | 59.7 | 8.3 |
| Harder | drafter_easy | 1,077 | 22 | 1 | 21 | 3 | 8 of 8 | 31,896 | 66.8 | 54.0 | 7.0 |
| Harder | drafter_random | 849 | 36 | 13 | 23 | 4 | 13 of 13 | 49,735 | 98.0 | 60.0 | 14.2 |

**Looks** counts the Office visits where the bot wanted to draft. Of the refused looks, 68% were on cost, 24% on the cooldown and 7% because a chosen part was already law. The Funds cap was 1,000,000 in every drafting run, so the cap itself never blocked a draft. What blocked drafting was holding 300,000円 at once while dues and items kept draining it. No bugs or stalls were logged in any of the 54 runs.

`drafter_easy` picks a first part heard by Agriculture, Environment or War; only 3 of its 116 drafts lapsed. `drafter_random` lapsed 22 of 117, almost all at Construction and Finance (ST15, ST16). Member visits were won every time a bot reached one (108 of 108).

## 2. Vote audit and negotiation rooms

Command: `.tools/godot --headless --path . tools/bill_audit.tscn` (after Phase 4, unchanged since).

| Profile | Patron bills carried (of 54, by protagonist) | Random 2-part drafts carried | Random 3-part drafts carried |
|---|---|---|---|
| No gate met / Reputation 65, standings 60 / Reputation 80, standings 72 | 0 | 0 | 0 |
| Standings 75 or 80, Funds 100k | 29, 29, 49, 49 | 87 of 195 | 93 of 198 |
| Standings 80, Funds 500k, Reputation 60, or stronger | 54 for all four | 195 of 195 | 198 of 198 |

| Kind | Levels | Member visit built | Lobbyist trade built |
|---|---|---|---|
| Patron Favor (BT01) | 27 | 8 | 17 |
| Patron Flagship (BT02) | 27 | 27 | 24 |
| Draft, 2 parts (BT03) | 200 | 107 | 138 |
| Draft, 3 parts (BT04) | 200 | 200 | 160 |

The cliff is still at standing 75 (the Party Faction gate). Below it nothing carries; at 75 about half do; at 80 with 500,000円 everything does.

## 3. Draft probe (three runs)

Command: `.tools/godot --headless --path . tools/bill_draft_probe.tscn`. Each run is 14 drafts by a strong player (standings about 80, Funds 700,000 or more).

| Run | Passed | Failed at vote | Lapsed at hearing |
|---|---|---|---|
| 1 | 7 | 2 | 5 |
| 2 | 10 | 1 | 3 |
| 3 | 10 | 0 | 4 |
| Total | **27 of 42** | 3 | 12 |

A passed draft's standing moves, for example "Fund clinics in rural towns + Guarantee payment within sixty days on public contracts + Move government services online": Neighborhood Associations +7, Rural Revitalization +7, Chamber of Commerce +7, Party Faction +9, Party Activists +11, Mayors' Network -4, Urban Neighborhood Alliance -2, and smaller moves for eleven more. Party support +14.

## 4. Economy of one draft

| Item | Passed draft (27) | Lapsed or failed draft (15) |
|---|---|---|
| XP, net of the level's own rewards | -223 | -317 |
| Funds, net | -229,815円 | -281,000円 |
| Party support | +11.3 | +2.3 |
| Organization standing, summed | +41.0 | +17.6 |

The bot's income on the same tier (mean Funds earned per week, `cap_dues`) was 533,991円 Relaxed, 453,316円 Standard and 312,978円 Harder. So one draft costs about half a week's income on Standard, and nearly a week's on Harder.

- **Party support:** drafting pays. +11 from a passed draft is more than most single levels give.
- **Standing:** drafting pays. +41 summed is spread over many organizations, which helps Election Strength's organization part.
- **Funds:** drafting does not pay. There is no Funds reward for a draft, and the bots that drafted ended poorer.
- **Election Strength:** neutral for a careful drafter (`drafter_easy` matched `cap_dues` on Standard), and worse for a careless one.

## 5. Against the baselines

| Measure | Before (2026-11-02) | Now |
|---|---|---|
| Bots drafting when allowed, passed | 4 of 78 (5%) | 37 of 233 (16%) |
| Prepared player, passed | 8 or 9 of 14 | 27 of 42 (64%; 7 to 10 per run) |
| Lapsed at the hearing (bots) | most failures | 25 of 233 (11%) |

## Findings, most severe first

1. **The vote is the wall, and bots cannot see it.** 171 of 233 bot drafts reached the vote and failed. The readiness line (Phase 4) now tells a human what is missing before they commit; the bots ignore it. A human player should do much better than 16%, but nothing here measures that.
2. **Drafting costs Funds and gives none back.** Every drafting strategy ended poorer than `cap_dues`, on every tier. Drafting is a Party support and standing play, not a Funds one.
3. **Saving 300,000円 is the real gate, not the cap.** The bots had a 1,000,000 cap but rarely held 300,000 at once. On Harder they drafted 22 to 36 times in 30 weeks, against 53 to 56 on Relaxed.
4. **The first part still decides the risk.** Easy committees (Agriculture, Environment, War) almost never lapse; Construction and Finance account for nearly all lapses. The Draft panel now names the committee, but not how hard it is (Cameron's choice).
5. **The standing-75 cliff.** Influence gates are all-or-nothing, so a player at 72 carries nothing and one at 80 carries everything.

## Decisions for Cameron

| # | Question | Options |
|---|---|---|
| 1 | Should a passed draft pay any Funds (a donation from its organizations), so drafting is not a pure Funds loss? | No Funds (as now) / a small donation per owner / a law effect per part |
| 2 | Is 300,000円 the right price, given it is half to a full week's income? | Keep / lower to 200,000 / scale by Campaign Pressure |
| 3 | Should the bots be taught to check readiness before drafting, so future runs measure a sensible player? | Yes (tools only, no game change) / No |

## Re-run after Cameron's decisions (2026-11-03)

Changes measured: the draft costs 200,000円 on Relaxed, 300,000 on Standard and 400,000 on Harder, and the drafting bots now read the readiness line and draft only when the influence gates are met. The same 36 drafting runs (`drafter_easy` and `drafter_random`, 6 seeds, three tiers) went to `design/bench/custom_bill_validation_ready.jsonl`.

| Tier | Drafted (before → after) | Passed | Failed at vote | Lapsed | Funds at end | Party support | Election Str. |
|---|---|---|---|---|---|---|---|
| Relaxed | 109 → 86 | 25 → 43 | 75 → 41 | 9 → 2 | 523,799 → 622,462 | 100 → 100 | 89.6 → 90.0 |
| Standard | 66 → 43 | 5 → 13 | 59 → 28 | 2 → 2 | 92,203 → 202,146 | 81.5 → 91.7 | 67.4 → 71.3 |
| Harder | 58 → 0 | 7 → 0 | 37 → 0 | 14 → 0 | 40,815 → 64,643 | 82.4 → 75.0 | 57.0 → 53.7 |

- **Reading readiness pays.** Pass rate 16% → 43%. Standard drafters now end with more Funds than `cap_dues` (202,146 against 165,996).
- **"Ready" is not a guarantee.** 69 of 129 ready drafts still failed: the gate can open for one party while the seats it can swing fall short of 51.
- **Harder shuts drafting off for these bots.** At 400,000円 they were never both ready and able to pay, so they never drafted. A human may manage it, but this is the edge of the design.
