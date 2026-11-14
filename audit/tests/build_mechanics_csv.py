#!/usr/bin/env python3
"""Audit Phase 2: writes audit/mechanics.csv from the static scan.

    python3 audit/tests/static_scan.py && python3 audit/tests/build_mechanics_csv.py

One row per variable: the mechanic it belongs to, its value or observed range,
where it is defined (workbook tab, hand-written JSON, or a script constant),
which scripts read it, and a status:
  workbook        defined in the workbook and read by a script
  unread          defined in the workbook; no script names it
  loader-only     named only by DataDB's loader/validation
  hand-written    defined in a JSON file the exporter never writes
  code            a number typed into a script
"""
import csv, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
scan = json.load(open(ROOT / "audit" / "tests" / "results" / "static_scan.json"))
rules = json.load(open(ROOT / "data" / "rules.json"))
standing = json.load(open(ROOT / "data" / "booster_standing.json"))

LEVER = {  # balance key prefix -> mechanic
    "patron": "Sponsored bills", "custom": "Sponsored bills", "difficulty": "Political Pressure", "trade": "Lobbyist trade",
    "election": "Election strength", "party": "Party opinion", "dues": "Party dues", "hosted": "Hosted events",
    "characters": "Characters list (presentation)", "mp": "Member visit", "member": "Member visit", "awareness": "Awareness",
    "research": "Staff: vote research", "starter": "Opening deck", "deck": "Deck", "stance": "Bill stance",
    "lean": "Bill stance", "whip": "Whip", "resign": "Resign", "tendency": "Organization suit tendency",
    "scroll": "Settings", "text": "Settings", "image": "Settings", "haptics": "Settings", "vote": "Floor vote",
    "supermajority": "Floor vote", "draft": "Drafted bills", "win": "Conversion costs", "promise": "Promises",
    "transition": "Stage transition (presentation)", "calendar": "Time", "weekend": "Time", "workday": "Time",
    "work": "Time", "week": "Decay", "decay": "Decay", "event": "Events", "staff": "Staff", "gaffes": "Crisis triggers",
    "jiban": "Crisis triggers", "special": "Crisis triggers", "question": "Questions", "questions": "Questions",
    "law": "Laws", "bill": "Bills", "brief": "Level briefing (presentation)", "player": "Cues (presentation)",
    "opponent": "Cues (presentation)", "cue": "Cues (presentation)", "standing": "Organization standing",
    "news": "Office ticker (presentation)", "press": "Press conference", "ally": "Party allies", "audience": "Audience mix",
    "panel": "Presentation", "stage": "Presentation", "scene": "Presentation", "xp": "XP",
}
TABLE = {
    "cards": "Cards", "suits": "Cards", "affinity": "Affinity", "stages": "Stages and rooms", "segments": "Audience mix",
    "modifiers": "Backings", "questions": "Questions", "opponents": "Opponents and intents", "opponent_cues": "Cues (presentation)",
    "player_cues": "Cues (presentation)", "card_cues": "Cues (presentation)", "levels": "Levels", "level_intros": "Level intro (presentation)",
    "level_intro_thoughts": "Level intro (presentation)", "visitors": "Office Hours", "visitor_questions": "Office Hours",
    "staff": "Staff", "player": "Protagonists", "boosters": "Organization standing", "parties": "Party opinion",
    "party_stakeholders": "Party opinion", "party_values": "Party opinion", "organization_tastes": "Hosted events",
    "floor_votes": "Floor vote", "law_effects": "Laws", "vote_influence_cues": "Influence swing", "vote_influence_triggers": "Influence swing",
    "bill_components": "Sponsored bills", "patron_bills": "Sponsored bills", "bill_level_templates": "Sponsored bills",
    "visit_questions": "Member visit", "visit_answers": "Member visit", "trade_questions": "Lobbyist trade",
    "lobbyist_lines": "Lobbyist trade", "events": "Events", "event_choices": "Events", "event_options": "Hosted events",
    "hosted_events": "Hosted events", "reaction_lines": "Hosted events", "shop": "Shop and items", "cosmetic_packages": "Cosmetics",
    "office_notices": "Office (presentation)", "office_ticker": "Office ticker (presentation)", "transition_cast": "Stage transition (presentation)",
    "transition_backgrounds": "Stage transition (presentation)", "transition_dialogue": "Stage transition (presentation)",
    "sanban": "Meta numbers", "awareness_effects": "Awareness", "standing_links": "Organization standing",
    "move_flashes": "Move flash (presentation)", "how_to_play": "How to Play (presentation)", "lists": "Lists",
    "booster_standing": "Organization standing", "party_standing": "Party opinion", "rules": "Rule switches",
    "art": "Art loading", "sounds": "Audio", "staff_names": "Staff", "level_opponent_overrides": "People draw",
    "level_visitor_overrides": "People draw", "playtest_level": "Playtest", "playtest_cards": "Playtest",
}
rows = []
for key, info in sorted(scan["levers"].items()):
    readers = info["readers"]
    rows.append([LEVER.get(key.split("_")[0], "Other"), key, info["value"], "", "workbook: Balance tab",
                 "; ".join(readers[:4]), len(readers), "workbook" if readers else "unread"])
for name, table in sorted(scan["tables"].items()):
    where = f"hand-written: data/{name}.json" if table["hand_written"] else f"workbook tab -> data/{name}.json"
    for field, info in sorted(table["fields"].items()):
        if field.startswith("_"):
            continue
        rng = "" if info["min"] is None else f"{info['min']} to {info['max']}"
        if table["hand_written"]:
            status = "hand-written"
        elif info["readers"]:
            status = "workbook"
        elif info.get("loader_only"):
            status = "loader-only"
        elif info["filled"] == 0:
            status = "empty column"
        else:
            status = "unread"
        rows.append([TABLE.get(name, "Other"), f"{name}.{field}", f"{info['filled']} of {table['rows']} rows filled", rng,
                     where, "; ".join(info["readers"][:4]), len(info["readers"]), status])
for key, value in rules.items():
    if key.startswith("_"):
        continue
    shown = value.get("value") if isinstance(value, dict) and "value" in value else value
    readers = scan["hand_written"]["rules"]["key_readers"].get(key, [])
    rows.append(["Rule switches", f"rules.{key}", json.dumps(shown)[:80], "", "hand-written: data/rules.json",
                 "; ".join(readers), len(readers), "hand-written"])
for key, value in standing.items():
    if key.startswith("_"):
        continue
    readers = scan["hand_written"]["booster_standing"]["key_readers"].get(key, [])
    rows.append(["Organization standing", f"booster_standing.{key}", json.dumps(value)[:80], "", "hand-written: data/booster_standing.json",
                 "; ".join(readers), len(readers), "hand-written"])
for const in scan["consts"]:
    rows.append(["Code constant (" + const["layer"] + ")", const["name"], const["value"], "", "code: " + const["at"], const["at"], 1, "code"])
for m in scan["magic"]:
    rows.append(["Number literal in gameplay code (candidate)", m["line"][:90], ", ".join(m["numbers"]), "", "code: " + m["at"], m["at"], 1, "code"])

path = ROOT / "audit" / "mechanics.csv"
with open(path, "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle)
    writer.writerow(["mechanic", "variable", "value_or_fill", "observed_range", "defined_in", "read_by", "reader_count", "status"])
    writer.writerows(rows)
counts = {}
for row in rows:
    counts[row[7]] = counts.get(row[7], 0) + 1
print(f"wrote {len(rows)} rows to {path.relative_to(ROOT)}: {counts}")
