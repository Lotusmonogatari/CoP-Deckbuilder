#!/usr/bin/env python3
"""P21 phase C (2026-11-26, Cameron): the Balance rows and Text rows of segments and credibility. The Segment Map tab was added with
tools/workbook/wbx.py add_sheet (see the changelog). Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
NOTE = "P21 phase C (2026-11-26, Cameron's economy guidance); a number Cameron can tune."
balance = [
    ("Segment Suit Use Weeks", 4, "How many of the latest weeks count when a segment's suit is measured."),
    ("Segment Suit Use Target", 20, "Cards of a segment's suit played in that window for the segment to count its organizations in full."),
    ("Credibility Debit Recovery Percent", 10, "Share of every segment debit that comes back each week (rounded down)."),
]
have = {c.get("A") for c in w.rows("Balance").values()}
for label, value, note in balance:
    if label not in have:
        w.append_row("Balance", {"A": label, "B": value, "C": NOTE + " " + note})
texts = {
    "credibility.title": "Credibility",
    "credibility.body": "How far the five groups who watch you take your word. Spending it costs you with all of them, and it comes back slowly.",
    "credibility.value": "Credibility: {value}",
    "segments.suit": "Responds to {suit}",
    "segments.line": "{name}: {value}",
    "segments.plays": "{count} of {target} plays in the last {weeks} weeks",
    "segments.debit": "Still owed from spent credibility: {debit}",
    "segments.orgs": "{orgs}",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P21 economy: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": "P21 phase C (2026-11-26); a draft for Cameron to edit."}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.save()
print("Text rows", added)
