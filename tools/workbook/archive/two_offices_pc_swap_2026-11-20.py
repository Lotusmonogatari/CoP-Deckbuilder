#!/usr/bin/env python3
"""Two offices (2026-11-20, Cameron): PC01 and PC04 swapped districts in the workbook upload (PC01 is now the Aomori
protagonist, PC04 the Wakkanai one), so each one's district-flavoured starting item flips with it:
PC01 gets the Box of Aomori Apples (SH25) in place of the Wakkanai Milk Caramels (SH29), and PC04 the reverse.
Run from the repo root; it checks the old text first and refuses to run twice. Then: python3 tools/export_data.py"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
r1, r4 = w.find_row("Player", "PC01"), w.find_row("Player", "PC04")
rows = w.rows("Player")
assert rows[r1]["R"] == "SH21 x1; SH15 x2; SH17 x2; SH29 x1", rows[r1]["R"]
assert rows[r4]["R"] == "SH21 x1; SH25 x1", rows[r4]["R"]
w.set_cell("Player", r1, "R", "SH21 x1; SH15 x2; SH17 x2; SH25 x1")
w.set_cell("Player", r4, "R", "SH21 x1; SH29 x1")
w.save()
print("PC01 now starts with the Aomori apples, PC04 with the Wakkanai caramels")
