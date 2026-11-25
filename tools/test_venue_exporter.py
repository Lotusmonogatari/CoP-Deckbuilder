#!/usr/bin/env python3
"""Checks for the Venue Lines exporter rule that a hint row has Topic `hint` and a blank Text (P16b, 2026-11-23).
Run by tools/verify.sh: python3 tools/test_venue_exporter.py. Feeds check_venues() small tables and reads what it reports."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_data  # noqa: E402


class Report:
    def __init__(self):
        self.errors, self.warnings = [], []

    def error(self, where, message):
        self.errors.append((where, message))

    def warn(self, where, message):
        self.warnings.append((where, message))


def run(lines):
    data = {
        "venues": [{"venue_id": "VN01", "zone": "Capitol Building", "order": 1}],
        "venue_activities": [{"activity_id": "VA01", "venue_id": "VN01", "kind": "chat", "pool": "cafeteria"}],
        "venue_lines": lines, "opponents": [], "staff": [], "visitors": [], "stages": [], "floor_votes": {}, "rules": {}, "strings": [],
    }
    report = Report()
    export_data.check_venues(data, report)
    return report


def line(line_id, **over):
    base = {"line_id": line_id, "pool": "cafeteria", "topic": "gossip", "speaker": None, "text": "A line.", "hint_kind": None}
    base.update(over)
    return base


def run_library(docs, lines=None, extra=None):
    """check_library_documents() on small tables (P18, 2026-11-24)."""
    data = {"library_documents": docs, "venue_lines": lines or [], "floor_votes": {"BI01": {}}, "parties": [{"party_id": "CP01", "name": "Frontier Party"}],
            "venues": [], "venue_activities": [], "rules": {}, "strings": []}
    if extra:
        data.update(extra)
    report = Report()
    export_data.check_library_documents(data, report)
    return report


def doc(doc_id, **over):
    base = {"doc_id": doc_id, "category": "history", "order": 1, "title": "T", "unlock": "start", "unlock_value": None, "party": None, "note": None}
    base.update(over)
    return base


def library_tests(expect):
    expect(not run_library([doc("LD01")]).errors, "a plain start document passes")
    expect(any("LD03" in w for w, m in run_library([doc("LD03", category="lore")]).errors), "an unknown category fails, naming the row")
    expect(any("LD04" in w for w, m in run_library([doc("LD04", unlock="whenever")]).errors), "an unknown Unlock fails")
    expect(any("LD05" in w for w, m in run_library([doc("LD05", unlock="line")]).errors), "a line document no venue line names fails")
    named = run_library([doc("LD06", unlock="line")], lines=[{"line_id": "VL001", "unlocks_doc": "LD06"}])
    expect(not named.errors, "a line document named by a venue line passes")
    expect(any("VL002" in w or "LD99" in m for w, m in run_library([doc("LD01")], lines=[{"line_id": "VL002", "unlocks_doc": "LD99"}]).errors),
           "an Unlocks Doc naming no document fails")
    expect(any("LD07" in w for w, m in run_library([doc("LD07", unlock="law", unlock_value="BI99 passed")]).errors), "a law document naming a missing bill fails")
    expect(any("LD08" in w for w, m in run_library([doc("LD08", unlock="law", unlock_value="BI01 maybe")]).errors), "a law result other than passed/failed fails")
    expect(not run_library([doc("LD09", unlock="law", unlock_value="BI01 failed")]).errors, "a law document with a real bill and a result passes")
    expect(any("LD10" in w for w, m in run_library([doc("LD10", unlock="own_party", party="CP99")]).errors), "an own_party document with no real party fails")
    expect(not run_library([doc("LD11", unlock="own_party", party="CP01")]).errors, "an own_party document with a real party passes")
    expect(any("LD12" in w for w, m in run_library([doc("LD12", note="DRAFT: placeholder")]).warnings), "a DRAFT row is reported as a warning")


VENUES = [{"venue_id": "VN01", "zone": "Capitol Building", "name": "Cafeteria"}, {"venue_id": "VN04", "zone": "Capital Area", "name": "Speech Coach"},
          {"venue_id": "VN08", "zone": "District", "name": "Old Shrine"}]


def run_area(people):
    report = Report()
    export_data.check_area_characters({"area_characters": people, "venues": VENUES}, report)
    return report


def person(cid, **over):
    base = {"character_id": cid, "name": "Someone", "site": None}
    base.update(over)
    return base


def area_tests(expect):
    expect(not run_area([person("VEN01", site="VN04"), person("CA01"), person("CB01"), person("DI01")]).errors, "valid VEN, CA, CB and DI rows pass")
    expect(any("VEN02" in w for w, m in run_area([person("VEN02")]).errors), "a VEN row with no Site fails")
    expect(any("VEN03" in w for w, m in run_area([person("VEN03", site="VN99")]).errors), "a Site naming no venue fails")
    expect(any("CA02" in w for w, m in run_area([person("CA02", site="VN01")]).errors), "a Capital Area person sited in the Capitol fails")
    expect(not run_area([person("CB02", site="VN01")]).errors, "a zone person narrowed to a venue of their zone passes")
    expect(any("CA03" in w for w, m in run_area([person("CA03", name=None)]).errors), "a blank Name fails")
    people = {"VEN01": person("VEN01", site="VN04"), "CA01": person("CA01")}
    expect(export_data.area_allowed(people["VEN01"], VENUES[1]) and not export_data.area_allowed(people["VEN01"], VENUES[0]),
           "a VEN person is allowed only at their Site")
    expect(export_data.area_allowed(people["CA01"], VENUES[1]) and not export_data.area_allowed(people["CA01"], VENUES[2]), "a zone person only in their zone")
    data = {"venues": VENUES, "venue_activities": [{"activity_id": "VA01", "venue_id": "VN01", "kind": "chat", "pool": "cafeteria"}],
            "venue_lines": [line("VL001", speaker="VEN01"), line("VL002", speaker="area")], "opponents": [], "staff": [], "visitors": [], "stages": [],
            "floor_votes": {}, "rules": {}, "strings": [], "area_characters": [people["VEN01"], people["CA01"]]}
    report = Report()
    export_data.check_venues(data, report)
    expect(any("VL001" in w and "does not appear" in m for w, m in report.errors), "a line whose speaker cannot appear at its venue fails")
    expect(not any("VL002" in w for w, m in report.errors), "the speaker word 'area' passes")


def run_overheard(lines, people=None, venue_extra=None):
    venues = [dict(v, order=1) for v in VENUES] + [{"venue_id": "VN06", "zone": "Capital Area", "name": "Super Station", "order": 1}]
    if venue_extra:
        venues[0].update(venue_extra)
    data = {"venues": venues, "venue_activities": [{"activity_id": "VA01", "venue_id": "VN01", "kind": "chat", "pool": "cafeteria"},
                                                   {"activity_id": "VA06", "venue_id": "VN06", "kind": "travel", "pool": None}],
            "venue_lines": [line("VL900")] + lines, "opponents": [], "staff": [], "visitors": [], "stages": [], "floor_votes": {}, "rules": {},
            "strings": [], "area_characters": people or []}
    report = Report()
    export_data.check_venues(data, report)
    return report


def over(line_id, where, **over_):
    return line(line_id, pool="overheard", where=where, **over_)


def overheard_tests(expect):
    expect(not run_overheard([over("VL901", "Capital Area"), over("VL902", "VN01"), over("VL903", "VN06/tracks"), over("VL904", "District; VN04")]).errors,
           "overheard lines naming a zone, a venue, a station's tracks or several places pass")
    expect(any("VL905" in w and "needs a Where" in m for w, m in run_overheard([over("VL905", None)]).errors), "an overheard line with no Where fails")
    expect(any("VL906" in w and "Where 'Nowhere'" in m for w, m in run_overheard([over("VL906", "Nowhere")]).errors), "a Where naming nothing fails")
    expect(any("VL907" in w for w, m in run_overheard([over("VL907", "VN01/tracks")]).errors), "/tracks on a venue that is not a station fails")
    expect(any("VL908" in w and "hint" in m for w, m in run_overheard([over("VL908", "VN01", topic="hint", text=None, hint_kind="stage_suit")]).errors),
           "an overheard line cannot be a hint row")
    coach = {"VEN01": {"character_id": "VEN01", "name": "Coach", "site": "VN04"}}
    expect(any("VL909" in w and "does not appear" in m for w, m in run_overheard([over("VL909", "VN01", speaker="VEN01")], list(coach.values())).errors),
           "a speaker who cannot appear at the place fails")
    expect(not run_overheard([over("VL910", "VN04", speaker="VEN01")], list(coach.values())).errors, "a VEN speaker at their own venue passes")
    expect(not [e for e in run_overheard([over("VL911", "Capitol Building", speaker="area")]).errors if "VL911" in e[0]], "the speaker word area passes")
    expect(any("Overheard Every" in m for w, m in run_overheard([over("VL912", "VN01")], venue_extra={"overheard_every": -1}).errors),
           "a negative Overheard Every fails")
    expect(any("VL913" in w for w, m in run_overheard([line("VL913", pool="cafeteria", where="VN01")]).warnings), "Where on a non-overheard line is reported")


def main():
    failures = []

    def expect(ok, what):
        print(("  ok  " if ok else "  X   ") + what)
        if not ok:
            failures.append(what)

    good = run([line("VL001"), line("VL002", topic="hint", text=None, hint_kind="stage_suit")])
    expect(not good.errors, "a hint row with Topic hint and no Text passes")
    with_text = run([line("VL003", topic="hint", text="Some words.", hint_kind="stage_suit")])
    expect(any("VL003" in w and "blank Text" in m for w, m in with_text.errors), "a hint row with Text filled fails, naming the row")
    wrong_topic = run([line("VL004", topic="gossip", text=None, hint_kind="opponent_suit")])
    expect(any("VL004" in w and "Topic 'hint'" in m for w, m in wrong_topic.errors), "a hint row with another Topic fails, naming the row")
    both = run([line("VL005", topic="watch", text="Words.", hint_kind="stage_suit")])
    expect(len([e for e in both.errors if "VL005" in e[0]]) >= 2, "a row wrong in both ways is reported twice")
    library_tests(expect)
    area_tests(expect)
    overheard_tests(expect)
    print("")
    print("VENUE EXPORTER TEST: " + ("PASS" if not failures else "FAIL"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
