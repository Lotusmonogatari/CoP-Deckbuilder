"""Item 6: what travel would take of a 40-hour week, per protagonist (hours_impact.md).

Method: replay the strategy bot's logged runs through the proposed offices. The logs are design/bench/pc_difficulty.jsonl
(144 runs: 4 protagonists x 3 Campaign Pressures x 12 runs, 30 weeks each, written 2026-11-02). Each run lists the levels
it played in order with the week and hours of each. Each level gets the Location from levels_location.csv. Starting at the
Capitol, a level at the other office costs a trip first; Either levels cost nothing; forced moves and mixed-level travel
cost nothing (the settled rules). Each week starts where the last ended.
"""
import collections
import csv
import json
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *

TRAIN = {"PC01": 6, "PC02": 1, "PC03": 1, "PC04": 6}
CAR = {"PC01": 5, "PC02": 1, "PC03": 1, "PC04": 9}
NAMES = {"PC01": "Kenshin Sako (Wakkanai)", "PC02": "Haru Yashi (Tomakomai)", "PC03": "Arata Ran (Sapporo Block 6)", "PC04": "Jyurou Nishihara (Aomori Block 3)"}
WEEK_HOURS = 40


def load_locations():
    rows = read_csv_rows(OUT / "levels_location.csv")
    return {r["level_id"]: r["proposed_location"] for r in rows if not r["level_id"].startswith("GEN")}


def simulate(levels_by_week, loc, hours_per_trip, batched):
    """Returns (trips, travel_hours, weeks_with_a_trip, per_week_trips list) for one run."""
    current = "Capitol"
    trips = 0
    weeks_with_trip = 0
    per_week = []
    for week in sorted(levels_by_week):
        needs = [loc.get(l, "Capitol") for l in levels_by_week[week]]
        week_trips = 0
        if batched:
            wanted = {n for n in needs if n != "Either"}
            if wanted and wanted != {current}:
                week_trips = 1
                current = "District" if current == "Capitol" else "Capitol"
                # a week needing both ends at the other office; a week needing only the other office also ends there
        else:
            for n in needs:
                if n != "Either" and n != current:
                    week_trips += 1
                    current = n
        trips += week_trips
        weeks_with_trip += 1 if week_trips else 0
        per_week.append(week_trips)
    return trips, weeks_with_trip, per_week


def main():
    loc = load_locations()
    runs = [json.loads(line) for line in open(ROOT / "design" / "bench" / "pc_difficulty.jsonl", encoding="utf-8")]
    stats = collections.defaultdict(lambda: collections.defaultdict(list))
    mix = collections.defaultdict(collections.Counter)
    level_hours_total = collections.defaultdict(float)
    level_count = collections.defaultdict(int)
    unknown = collections.Counter()
    for run in runs:
        pc = run["protagonist"]
        by_week = collections.defaultdict(list)
        weeks_played = set()
        for l in run["levels"]:
            by_week[l["week"]].append(l["level"])
            weeks_played.add(l["week"])
            where = loc.get(l["level"])
            if where is None:
                unknown[l["level"]] += 1
                where = "Capitol"
            mix[pc][where] += l["hours"]
            level_hours_total[pc] += l["hours"]
            level_count[pc] += 1
        weeks = max(run["weeks"], 1)
        for mode, hours in (("train", TRAIN), ("car", CAR)):
            for batched in (False, True):
                trips, weeks_with, per_week = simulate(by_week, loc, hours[pc], batched)
                key = (mode, "batched" if batched else "as played")
                stats[pc][key].append({"trips_per_week": trips / weeks, "hours_per_week": trips * hours[pc] / weeks, "weeks_with_trip": weeks_with / weeks,
                                       "max_week_hours": max(per_week) * hours[pc] if per_week else 0, "difficulty": run["difficulty"]})
    L = ["# Hours impact: what travel would take of a 40-hour week", "",
         "## Method (read this before the numbers)", "",
         "1. **The play data** is the strategy bot's 144 logged runs in `design/bench/pc_difficulty.jsonl` (4 protagonists x 3 Campaign Pressures x 12 runs; 30 weeks each). "
         "Each run lists the levels it played, in order, with the week and the hours of each: %d level plays." % sum(level_count.values()),
         "2. **Each level's office** comes from `levels_location.csv` (this audit's proposal: Capitol, District or Either; a mixed level takes its overall shape). "
         "Levels the bot played that the CSV does not list: %s." % (dict(unknown) or "none"),
         "3. **The replay.** The player starts a run at the Capitol and each week starts where the last one ended (settled rule). Playing a level at the other office costs one trip "
         "first; an Either level costs nothing; a mixed level's travel is built in and costs nothing; forced moves (the Dated Prime Minister's Opening Address, EV47) cost nothing. "
         "Two orders: **as played** (the bot's own order, which ignores location, so it is a pessimistic and noisy upper bound) and **batched** (the best a thoughtful player can do: "
         "do everything at the current office first, then make at most one trip a week).",
         "4. **Hours.** Train and car hours are the settled ones (PC01 6/5, PC02 1/1, PC03 1/1, PC04 6/9). One trip spends that many hours from the week's pool of 40. "
         "A week is the work week (Monday to Friday); the weekend (8 optional hours) is left out, and so is travel at the weekend (an open question).",
         "5. **What it does not model.** The bot would choose different levels if only one office's levels were listed; the real mix per office would shift play. "
         "Crisis levels (LV83 and LV84) wait at their own office and are forced on arrival without a trip; promises and events that need an office are not modelled. "
         "The logs predate the staff wages and tasks (2026-11-16), so level hours per week are older numbers. Treat every figure as an order of magnitude.", ""]
    L += ["## Where the levels are (share of the hours the bot played)", "",
          "| Protagonist | Capitol | District | Either | Mean hours per level | Mean levels per week |", "|---|---|---|---|---|---|"]
    for pc in sorted(TRAIN):
        total = sum(mix[pc].values())
        weeks = sum(r["weeks"] for r in runs if r["protagonist"] == pc)
        L.append("| %s | %.0f%% | %.0f%% | %.0f%% | %.1f | %.1f |" % (NAMES[pc], 100 * mix[pc]["Capitol"] / total, 100 * mix[pc]["District"] / total, 100 * mix[pc]["Either"] / total,
                 level_hours_total[pc] / level_count[pc], level_count[pc] / weeks))
    L += ["", "## Travel per protagonist (all 144 runs; mean per week of 40 work hours)", "",
          "| Protagonist | Mode | Order | Trips per week | Travel hours per week | Share of the 40 hours | Weeks with at least one trip | Worst week (hours) |", "|---|---|---|---|---|---|---|---|"]
    summary = {}
    for pc in sorted(TRAIN):
        for mode in ("train", "car"):
            for order in ("as played", "batched"):
                rows = stats[pc][(mode, order)]
                t = statistics.mean(r["trips_per_week"] for r in rows)
                h = statistics.mean(r["hours_per_week"] for r in rows)
                w = statistics.mean(r["weeks_with_trip"] for r in rows)
                worst = max(r["max_week_hours"] for r in rows)
                summary[(pc, mode, order)] = (t, h, w, worst)
                L.append("| %s | %s | %s | %.2f | %.1f | %.0f%% | %.0f%% | %d |" % (NAMES[pc], mode, order, t, h, 100 * h / WEEK_HOURS, 100 * w, worst))
    # By pressure, train, as played and batched, standard only.
    L += ["", "## Standard Campaign Pressure only, train, hours per week", "", "| Protagonist | As played | Batched |", "|---|---|---|"]
    for pc in sorted(TRAIN):
        a = statistics.mean(r["hours_per_week"] for r in stats[pc][("train", "as played")] if r["difficulty"] == "standard")
        b = statistics.mean(r["hours_per_week"] for r in stats[pc][("train", "batched")] if r["difficulty"] == "standard")
        L.append("| %s | %.1f | %.1f |" % (NAMES[pc], a, b))
    # Reading.
    p1 = summary[("PC01", "train", "batched")][1]; p4 = summary[("PC04", "train", "batched")][1]; p2 = summary[("PC02", "train", "batched")][1]
    a1 = summary[("PC01", "train", "as played")][1]; a4 = summary[("PC04", "train", "as played")][1]
    L += ["", "## Reading", "",
          "- **Short routes are almost free.** PC02 and PC03 spend a trip hour each way: batched, about %.1f hours a week (%.0f%% of the work week); the bot's order, about %.1f." % (p2, 100 * p2 / WEEK_HOURS, summary[("PC02", "train", "as played")][1]),
          "- **PC01 and PC04 look harder.** A 6-hour train is %.1f hours a week batched (%.0f%%) and %.1f as played (%.0f%%). In the worst week a player who keeps crossing spends %d hours travelling." % (p1, 100 * p1 / WEEK_HOURS, a1, 100 * a1 / WEEK_HOURS, summary[("PC01", "train", "as played")][3]),
          "- **PC04's car is slower, not faster** (9 hours against 6): by car it is %.1f hours a week batched against %.1f by train. PC01's car saves an hour a trip." % (summary[("PC04", "car", "batched")][1], p4),
          "- **Most weeks have a trip.** Because the logged levels are %.0f%% Capitol by hours for PC01, a player who lives mostly at the Capitol and goes home for District levels crosses in about %.0f%% of weeks (batched)." % (100 * mix["PC01"]["Capitol"] / sum(mix["PC01"].values()), 100 * summary[("PC01", "train", "batched")][2]),
          "- **The honest answer on Easy:** the cost is not the average, it is the lumpiness. A 12-hour round trip is 30% of a week at once, and the level hours a player can no longer fit. Whether PC01 stays Easy is Cameron's call; "
          "the numbers say a PC01 who uses the District office at all pays an order of magnitude more than PC02 or PC03, and PC04 pays the same by train and more by car.",
          "- **Levers that would soften it** (not recommended here, listed for the design): make Either levels more common for PC01 and PC04; let a District week be a fixed block; raise the hours pool for those two; or count a train ride as Office time (the train encounter turns the hours into play)."]
    write_text("hours_impact.md", "\n".join(L) + "\n")
    # A small CSV of the numbers.
    out = []
    for (pc, mode, order), (t, h, w, worst) in sorted(summary.items()):
        out.append([pc, mode, order, "%.3f" % t, "%.2f" % h, "%.3f" % w, worst])
    write_csv("hours_impact_numbers.csv", ["protagonist", "mode", "order", "trips_per_week", "travel_hours_per_week", "share_of_weeks_with_a_trip", "worst_week_hours"], out)


if __name__ == "__main__":
    main()
