#!/usr/bin/env python3
"""P20 phase B, second batch of Text rows (2026-11-26, Cameron): added while the screens were built. Run once from the repo root, then
python3 tools/export_data.py --accept-wording. Add new rows to the `texts` dict; a key already in the Text tab is skipped."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P20 phase B (2026-11-26); a draft for Cameron to edit."
w = WB("design/Game_Workbook.xlsx")
texts = {
    "campaign.howto.group": "The Campaign",
    "campaign.tab.staff": "Staff",
    "campaign.tab.van": "Van",
    "campaign.office.status": "Your campaign",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P20 campaign: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": NOTE}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.save()
print("Text rows added:", added)
