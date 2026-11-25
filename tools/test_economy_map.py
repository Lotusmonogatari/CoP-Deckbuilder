#!/usr/bin/env python3
"""Checks for tools/economy_map.py (P19, 2026-11-25). Run by tools/verify.sh. Plain asserts, no framework:
    python3 tools/test_economy_map.py
The GDScript half (the week's dues and wages against the real PartyDues and StaffLoyalty) is tests/test_economy_week.gd."""
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import economy_map as em  # noqa: E402

FILES, FINDINGS = em.run()
CATALOG = FINDINGS["catalog"]


def test_catalog_columns_are_filled_and_allowed():
    assert CATALOG, "the catalog is empty"
    for row in CATALOG:
        assert row["Stock"], f"{row['Flow ID']} has no Stock"
        assert row["Class"], f"{row['Flow ID']} has no Class"
        assert row["Source"], f"{row['Flow ID']} has no Source"
        assert row["Class"] in em.CLASSES, row
        assert row["Timing"] in em.TIMINGS, row
        assert row["Control"] in em.CONTROLS, row
        assert row["Status"] in em.STATUSES, row
        assert row["Mechanic type"] in em.MECHANIC_TYPES, row
        assert row["Stock"] in em.NODES, row


def test_the_two_dead_stocks_are_marked_unused():
    unused = {row["Stock"] for row in CATALOG if row["Status"] == "unused"}
    assert {"segment_favorability", "election_strength"} <= unused, unused


def test_every_converter_that_spends_also_gains():
    sides = {}
    for row in CATALOG:
        if row["Class"] == "converter":
            sides.setdefault(row["Mechanic"].replace("Staff upgrade", "Hire staff"), set()).add(row["Amount"].split(" ")[0])
    for mechanic, kinds in sides.items():
        if "SPENDS" in kinds:
            assert "GAINS" in kinds, f"{mechanic} spends a stock but no row says what it gains"


def test_every_expected_link_is_present():
    assert not FINDINGS["missing_links"], FINDINGS["missing_links"]


def test_every_expected_loop_is_found():
    missing = [name for name, hit in FINDINGS["found"] if hit is None]
    assert not missing, missing


def test_the_three_spirals_are_flagged_and_the_dead_ends_named():
    spirals = [hit for name, hit in FINDINGS["found"] if name.startswith("S")]
    assert all(h and h["spiral"] for h in spirals), spirals
    assert {"segment_favorability", "election_strength"} <= set(FINDINGS["dead"]), FINDINGS["dead"]


def test_the_week_figures_follow_the_formulas():
    week = json.loads(FILES["economy_week.json"])
    cfg = em.dues_cfg(json.loads((em.DATA / "balance.json").read_text(encoding="utf-8")))
    for name in ("standard", "early"):
        w = week[name]
        assert w["dues"] == em.week_dues(cfg, w["party_support"], week["funds_earned"]), name
        assert w["wages"] == sum(em.wage(i, week["wage_percent"]) for i in w["invested"]), name
        assert w["forced_funds"] == w["dues"] + w["wages"], name
    # The prompt's own anchors: the dues limit holds the standard week at 90,000円 and wages are 10% of 390,000円.
    assert week["standard"]["dues"] == 90000
    assert week["standard"]["wages"] == 39000


def test_dues_formula_cases():
    cfg = {"base": 50000, "reward_percent": 15.0, "support_start": 40, "support_step": 15, "step_amount": 5000, "max_per_week": 90000}
    assert em.week_dues(cfg, 40, 0) == 50000
    assert em.week_dues(cfg, 55, 0) == 55000, "one full step above 40"
    assert em.week_dues(cfg, 54, 0) == 50000, "a step needs the full 15 points"
    assert em.week_dues(cfg, 40, 100000) == 65000, "the 15% share"
    assert em.week_dues(cfg, 100, 1000000) == 90000, "the limit"
    assert em.week_dues(cfg, 70, 249539, reduction=50000) == 40000, "the relief comes off after the limit"
    assert em.godot_round(0.5) == 1 and em.godot_round(2.5) == 3 and em.godot_round(-0.5) == -1


def test_check_passes_on_a_fresh_run_and_fails_when_a_balance_value_changes():
    assert em.main(["--check"]) == 0, "the files on disk are out of date: run python3 tools/economy_map.py"
    temp = Path(tempfile.mkdtemp())
    try:
        shutil.copytree(em.DATA, temp / "data")
        balance = json.loads((temp / "data" / "balance.json").read_text(encoding="utf-8"))
        balance["dues_base"] = int(balance["dues_base"]) + 1000
        (temp / "data" / "balance.json").write_text(json.dumps(balance), encoding="utf-8")
        real = em.DATA
        em.DATA = temp / "data"
        try:
            assert em.main(["--check"]) == 1, "--check did not notice the changed Balance value"
        finally:
            em.DATA = real
    finally:
        shutil.rmtree(temp, ignore_errors=True)


if __name__ == "__main__":
    failed = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print(f"ok   {name}")
            except AssertionError as error:
                failed += 1
                print(f"FAIL {name}: {error}")
    print("ECONOMY MAP TEST: " + ("PASS" if not failed else f"{failed} failed"))
    sys.exit(1 if failed else 0)
