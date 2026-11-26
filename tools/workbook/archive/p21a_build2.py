#!/usr/bin/env python3
"""P21 phase A step 2 (2026-11-26, Cameron): the Balance rows, the two new columns (Shop: Cost Step XP; Awareness Effects: Once Per), the dues limit
as a share of the Funds cap, and the Funds ceiling of 2,000,000. Run once from the repo root, then python3 tools/export_data.py
--accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, n2col, col2n

w = WB("design/Game_Workbook.xlsx")
NOTE = "P21 phase A (2026-11-26, Cameron's economy guidance); a number Cameron can tune."


def add_header(sheet, name):
    head = w.rows(sheet)[1]
    last = sorted(head, key=lambda c: (len(c), c))[-1]
    style = w.sty(sheet, last + "1")
    at = col2n(last) + 1
    w.set_cell(sheet, 1, n2col(at), name, style=style)
    return n2col(at)


balance = [
    ("XP Decay Percent", 15, "Share of the Political Capital above the floor that fades at each week's end."),
    ("XP Decay Floor", 300, "Political Capital up to this much never fades."),
    ("Party Support Decay At 50", 5, "Party support lost each week end while it is 50 to 74 (never below 50 from this rule)."),
    ("Party Support Decay At 75", 8, "Party support lost each week end while it is 75 or more (never below 50 from this rule)."),
    ("Awareness Decay Percent", 2, "Share of the distance above its start that District and National awareness lose each week end (rounded down, at least 1 above the start)."),
    ("Awareness Start District", 20, "District awareness at the start of a run; its decay stops here."),
    ("Awareness Start National", 10, "National awareness at the start of a run; its decay stops here."),
    ("Decay Hold XP", 200, "Political Capital to stop one meter's decay at this week's end."),
    ("Decay Hold Step XP", 50, "Added for each consecutive week the same meter is held."),
    ("Keep In Touch XP", 60, "Political Capital to stop one organization's decay at this week's end."),
    ("Keep In Touch Step XP", 20, "Added for each consecutive week the same organization is held."),
    ("Dues Limit Cap Percent", 90, "The weekly dues limit as a share of the player's current Funds cap (replaces Dues Max Per Week)."),
    ("Dues Bailout XP", 100, "Political Capital for one dues bailout."),
    ("Dues Bailout Yen", 10000, "Dues owed that one bailout writes off."),
    ("Funds Petition Ceiling", 1000000, "The Funds cap the petition can raise to; the two cap calls go beyond it."),
    ("Cap Call Min Support", 70, "Party support the player must be over to call on the party."),
    ("Cap Call Party Support", 50, "Party support paid to call on the party."),
    ("Cap Call XP", 200, "Political Capital paid to call on the party."),
    ("Cap Call Yen", 500000, "Funds cap added by calling on the party (once per run)."),
    ("Cap Call Finance Min Standing", 70, "Standing with the Financial Industry Association the player must be over."),
    ("Cap Call Finance Standing", 40, "Standing with the Financial Industry Association paid."),
    ("Cap Call Finance XP", 150, "Political Capital paid to call on the financial industry."),
    ("Cap Call Finance Yen", 500000, "Funds cap added by calling on the financial industry (once per run)."),
    ("XP Price Relaxed Percent", 85, "Every Political Capital price in P21 on Relaxed (rounded to the nearest 5)."),
    ("XP Price Harder Percent", 115, "Every Political Capital price in P21 on Harder (rounded to the nearest 5)."),
]
have = {c.get("A") for c in w.rows("Balance").values()}
for label, value, note in balance:
    if label not in have:
        w.append_row("Balance", {"A": label, "B": value, "C": NOTE + " " + note})

# The dues limit is a share of the Funds cap now: the old flat row goes.
w.delete_row("Balance", w.find_row("Balance", "Dues: Max Per Week"))

# The Funds ceiling: the petition stops at 1,000,000 (Funds Petition Ceiling); the two cap calls go to 2,000,000.
w.set_cell("Sanban", w.find_row("Sanban", "Funds"), "F", 2000000)

# Shop: Cost Step XP (SH13 rises 50 Political Capital each purchase)
column = add_header("Shop", "Cost Step XP")
w.set_cell("Shop", w.find_row("Shop", "SH13"), column, 50)

# Awareness Effects: Once Per (AE02, the District 80 coupon, pays at most once a calendar month)
column = add_header("Awareness Effects", "Once Per")
w.set_cell("Awareness Effects", w.find_row("Awareness Effects", "AE02"), column, "month")
w.save()
print("done")
