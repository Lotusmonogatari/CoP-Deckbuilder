#!/usr/bin/env python3
"""Tables for the protagonist x Campaign Pressure playtest (reads the strategy
runs in design/bench/pc_difficulty.jsonl). Prints Markdown."""
import json, sys, statistics as st
from collections import defaultdict

runs = [json.loads(l) for l in open(sys.argv[1] if len(sys.argv) > 1 else "design/bench/pc_difficulty.jsonl")]
PCS = sorted({r["protagonist"] for r in runs})
TIERS = ["relaxed", "standard", "harder"]
STRATS = sorted({r["strategy"] for r in runs})
mean = lambda xs: sum(xs) / len(xs) if xs else 0.0
win = lambda r: r["wins"] / max(1, r["wins"] + r["losses"])
earned = lambda r: sum(s.get("week_earned", 0) for s in r["series"])
collapsed = lambda r: r["party"] < 30
T = lambda h, rows: print("| " + " | ".join(h) + " |\n|" + "|".join("---" for _ in h) + "|\n" + "\n".join("| " + " | ".join(map(str, x)) + " |" for x in rows) + "\n")

def cell(sel, f, fmt="{:.1f}"):
    return fmt.format(mean([f(r) for r in sel])) if sel else "-"

print(f"# Protagonist x Campaign Pressure: {len(runs)} runs\n")
for title, f, fmt in (("Stage win rate", win, "{:.0%}"), ("Election Strength", lambda r: r["es"], "{:.1f}"),
                      ("Party support", lambda r: r["party"], "{:.0f}"), ("Total Funds earned (millions)", lambda r: earned(r) / 1e6, "{:.1f}"),
                      ("Weeks with dues overdue (of 30)", lambda r: r["weeks_overdue"], "{:.1f}"),
                      ("District / National awareness", None, None)):
    print(f"## {title} (mean over strategies and seeds)\n")
    rows = []
    for pc in PCS:
        row = [pc]
        for t in TIERS:
            sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t]
            row.append(cell(sel, f, fmt) if f else f"{mean([r['dist'] for r in sel]):.0f} / {mean([r['nat'] for r in sel]):.0f}")
        rows.append(row)
    T(["Protagonist"] + TIERS, rows)

print("## Runs that collapsed (Party support under 30 at week 30)\n")
rows = []
for pc in PCS:
    row = [pc]
    for t in TIERS:
        sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t]
        row.append(f"{sum(collapsed(r) for r in sel)} of {len(sel)}")
    rows.append(row)
T(["Protagonist"] + TIERS, rows)

for s in STRATS:
    print(f"## Strategy {s}: Election Strength / Party / win rate\n")
    rows = []
    for pc in PCS:
        row = [pc]
        for t in TIERS:
            sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t and r["strategy"] == s]
            row.append(f"{mean([r['es'] for r in sel]):.1f} / {mean([r['party'] for r in sel]):.0f} / {mean([win(r) for r in sel]):.0%}" if sel else "-")
        rows.append(row)
    T(["Protagonist"] + TIERS, rows)

print("## Tier spread: change from Standard, by protagonist (all strategies)\n")
rows = []
for pc in PCS:
    base = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == "standard"]
    row = [pc]
    for t in ("relaxed", "harder"):
        sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t]
        row.append(f"win {100 * (mean([win(r) for r in sel]) - mean([win(r) for r in base])):+.0f} pts, ES {mean([r['es'] for r in sel]) - mean([r['es'] for r in base]):+.1f}, earned {mean([earned(r) for r in sel]) / max(1, mean([earned(r) for r in base])) - 1:+.0%}")
    rows.append(row)
T(["Protagonist", "Relaxed vs Standard", "Harder vs Standard"], rows)

print("## Early game: Party support and Funds at weeks 2, 5, 10 (all strategies)\n")
rows = []
for pc in PCS:
    for t in TIERS:
        sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t]
        row = [pc, t]
        for w in (2, 5, 10):
            pts = [s for r in sel for s in r["series"] if s["week"] == w]
            row.append(f"{mean([p['party'] for p in pts]):.0f} / {mean([p['funds'] for p in pts]) / 1000:.0f}k")
        rows.append(row)
T(["Protagonist", "Tier", "Week 2 (party / funds)", "Week 5", "Week 10"], rows)

print("## Levels cleared and deck, by protagonist and tier\n")
rows = []
for pc in PCS:
    for t in TIERS:
        sel = [r for r in runs if r["protagonist"] == pc and r["difficulty"] == t]
        rows.append([pc, t, f"{mean([r['levels_cleared'] for r in sel]):.0f}", f"{mean([r['owned_cards'] for r in sel]):.0f}", f"{mean([r['backing_owned'] for r in sel]):.0f}", f"{mean([r['laws'] for r in sel]):.1f}", f"{mean([r['gaffes'] for r in sel]):.0f}"])
T(["Protagonist", "Tier", "Levels cleared", "Cards owned", "Backings", "Laws passed", "Gaffes"], rows)

print("## Suit mix by tier (share of plays, all strategies)\n")
rows = []
for t in TIERS:
    tot = defaultdict(int)
    for r in runs:
        if r["difficulty"] == t:
            for k, v in r["suit_plays"].items():
                tot[k] += v
    n = sum(tot.values()) or 1
    rows.append([t] + [f"{tot[s] / n:.0%}" for s in ("Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous")])
T(["Tier", "Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"], rows)

print("## Hardest stage types: win rate by tier (fights >= 30)\n")
res = defaultdict(lambda: defaultdict(lambda: [0, 0]))
for r in runs:
    for k, v in r["stage_type_results"].items():
        res[k][r["difficulty"]][0] += v.get("wins", 0)
        res[k][r["difficulty"]][1] += v.get("losses", 0)
stages = {s["stage_id"]: s for s in json.load(open("data/stages.json"))}
rows = []
for k, d in res.items():
    if all(sum(d[t]) >= 30 for t in TIERS):
        rates = [d[t][0] / sum(d[t]) for t in TIERS]
        rows.append((rates[1], [k, stages.get(k, {}).get("name_en", "?")] + [f"{x:.0%}" for x in rates]))
rows.sort()
T(["Stage", "Name", "Relaxed", "Standard", "Harder"], [x[1] for x in rows[:10]])

print("## Bugs the bot logged\n")
bugs = defaultdict(int)
for r in runs:
    for b in r["bugs"]:
        bugs[b.split("]")[-1][:150]] += 1
print("None.\n" if not bugs else "\n".join(f"- {n}x {b}" for b, n in sorted(bugs.items(), key=lambda x: -x[1])[:8]))
print(f"\nStalls: {sum(r['stalls'] for r in runs)}")
