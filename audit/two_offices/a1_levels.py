"""Item 1 and 1b: every level and its proposed location; the Either rooms' backgrounds.

Location rules (the spec's settled rules):
  * every room has an office (common.KIND_OFFICE): committees, hearings, caucus, floor, TV, press and member
    visits are Capitol; town halls and local events are District; lobbyist meetings, policy study, Office Hours
    and media ambushes are Either;
  * a level whose rooms are all Capitol/Either is Capitol (Either if all rooms are Either); all District/Either
    is District;
  * a level with both Capitol and District rooms is MIXED and is tagged by its overall shape (rule 5): a level
    built around a bill, a committee or the media is Capitol, even if it opens with a town hall. Where the
    other signals (the speaker of its purpose line, its name, the share of District rooms) lean the other way,
    the confidence drops so Cameron looks at it.
"""
import collections
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *

# Cameron's decisions (2026-11-19), applied over what the rule alone says. Each is a Mixed level that starts in the
# District and finishes at the Capitol; its travel is built in and free, and (settled rule) the player ends where
# they started. The rule alone gave Capitol for both (a committee makes a Mixed level Capitol).
DECIDED = {
    "LV12": (DISTRICT, "Cameron's decision, 2026-11-19: District. It starts in the District and finishes at the Capitol, with the travel built in"),
    "LV62": (DISTRICT, "Cameron's decision, 2026-11-19: District. It starts in the District and finishes at the Capitol, with the travel built in"),
    "LV61": (DISTRICT, "Cameron's decision, 2026-11-19: District. It starts in the District and finishes at the Capitol, with the travel built in"),
}

DISTRICT_NAME_WORDS = re.compile(r"constituen|outreach|neighbor|hometown|tour|festival|local|village|town|district|community|family|market|harbor|farm|fish", re.I)


def classify_level(level, stages):
    ids = level_stage_ids(level)
    rooms = []
    for sid in ids:
        office, kind, how, nm = slot_office(sid, stages)
        rooms.append((sid, nm, office, kind, how))
    counts = collections.Counter(room[2] for room in rooms)
    kinds = collections.Counter(room[3] for room in rooms)
    cap, dis, eit = counts.get(CAPITOL, 0), counts.get(DISTRICT, 0), counts.get(EITHER, 0)
    name = level["description"]
    speaker = level.get("purpose_speaker") or ""
    purpose = level.get("purpose") or ""
    special = level.get("special_trigger")
    mixed = cap > 0 and dis > 0
    anchors = [k for k in ("Floor Vote", "Floor Debate", "Committee or Hearing", "Special Committee", "Party Caucus",
                           "Party Steering Committee", "TV Debate", "Press Conference") if kinds.get(k)]
    notes = []
    confidence = "high"
    if cap == 0 and dis == 0:
        location, reason = EITHER, "every room is Either (%s)" % ", ".join(sorted(kinds))
    elif dis == 0:
        location = CAPITOL
        reason = "%d Capitol room(s) (%s) and %d Either" % (cap, ", ".join(k for k in sorted(kinds) if KIND_OFFICE[k] == CAPITOL), eit)
    elif cap == 0:
        location = DISTRICT
        reason = "%d District room(s) (%s) and %d Either" % (dis, ", ".join(k for k in sorted(kinds) if KIND_OFFICE[k] == DISTRICT), eit)
    else:
        # Mixed: overall shape (rule 5).
        built_on = [k for k in anchors if k in ("Floor Vote", "Floor Debate", "Committee or Hearing", "Special Committee", "Party Caucus", "Party Steering Committee")]
        media = [k for k in anchors if k in ("TV Debate", "Press Conference")]
        if built_on:
            location = CAPITOL
            reason = "MIXED (%d Capitol, %d District, %d Either): built around %s, so Capitol by rule 5" % (cap, dis, eit, ", ".join(built_on))
        elif media:
            location = CAPITOL
            reason = "MIXED (%d Capitol, %d District, %d Either): built around the media (%s), so Capitol by rule 5" % (cap, dis, eit, ", ".join(media))
        else:
            location = DISTRICT if dis >= cap else CAPITOL
            reason = "MIXED (%d Capitol, %d District, %d Either): no bill, committee or media anchor; the larger share decides" % (cap, dis, eit)
            confidence = "low"
        # Signals that lean the other way lower the confidence.
        lean_district = 0
        if speaker == "District Representative":
            lean_district += 1
            notes.append("purpose spoken by the District Representative")
        if DISTRICT_NAME_WORDS.search(name):
            lean_district += 1
            notes.append("name reads local")
        if dis * 2 >= cap + dis and location == CAPITOL:
            lean_district += 1
            notes.append("half or more of the Capitol/District rooms are District")
        if location == CAPITOL and lean_district >= 2:
            confidence = "low"
        elif location == CAPITOL and lean_district == 1:
            confidence = "medium"
        elif location == CAPITOL:
            confidence = "high" if built_on else "medium"
    if special == "Town Hall":
        notes.append("forced crisis level (Constituency support falls to its line): a District level that waits at the District office (spec)")
        location, confidence = DISTRICT, "high"
    elif special == "Steering Committee":
        notes.append("forced crisis level (Party support below its line): a Capitol level that waits at the Capitol office (spec)")
        location, confidence = CAPITOL, "high"
    if level.get("event_only") == "Yes":
        notes.append("event-only level: started by an event choice, not the level list (the event decides where it is reached)")
    if re.search(r"Chishima", name) and "Act" in name:
        notes.append("Chishima act: national legislation, Capitol (spec)")
    return rooms, location, mixed, confidence, reason + ("; " + "; ".join(notes) if notes else "")


def main():
    stages = stages_by_id()
    levels = load("levels")
    rows = []
    tally = collections.Counter()
    for level in levels:
        rooms, location, mixed, confidence, reason = classify_level(level, stages)
        if level["level_id"] in DECIDED:
            location, decided = DECIDED[level["level_id"]]
            confidence = "high"
            reason = decided + ". The rule alone said: " + reason
        stage_text = " | ".join("%s %s" % (sid, nm) for sid, nm, _o, _k, _h in rooms)
        room_summary = " / ".join("%s=%s" % (kind, office[0]) for _sid, _nm, office, kind, _h in rooms)
        rows.append([level["level_id"], level["description"], level["tier"], len(rooms), stage_text, room_summary,
                     location, "Yes" if mixed else "No", confidence, reason, level.get("special_trigger") or "",
                     level.get("event_only") or "", level.get("seasons") or "", level.get("purpose_speaker") or ""])
        tally[(location, "mixed" if mixed else "pure")] += 1
        tally[("conf", confidence)] += 1
    # The four runtime-generated bill levels (patron "Favor" and "Flagship" bills, drafted bills).
    for template in load("bill_level_templates"):
        tokens = [template.get(f"stage_{i}") for i in range(1, 9) if template.get(f"stage_{i}")]
        rooms = []
        for token in tokens:
            kind, how = TEMPLATE_TOKEN[token]
            rooms.append((token, how, KIND_OFFICE[kind], kind, how))
        kinds = collections.Counter(r[3] for r in rooms)
        has_public = "PUBLIC" in tokens
        stage_text = " | ".join("%s (%s)" % (r[0], r[4]) for r in rooms)
        room_summary = " / ".join("%s=%s" % (r[3], r[2][0]) for r in rooms)
        reason = ("generated at run time for a %s bill (%s): hearing, member visit and Floor Vote are Capitol; the patron visit and "
                  "lobbyist trade are Either" % (template["kind"], template["template_id"]))
        mixed = "No"
        location, confidence = CAPITOL, "high"
        if has_public:
            mixed = "Yes"
            reason += ("; its public room is a Town Hall (District) when the bill's organization is a Constituency one, a Press Conference "
                       "(Capitol) when it is a National one, so it is MIXED and Capitol by rule 5 (built around a bill)")
        rows.append(["GEN-" + template["template_id"], "Generated %s bill level (%s)" % (template["kind"], template["template_id"]),
                     template.get("level_tier"), len(rooms), stage_text, room_summary, location, mixed, confidence, reason, "", "", "", ""])
        tally[(location, "generated")] += 1
    write_csv("levels_location.csv", ["level_id", "level_name", "tier", "rooms", "stages (id name)", "room kinds (office initial)",
                                      "proposed_location", "mixed", "confidence", "reason", "special_trigger", "event_only", "seasons",
                                      "purpose_speaker"], rows)
    # Summary for the report.
    summary = collections.Counter()
    for r in rows:
        summary[r[6]] += 1
    mixed_by = collections.Counter((r[6]) for r in rows if r[7] == "Yes")
    print("location counts:", dict(summary), "| mixed by tag:", dict(mixed_by), "| confidence:", dict(collections.Counter(r[8] for r in rows)))
    (OUT / "levels_location_summary.json").write_text(json.dumps({"by_location": summary, "mixed_by_location": mixed_by,
        "mixed": sum(mixed_by.values()), "confidence": collections.Counter(r[8] for r in rows)}, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
