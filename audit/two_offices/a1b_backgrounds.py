"""Item 1b: the room types that could be Either, their backgrounds today, and what a District version needs.

The 'reads as Capitol' column comes from LOOKING at each picture in assets/backgrounds (a contact sheet of
ST07, ST19, ST20, ST21, ST05, ST06, OFFICE, OFFICE_UPGRADED, DINING and OUT_STREET_1 was reviewed on 2026-11-19);
the counts and ids come from data/stages.json.
"""
import collections
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *

# (room kind, how its picture reads, what the District needs, candidates already in the repo)
READS = {
    "Lobbyist Meeting": ("Yes", "A modern high-rise office, glass walls, a city skyline beyond: reads as a Sapporo office tower",
                         "A local meeting room or a restaurant, shared by all four protagonists (spec: 1 new picture)",
                         "DINING and DINING_ALT (a dining room, today the hosted-dinner scene) could stand in for 'a restaurant'; no OUT_* picture is an interior"),
    "Policy Study": ("Yes", "A large government conference room with a horseshoe table: reads as an Assembly or ministry committee room",
                     "A local library or community room, shared (spec: 1 new picture)",
                     "None. OUT_CULTURAL_CENTER_1_AINU is an exterior; no interior community room exists"),
    "Office Hours": ("Ambiguous", "A dark wood-panelled office with a desk and a sofa; nothing in it says Sapporo, so it reads as 'the member's office' and would pass at either",
                     "The District office's own meeting room, one per District office (spec), or reuse the office picture",
                     "OFFICE and OFFICE_UPGRADED are the Capitol office (the Office screen's own picture, data/art.json office_hotspots); they cannot double as the District office"),
    "Media Ambush": ("Yes", "A corridor with TV cameras and microphones in the foreground: reads as the Assembly building or a broadcaster's corridor",
                     "A street or a station platform in the district",
                     "OUT_STREET_1, OUT_STREET_2 and OUT_STREET_3 (shopping lanes) may serve; OUT_VILLAGE_ROAD_SNOW_1 and _2 for winter"),
    "Lobbyist Trade": ("Unknown", "The Lobbyist Trade screen uses the Office Hours layout; its backdrop was not re-checked",
                       "Same as Office Hours", "See Office Hours"),
    "Open House": ("Yes", "OFFICE: the Capitol office itself (bookshelves, desk). The constituency office's open day would show the wrong office",
                   "The District office room (spec: EV34 Constituency Office Open Day is District)", "None; needs the District office picture"),
}


def main():
    stages = stages_by_id()
    by_kind = collections.defaultdict(list)
    for sid, stage in stages.items():
        kind, how = room_kind(stage)
        by_kind[kind].append(sid)
    # Office Hours splits by picture: ST07-based (Office Hours, Office Hours: <bill>, Patron Visit) and OFFICE-based.
    office_st07 = [sid for sid in by_kind["Office Hours"] if "OFFICE" not in str(stages[sid].get("background_id"))]
    office_room = [sid for sid in by_kind["Office Hours"] if "OFFICE" in str(stages[sid].get("background_id"))]
    rows = []

    def row(room, ids, bg, exists, reads, shows, need, candidates, note):
        rows.append([room, len(ids), " ".join(ids[:40]) + (" ..." if len(ids) > 40 else ""), bg, exists, reads, shows, need, candidates, note])

    def exists(bg):
        parts = [p.strip() for p in bg.split(";")]
        return "; ".join("%s: %s" % (p, "yes" if (ROOT / "assets" / "backgrounds" / (p + ".png")).exists() else "MISSING") for p in parts)

    r = READS["Lobbyist Meeting"]; ids = by_kind["Lobbyist Meeting"]
    row("Lobbyist Meeting", ids, "ST20", exists("ST20"), r[0], r[1], r[2], r[3], "13 stages share ST20 (spec: 13)")
    r = READS["Policy Study"]; ids = by_kind["Policy Study"]
    row("Policy Study (Session)", ids, "ST21", exists("ST21"), r[0], r[1], r[2], r[3], "14 stages share ST21 (spec: 14)")
    r = READS["Office Hours"]
    row("Office Hours (and bill-named variants, Patron Visit)", office_st07, "ST07", exists("ST07"), r[0], r[1], r[2], r[3],
        "%d stages use ST07 (spec: 32); the count here also includes Patron Visit and the Office Hours: <bill> variants" % len(office_st07))
    row("Office Hours in the Office room (Follow-Up, Receiving Line, Closing Reception, Extended)", office_room,
        "OFFICE", exists("OFFICE"), "Yes", "The Capitol office's own picture (bookshelves and a desk): the same room the Office screen shows",
        "The District office room; if Either levels are played from the District they would show the Capitol office", READS["Office Hours"][3],
        "These 4 stages are non-combat Office Hours variants in levels LV102 to LV113; tagged Either by their room kind but they SHOW the Capitol office")
    r = READS["Open House"]
    row("Open House Day (constituency office open day)", by_kind["Open House"], "OFFICE", exists("OFFICE"), r[0], r[1], r[2], r[3],
        "Tagged District (the office is the constituency office) but its picture is the Capitol office")
    r = READS["Media Ambush"]; ids = by_kind["Media Ambush"]
    row("Media Ambush", ids, "ST19", exists("ST19"), r[0], r[1], r[2], r[3], "6 stages, hidden from the briefing (reveal_in_briefing = No); 5 reference ST19 as background_id")
    r = READS["Lobbyist Trade"]
    row("Lobbyist Trade (screen, not a battle room)", by_kind["Lobbyist Trade"], "(screen)", "n/a", r[0], r[1], r[2], r[3], "1 stage (ST262)")
    row("TV Debate", by_kind["TV Debate"], "ST06", exists("ST06"), "Yes", "A broadcast studio desk with a skyline: Capitol (settled: TV Debate is Capitol)", "None: Capitol only", "n/a", "not Either")
    row("Town Hall", by_kind["Town Hall"], "ST05", exists("ST05"), "No", "A shrine pavilion in a park with a city skyline far behind (ST05); one stage uses the harbor", "None: already District", "n/a",
        "not Either; also the fallback for any missing OUT_* picture (data/art.json outdoor_background_fallback)")
    # Missing OUT_ pictures referenced by stages.
    missing = collections.defaultdict(list)
    for sid, stage in stages.items():
        for part in str(stage.get("background_id") or "").split(";"):
            part = part.strip()
            if part and not (ROOT / "assets" / "backgrounds" / (part + ".png")).exists() and part not in ("OFFICE",):
                missing[part].append(sid)
    for bg, ids in sorted(missing.items()):
        row("(missing picture) " + bg, ids, bg, "MISSING", "n/a", "No file in assets/backgrounds; the game falls back to ST05 (the Town Hall pavilion)",
            "The picture, or a mapping to an existing OUT_* scene", "n/a", "FINDING: stages use a background id with no picture")
    write_csv("backgrounds_either.csv", ["room_type", "stages", "stage_ids", "background_today", "file_exists", "reads_as_capitol",
              "what_the_picture_shows", "district_background_needed", "existing_pictures_that_could_serve", "note"], rows)


if __name__ == "__main__":
    main()
