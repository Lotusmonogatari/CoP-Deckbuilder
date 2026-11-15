# Follow-up: closing the "not tested" items

Run after the Phase 8 summary. Tools: `audit/tests/followup_probe.gd` (headless), `audit/tests/exporter_probe.py` (the real exporter on a temporary copy of the workbook; the project's workbook and `data/` were not touched). Raw results: `audit/tests/results/followup.json`, `exporter_cases.json`. Labels: **Verified** (ran it), **Inferred**.

## 1. Invariants that were "not tested"

| ID | Result | Evidence | Status |
|---|---|---|---|
| INV-11 (Floor Votes and Office Hours cannot be lost) | The Office Hours and Floor Vote engines contain no loss path (0 occurrences of `LOST` or `"loss"`), and no Non-combat or Vote stage in the data ends a level on a loss | source search and `data/stages.json` | **Pass** (Verified for the data; the screens were not driven) |
| INV-17 (a level starts only if it fits the hours left) | All 114 levels checked at 40, 20, 10, 4 and 0 hours left: 114 / 95 / 36 / 22 / 0 startable. **0 mismatches** with "hours needed ≤ hours left". Longest level 35 h (LV19) | `followup.json` `INV-17` | **Pass** |
| INV-18 (each crisis fires once per crossing) | Constituency support 50, 14, 10, 9, 40, 12: Town Hall "entered" at 14 only, nothing at 10 and 9, "left" at 40, "entered" again at 12. Totals 2 entered, 1 left, as expected | `followup.json` `INV-18` | **Pass** (Town Hall; the other two triggers share the same edge code, `GameState.gd:2603-2642`, not run separately) |
| INV-19 (Acts) | BI01: before any vote not settled; absent: not settled; abstain replaces the absent entry (still 1 entry); Aye replaces the abstain and settles it; a later Nay is ignored and the entry stays Yes. The 7,488-hour replay value is the cooldown on all 50 bill levels | `followup.json` `INV-19`; `data/levels.json` | **Pass** (the replay clock itself was not run) |
| INV-24, second half (a result shown on screen survives closing the app) | A recorded loss on LV01 stage ST05 survived save then load: the stage key matched (`LV01:0:ST05`), the result read back as "loss", score 12 | `followup.json` `INV-24b` | **Pass** |

## 2. Reload and seating (revises F-17)

After a save and load in the middle of a level, the seated opponents were identical (`OP105, OP109, OP102` before and after). The seating is stored in the saved level snapshot. So a **reloaded stage keeps its opponents**; only a *new* stage draws them with an unseedable generator. F-17 in `audit/conformance.md` is therefore narrower than first written: it affects reproducing a new stage from a seed, not reloading.

## 3. Save size

A deliberately worst-case save (all 70 cards, 50 statute entries, 298 met characters, 200 promises, every stage and level record filled) is **75 KB** and writes in 8 ms, against the proposed 1 MB and 50 ms (TEC-16). A real 30-week run was not saved to disk by the bot, so this is a constructed upper bound, not a measurement of a run. **Pass** (constructed).

## 4. Malformed workbook rows through the real exporter (INV-29, import pipeline)

Each case edits one cell of a temporary copy of the workbook and runs `tools/export_data.py`.

| Edit | Exporter says | Status |
|---|---|---|
| No edit | "No errors" | baseline |
| ST02 turn limit blank | **Error**: combat stage has no turn_limit | caught |
| ST02 energy per turn blank | **Error** | caught |
| Card C23 cost blank | **Error** | caught |
| Card C23 suit "Sarcasm" | **Error**: not in the Suits tab | caught |
| LV01 part 1 = ST9999 | **Error**: stage does not exist | caught |
| "Funds" renamed in Sanban | **Error** (and explains why the name is a lookup key) | caught |
| **ST02 win threshold or player start blank** | **Warning only**; "No errors" | **not caught** (E-01: a non-committee room that never ends) |
| **Balance lever "Dues: Base" deleted** | **"No errors"** | **not caught** by the exporter; only `tests/test_balance_keys.gd` catches it, and only once a script asks for it, and the code fallback hides the loss (E-07) |
| **Text row `office.haptics` English cell blank** | **"No errors"** | **not caught** |
| **Shop SH25 Icon = a file that does not exist** | **"No errors"** | **not caught** by the exporter (my new `test_icon_names.gd` catches it in `verify.sh`) |
| **Visitor VI01 stage cell = ST9999** | **"No errors"** | **not caught** (the visitor silently never appears there) |

**Result:** the exporter validates the structured columns well and misses five kinds of mistake. The roadmap gets one new item, W-11.

## 5. Still not verified

Everything on a phone; human play and feel; the replay clock running forward 7,488 hours; the other two crisis triggers run individually; mid-action touch interruption; a save from an older build; Floor Vote and Office Hours screens driven through a lost-stage attempt.
