#!/usr/bin/env python3
"""P21 phase A step 3 (2026-11-26, Cameron): the Text rows of the Upkeep tab (holds, dues bailout, cap calls), the week-end fade lines, and the
Rules row naming the financial industry organization. Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P21 phase A (2026-11-26); a draft for Cameron to edit."
w = WB("design/Game_Workbook.xlsx")
texts = {
    "upkeep.tab": "Upkeep",
    "upkeep.shore_title": "Shore up support",
    "upkeep.shore_blurb": "Pay Political Capital to stop one meter fading at this week's end. A hold never raises it, and each week in a row on the same meter costs a little more.",
    "upkeep.touch_title": "Keep in touch",
    "upkeep.touch_blurb": "Pay Political Capital to stop one organization's standing fading at this week's end. Only organizations that are fading are listed.",
    "upkeep.meter_line": "{name}: {value} · fades {fade} at week's end",
    "upkeep.org_line": "{name}: {value} · fades {fade}",
    "upkeep.hold_button": "Hold · {cost} PC",
    "upkeep.held": "Held this week",
    "upkeep.refuse_held": "Already held this week.",
    "upkeep.refuse_not_fading": "It is not fading.",
    "upkeep.refuse_pc": "Not enough PC.",
    "upkeep.refuse_no_dues": "No dues are owed.",
    "upkeep.dues_title": "Dues and the Funds limit",
    "upkeep.bailout_blurb": "Write off part of the dues you owe.",
    "upkeep.bailout_button": "Dues bailout · {cost} PC for {yen}円 off the dues",
    "upkeep.cap_blurb": "Once petitions have raised the Funds limit to {ceiling}円, you can call on the party and on the financial industry to raise it further, once each per run.",
    "upkeep.cap_party_button": "Call on the party · {support} Party support and {cost} PC for {yen}円 more Funds limit",
    "upkeep.cap_finance_button": "Call on the financial industry · {standing} standing and {cost} PC for {yen}円 more Funds limit",
    "upkeep.cap_refuse_done": "Already called on.",
    "upkeep.cap_refuse_petition": "Raise the Funds limit to {ceiling}円 with petitions first.",
    "upkeep.cap_refuse_support": "Needs Party support over {min}.",
    "upkeep.cap_refuse_standing": "Needs standing over {min} with {org}.",
    "pc.fade_note": "{count} Political Capital will fade at week's end.",
    "pc.fade_report": "{count} Political Capital faded.",
    "decay.week_meter": "{name} faded by {count}.",
    "record.cause_cap_call": "A call on the party or the financial industry",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P21 economy: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": NOTE}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.append_row("Rules", {"A": "cap_call_finance_org", "B": "BO24", "C": "an organization ID",
                       "D": "The organization the call on the financial industry spends standing with (the Financial Industry Association).",
                       "F": "P21 phase A (2026-11-26, Cameron)."})
w.save()
print("Text rows", added)
