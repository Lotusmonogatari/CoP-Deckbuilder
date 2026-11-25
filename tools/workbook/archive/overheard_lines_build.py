#!/usr/bin/env python3
"""Overheard lines (2026-11-25, Cameron): a line drawn when the player goes to a place, on every N-th move, with the places and seasons in the
workbook. Adds the Where column to Venue Lines (venue IDs, zone names or VNxx/tracks, semicolon separated; the Pool is `overheard`), the
Overheard Every column to Venues (blank = the Balance default, 0 = never), four Balance rows and Cameron's six sample lines.
Run once from the repo root: python3 tools/workbook/archive/overheard_lines_build.py, then python3 tools/export_data.py."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "Cameron 2026-11-25 (overheard lines)."

# Columns
w.set_cell("Venue Lines", 1, "V", "Where", style=w.sty("Venue Lines", "U1"))
w.set_cell("Venues", 1, "L", "Overheard Every", style=w.sty("Venues", "K1"))

# Balance rows
tail = w.last_data_row("Balance")
for lever, value, note in [
    ("Overheard Every", 6, "Moves between overheard lines: pressing Go at a place counts one move; on the N-th the place opens with a passing line. A Venues row's Overheard Every overrides it (0 = never) (" + NOTE + ")"),
    ("Overheard Wobble", 2, "The N above varies by up to this many moves either way, from a seed, so lines do not come on a beat (" + NOTE + ")"),
    ("Overheard Specific Boost", 5, "A line that names the place itself (its venue ID or its tracks) counts its Weight times this; a zone-wide line counts its plain Weight (" + NOTE + ")"),
    ("Overheard No Repeat", 4, "A line heard in the last this-many overheard lines is skipped while another can be drawn (" + NOTE + ")"),
]:
    tail += 1
    w.append_row("Balance", {"A": lever, "B": value, "C": note}, style_row=tail - 1)

# Cameron's six sample lines
SAMPLES = [
    ("Capital Area", "Heading to the office again only to join remote calls."),
    ("Capital Area", "When will the city fix the street parking signs?"),
    ("District", "Another chain restaurant opening soon?"),
    ("District", "The wind is nice today."),
    ("Capitol Building", "Too many new staff getting lost all day."),
    ("Capitol Building", 'The new interns and their "ideas." Ugh.'),
]
rows = w.rows("Venue Lines")
last = max(int(r["A"][2:]) for r in rows.values() if str(r.get("A", "")).startswith("VL"))
for i, (where, text) in enumerate(SAMPLES, 1):
    w.append_row("Venue Lines", {"A": "VL%03d" % (last + i), "B": "overheard", "C": "gossip", "D": "area", "E": text, "O": 1, "P": "N",
                                 "U": "Cameron's sample line (2026-11-25): overheard in passing by someone from the zone's pool.", "V": where},
                 style_row=w.last_data_row("Venue Lines"))
w.save()
print("overheard lines: columns, Balance rows and 6 lines added")
