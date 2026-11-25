#!/usr/bin/env python3
"""Run statistics (2026-11-25, Cameron): the Text rows for the Your Statistics screen and the exported report. Run once from the repo root,
then python3 tools/export_data.py --accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

T = "Cameron 2026-11-25 (run statistics); a draft for Cameron to reword."
w = WB("design/Game_Workbook.xlsx")
rows = [
    ("admin.label_statistics", "Administration: the statistics row", "Your Statistics", None),
    ("stats.title", "Statistics screen: title", "Your Statistics", None),
    ("stats.blurb", "Statistics screen: what it is", "What this run has counted so far. A new game starts the count again.", None),
    ("stats.nothing", "Statistics screen: a list with nothing in it", "Nothing yet.", None),
    ("stats.suits_heading", "Statistics: cards played by suit", "Cards played by suit", None),
    ("stats.suits_most", "Statistics: the suit played most", "Played most", None),
    ("stats.items_heading", "Statistics: items used", "Items used", None),
    ("stats.people_heading", "Statistics: people met", "People met", None),
    ("stats.promises_heading", "Statistics: promises", "Promises", None),
    ("stats.promises_kept", "Statistics: promises kept", "Kept", None),
    ("stats.promises_broken", "Statistics: promises broken", "Broken", None),
    ("stats.gaffes_heading", "Statistics: gaffes", "Gaffes", None),
    ("stats.gaffes_made", "Statistics: gaffes made over the run", "Gaffes made", None),
    ("stats.gaffes_lost", "Statistics: stages lost to the gaffe meter", "Stages lost to the gaffe meter", None),
    ("stats.wins_heading", "Statistics: how stages were won", "Stages won", None),
    ("stats.win_threshold", "Statistics: won by reaching the threshold", "By reaching the threshold", None),
    ("stats.win_zero", "Statistics: won by arguing the opponent down to nothing", "By arguing the opponent down to nothing", None),
    ("stats.win_other", "Statistics: won in a room with neither", "In a room with neither", None),
    ("stats.venues_heading", "Statistics: places gone to", "Places gone to", None),
    ("stats.activities_heading", "Statistics: activities done", "Activities done", None),
    ("stats.export_button", "Statistics screen: the export button", "Export report", None),
    ("stats.export_hint", "Statistics screen: what the export button does", "Saves these numbers as a text file and copies them to the clipboard.", None),
    ("stats.exported_downloads", "Statistics export: saved to Downloads", "Saved to your Downloads folder as {file}. A copy is on the clipboard.", "file"),
    ("stats.exported_app", "Statistics export: saved only in the game's folder", "Saved in the game's own folder as {file}. A copy is on the clipboard.", "file"),
    ("stats.export_failed", "Statistics export: the file could not be written", "The file could not be saved. A copy is on the clipboard.", None),
    ("stats.report_title", "Statistics report: first line", "Coliseum of Parliament: run statistics", None),
    ("stats.report_player", "Statistics report: who played", "Legislator: {name}", "name"),
]
last = w.last_data_row("Text")
for key, where, eng, ph in rows:
    last += 1
    d = {"A": key, "B": where, "C": eng, "E": T}
    if ph:
        d["D"] = ph
    w.append_row("Text", d, style_row=last - 1)
w.save()
print("added", len(rows), "Text rows")
