#!/usr/bin/env python3
"""Two offices, slice 6 (2026-11-20): the eight protagonist levels (LV115 to LV122) from the spec ("Levels per protagonist: one
District fight, one Capitol policy") and a Protagonist column on Levels (blank = everyone). PC01 and PC04 swapped districts
(Cameron, 2026-11-20), so the Wakkanai levels (the Soya Line, the Sakhalin Ferry) belong to PC04 and the Aomori levels
(Rokkasho, Oma's bluefin quota) to PC01. Built from existing stages. Win ranges follow the spec; the meta bonus, cooldown and
unlock costs are copied from LV11 (tier 1) or LV21 (tier 2). **Claude's drafts for Cameron.** Not built: weekend play for LV117 and LV119 (the spec asked for it, but a weekend level must fit a 4-hour day and these are 11 hours), a level that needs
discovery by an event (the Rokkasho level), the spec's "unique hooks", the Rokkasho Mixed variant. Refuses to run twice.
Then: python3 tools/export_data.py --accept-wording"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, col2n, n2col

DISTRICT_SPEAKER = "District Representative"
CAPITOL_SPEAKER = "Policy Research Assistant"

# id, protagonist, description, tier, location, stages, wins {BOxx: "min-max"}, weekend, seasons, purpose
LEVELS = [
    ("LV115", "PC04", "Keep the Sōya Line Running", 1, "District", ["ST267", "ST24", "ST19", "ST25", "ST20", "ST05"],
     {"BO14": "3-7", "BO30": "2-6", "BO04": "2-5", "BO18": "2-5", "BO10": "1-3"}, "", "",
     "The trains to Wakkanai are on the list again. Ride it, count who's on it, and come back with a deal the towns can pay for."),
    ("LV116", "PC04", "The Sakhalin Ferry", 2, "Capitol", ["ST20", "ST21", "ST14", "ST04", "ST03"],
     {"BO05": "2-6", "BO07": "2-5", "BO25": "2-5", "BO04": "1-4", "BO08": "1-3"}, "", "",
     "From {place:landmark} you can see Sakhalin on a clear day. The ferry is gone. Bring it back, if the Capitol will let you."),
    ("LV117", "PC02", "Carbon Under the Harbor", 1, "District", ["ST267", "ST20", "ST29", "ST19", "ST53", "ST21"],
     {"BO16": "3-6", "BO09": "2-5", "BO05": "2-5", "BO07": "1-4", "BO26": "1-3"}, "", "",
     "They want to bury more carbon under {place:harbor}. The port wants the jobs; the clam boats want guarantees. Find a deal both can sign."),
    ("LV118", "PC02", "A Casino by Lake Utonai?", 2, "Capitol", ["ST233", "ST235", "ST234", "ST236", "ST238"],
     {"BO05": "3-7", "BO09": "2-5", "BO25": "2-5", "BO04": "1-4", "BO26": "-2--1", "BO19": "-2--1"}, "", "",
     "The resort is back, and Tomakomai wants it. Win the site in the Capitol without losing {place:landmark}."),
    ("LV119", "PC03", "Wind on Ishikari Bay", 1, "District", ["ST20", "ST29", "ST19", "ST149", "ST21", "ST276"],
     {"BO07": "3-7", "BO16": "2-5", "BO05": "1-4", "BO06": "1-4", "BO18": "1-3"}, "", "Autumn",
     "The developers want a second wind farm off {place:beach}. The port wants the work and the city wants the power; the salmon netters at the river mouth want their water left alone. Settle it here, before the Capitol settles it for you."),
    ("LV120", "PC03", "The Tunnel Under Teine", 2, "Capitol", ["ST138", "ST21", "ST137", "ST139", "ST04"],
     {"BO14": "3-6", "BO05": "2-5", "BO06": "2-5", "BO23": "1-3", "BO18": "1-3"}, "", "",
     "The bullet train is eight years late and digging under Teine. Make the Capitol pay its share, and make sure Teine gets more than noise."),
    ("LV121", "PC01", "The Rokkasho Question", 2, "District", ["ST267", "ST05", "ST19", "ST20", "ST21", "ST29"],
     {"BO30": "3-7", "BO04": "2-5", "BO07": "2-6", "BO18": "2-5", "BO16": "1-3"}, "", "",
     "The fuel plant at Rokkasho has slipped again. The village wants its grants and its jobs; the fishers want proof about the sea. Hear Rokkasho out, then answer for it."),
    ("LV122", "PC01", "Ōma's Bluefin Quota", 1, "Capitol", ["ST28", "ST57", "ST14", "ST04"],
     {"BO07": "3-7", "BO30": "1-4", "BO25": "1-3", "BO18": "1-3"}, "", "Autumn; Winter",
     "There's more tuna and more quota. Make sure Ōma's pole-and-line boats get their share, not just the big nets."),
]
REFERENCE = {1: "LV11", 2: "LV21"}

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Levels")
    head = rows[1]
    by = {t: l for l, t in head.items()}
    if "Protagonist" in by:
        raise SystemExit("already there: Protagonist")
    prot_col = n2col(max(col2n(c) for c in head) + 1)
    w.set_cell("Levels", 1, prot_col, "Protagonist", style_from=1)
    org_cols = {title.split("Δ")[1]: letter for letter, title in head.items() if title.startswith("Win Δ")}
    for level_id, pid, name, tier, location, stages, wins, weekend, seasons, purpose in LEVELS:
        overrides = {by["Level ID"]: level_id, by["Level Description"]: name, by["Level Tier"]: tier,
                     by["One-Time (Yes/No)"]: "No", by["Location"]: location, by["Level Purpose"]: purpose,
                     by["Purpose Speaker"]: DISTRICT_SPEAKER if location == "District" else CAPITOL_SPEAKER,
                     by["Weekend OK (Yes/No)"]: weekend or "No", by["Needs Discovery (Yes/No)"]: "No",
                     by["Event Only (Yes/No)"]: "No", prot_col: pid}
        for number in range(1, 11):
            overrides[by["Stage ID for Part %d" % number]] = stages[number - 1] if number <= len(stages) else "N/A"
        for org, letter in org_cols.items():
            overrides[letter] = wins.get(org, "0")
        if seasons:
            overrides[by["Seasons"]] = seasons
        elif "Seasons" in by:
            overrides[by["Seasons"]] = None
        # a copied row keeps no Travel Trips (a District or Capitol level here has none)
        overrides[by["Travel Trips"]] = None
        w.copy_row("Levels", REFERENCE[tier], overrides)
    w.save()
    print("added %d levels" % len(LEVELS))
