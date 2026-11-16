#!/usr/bin/env python3
"""Text rows for the Staff Assignments screen (Cameron, 2026-11-16). Claude's
draft. Safe to run again: existing keys are overwritten."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-16 staff assignments (Cameron). Claude's draft."
ROWS = [
    ("assign.confirmed_already", "Staff Assignments, confirm button when already locked", "Today's work is already locked in", ""),
    ("assign.no_tasks", "Staff Assignments, confirm button with no tasks", "There are no tasks today", ""),
    ("assign.nothing_assigned", "Staff Assignments, confirm button with nothing given out", "Give someone a task first", ""),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Text")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for key, where, english, placeholders in ROWS:
        values = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            values["D"] = placeholders
        if key in by_key:
            for col, value in values.items():
                w.set_cell("Text", by_key[key], col, value)
        else:
            w.append_row("Text", values, style_row=w.last_data_row("Text"))
    w.save()
    print("ok", len(ROWS))

if __name__ == "__main__":
    main()
