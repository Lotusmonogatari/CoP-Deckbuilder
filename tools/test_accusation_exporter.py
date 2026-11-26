#!/usr/bin/env python3
"""Checks for the P21 phase D exporter rules (2026-11-26): the Accusers, Claims and Outlets tabs. Run by tools/verify.sh:
python3 tools/test_accusation_exporter.py. Feeds the check function small tables and reads what it reports."""
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


BASE = {"boosters": [{"booster_id": "BO01"}, {"booster_id": "BO02"}],
        "organization_tastes": [{"booster_id": "BO01", "likes": ["humble"], "dislikes": ["risky"]}]}
failures = []


def run(**tables):
    data = dict(BASE)
    data.update(tables)
    report = Report()
    export_data.check_accusation_pool(data, report)
    return [m for _, m in report.errors]


def expect(label, errors, needle=None):
    ok = (not errors) if needle is None else any(needle in e for e in errors)
    print(("  ok  " if ok else "  X   ") + label + ("" if ok else f"  -> {errors}"))
    if not ok:
        failures.append(label)


good_accuser = {"accuser_id": "AC01", "accuser": "A", "title": "Chair", "group": "Group", "tracked_org": "BO01", "status": "Approved"}
expect("a complete approved accuser is fine", run(accusers=[good_accuser]))
expect("an accuser may be a draft with blanks", run(accusers=[{"accuser_id": "AC02", "status": "Draft"}]))
expect("an unknown status is refused", run(accusers=[{**good_accuser, "status": "Maybe"}]), "Status")
expect("an unknown organization is refused", run(accusers=[{**good_accuser, "tracked_org": "BO99"}]), "not an organization")
expect("an approved accuser needs a title", run(accusers=[{**good_accuser, "title": None}]), "no Title")

good_claim = {"claim_id": "R01", "kind": "Rumor!", "claim_en": "{player} is {accuser_full}.", "fits": ["humble"], "target": "Player", "source": "Blunder!", "status": "Approved"}
expect("a good claim is fine", run(claims=[good_claim]))
expect("an any-fit claim is fine", run(claims=[{**good_claim, "fits": ["any"]}]))
expect("a kind that is neither is refused", run(claims=[{**good_claim, "kind": "Gossip"}]), "Kind")
expect("an R claim must be a Rumor!", run(claims=[{**good_claim, "kind": "Scandal!"}]), "starts with R")
expect("an S claim must be a Scandal!", run(claims=[{**good_claim, "claim_id": "S01"}]), "starts with S")
expect("a hand-made claim says so", run(claims=[{**good_claim, "claim_id": "H01", "source": "Blunder!"}]), "hand-made")
expect("a Fits tag nobody has is refused", run(claims=[{**good_claim, "fits": ["nonsense"]}]), "no organization likes or dislikes")
expect("a disliked tag is a real tag", run(claims=[{**good_claim, "fits": ["risky"]}]))
expect("an unknown slot is refused", run(claims=[{**good_claim, "claim_en": "{who} did it"}]), "does not fill")
expect("a colleague slot needs a colleague target", run(claims=[{**good_claim, "claim_en": "{colleague} did it"}]), "Target")
expect("a colleague slot is fine for a colleague claim", run(claims=[{**good_claim, "claim_en": "{colleague} did it", "target": "Colleague"}]))
expect("an approved claim needs its text", run(claims=[{**good_claim, "claim_en": None}]), "no Claim")
expect("a to-write claim may have no text", run(claims=[{"claim_id": "R02", "kind": "Rumor!", "status": "To write"}]))
expect("an unknown target is refused", run(claims=[{**good_claim, "target": "Everyone"}]), "Target")

expect("an outlet with reach and lodges is fine", run(outlets=[{"outlet_id": "PR01", "outlet": "X", "reach": "National", "lodges": "Both"}]))
expect("an outlet may have them blank", run(outlets=[{"outlet_id": "PR02", "outlet": "Y"}]))
expect("an unknown reach is refused", run(outlets=[{"outlet_id": "PR03", "outlet": "Z", "reach": "Global"}]), "Reach")
expect("an unknown lodges is refused", run(outlets=[{"outlet_id": "PR03", "outlet": "Z", "lodges": "Neither"}]), "Lodges")

print("")
print("ACCUSATION EXPORTER TEST: " + ("FAIL" if failures else "PASS"))
sys.exit(1 if failures else 0)
