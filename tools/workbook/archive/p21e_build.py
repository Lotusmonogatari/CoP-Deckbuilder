#!/usr/bin/env python3
"""P21 phase E (2026-11-26, Cameron): the Political Capital sinks that could be built on today's main: Trim the deck, Mentoring, Pep talk and the Library's
Rush request. Balance rows and Text rows. Not built (see the changelog): Reserved table, Private session, Committee seat, Backstage pass, Rush a favor and the
Rare books room. Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "P21 phase E (2026-11-26, Cameron's economy guidance); a number Cameron can tune."
balance = [
    ("Trim Deck XP", 75, "Political Capital to remove one card from the deck for good."),
    ("Trim Deck Step XP", 25, "Added to the price for each card already trimmed."),
    ("Trim Deck Min Size", 12, "The deck never goes below this many cards by trimming (the removed card also takes one deck slot, so the deck stays legal)."),
    ("Mentoring XP", 100, "Political Capital to cancel the Loyalty loss from this week's unpaid or late wage for one person."),
    ("Pep Talk XP", 60, "Political Capital for a pep talk."),
    ("Pep Talk Loyalty", 5, "Loyalty a pep talk gives."),
    ("Rush Request XP", 60, "Political Capital for a Library reading without its hours (once a day)."),
]
have = {c.get("A") for c in w.rows("Balance").values()}
for label, value, note in balance:
    if label not in have:
        w.append_row("Balance", {"A": label, "B": value, "C": NOTE + " " + note})
texts = {
    "trim.title": "Trim the deck",
    "trim.body": "Remove one card from your deck for good. It also takes one deck slot with it, so the deck stays legal.",
    "trim.row": "{name} · {cost} PC",
    "trim.refuse_min": "The deck cannot go below {min} cards.",
    "trim.refuse_pc": "Not enough PC.",
    "trim.done": "{name} is out of your deck for good.",
    "staff.mentoring": "Mentoring · {price} PC",
    "staff.mentoring_body": "Sit down with {name} about the late pay. They don't hold it against you.",
    "staff.mentoring_done": "Mentored this week",
    "staff.pep_talk": "Pep talk · {price} PC · +{count} Loyalty",
    "staff.pep_talk_done": "Had a pep talk this week",
    "staff.refuse_pc": "Not enough PC.",
    "venue.rush_request": "Rush request · {price} PC",
    "venue.rush_request_body": "A reading without its hours. Once a day.",
    "venue.rush_refuse_used": "Already rushed today.",
    "venue.rush_refuse_pc": "Not enough PC.",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P21 economy: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": "P21 phase E (2026-11-26); a draft for Cameron to edit."}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.save()
print("Text rows", added)
