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
    print("")
    print("VENUE EXPORTER TEST: " + ("PASS" if not failures else "FAIL"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
