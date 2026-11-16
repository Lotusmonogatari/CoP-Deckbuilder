#!/usr/bin/env python3
"""Task family names (Cameron, 2026-11-16): a Family column on the Staff
Assignments tab, one word per icon family, shown under a task's icon in a
staff box. Safe to run again."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

FAMILY = {"LL01": "Correspondence", "LL02": "Press", "LL03": "Analysis", "LL04": "Meetings",
          "LL05": "Constituents", "LL06": "Administration", "LL07": "Chores", "LL08": "Rest"}

def main():
    w = WB("design/Game_Workbook.xlsx")
    w.set_cell("Staff Assignments", 1, "O", "Family", style_from=1)
    for row, values in w.rows("Staff Assignments").items():
        if values.get("A", "").startswith("TK"):
            w.set_cell("Staff Assignments", row, "O", FAMILY[values["C"]], style_from=2)
    w.save()
    print("ok")

if __name__ == "__main__":
    main()
