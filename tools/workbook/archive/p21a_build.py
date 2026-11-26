#!/usr/bin/env python3
"""P21 phase A step 1 (2026-11-26, Cameron): the player sees "Political Capital" (short form PC) wherever the game said XP. Text rows and the
display columns of How To Play, Modifiers (Effect) and Shop (Bonus Condition 1) change; the data key, save field, Balance rows, structured
columns (Effect Target, staff task rewards) and code names stay `xp`. Run once from the repo root, then python3 tools/export_data.py
--accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
XP = re.compile(r"\bXP\b")

# Text rows whose short form reads better as a name or a label than "PC"
NAMED = {
    "office.backup_label": "Political Capital",
    "briefing.xp_growth": "PC Growth",
    "briefing.tile_xp": "PC",
    "assign.name_xp": "Political Capital",
    "shop.styles_blurb": "Political Capital",
    "travel.evening_free": "Political Capital",
}
changed = 0
for r, row in w.rows("Text").items():
    text = row.get("C")
    if r == 1 or not isinstance(text, str) or not XP.search(text):
        continue
    key = row.get("A")
    if key == "travel.evening_free":
        new = text.replace("you had no XP to spend", "you had no Political Capital to spend")
    elif key in NAMED:
        new = XP.sub(NAMED[key], text)
    else:
        new = XP.sub("PC", text)
    w.set_cell("Text", r, "C", new)
    changed += 1

for sheet, column in (("How To Play", "F"), ("How To Play", "D"), ("Modifiers", "G"), ("Shop", "F")):
    for r, row in w.rows(sheet).items():
        text = row.get(column)
        if r == 1 or not isinstance(text, str) or not XP.search(text):
            continue
        # a heading or a sentence names the currency in full; an effect line or price uses the short form
        long_form = sheet == "How To Play"
        w.set_cell(sheet, r, column, XP.sub("Political Capital" if long_form else "PC", text))
        changed += 1

# the name itself, for the few labels the code writes (OfficeScreen, GameState)
have = {c.get("A") for c in w.rows("Text").values()}
if "pc.name" not in have:
    last = w.last_data_row("Text") + 1
    w.append_row("Text", {"A": "pc.name", "B": "P21 economy: the currency's name", "C": "Political Capital",
                          "E": "P21 phase A (2026-11-26): what the game called XP; the short form is PC."}, style_row=last - 2)
w.save()
print("cells changed", changed)
