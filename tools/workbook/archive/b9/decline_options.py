#!/usr/bin/env python3
"""Adds a "Decline" choice to the Random events (2026-10-29, Cameron).

Rule (Cameron's): the Decline penalty is 1.5 x the SHORTFALL of sending staff
against accepting, applied as a loss, rounded half up. Accepting is choice A.
"Sending staff" is the event's send-staff choice (rules.json
staff_delegation_phrases); an event without one counts staff as giving
nothing, so the shortfall is everything accepting would have given. Only
Constituency, Reputation, Party, District, National and booster-standing
rewards are scaled: never XP, Funds, dues or unlocks.

Skipped: events whose choices already include a decline-like one (a choice
starting "Decline", "Send regrets", "Send your regrets", "Say you are busy",
"Skip it" or "Ignore it"). Run from the repo root; then
python3 tools/export_data.py (and --accept-wording is NOT needed: no Text rows).
The Decline wording is a draft for Cameron to rewrite.
"""
import json
import math
import sys

sys.path.insert(0, "tools/workbook")
from wbx import WB  # noqa: E402

WB_PATH = "design/Game_Workbook.xlsx"
FIELDS = [("constituency_delta", "H"), ("reputation_delta", "I"), ("party_support_delta", "J"),
          ("district_delta", "K"), ("national_delta", "L")]
DECLINE_STARTS = ("decline", "send regrets", "send your regrets", "say you are busy", "skip it", "ignore it")
RESULT = {
    "EV12": "You decline to take it on. He says nothing more about the street, and a few people nearby notice.",
    "EV13": "You decline the invitation. The head table has one empty chair, and people notice whose.",
    "EV15": "You set the letter aside without answering. The resident notices when no reply comes.",
    "EV16": "You decline to discuss it. The treasurer leaves a note and a cooler goodbye.",
    "EV17": "You decline to engage. The hall secretary will remember that nobody answered.",
    "EV18": "You decline to see them. The mayors leave without their ten minutes.",
    "EV19": "You decline to get involved. The priest and the caretaker leave as they came.",
    "EV22": "You decline to take it up. The owner thanks you and goes back to two shut floors.",
    "EV23": "You decline to look at the slip. She puts it away without a word.",
    "EV25": "You decline to discuss it. He says he understands, in the tone of someone who does not.",
    "EV26": "You decline to act. The nurse says the doctor's Fridays will stay empty.",
    "EV27": "You decline to take it further. The harbor office hears nothing back.",
    "EV37": "You decline the visit. The class waits for an answer that never comes.",
    "EV38": "You decline to get involved. Both neighborhoods hear that you stayed out.",
    "EV41": "You decline to take the call. The village office is left to ring around.",
    "EV42": "You decline to respond. The school manages without you.",
    "EV43": "You decline to receive them. The folders stay in their plastic.",
}


def rhu(x):
    return int(math.floor(x + 0.5))


def rng(v):
    return (v["min"], v["max"]) if isinstance(v, dict) else (0, 0)


def cell(mn, mx):
    return str(mn) if mn == mx else f"{mn}-{mx}"


def main():
    events = {e["event_id"]: e for e in json.load(open("data/events.json"))}
    rules = json.load(open("data/rules.json"))["staff_delegation_phrases"]["value"]
    choices = {}
    for c in json.load(open("data/event_choices.json")):
        choices.setdefault(c["event_id"], []).append(c)
    w = WB(WB_PATH)
    added, skipped = [], []
    for eid, ev in events.items():
        if ev["trigger"] != "Random":
            continue
        cs = sorted(choices[eid], key=lambda c: c["choice"])
        if any(str(c["choice_text"]).lower().startswith(DECLINE_STARTS) for c in cs):
            skipped.append(eid)
            continue
        a = cs[0]
        staff = next((c for c in cs if any(p in str(c["choice_text"]).lower() for p in rules)), None)
        cells = {}
        for field, col in FIELDS:
            amin, amax = rng(a.get(field))
            smin, smax = rng(staff.get(field)) if staff else (0, 0)
            lo, hi = sorted((max(0, amin - smin), max(0, amax - smax)))
            if hi > 0:
                cells[col] = cell(-rhu(1.5 * hi), -rhu(1.5 * lo))
        parts = []
        for r in a.get("rewards") or []:
            gain = r["delta"] - next((s["delta"] for s in (staff.get("rewards") or []) if s["target"] == r["target"]), 0) if staff else r["delta"]
            if gain > 0:
                parts.append(f"{r['target']} -{rhu(1.5 * gain)}")
        if parts:
            cells["M"] = "; ".join(parts)
        letter = "ABCD"[len(cs)]
        row = {"A": eid, "B": letter, "C": "Decline", "D": RESULT[eid]}
        row.update(cells)
        w.append_row("Event Choices", row, style_row=w.last_data_row("Event Choices"))
        added.append((eid, letter, cells))
    w.save()
    for eid, letter, cells in added:
        print("added", eid, letter, cells)
    print("skipped (already have a decline-like choice):", skipped)


if __name__ == "__main__":
    main()
