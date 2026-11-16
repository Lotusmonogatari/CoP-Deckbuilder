# W-5 draft: card power changes (NOT applied)

Drafted 2026-11-16 at Cameron's request ("draft numbers, simulate, you approve"). Nothing here is in the workbook. Simulated with `audit/tests/sim_harness.gd`: greedy policy, 4 protagonists x 15 fights x every combat room (3,435 fights per row), current data otherwise (including the committee-room changes made the same day).

## What the audit flagged

| Flag | Cards |
|---|---|
| Discard cards far above the power curve | C63 (9 opponent for cost 1), C65 (11), C67 (11 for yourself), C69 (10 plus 3 guard) |
| Played 3x the mean or more | C14, C38, C02, C09 (starter cards: expected to be common), and C63, C64, C67 with a full kit |
| Never played by the bot | C04, C16, C20, C24, C29, C41, C44, C46, C53 (mostly Tier 3, cost 3, or heavy on gaffes) |
| Printed power per energy by suit | Appeal 2.2 and Earnest 2.7 against Duplicitous 4.1. Note this measure ignores that most Appeal and Earnest cards cost no gaffe |

## Draft 1: trim the four discard cards, cut Tier 3 costs, buff the safe Appeal and Earnest cards

C63 opp -9 to -8, C65 -11 to -9, C67 +11 to +9, C69 +10 to +8; C04, C16, C44 cost 3 to 2; C20 gaffe 3 to 2; C41 +1 to +3; C09 +4 to +5, C38 +2 to +3, C01 +4 to +5, C10 +4 to +5.

| | Greedy, opening deck | Greedy, full kit |
|---|---|---|
| Win rate | 78.7% to **85.4%** | 94.5% to 95.5% |
| Rooms won over 95% | 37 to **78** | 189 to 192 |
| Rooms won under 50% | 7 to 5 | 5 to 2 |
| Most-played cards | C14, C38, C02, C09 unchanged | C63 8x, C41 8x |

**Result:** worse. Buffing the safe Appeal cards makes the opening deck easier and the easy rooms easier.

## Draft 2: only the discard cards and the never-played cards

C63 opp -9 to -6, C64 -11 to -9, C65 -11 to -8, C67 +11 to +8, C69 +10 to +7; C04, C16, C44 cost 3 to 2; C20 gaffe 3 to 2; C41 +1 to +3. No Appeal or Earnest change.

| | Greedy, opening deck | Greedy, full kit |
|---|---|---|
| Win rate | 78.7% to **75.5%** | 94.5% to 94.8% |
| Rooms won over 95% | 37 to 34 | 189 to 190 |
| Rooms won under 50% | 7 to **18** | 5 to 6 |
| Most-played cards | unchanged (starter staples) | C41 **9x**, C63 6x, C44 6x |

**Result:** the discard nerfs help the full kit's over-reliance on C63 (10x to 6x), but they cost the opening deck 3 points, and C41 (cost 1, +3, draw 1, gaffe -1) becomes the new favorite.

## Recommendation (for you to approve)

Take Draft 2 **without** the C41 change (leave C41 at +1), keep the cost cuts on C04, C16 and C44, and treat the starter staples (C14, C38, C02, C09) as expected: the "3x the mean" benchmark was written without separating cards every deck starts with. Re-run `audit/tests/run_sims.sh` after you edit the Cards tab.

Cards flagged but not touched here: C24, C29, C46, C53 (never played; each needs a design view on what its special effect should be worth), and C01 (dominated by C25).
