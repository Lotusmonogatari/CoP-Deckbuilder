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

SRC = ROOT / "design" / "CoP_Starter_Card_Stage_Data.xlsx"

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
