#!/usr/bin/env python3
"""P16 (2026-11-23): merge Cameron's Capitol venues content package into the workbook.

Reads CAPITOL_VENUES_CONTENT_2026-11-23.xlsx (Venues 6 rows, Venue Activities 6, Venue Lines 90, Hint Text 56, Rules 7), adds the three
new tabs with wbx.add_sheet, then appends the Hint Text rows to the Text tab and the seven Rules rows. Every line is a draft for Cameron.
Run once from the repo root: python3 tools/workbook/archive/p16_capitol_venues_import.py <path to the content xlsx>
"""
import sys
sys.path.insert(0, "tools/workbook")
import openpyxl
from wbx import WB, add_sheet

SOURCE = sys.argv[1]
PATH = "design/Game_Workbook.xlsx"
src = openpyxl.load_workbook(SOURCE, data_only=True)
NUMERIC = {"Order", "Hours", "Funds", "XP", "Per Day", "Per Week", "Condition Value", "Weight"}


def table(name, widths):
    ws = src[name]
    headers = [str(c.value) for c in ws[1]]
    rows = []
    for raw in ws.iter_rows(min_row=2, values_only=True):
        if all(v is None or v == "" for v in raw):
            continue
        row = []
        for header, v in zip(headers, raw):
            if v is None or v == "":
                row.append(None)
            elif header in NUMERIC and str(v).replace(".", "", 1).lstrip("-").isdigit():
                row.append(int(float(v)))
            else:
                row.append(str(v))
        rows.append(row)
    add_sheet(PATH, name, headers, rows, widths)
    print(name, len(rows), "rows")


table("Venues", [10, 24, 16, 20, 18, 7, 16, 22, 50, 10, 10])
table("Venue Activities", [11, 10, 8, 24, 12, 12, 7, 7, 6, 8, 9, 14, 14, 12, 14])
table("Venue Lines", [9, 11, 9, 10, 90, 12, 14, 9, 10, 10, 10, 10, 9, 11, 7, 6, 13, 12, 12, 10, 40])

w = WB(PATH)
DRAFT = "P16 (2026-11-23): Claude's draft for Cameron to rewrite."
ws = src["Hint Text"]
count = 0
for key, english, use in ws.iter_rows(min_row=2, values_only=True):
    if not key:
        continue
    placeholder = "stage" if "{stage}" in english else ("name" if "{name}" in english else "")
    cells = {"A": key, "B": use, "C": english, "E": DRAFT}
    if placeholder:
        cells["D"] = placeholder
    w.append_row("Text", cells, style_row=w.last_data_row("Text"))
    count += 1
print("Text rows", count)

RULES = [
    ("venue_walk_hours_building", 0, "Hours from the Capitol office to the Capitol Building (Step out)."),
    ("venue_walk_hours_area", 0, "Hours from the Capitol Building to the Capital Area."),
    ("venue_daily_set", 12, "Lines dealt per line-giving venue per day."),
    ("venue_daily_heard", 8, "Lines a player can hear per venue per day before the dry pool."),
    ("venue_hint_share", 8, "One in N dealt lines is a rhetoric tip (8 means one in eight)."),
    ("tips_max_held", 10, "Rhetoric tips held at once; a new one replaces the oldest."),
    ("tips_days", 14, "Days a rhetoric tip lasts on the game calendar."),
]
for key, value, means in RULES:
    w.append_row("Rules", {"A": key, "B": value, "C": "a whole number", "D": means, "F": "P16 (2026-11-23, Cameron)."},
                 style_row=w.last_data_row("Rules"))
w.save()
print("done")
