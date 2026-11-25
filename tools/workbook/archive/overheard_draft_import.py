#!/usr/bin/env python3
"""Cameron's draft of overheard lines (2026-11-25, the 550-line sheet "Overheard lines: Capitol, Sapporo and the district"), taken apart and
written into the Venue Lines tab, and the Area Characters rows for the venue character pictures he uploaded.

Each draft row (Line ID OHnnn, Place, Line, Season, Venue ID) becomes a Venue Lines row: Pool `overheard`, Topic `gossip`, Speaker `area`
(someone from the place's pool), Where from the Place (below), Seasons from Season, Weight 1, and the draft ID in the Note. Places:
  The Capitol -> Capitol Building (the zone)   The Capitol garden -> VN03   The Capitol library -> VN02
  The Capital Area, Sapporo -> Capital Area (the zone)   Odori Park -> VN05 (the Sapporo Stage)
  Sapporo Station concourse -> VN06   Station tracks -> VN06/tracks   District office streets -> VN07 (the draft's Venue ID)
  Shotengai -> VN09   The old shrine in the forest -> VN08
40 lines used he, she, his, man, girl and the like for unnamed people; they are reworded (REWORD, Claude's draft for Cameron) because
the rule is that text about an unnamed person is genderless (test_events_genderless.gd). "women-only" (a train car) is kept.
Run once from the repo root: python3 tools/workbook/archive/overheard_draft_import.py <the draft .xlsx>, then python3 tools/export_data.py."""
import glob
import os
import sys

sys.path.insert(0, "tools/workbook")
import openpyxl  # noqa: E402
from wbx import WB  # noqa: E402

WHERE = {"The Capitol": "Capitol Building", "The Capitol garden": "VN03", "The Capitol library": "VN02", "The Capital Area": "Capital Area",
         "Sapporo": "Capital Area", "Odori Park": "VN05", "Sapporo Station concourse": "VN06", "Station tracks": "VN06/tracks",
         "District office streets": "VN07", "Shotengai": "VN09", "The old shrine in the forest": "VN08"}
REWORD = {
    "OH003": "They read every amendment. Nobody else does.",
    "OH007": "They want it in writing before they say anything.",
    "OH010": "The office says the member is in a meeting. They say that a lot.",
    "OH018": "Voted yes in committee and no on the floor. Explain that.",
    "OH030": "Can you read that handwriting? Neither can the writer.",
    "OH031": "That's not anger. That's just how they walk.",
    "OH037": "Someone is practicing a question for the minister in the stairwell.",
    "OH062": "Someone is on the phone, pacing around the pond.",
    "OH071": "Don't sit on that moss. The groundskeeper will yell.",
    "OH075": "Two laps around the pond when angry, three when furious.",
    "OH082": "Someone is feeding the sparrows from a bento.",
    "OH084": "I said not here, but they insisted.",
    "OH094": "Ask the groundskeeper. The groundskeeper knows who comes out here.",
    "OH108": "Someone is asleep on the reports again.",
    "OH121": "Someone is researching something they won't name.",
    "OH131": "Someone reads the old speeches out loud under their breath.",
    "OH163": "My grandparent still calls it by the old name.",
    "OH172": "They say Sapporo is too big. They're from Wakkanai.",
    "OH193": "Someone says Sapporo is the best city in Yezo. Discuss.",
    "OH203": "Someone is practicing a speech at the coach's studio.",
    "OH216": "Someone bows to every black car, just in case.",
    "OH223": "The coffee stand owner knows everyone's order and their politics.",
    "OH244": "Someone is waiting outside the studio for an interview.",
    "OH259": "Someone is selling balloons shaped like crabs.",
    "OH268": "That candidate is handing out tissues with their face on them.",
    "OH280": "That regular plays shogi here with anyone.",
    "OH318": "Someone is asleep on a suitcase.",
    "OH375": "Someone is waving goodbye until the train disappears.",
    "OH392": "Someone is crying a little. A long goodbye.",
    "OH407": "My child works in Sapporo. They rarely visit.",
    "OH412": "Do you think they remember us now that they're in the capital?",
    "OH417": "The old-timer at the tobacco shop has opinions.",
    "OH431": "My child wants to move to Sapporo. I want them to stay.",
    "OH458": "The shopkeeper at the rice cracker shop gave me extra.",
    "OH475": "The bookstore owner reads more than they sell.",
    "OH480": "Someone is fixing umbrellas on a stool.",
    "OH489": "A grandparent is bargaining hard over daikon.",
    "OH510": "My grandparents said this shrine protected the fields.",
    "OH519": "My father played here as a child.",
}
KEPT = {"OH382"}   # "The last car is women-only during rush hour." (a train car's rule, not a person)

src = sys.argv[1]
sheet = openpyxl.load_workbook(src, read_only=True, data_only=True).worksheets[0]
draft = []
for row in sheet.iter_rows(values_only=True):
    cells = (list(row) + [None] * 5)[:5]
    if cells[0] and str(cells[0]).startswith("OH") and cells[2]:
        draft.append(cells)
assert len(draft) == 550, len(draft)

w = WB("design/Game_Workbook.xlsx")
last = max(int(r["A"][2:]) for r in w.rows("Venue Lines").values() if str(r.get("A", "")).startswith("VL"))
for n, (oh, place, text, season, venue_id) in enumerate(draft, 1):
    assert place in WHERE, place
    text = REWORD.get(oh, text)
    values = {"A": "VL%03d" % (last + n), "B": "overheard", "C": "gossip", "D": "area", "E": text, "O": 1, "P": "N", "V": WHERE[place],
              "U": "Cameron's draft %s (2026-11-25), %s." % (oh, place)}
    if season:
        values["M"] = str(season)
    w.append_row("Venue Lines", values, style_row=w.last_data_row("Venue Lines"))

# Area Characters: a row for every picture in assets/characters/area (VEN01 is already there). The names are placeholders until Cameron names
# them (never an invented name); a zone person's Site is blank (the whole zone); the VEN rows' Sites are read from the pictures: his to confirm.
VEN = {"VEN02": ("Station attendant", "VN06; VN07", "a station attendant in uniform"),
       "VEN03": ("Shopkeeper", "VN09", "an older person in an apron carrying parcels"),
       "VEN04": ("Street musician", "VN05", "a busker with a shamisen and a microphone stand"),
       "VEN05": ("Shamisen player", "VN05", "a performer in a kimono with a shamisen"),
       "VEN06": ("Reporter", "VN01; VN03", "a woman with a phone and a camera, in a suit"),
       "VEN07": ("Reporter", "VN02; VN03", "a woman in a coat with a notebook")}
have = {r["A"] for r in w.rows("Area Characters").values() if str(r.get("A", "")).startswith(("VEN", "CA", "CB", "DI"))}
for path in sorted(glob.glob("assets/characters/area/*.png")):
    cid = os.path.basename(path)[:-4]
    if cid in have:
        continue
    if cid in VEN:
        name, site, seen = VEN[cid]
        note = "Placeholder name and Site, read from the picture (%s): Cameron to confirm or rename (2026-11-25)." % seen
    else:
        name, site = "Passerby", ""
        note = "Placeholder name: Cameron to name (picture uploaded 2026-11-25)."
    values = {"A": cid, "B": name, "F": site, "G": note}
    if site == "":
        values.pop("F")
    w.append_row("Area Characters", values, style_row=w.last_data_row("Area Characters"))
w.save()
print("imported", len(draft), "lines;", len(glob.glob("assets/characters/area/*.png")), "pictures")
