"""One-off (2026-11-16, audit W-1): builds the Rules, Standing Rules and Party
Start Standing tabs from the hand-written JSON files, so their values live in
the workbook. Run once, from the repo root:  python3 tools/workbook/archive/w1_rules_tabs_2026-11-16.py
The exporter (tools/export_data.py) then writes the three JSON files back out;
a round-trip check against the old files is in tests/test_rules_tabs_round_trip.gd
and in the note at the end of this script's run."""
import json, os, sys
sys.path.insert(0, "tools/workbook")
import wbx

PATH = "design/Game_Workbook.xlsx"
rules = json.load(open("data/rules.json"))
standing = json.load(open("data/booster_standing.json"))
party = json.load(open("data/party_standing.json"))


def cell(value):
    """A value as a cell: plain numbers and words, JSON text for lists and objects."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    return value


rule_rows = []
for key, entry in rules.items():
    if key.startswith("_"):
        continue
    if isinstance(entry, dict) and "value" in entry:
        notes = entry.get("notes", entry.get("note", ""))
        rule_rows.append([key, cell(entry["value"]), cell(entry.get("options", "")), entry.get("question", ""),
                          cell(entry.get("means", "")), cell(notes), ""])
    else:   # the calendar eras: an object kept as written
        rule_rows.append([key, json.dumps(entry, ensure_ascii=False), "", "", "", "", "block"])

standing_rows = []
notes = {"start": "Where standing with every organisation starts (an organisation's own Starting Standing in the Boosters tab wins)",
         "decay_percent": "Default percent of the distance back to its start an organisation settles each week (an organisation's own Decay Percent wins)",
         "required_standing": "Standing needed before an organisation sells you its backing (a row required_standing_<MODID> sets one backing)",
         "gain_band_1_below": "Gains are multiplied by a factor that shrinks as standing rises: below this standing...",
         "loss_band_1_below": "Penalties grow as standing rises: below this standing..."}
for key in ["start", "min", "max", "per_please", "per_displease", "per_opposed", "question_swing_cap",
            "instant_win_penalty", "neglect_decay", "decay_percent", "required_standing"]:
    standing_rows.append([key, standing[key], notes.get(key, "")])
for name in ("gain", "loss"):
    for i, band in enumerate(standing[name + "_bands"], start=1):
        if "below" in band:
            standing_rows.append([f"{name}_band_{i}_below", band["below"], notes.get(f"{name}_band_{i}_below", "")])
        standing_rows.append([f"{name}_band_{i}_factor", band["factor"], "The last band has no 'below': it applies to everything above" if "below" not in band else ""])
for mod, value in standing.get("required_standing_by_modifier", {}).items():
    standing_rows.append([f"required_standing_{mod}", value, "Standing needed for this one backing"])

party_rows = [[k, party[k], "Standing every other party starts at (0 to 100)" if k == "start" else ""]
              for k in ("start", "min", "max")]

wbx.add_sheet(PATH, "Rules", ["Key", "Value", "Options", "Question", "Means", "Notes", "Shape"], rule_rows, [30, 38, 28, 60, 60, 50, 8])
os.replace(PATH + ".tmp", PATH) if os.path.exists(PATH + ".tmp") else None
wbx.add_sheet(PATH, "Standing Rules", ["Key", "Value", "Note"], standing_rows, [34, 12, 90])
os.replace(PATH + ".tmp", PATH) if os.path.exists(PATH + ".tmp") else None
wbx.add_sheet(PATH, "Party Start Standing", ["Key", "Value", "Note"], party_rows, [14, 10, 60])
os.replace(PATH + ".tmp", PATH) if os.path.exists(PATH + ".tmp") else None
print("added 3 tabs:", len(rule_rows), len(standing_rows), len(party_rows), "rows")
