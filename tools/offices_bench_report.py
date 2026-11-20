#!/usr/bin/env python3
"""Two offices, slice 7 (2026-11-20): tables comparing the strategy bot with and without the offices.

Reads design/bench/offices/offices_<0|1>_<pressure>.jsonl (written by tools/strategy_runs.sh with PLAYTEST_OFFICES=0 or 1;
the 1 runs travel as a batching player on the rail pass and pay a mixed level's built-in trips). Prints Markdown.

    python3 tools/offices_bench_report.py [folder]
"""
import json
import statistics
import sys
from pathlib import Path

FOLDER = Path(sys.argv[1] if len(sys.argv) > 1 else "design/bench/offices")
PRESSURES = ["relaxed", "standard", "harder"]
RATING = {"PC01": "Easy", "PC02": "Normal", "PC03": "Hard", "PC04": "Very Hard"}


def load(mode, pressure):
    path = FOLDER / ("offices_%s_%s.jsonl" % (mode, pressure))
    if not path.exists():
        return []
    return [json.loads(line) for line in open(path, encoding="utf-8") if line.strip()]


def mean(values):
    values = list(values)
    return statistics.mean(values) if values else float("nan")


def win_rate(run):
    return run["wins"] / max(1, run["wins"] + run["losses"])


def earned(run):
    return sum(week.get("week_earned", 0) for week in run["series"])


def levels_per_week(run):
    return len(run["levels"]) / max(1, run["weeks"])


METRICS = [
    ("Stage win rate", win_rate, "{:.1%}"),
    ("Election Strength at week 30", lambda r: r["es"], "{:.1f}"),
    ("Levels played per week", levels_per_week, "{:.2f}"),
    ("Different levels cleared", lambda r: r["levels_cleared"], "{:.1f}"),
    ("Party support at week 30", lambda r: r["party"], "{:.0f}"),
    ("Funds earned over 30 weeks (millions)", lambda r: earned(r) / 1e6, "{:.1f}"),
    ("Weeks with dues overdue (of 30)", lambda r: r["weeks_overdue"], "{:.1f}"),
    ("Laws passed", lambda r: r["laws"], "{:.1f}"),
]


def main():
    print("# Strategy bot with and without the offices\n")
    for pressure in PRESSURES:
        off, on = load("0", pressure), load("1", pressure)
        if not off or not on:
            continue
        pcs = sorted({r["protagonist"] for r in on})
        print("## Campaign Pressure: %s (%d runs without, %d with)\n" % (pressure, len(off), len(on)))
        print("| Metric | " + " | ".join("%s (%s)" % (pc, RATING.get(pc, "")) for pc in pcs) + " |")
        print("|---|" + "---|" * len(pcs))
        for title, fn, fmt in METRICS:
            cells = []
            for pc in pcs:
                a = [fn(r) for r in off if r["protagonist"] == pc]
                b = [fn(r) for r in on if r["protagonist"] == pc]
                cells.append("%s → %s" % (fmt.format(mean(a)), fmt.format(mean(b))))
            print("| %s | %s |" % (title, " | ".join(cells)))
        for title, key in (("Trips taken (swipes and built-in)", "trips"), ("Travel hours spent", "trip_hours"), ("Mixed levels played", "mixed_levels")):
            cells = []
            for pc in pcs:
                b = [r.get(key, 0) for r in on if r["protagonist"] == pc]
                cells.append("%.1f" % mean(b))
            print("| %s (with offices, over 30 weeks) | %s |" % (title, " | ".join(cells)))
        share = []
        for pc in pcs:
            b = [r.get("trip_hours", 0) / max(1, r["weeks"] * 40) for r in on if r["protagonist"] == pc]
            share.append("%.0f%%" % (100 * mean(b)))
        print("| Share of the 40-hour week spent travelling | %s |\n" % " | ".join(share))
        print("Each cell reads *without offices → with offices*.\n")


main()
