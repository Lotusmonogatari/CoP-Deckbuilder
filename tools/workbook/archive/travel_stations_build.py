#!/usr/bin/env python3
"""Travel at the stations (2026-11-24, Cameron): the District station venue, its Departures activity, the new Text rows and
the two How To Play entries that described the train strip. Run once from the repo root:
    python3 tools/workbook/archive/travel_stations_build.py
Then python3 tools/export_data.py (must say "No errors"). Every sentence is Claude's draft for Cameron to rewrite."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "Travel at the stations (2026-11-24): Claude's draft for Cameron to reword."

# --- Venues: one District station, whose name and picture follow the protagonist's District office -----------------------------
# {office} is the office's town ("Daikoku"); {OFFICE_ID} is the same in capitals with underscores ("AKENO_SHINMACHI"), the
# spelling of the picture AREA_<OFFICE_ID>_STATION.
w.append_row("Venues", {"A": "VN07", "B": "{office} Station", "C": "駅", "D": "Eki", "E": "District", "F": 7, "G": "VEN_STATION",
                        "H": "AREA_{OFFICE_ID}_STATION", "I": "The line to the Capitol begins here.", "J": "Any"},
             style_row=w.last_data_row("Venues"))
w.append_row("Venue Activities", {"A": "VA07", "B": "VN07", "C": "travel", "D": "Departures", "E": "ACT_TRAVEL"},
             style_row=w.last_data_row("Venue Activities"))

# --- Text rows -------------------------------------------------------------------------------------------------------------------
TEXT = [
    ("venue.zone_district", "Venue map: the heading over the District office's own places", "Around {office}", "office"),
    ("station.to_tracks", "Station concourse: the button that goes to the tracks", "To the tracks", None),
    ("station.tracks_title", "The tracks screen: the title", "The tracks", None),
    ("station.tracks_title_jp", "The tracks screen: the Japanese accent beside the title", "線路", None),
    ("station.tracks_blurb", "The tracks screen: the line under the picture", "Your train is waiting.", None),
    ("station.back_concourse", "The tracks screen: the way back to the concourse", "Back to the concourse", None),
    ("station.concourse_hint", "Station concourse: how a plane or a car leaves", "A plane or a car leaves from right here.", None),
    ("travel.mode_not_yours", "A way to travel this protagonist does not have (greyed)", "{mode} · not yours", "mode"),
]
for key, where, english, placeholders in TEXT:
    cells = {"A": key, "B": where, "C": english, "E": NOTE}
    if placeholders:
        cells["D"] = placeholders
    w.append_row("Text", cells, style_row=w.last_data_row("Text"))

# --- venue.refuse_elsewhere now means "a place of the other office" (it was "reached from the Capitol office") ---------------------
_row = w.find_row("Text", "venue.refuse_elsewhere")
w.set_cell("Text", _row, "B", "Venues: a place that belongs to the other office (the map lists only this office's places)")
w.set_cell("Text", _row, "C", "You cannot get there from this office.")

# --- How To Play: the strip is no longer under the level list (final wording, at most three sentences each) -----------------------
w.set_cell("How To Play", 37, "F",
           "Trips leave from the stations: press Step out, then go to Sapporo Super Station at the Capitol, or to the station at your "
           "District office. Choose how to go, then drag the train along the track and let go, or tap it to confirm. A trip spends "
           "hours from the same week as a level, its cost is shown before you go, and it is refused at the weekend and in the middle "
           "of a level.")
w.set_cell("How To Play", 38, "F",
           "Some levels have their trips built in: the briefing adds the travel to the level's hours and, if you own more than one way "
           "of going, lets you pick. The rail pass is free; a paid train ticket, a private car or a plane ticket from the Marketplace "
           "costs Funds, and a car or plane leaves from the station concourse with no tracks and can save hours. On the rail pass or "
           "a paid ticket, now and then a fellow passenger starts a conversation that needs an answer; a car or plane never does.")
w.save()
print("workbook updated")
