#!/usr/bin/env python3
"""P21 phase B (2026-11-26, Cameron): Blunders. The Balance rows (and the two old per-meter gaffe rows go) and the Text rows. Run once from the repo root,
then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "P21 phase B (2026-11-26, Cameron's economy guidance); a number Cameron can tune."
balance = [
    ("Awareness Gaffes Per Roll", 30, "Each time the run's leftover gaffes pass another this many, an awareness roll is made."),
    ("Awareness Gaffe Roll Chance", 0.2, "The chance that such a roll costs awareness."),
    ("Awareness Gaffe Roll Delta", 1, "District and National awareness lost when it does."),
    ("Blunder Gaffes Per Roll", 25, "Each time the run's leftover gaffes pass another this many, a Blunder! roll is made."),
    ("Blunder Chance", 0.3333, "The chance of a Blunder! from a gaffe threshold, and from each stage lost to gaffes (one third)."),
    ("Blunder Awareness Delta", -10, "District and National awareness a Blunder! takes (negative)."),
    ("Blunder Floor", 21, "A Blunder! never takes either meter below this; a meter at or under it loses nothing."),
    ("Blunder Cancel XP Tier 0", 200, "Political Capital for a tier 0 Media Spokesperson to cancel a Blunder!."),
    ("Blunder Cancel XP Tier 1", 150, "Political Capital for a tier 1 Media Spokesperson."),
    ("Blunder Cancel XP Tier 2", 100, "Political Capital for a tier 2 Media Spokesperson."),
    ("Blunder Scandal Chance", 0.125, "The chance that a Blunder! leaves a Scandal! (checked first; one eighth)."),
    ("Blunder Rumor Chance", 0.3333, "The chance that it leaves a Rumor! otherwise (one third)."),
    ("Blunder Cancelled Chance Factor", 0.5, "Both accusation chances are multiplied by this when the Blunder! was cancelled."),
]
have = {c.get("A") for c in w.rows("Balance").values()}
for label, value, note in balance:
    if label not in have:
        w.append_row("Balance", {"A": label, "B": value, "C": NOTE + " " + note})
for old in ("Awareness Gaffes Per District Point", "Awareness Gaffes Per National Point"):
    try:
        w.delete_row("Balance", w.find_row("Balance", old))
    except KeyError:
        print("not found:", old)

texts = {
    "blunder.title": "Blunder!",
    "blunder.body": "Too many slips have piled up, and the papers noticed. District and National awareness fall by {amount}.",
    "blunder.floor": "Your name was already quiet. Nothing more is lost.",
    "blunder.cancel": "Have {spokesperson} handle it ({price} PC)",
    "blunder.cancelled": "{spokesperson} spends the afternoon on the phone. By evening the story has gone nowhere.",
    "blunder.no_spokesperson": "A Media Spokesperson could have handled this.",
    "blunder.take_it": "Take it",
    "blunder.taken": "District awareness fell by {district} and National awareness by {national}.",
    "blunder.refuse_pc": "Not enough PC.",
    "blunder.counter": "Blunders!: {count}",
    "blunder.progress": "Slips on the record: {total}. The next awareness check comes at {awareness_at}; the next Blunder! check at {blunder_at}.",
    "blunder.card_title": "Slips and Blunders!",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P21 economy: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": "P21 phase B (2026-11-26); a draft for Cameron to edit."}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.save()
print("Text rows", added)
