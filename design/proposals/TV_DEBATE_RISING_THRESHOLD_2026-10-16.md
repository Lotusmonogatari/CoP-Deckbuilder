# TV Debate: a threshold that rises each turn (plan, 2026-10-16)

## Executive summary

| | |
|---|---|
| Goal | The TV Debate's survival line (today a flat 65) rises every turn by a random amount from a range you set. |
| Done now | Three new editable columns on the workbook's **Stages** tab, exported to `data/stages.json`, checked by the exporter. **No game behaviour changes yet.** |
| Not done | The engine, display and tests below. They are about 150 lines across 6 files, so per the working agreement I am waiting for your approval. |
| Draft numbers | Rise 0 to 3 per turn on all seven TV Debate rooms. Placeholder; a bot trial sets the real value after the engine exists. |

## 1. What is in the workbook now

Stages tab, columns AU to AW, header row 1:

| Column | Meaning | Blank means |
|---|---|---|
| **Threshold Rise Min** | Smallest rise per turn (whole number, 0 or more) | The line never moves (today's rule) |
| **Threshold Rise Max** | Largest rise per turn (at least Min) | Same |
| **Threshold Cap** | Highest the line may ever reach | The stage's Bar max (100) |

Rules the exporter enforces:

| Check | Result |
|---|---|
| Only one of Min / Max filled | Error |
| Min below 0, or Max below Min | Error |
| Cap below the Win threshold, or above Bar max | Error |
| Filled on a stage that is not a Survival (TV Debate) bar | Warning, ignored |

Seeded rows (Min 0, Max 3): ST06 and the six topic TV Debates (ST41, 44, 73, 84, 91, 98). Every other stage is blank and unaffected. The column header notes (hover text) are not written; add them in Excel with Insert Note, the same as the Free Card Tier column.

## 2. The rule I propose

| Question | Proposal | Why |
|---|---|---|
| When is the line rolled? | After a turn's survival check passes, for the **next** turn. Turn 1 is always the base 65. | The player sees the new number before they spend energy. A hidden rise would be unfair. |
| How is it rolled? | One whole number, equally likely from Min to Max inclusive, with the battle's own seeded random generator. | Repeatable in tests, like every other roll. |
| Does it accumulate? | Yes. Turn 3's line is base plus the turn 2 and turn 3 rises. | "Increases each turn". |
| What stops it? | The Cap column (blank = Bar max). | A line above what the bar can hold would be an automatic loss. |
| Which stages? | Survival bar only. | Every other room is won by crossing its threshold, where a rising line would make the stage unwinnable rather than harder. |
| Win and loss | Unchanged: still survived by being at or above the line at the end of every turn. | No new win condition. |

Line by turn if Min 0, Max 3 (65 start, 5 turns):

| Turn | Line, lowest case | Line, highest case |
|---|---|---|
| 1 | 65 | 65 |
| 2 | 65 | 68 |
| 3 | 65 | 71 |
| 4 | 65 | 74 |
| 5 | 65 | 77 |

The player starts at 60, so turn 1 already needs 5 or more net gain, and the highest case needs about 17 net by turn 5. That is the number the bot trial must check.

## 3. Build plan (needs your go-ahead)

| Step | File | Change | About |
|---|---|---|---|
| 1 | `scripts/rules/BattleEngine.gd` | Read the three fields into the config; roll in `end_turn()` after `_check_outcome(true)` when the stage is Survival and not over; clamp to the cap; record the rise in the turn result. | 30 lines |
| 2 | `scripts/rules/BarModel.gd` | A small `raise_threshold(amount, cap)` so the bar owns its line. | 10 lines |
| 3 | `scripts/rules/BattleSetup.gd` | Pass the three columns from the stage row into the engine config. | 5 lines |
| 4 | `scripts/ui/BattleScreen.gd`, `SupportBar.gd` | Redraw the threshold line when it moves; announce "The line rises by 2, to 67." in the room notice. The bar's caption ("65 to win") follows. | 20 lines |
| 5 | Text tab | Two new rows for the announcement and the briefing line (no sentence in a script). | 2 rows |
| 6 | `scripts/ui/StageBrief.gd`, `HowToPlay.gd` | The level briefing says the line rises by Min to Max each turn; add a How to Play entry. | 15 lines |
| 7 | `tests/test_battle_engine.gd` | Seeded rise lands inside the range; accumulates; respects the cap; no rise when blank; no rise on non-Survival stages; fail-below-line uses the raised line. | 6 tests |
| 8 | `tools/playtest_optimal.gd` | Stage trial for ST06 with the rise on, to pick Min and Max. | existing tool |

## 4. Decisions for you

| # | Decision | My recommendation |
|---|---|---|
| 1 | Roll at the start of the next turn and show it at once (above), or keep the next rise hidden until it lands? | Show it at once. |
| 2 | Keep 0 to 3 as the starting range, or tune it after the bot trial? | Tune. I will report the bot's win rate for 0-2, 0-3, 1-3 and 1-4 before you pick. |
| 3 | Should the six topic TV Debates share ST06's range, or each have their own? | Own columns already exist per row, so start equal and edit freely. |
| 4 | Should a rising line also be allowed on other rooms later? | Not now. It would need its own win rule. |
