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
    print("Each cell reads *no offices → stays at its office (lazy) → follows its own order and crosses (pessimistic)*. "
          "A policy with no runs shows a dash.\n")
    for pressure in PRESSURES:
        runs = {mode: load(mode, pressure) for mode in ("0", "1", "2")}
        if not runs["0"] or not runs["1"]:
            continue
        pcs = sorted({r["protagonist"] for r in runs["1"]})
        counts = ", ".join("%d %s" % (len(v), {"0": "without", "1": "lazy", "2": "pessimistic"}[k]) for k, v in runs.items() if v)
        print("## Campaign Pressure: %s (%s runs)\n" % (pressure, counts))
        print("| Metric | " + " | ".join("%s (%s)" % (pc, RATING.get(pc, "")) for pc in pcs) + " |")
        print("|---|" + "---|" * len(pcs))

        def cells_for(fn, fmt):
            cells = []
            for pc in pcs:
                parts = []
                for mode in ("0", "1", "2"):
                    sel = [fn(r) for r in runs[mode] if r["protagonist"] == pc]
                    parts.append(fmt.format(mean(sel)) if sel else "-")
                cells.append(" → ".join(parts))
            return cells

        for title, fn, fmt in METRICS:
            print("| %s | %s |" % (title, " | ".join(cells_for(fn, fmt))))
        print("| District awareness at week 30 | %s |" % " | ".join(cells_for(lambda r: r["dist"], "{:.0f}")))
        for title, key, fmt in (("Trips taken over 30 weeks", "trips", "{:.1f}"), ("Travel hours over 30 weeks", "trip_hours", "{:.0f}"),
                                ("Mixed levels played over 30 weeks", "mixed_levels", "{:.1f}")):
            cells = []
            for pc in pcs:
                parts = []
                for mode in ("1", "2"):
                    sel = [r.get(key, 0) for r in runs[mode] if r["protagonist"] == pc]
                    parts.append(fmt.format(mean(sel)) if sel else "-")
                cells.append(" / ".join(parts))
            print("| %s (lazy / pessimistic) | %s |" % (title, " | ".join(cells)))
        share = []
        for pc in pcs:
            parts = []
            for mode in ("1", "2"):
                sel = [r.get("trip_hours", 0) / max(1, r["weeks"] * 40) for r in runs[mode] if r["protagonist"] == pc]
                parts.append("%.0f%%" % (100 * mean(sel)) if sel else "-")
            share.append(" / ".join(parts))
        print("| Share of the 40-hour week spent travelling (lazy / pessimistic) | %s |\n" % " | ".join(share))


main()
