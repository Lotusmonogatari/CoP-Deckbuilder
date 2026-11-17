# Panel P4: information standards (2026-11-17)

Branch `panel/p4-information`. One commit per item, each with before and after shots at the default shape (1080x2340), the 9:16 shape (`_169`) and Large text (`_bigtext`), in `item1` to `item6`. All new wording is a Text row, a draft for Cameron. No rule or number changed.

| # | Item | Commit | Result |
|---|---|---|---|
| 1 | Week-over popup previews dues (base, earned share, awareness relief, carried), wages, Funds now/after, shortfall, Party support penalty, backings withdrawn, standing settles back | 6c92ab4 | Preview is computed by `GameState.week_end_preview()` with the same rule functions as `go_home()`; `test_week_end_preview.gd` asserts preview == charge (covered, short, wages short, awareness relief, holiday) |
| 2 | Draft a Bill and Marketplace items priced above the Funds limit say why, and name the Funds Cap Increase Petition | cab739a | Disabled buttons show the reason (Standard 2); tested |
| 3 | Marketplace header at the limit | 0cebfaa | Cameron's wording: "Earnings exceed the approved limit. Request a Funds cap increase. Excess funds go to the parliament pension program." |
| 4 | Contrast: party names and Details icons | dc55c2a | Cameron chose option A, a plate per party (light or dark). Hues unchanged. Measured from pixels (below) |
| 5 | Win result: icons behind "Taken care of" | aa86b66 | Timed capture: the question band times out by itself, left alone. The icons were the battle's listening strip showing through the 85% panel; hidden once the stage is over |
| 6 | Office box note; Shredder pop-up | 9a32746 | Note reworded; pop-up says "Use this on the Staff Assignments screen." and drops the untrue "Takes effect immediately."; `Items.is_staff_item`, tested |
| 7 | Election Strength total/potential | none | Cameron said No; the eight bars stay |

## Contrast, measured from screenshot pixels (WCAG)

| Item | Measured | Target |
|---|---|---|
| Butsutou | 8.3 | 4.5 |
| Yezo Heritage Party | 15.5 | 4.5 |
| Frontier Party (your party) | 4.6 | 4.5 |
| Five Point Independents | 5.6 | 4.5 |
| Keizaijiyuutou | 4.8 | 4.5 |
| Country Initiative | 5.7 | 4.5 |
| Scrutiny, Pleased, Annoyed icons in Details | 16.6 | 3.0 |

Checked by `tests/test_party_plate.gd` (all six colours) and `tests/interaction/party_plate_test.tscn` (real pixels).

## Notes for Cameron

- The "Funds above the limit" shots were hand-set; in real play Funds clamp to the limit, so the header note appears at the limit.
- Going home from the weekend-state week button does not show a confirmation popup; only the week-over popup has the preview.
- Merge order: P3 (`panel/p3-text-sweep`) then P4. Not merged; awaiting "merge".
