"""Shared helpers for the P11 two-offices audit (read-only: it only reads data/ and writes the report folder).

Run any script from the repo root:  python3 -I audit/two_offices/<script>.py
The report folder is design/review/p11_two_offices_audit_2026-11-19/ (override with P11_OUT; the repo with P11_ROOT).
"""
import csv
import json
import os
import re
from pathlib import Path

ROOT = Path(os.environ.get("P11_ROOT") or Path(__file__).resolve().parents[2])
DATA = ROOT / "data"
OUT = Path(os.environ.get("P11_OUT", ROOT / "design" / "review" / "p11_two_offices_audit_2026-11-19"))
PROPOSALS = ROOT / "design" / "proposals" / "two_offices_2026-11-19"


def load(name):
    with open(DATA / f"{name}.json", encoding="utf-8") as handle:
        return json.load(handle)


def write_csv(name, header, rows):
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        writer.writerows(rows)
    print(f"wrote {name}: {len(rows)} rows")


def write_text(name, text):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(text, encoding="utf-8")
    print(f"wrote {name}")


def read_csv_rows(path):
    with open(path, encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def stages_by_id():
    return {s["stage_id"]: s for s in load("stages")}


def level_stage_ids(level):
    return [level[f"stage_{i}"] for i in range(1, 11) if level.get(f"stage_{i}")]


# ----------------------------------------------------------------------------------------------
# Room kinds: what a stage IS, from its structured fields first (mode, question pool, background
# template), with the stage's name only as a fallback. Each kind has one office.
# ----------------------------------------------------------------------------------------------
CAPITOL, DISTRICT, EITHER = "Capitol", "District", "Either"

KIND_OFFICE = {
    "Floor Vote": CAPITOL,
    "Floor Debate": CAPITOL,
    "Committee or Hearing": CAPITOL,
    "Special Committee": CAPITOL,
    "Party Caucus": CAPITOL,
    "Party Steering Committee": CAPITOL,
    "TV Debate": CAPITOL,
    "Press Conference": CAPITOL,       # "stay as they are for now" (spec); local ones come later as District rooms
    "Member Visit": CAPITOL,           # fellow members visit the Capitol office (spec: Promises, staff and events by location)
    "Town Hall": DISTRICT,
    "Local Event": DISTRICT,           # festivals, walkabouts, school and clinic days: outdoor District scenes
    "Open House": DISTRICT,            # the constituency office's open day (spec: EV34 is District)
    "Lobbyist Meeting": EITHER,
    "Lobbyist Trade": EITHER,
    "Policy Study": EITHER,
    "Office Hours": EITHER,
    "Media Ambush": EITHER,
    "Other": EITHER,
}


def room_kind(stage):
    """(kind, how) for one stage. `how` says which field decided it, for the reason column."""
    mode = stage.get("mode")
    pool = stage.get("question_pool")
    name = stage.get("name_en") or ""
    background = str(stage.get("background_id") or "")
    if mode == "Vote":
        return "Floor Vote", "mode Vote"
    if mode == "Visit":
        return "Member Visit", "mode Visit"
    if mode == "Trade":
        return "Lobbyist Trade", "mode Trade"
    if pool == "town_hall":
        return "Town Hall", "question pool town_hall"
    if pool == "press_conference":
        return "Press Conference", "question pool press_conference"
    if pool == "policy_study":
        return "Policy Study", "question pool policy_study"
    if pool == "lobbyist_meeting":
        return "Lobbyist Meeting", "question pool lobbyist_meeting"
    if pool == "media_ambush":
        return "Media Ambush", "question pool media_ambush"
    if mode == "Non-combat":
        if background.startswith("OUT_"):
            return "Local Event", "non-combat, outdoor background %s" % background.split(";")[0]
        if name.startswith("Open House"):
            return "Open House", "non-combat, office background, a constituency open day"
        if background == "ST08" or "Steering" in name:
            return "Party Steering Committee", "non-combat, the Steering Committee check-in"
        if background in ("ST07", "OFFICE") or "Office Hours" in name or name == "Patron Visit":
            return "Office Hours", "non-combat, office background %s" % (background or "ST07")
        return "Other", "non-combat, no rule matched"
    # Combat rooms without a question pool: committees, floor, caucus, TV, steering.
    if name.startswith("Press Conference") or background == "ST04":
        return "Press Conference", "background template ST04 (a press conference variant)"
    if background.startswith("OUT_"):
        return "Local Event", "combat room on an outdoor background %s (a local Q&A)" % background.split(";")[0]
    if name.startswith("TV Debate") or background == "ST06":
        return "TV Debate", "background template ST06"
    if name.startswith("Floor Debate"):
        return "Floor Debate", "stage name"
    if name.startswith("Party Caucus") or background == "ST03":
        return "Party Caucus", "background template ST03"
    if name.startswith("Party Steering") or background == "ST08":
        return "Party Steering Committee", "background template ST08"
    if name.startswith("Special Committee") or background == "ST01":
        return "Special Committee", "background template ST01"
    if name.startswith("Committee") or name.startswith("Hearing") or re.fullmatch(r"ST(09|1[0-8])", background):
        return "Committee or Hearing", "committee template %s" % (background or "by name")
    return "Other", "no rule matched"


def is_bill_slot(value):
    """A 'BIxx' value in a level's stage slot is a bill: it always means the Floor Voting room (ST23)."""
    return isinstance(value, str) and re.fullmatch(r"BI\d+", value) is not None


def stage_office(stage):
    kind, how = room_kind(stage)
    return KIND_OFFICE[kind], kind, how


def slot_office(slot_value, stages):
    """(office, kind, how, name) for one stage slot of a level (a stage id, or a bill id)."""
    if is_bill_slot(slot_value):
        return CAPITOL, "Floor Vote", "slot holds the bill %s: it is the Floor Voting room (ST23)" % slot_value, "Floor Vote on %s" % slot_value
    stage = stages[slot_value]
    office, kind, how = stage_office(stage)
    return office, kind, how, stage["name_en"]


# The runtime-generated levels (data/bill_level_templates.json: BT01 to BT04) use these room tokens.
TEMPLATE_TOKEN = {
    "PATRON_VISIT": ("Office Hours", "the organization's patron visit: an Office Hours style visit"),
    "HEARING": ("Committee or Hearing", "the committee hearing for the bill's first component"),
    "MP_VISIT": ("Member Visit", "a visit from a fellow member"),
    "LOBBYIST_TRADE": ("Lobbyist Trade", "an optional lobbyist trade"),
    "VOTE": ("Floor Vote", "the Floor Vote"),
    "CAUCUS": ("Party Caucus", "the player's own Party Caucus"),
    "PUBLIC": ("Town Hall", "the public room: a Town Hall for a Constituency organization (District), a Press Conference for a National one (Capitol)"),
}
