#!/usr/bin/env python3
"""Speech Coach activities (2026-11-24, Cameron): beside regular training, Practice your talking points (-1 hour, -10,000円, +1 to the gaffe
limit for the next stage) and Work on your speech timing (-20,000円, -1 hour, +1 turn for the next stage). Cameron gave a daily limit only
for the first; the second is once a day too, so the bonus cannot be stacked without end (his call to change).
Run once from the repo root: python3 tools/workbook/archive/speech_coach_activities_build.py
Then python3 tools/export_data.py (must say "No errors"). Wording is Claude's draft for Cameron to reword."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "Speech Coach activities (2026-11-24): Claude's draft for Cameron to reword."
w.append_row("Venue Activities", {"A": "VA16", "B": "VN04", "C": "act", "D": "Practice your talking points", "E": "ACT_TRAIN",
                                  "G": 1, "H": 10000, "J": 1, "P": "GAFFE_CAP",
                                  "U": "You practice your talking points aloud until each one comes out clean. Tomorrow's slips will be fewer."},
             style_row=w.last_data_row("Venue Activities"))
w.append_row("Venue Activities", {"A": "VA17", "B": "VN04", "C": "act", "D": "Work on your speech timing", "E": "ACT_TRAIN",
                                  "G": 1, "H": 20000, "J": 1, "P": "TURNS",
                                  "U": "You work on the pauses between your sentences. You will have more room to make your points."},
             style_row=w.last_data_row("Venue Activities"))
for key, where, english, placeholders in [
    ("venue.effect_gaffe_limit", "Venue activity effect: the gaffe limit in the next stage", "Gaffe limit in your next stage {delta}", "delta"),
    ("venue.effect_turns", "Venue activity effect: turns in the next stage", "Turns in your next stage {delta}", "delta"),
    ("venue.act_open", "Venue activity that opens a page (Rhetoric Training): the button", "Open", None),
]:
    cells = {"A": key, "B": where, "C": english, "E": NOTE}
    if placeholders:
        cells["D"] = placeholders
    w.append_row("Text", cells, style_row=w.last_data_row("Text"))
w.save()
print("workbook updated")
