#!/usr/bin/env python3
"""Two offices, slice 1 (2026-11-20): the Text rows for the trip button and popup, the refusals, the place lines and the
briefing's badge and travel line. Claude's draft for Cameron to rewrite. Refuses to run twice.
Then: python3 tools/export_data.py --accept-wording"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-20 two offices (Claude's draft)"

ROWS = [
    ("travel.button", "Office, the button under Choose a level: where a trip goes, its hours and how", "To {place} · {count} h · {mode}", "place, count, mode"),
    ("travel.confirm_title", "Trip popup, heading", "Take the trip?", ""),
    ("travel.confirm_line", "Trip popup: where, how long, how, and what it costs", "Go to {place}: {count} h by {mode}. {cost}", "place, count, mode, cost"),
    ("travel.cost_free", "Trip popup: the rail pass costs no Funds", "Free on the member's rail pass.", ""),
    ("travel.after_line", "Trip popup: the week's hours left after the trip", "You will have {count} h left this week.", "count"),
    ("travel.level_waiting", "Trip popup: a crisis level is waiting at the office the trip goes to", "A level is waiting for you at {place}: {level}.", "place, level"),
    ("travel.confirm_go", "Trip popup, the button that takes the trip", "Take the trip", ""),
    ("travel.confirm_stay", "Trip popup, the button that stays", "Stay here", ""),
    ("travel.refuse_in_level", "Trip button, greyed: a level is in progress", "Finish the level in progress first.", ""),
    ("travel.refuse_weekend", "Trip button, greyed: no travel at the weekend", "No travel at the weekend.", ""),
    ("travel.refuse_hours", "Trip button, greyed: the week has too few hours left", "The trip takes {count} h and the week has less left.", "count"),
    ("travel.refuse_elsewhere_capitol", "A level that starts at the Capitol, seen from the District office", "This level starts at the Capitol. Travel there first.", ""),
    ("travel.refuse_elsewhere_district", "A level that starts at the District office, seen from the Capitol", "This level starts at your District office. Travel there first.", ""),
    ("travel.mode_pass", "A way to travel: the member's rail pass", "Rail pass", ""),
    ("travel.mode_ticket", "A way to travel: a paid train ticket", "Paid train ticket", ""),
    ("travel.mode_car", "A way to travel: a private car", "Private car", ""),
    ("travel.mode_plane", "A way to travel: a plane ticket", "Plane ticket", ""),
    ("travel.place_capitol", "A trip's destination", "the Capitol", ""),
    ("travel.district_plain", "A trip's destination when the protagonist has no District office town in the data", "your District office", ""),
    ("travel.here_capitol", "Office, the line about where you are", "You are at the Capitol.", ""),
    ("travel.here_district", "Office, the line about where you are", "You are at your District office in {place}.", "place"),
    ("travel.here_district_plain", "Office, the line about where you are, no town in the data", "You are at your District office.", ""),
    ("travel.forced_move", "Office: an appointment at one office has taken you there", "This appointment is at {place}, so you have been taken there.", "place"),
    ("briefing.location_capitol", "Level briefing and level list: a level that starts at the Capitol", "Capitol", ""),
    ("briefing.location_district", "Level briefing and level list: a level that starts at the District office", "District office", ""),
    ("briefing.location_either", "Level list: a level that starts at either office", "Either office", ""),
    ("briefing.travel_included", "Level briefing, under the meta line: a mixed level's trips are in its hours", "Includes {count} h of travel by {mode}", "count, mode"),
    ("office.level_travel_line", "Level list: a mixed level's trips are in its hours", "includes {count} h of travel between the offices", "count"),
]

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")
    for key, *_ in ROWS:
        try:
            w.find_row("Text", key)
            raise SystemExit("already there: " + key)
        except KeyError:
            pass
    style = w.last_data_row("Text")
    for key, where, english, placeholders in ROWS:
        cells = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            cells["D"] = placeholders
        w.append_row("Text", cells, style_row=style)
    w.save()
    print("added %d Text rows" % len(ROWS))
