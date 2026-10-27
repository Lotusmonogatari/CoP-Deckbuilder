# Editing the design workbook safely

The workbook (`design/CoP_Starter_Card_Stage_Data.xlsx`) is the source of truth for all content. **Never save it with openpyxl**: a load/save round trip silently corrupts cached values (it wiped the Stages tab's formula results and altered Sanban numbers). openpyxl is fine for *reading*.

`wbx.py` edits the raw XML instead, so only the cells you touch change:

```python
import sys; sys.path.insert(0, "tools/workbook")
from wbx import WB
w = WB("design/CoP_Starter_Card_Stage_Data.xlsx")
w.rows("Modifiers")                                   # {row: {column letter: text}}
w.find_row("Boosters", "BO19")                        # row number of a key
w.set_cell("Boosters", w.find_row("Boosters", "BO19"), "F", "M33", style_from=4)
w.append_row("Modifiers", {"A": "M99", "B": "Name", "M": 1}, style_row=w.last_data_row("Modifiers"))
w.save()
```

Text goes in as inline strings; `sharedStrings.xml` is never touched. Numbers go in as numbers (not text).

## After every edit

1. `python3 tools/export_data.py` must end with "No errors".
2. Confirm only the sheets you meant changed (compare the zip members byte for byte; `selftest.py` shows the idea).
3. `tools/verify.sh`, then commit the workbook **and** the regenerated `data/*.json` together.
4. Keep a copy before a big edit (`cp ... /tmp/...`), because the workbook is binary and a bad edit is hard to diff.

`python3 tools/workbook/selftest.py` checks the helper against a throwaway copy.

Adding a whole new sheet, header comments (notes) and the other bigger operations were done with hand-built XML parts; the batch scripts in `archive/` show how.

## `archive/`: the scripts that built the content batches

Historical record, **not runnable as they stand** (they hard-code scratch paths such as `/tmp/claude-0/...` and read draft workbooks). Kept so a future session can see how each batch was generated and reuse the techniques:

| Folder | What it built |
|---|---|
| `b1/` | Batch 1: transition pools, eight topic rooms, committee questions, cues |
| `b2/` | Batch 2: twenty bills BI31-BI50, party-position model, law effects, reports |
| `b3/` | Batch 3: 69 rooms and 20 levels for the new bills, topic cues |
| `b4/` | Visitors per bill, Level Intro cues |
| `b5/` | Opponent-specific cues |
| `b6/` | Gap-filling batch: questions, transitions, ticker |
| `audits/` | Read-only audit scripts (content gaps, tone, depth, consistency) |

Guides for writing the content itself: `design/WORKBOOK_EXPANSION_GUIDE.md`, `design/EDITING_TEXT.md`.

## Excel's "repair" message

`python3 tools/workbook/check_formulas.py` finds what makes Excel say "Removed Records: Shared formula ..." or "Formula from /xl/calcChain.xml": a shared formula whose range does not contain its own cells, or a calcChain entry for a cell that no longer holds a formula. `WB.save()` now drops `calcChain.xml` on every save (Excel rebuilds it silently); `tools/verify.sh` runs the check.
