#!/usr/bin/env python3
"""Proves wbx.py edits a COPY of the workbook safely: one appended Modifiers row
reads back, and no sheet other than Modifiers changes.

    python3 tools/workbook/selftest.py
"""
import shutil, sys, tempfile, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from wbx import WB

SRC = ROOT / "design" / "Game_Workbook.xlsx"

with tempfile.TemporaryDirectory() as tmp:
    copy = Path(tmp) / "copy.xlsx"
    shutil.copy(SRC, copy)
    w = WB(str(copy))
    row = w.append_row("Modifiers", {"A": "M99", "B": "Selftest backing", "K": "STAGE_START_BONUS",
                                     "L": "ST02", "M": 1}, style_row=w.last_data_row("Modifiers"))
    w.save()
    back = WB(str(copy)).rows("Modifiers")[row]
    assert back.get("A") == "M99" and back.get("M") == "1", back
    a, b = zipfile.ZipFile(SRC), zipfile.ZipFile(copy)
    changed = sorted(n for n in a.namelist() if a.read(n) != b.read(n))
    assert len(changed) == 1 and changed[0].startswith("xl/worksheets/"), changed
    print("wbx selftest OK: one new row, only", changed[0], "changed")

# copy_row: types kept, formulas become plain values, overrides by header or letter
with tempfile.TemporaryDirectory() as tmp:
    copy = Path(tmp) / "copy.xlsx"
    shutil.copy(SRC, copy)
    w = WB(str(copy))
    src_row = w.find_row("Stages", "ST05")
    before = w.typed_row("Stages", src_row)
    new_row = w.copy_row("Stages", "ST05", {"A": "ST999", "Stage (EN)": "Selftest Town Hall"})
    w.save()
    w2 = WB(str(copy))
    after = w2.typed_row("Stages", new_row)
    assert after["A"] == "ST999" and after["B"] == "Selftest Town Hall", after
    numeric = [c for c, v in before.items() if isinstance(v, (int, float)) and c not in ("W",)]
    assert numeric, "the source row has numeric cells"
    for c in numeric:
        assert after[c] == before[c] and not isinstance(after[c], str), (c, before[c], after[c])
    try:
        w2.copy_row("Stages", "ST05", {})
        raise SystemExit("copy_row should refuse a copy that keeps the key")
    except ValueError:
        pass
    x = w2._x("Stages")
    import re as _re
    mrow = _re.search(r'<row r="%d"[^>]*>(.*?)</row>' % new_row, x, _re.S).group(1)
    assert "<f" not in mrow, "no formula is carried into the copy"
    print("wbx copy_row OK: types kept, no formulas, key enforced")

