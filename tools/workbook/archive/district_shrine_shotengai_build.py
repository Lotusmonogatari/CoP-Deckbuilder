#!/usr/bin/env python3
"""District shrine and shotengai (2026-11-24, Cameron): two more places on the District office's Step out map, one picture each for every
protagonist (AREA_SHRINE_PC01 .. PC04, AREA_SHOTENGAI_PC01 .. PC04). Both are "Coming soon" until Cameron says what a visit does.
Run once from the repo root: python3 tools/workbook/archive/district_shrine_shotengai_build.py
Then python3 tools/export_data.py (must say "No errors"). Names, blurbs and the Japanese are Claude's drafts for Cameron to reword."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
# {PC_ID} is the protagonist's ID ("PC03"), the spelling of the pictures AREA_SHRINE_<PC_ID> and AREA_SHOTENGAI_<PC_ID>.
w.append_row("Venues", {"A": "VN08", "B": "Old Shrine", "C": "古い神社", "D": "Furui Jinja", "E": "District", "F": 8, "G": "VEN_SHRINE",
                        "H": "AREA_SHRINE_{PC_ID}", "I": "A long walk off the beaten track, and almost no one comes.", "J": "Any"},
             style_row=w.last_data_row("Venues"))
w.append_row("Venues", {"A": "VN09", "B": "Local Shotengai", "C": "商店街", "D": "Shōtengai", "E": "District", "F": 9, "G": "VEN_SHOTENGAI",
                        "H": "AREA_SHOTENGAI_{PC_ID}", "I": "Every shop knows your name, and your business.", "J": "Any"},
             style_row=w.last_data_row("Venues"))
w.append_row("Venue Activities", {"A": "VA08", "B": "VN08", "C": "shrine", "D": "Visit the Shrine", "E": "ACT_SHRINE"},
             style_row=w.last_data_row("Venue Activities"))
w.append_row("Venue Activities", {"A": "VA09", "B": "VN09", "C": "shotengai", "D": "Walk the Shotengai", "E": "ACT_SHOTENGAI"},
             style_row=w.last_data_row("Venue Activities"))
w.save()
print("workbook updated")
