#!/usr/bin/env python3
"""Cafeteria seats and meals, and Catch Up on Paperwork (2026-11-25, Cameron's playtest ideas). Adds the Venue Choices tab (seats and meals,
workbook-driven so any venue can use them), the Chance and Extra Rewards columns on Venue Activities and the paperwork activity row (VA19), and
the Text rows. Every name, blurb, reward and sentence is Claude's draft for Cameron to rewrite; the odds are Cameron's (1 in 10 for meals and
paperwork). Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

NOTE = "Claude's draft for Cameron to reword (2026-11-25, playtest idea)."
HEAD = ["Choice ID", "Venue ID", "Step", "Name", "Blurb", "Party", "Weight", "Rewards", "Party Opinion", "XP", "Chance", "Extra Rewards",
        "Extra Party Opinion", "Extra Tip", "Note"]
PARTIES = [("PT01", "Butsutou"), ("PT02", "Yezo Heritage Party"), ("PT03", "Frontier Party"), ("PT04", "Five Point Independents"),
           ("PT05", "Keizaijiyuutou"), ("PT06", "Country Initiative")]
ROWS = []
n = 0
for pid, pname in PARTIES:
    n += 1
    ROWS.append(["VC%02d" % n, "VN01", "seat", "A {party} member's table", "A member of {party} waves you over to a free chair.", pid, 1, "", 1, "", 5, "", "", "opponent", NOTE])
ROWS += [
    ["VC07", "VN01", "seat", "The mixed-party table", "Members of several parties argue amicably over one tray of tea.", "", 1, "BO17 +1", "", "", 5, "", 1, "", NOTE],
    ["VC08", "VN01", "seat", "The young staffers' table", "Interns and junior aides compare which committee is the worst.", "", 1, "", "", 5, 3, "", "", "stage", NOTE],
    ["VC09", "VN01", "seat", "A member and a staffer", "A member and an aide are going over tomorrow's schedule between bites.", "", 1, "BO17 +1", "", "", 3, "", "", "stage", NOTE],
    ["VC10", "VN01", "seat", "The older staffers' table", "Long-serving staff, who have seen every kind of sitting.", "", 1, "", "", 5, 3, "", "", "stage", NOTE],
    ["VC11", "VN01", "seat", "Anywhere open", "Whichever chair is free. You hear what is said around you.", "", 1, "", "", "", "", "", "", "", NOTE],
]
MEALS = [
    ("Persimmon and fruit medley", "Sweet, cold and cut by someone who cares.", "BO10 +1"),
    ("Grilled salmon set", "Salmon, rice and pickles, the way the coast does it.", "BO07 +1"),
    ("Sito dumplings", "Soft millet dumplings in a savory broth.", "BO28|BO29 +1"),
    ("Genghis Khan grilled lamb set", "Sizzling lamb and onions, a Hokkaido classic.", "BO30 +1"),
    ("Miso ramen", "A big bowl, a little salty, very hot.", "BO27 +1"),
    ("Tofu and vegetable plate", "Light, plain and gentle on the stomach.", "BO21 +1"),
    ("Soup curry", "Chicken, vegetables and spice in a thin golden soup.", "BO25 +1"),
    ("Set lunch", "Today's fixed lunch: fish, rice, soup and pickles.", ""),
    ("Rice ball and miso soup", "Quick, warm and eaten standing up.", ""),
    ("Coffee and a sandwich", "The cafeteria's strong coffee and an egg sandwich.", ""),
]
for i, (name, blurb, extra) in enumerate(MEALS):
    ROWS.append(["VC%02d" % (20 + i), "VN01", "meal", name, blurb, "", 1, "", "", "", 10 if extra else "", extra, "", "", NOTE])
add_sheet("design/Game_Workbook.xlsx", "Venue Choices", HEAD, ROWS, [10, 10, 8, 30, 50, 8, 8, 14, 12, 6, 8, 18, 12, 10, 40])

w = WB("design/Game_Workbook.xlsx")
# Venue Activities: Chance and Extra Rewards columns, and the paperwork row (Venue ID OFFICE, Kind office)
head = w.rows("Venue Activities")[1]
col_next = lambda: None
letters = sorted(head, key=lambda c: (len(c), c))
last = letters[-1]
from wbx import n2col, col2n
c1, c2 = n2col(col2n(last) + 1), n2col(col2n(last) + 2)
w.set_cell("Venue Activities", 1, c1, "Chance", style=w.sty("Venue Activities", last + "1"))
w.set_cell("Venue Activities", 1, c2, "Extra Rewards", style=w.sty("Venue Activities", last + "1"))
cols = {name: letter for letter, name in head.items()}
vals = {"A": "VA19", "B": "OFFICE", "C": "office", "D": "Catch Up on Paperwork", "E": "ACT_PAPERWORK", cols["Hours"]: 1,
        cols["Result Text"]: "An hour of forms, filing and replies, and the desk is clearer.", c1: 10, c2: "BO01|BO02|BO31|BO32|BO17 +1"}
w.append_row("Venue Activities", vals, style_row=w.last_data_row("Venue Activities"))
w.save()
print("Venue Choices tab, Chance/Extra Rewards columns and VA19 added; chance column letters", c1, c2)
