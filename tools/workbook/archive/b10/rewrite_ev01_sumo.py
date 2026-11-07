"""Rewrites EV01 (Sapporo Grand Sumo) to Cameron's own spec, 2026-11-07:
a sumo association lobbyist visit; A radio support, B welcome it and fund
tickets, C a reply about more pressing issues. Draft wording by Claude.
Archived copy: not runnable as it stands (see ../../README.md)."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

EVENT = {"B": "Sapporo Grand Sumo Wants an Answer",
 "C": "The sumo association's organizing committee sends a lobbyist to your office. The Sapporo Grand Sumo tournament, the lobbyist says, can return every year if legislators back it. Sumo is rooted deep in Japanese culture, and a yearly tournament keeps Yezo aligned with Japan, brings visitors into local shops while it is in town, and gives students an easy way into a sport.",
 "D": "Random", "E": "Both", "F": 1, "I": 5, "M": "OUT_FESTIVAL_1", "Q": "Summer"}

COLS = "CDEFGHIJKLMNOPQRST"
CHOICES = {
 2: {"B": "A", "C": "Go on the radio to back an annual tournament",
     "D": "You tell the radio audience that Sapporo should host the Grand Sumo tournament every year. The Traditional Society and the shopkeepers are delighted. The Care and Welfare Council and the Innovation Society are not.",
     "M": "BO15 +1; BO25 +1; BO21 -1; BO16 -1",
     "Q": "Promise Hours 2 within 72 for BO15",
     "R": "BO15 +1; BO25 +1", "S": "BO15 -3; BO25 -3; Reputation -2",
     "T": "You spend two hours at the radio station making the case for a yearly tournament, and the callers remember it."},
 3: {"B": "B", "C": "Welcome it this year and fund tickets for constituents",
     "D": "You tell the lobbyist Sapporo will welcome the tournament, and you buy a block of tickets for constituents. The Traditional Society, Students United and the Local Kōenkai are thrilled. The Taxpayers' Alliance, the Care and Welfare Council and the Innovation Society are not.",
     "M": "BO15 +2; BO11 +2; BO03 +2; BO23 -1; BO21 -1; BO16 -1",
     "Q": "Promise Hours 4 within 120 for BO15; Funds 100000",
     "R": "BO15 +1; BO11 +1; BO03 +1", "S": "BO15 -4; BO11 -4; BO03 -4; Reputation -2",
     "T": "You spend four hours handing out tickets and seeing constituents into the arena. Students fill the cheap seats, and the shopkeepers stay open late."},
 4: {"B": "C", "C": "Reply that you are focused on more pressing issues",
     "D": "You write back that other matters come first this year. The Care and Welfare Council and the Innovation Society approve. The Traditional Society and the shopkeepers take note.",
     "M": "BO21 +1; BO16 +1; BO15 -1; BO25 -1"},
}

w = WB("design/Game_Workbook.xlsx")
for col, value in EVENT.items():
    w.set_cell("Events", 2, col, value, style_from=4)
for row, cells in CHOICES.items():
    for col in COLS:
        w.set_cell("Event Choices", row, col, cells.get(col), style_from=8)
w.save()
print("EV01 rewritten")
