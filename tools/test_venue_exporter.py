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
    print("")
    print("VENUE EXPORTER TEST: " + ("PASS" if not failures else "FAIL"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
