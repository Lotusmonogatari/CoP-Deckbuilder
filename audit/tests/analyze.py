#!/usr/bin/env python3
"""Audit Phase 4: turns the harness and bot results into benchmark numbers.

    python3 audit/tests/analyze.py     (reads audit/tests/results/, prints a report,
                                        writes audit/tests/results/analysis.json)

Every number printed here is what audit/testing.md quotes. Thresholds are the
frozen ones in audit/benchmarks.md; nothing here decides a target.
"""
import collections, glob, json, re, statistics as st
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "audit" / "tests" / "results"
DATA = ROOT / "data"
out = {}


def load_sims(policy, kit, pressure="standard"):
    return [json.load(open(f)) for f in sorted(glob.glob(str(RES / f"sim_{policy}_{kit}_*_{pressure}_s*.json")))]


stages = {s["stage_id"]: s for s in json.load(open(DATA / "stages.json"))}


def family(stage_id):
    """A bill's own copy of a room points at the generic room through its
    Background ID, so the family is that generic room's name."""
    row = stages.get(stage_id, {})
    base = stages.get(row.get("background_id") or "", row)
    return base.get("name_en", stage_id)


def pool(sims):
    rooms = {}
    for sim in sims:
        for r in sim["rooms"]:
            if r.get("skipped"):
                continue
            a = rooms.setdefault(r["stage_id"], {"n": 0, "wins": 0, "name": r["name"], "bar": r["bar_model"],
                                                 "limit": r["turn_limit"], "seq": r.get("sequence_mode", ""),
                                                 "opps": max(r.get("opponent_count", 1), 1), "tw": [], "causes": collections.Counter(),
                                                 "cards": []})
            a["n"] += r["n"]; a["wins"] += r["wins"]
            if r["wins"]:
                a["tw"].append((r["turns_won_mean"], r["wins"]))
            a["causes"].update(r["loss_causes"]); a["cards"].append(r["cards_per_fight"])
    for a in rooms.values():
        a["rate"] = a["wins"] / a["n"] if a["n"] else 0.0
        w = sum(n for _, n in a["tw"])
        a["turns_won"] = sum(t * n for t, n in a["tw"]) / w if w else None
    return rooms


gs, gf = pool(load_sims("greedy", "starter")), pool(load_sims("greedy", "full"))
rs, rf = pool(load_sims("random", "starter")), pool(load_sims("random", "full"))

# BAL-01 / BAL-02 -------------------------------------------------------------
def band(rooms, low, high):
    return {"rooms": len(rooms), "n_per_room": st.median(r["n"] for r in rooms.values()),
            "overall": round(sum(r["wins"] for r in rooms.values()) / sum(r["n"] for r in rooms.values()), 4),
            "below": sorted([(k, r["name"], round(r["rate"], 2)) for k, r in rooms.items() if r["rate"] < low], key=lambda x: x[2]),
            "above": sorted([(k, r["name"], round(r["rate"], 2)) for k, r in rooms.items() if r["rate"] > high], key=lambda x: -x[2]),
            "median": round(st.median(r["rate"] for r in rooms.values()), 3)}
out["BAL-01"] = band(gs, 0.15, 0.95)
out["BAL-02"] = band(gf, 0.50, 0.98)
out["BAL-04"] = {"starter_in_50_90": sum(1 for r in gs.values() if 0.5 <= r["rate"] <= 0.9), "rooms": len(gs)}

# Families: BAL-03, BAL-05, BAL-07 --------------------------------------------
fam = collections.defaultdict(lambda: collections.defaultdict(lambda: [0, 0]))
fam_causes = collections.defaultdict(collections.Counter)
for label, rooms in (("gs", gs), ("gf", gf), ("rs", rs), ("rf", rf)):
    for k, r in rooms.items():
        f = family(k)
        fam[f][label][0] += r["wins"]; fam[f][label][1] += r["n"]
        if label == "gs":
            fam_causes[f].update(r["causes"])
rows = []
for f, d in sorted(fam.items()):
    rate = lambda l: (d[l][0] / d[l][1]) if d[l][1] else None
    causes = fam_causes[f]; total = sum(causes.values())
    top = causes.most_common(1)[0] if total else ("", 0)
    rows.append({"family": f, "rooms": sum(1 for k2 in gs if family(k2) == f),
                 "greedy_starter": rate("gs"), "greedy_full": rate("gf"), "random_starter": rate("rs"),
                 "kit_gain": (rate("gf") - rate("gs")) if rate("gf") is not None else None,
                 "skill_gap": rate("gs") - rate("rs"),
                 "top_loss_cause": top[0], "top_loss_share": (top[1] / total) if total else None, "losses": total})
out["families"] = rows
out["BAL-03"] = {"families": len(rows), "fail": [(r["family"], round(r["kit_gain"], 3)) for r in rows if r["kit_gain"] is not None and r["kit_gain"] < 0.10]}
out["BAL-05"] = {"fail": [(r["family"], round(r["skill_gap"], 3)) for r in rows if r["skill_gap"] < 0.20],
                 "overall_random_starter": round(sum(r["wins"] for r in rs.values()) / sum(r["n"] for r in rs.values()), 4)}
out["BAL-07"] = {"fail": [(r["family"], r["top_loss_cause"], round(r["top_loss_share"], 2), r["losses"]) for r in rows
                          if r["top_loss_share"] is not None and r["top_loss_share"] > 0.80 and r["losses"] >= 20]}
allc = collections.Counter()
for r in gs.values():
    allc.update(r["causes"])
out["loss_causes_overall_greedy_starter"] = dict(allc)

# BAL-06: turns used on a win, as a share of the limit --------------------------
ratios = []
for k, r in gs.items():
    if r["turns_won"] is None or not r["limit"] or r["bar"] == "Single":
        continue   # a press conference always runs its whole limit, by rule
    denom = r["limit"] * (max(r["opps"], 1) if r["seq"] == "reset" else 1)
    ratios.append((k, r["name"], r["turns_won"] / denom, r["seq"], r["limit"], r["opps"], round(r["turns_won"], 2)))
vals = [x[2] for x in ratios]
out["BAL-06"] = {"rooms": len(ratios), "median_ratio": round(st.median(vals), 3),
                 "in_band": sum(1 for v in vals if 0.40 <= v <= 0.85),
                 "below": sum(1 for v in vals if v < 0.40), "above": sum(1 for v in vals if v > 0.85),
                 "by_seq": {s: [round(st.median([x[2] for x in ratios if x[3] == s]), 3), sum(1 for x in ratios if x[3] == s)] for s in set(x[3] for x in ratios)},
                 "fastest": sorted([(x[0], x[1], round(x[2], 2)) for x in ratios], key=lambda x: x[2])[:5]}
rc = collections.Counter()
for r in rs.values():
    rc.update(r["causes"])
out["loss_causes_overall_random_starter"] = dict(rc)

# BAL-20 pressure ---------------------------------------------------------------
pr = {}
for p in ("relaxed", "standard", "harder"):
    sims = [s for s in load_sims("greedy", "starter", p) if s["meta"]["pc"] == "PC02" and s["meta"]["seed"] == 12]
    rooms = pool(sims)
    pr[p] = {"overall": sum(r["wins"] for r in rooms.values()) / max(sum(r["n"] for r in rooms.values()), 1), "fam": collections.defaultdict(lambda: [0, 0])}
    for k, r in rooms.items():
        pr[p]["fam"][family(k)][0] += r["wins"]; pr[p]["fam"][family(k)][1] += r["n"]
bad = []
for f in pr["standard"]["fam"]:
    v = [pr[p]["fam"][f][0] / max(pr[p]["fam"][f][1], 1) for p in ("relaxed", "standard", "harder")]
    if v[0] + 0.03 < v[1] or v[1] + 0.03 < v[2]:
        bad.append((f, [round(x, 2) for x in v], pr["standard"]["fam"][f][1]))
out["BAL-20"] = {"overall": {p: round(pr[p]["overall"], 4) for p in pr}, "families_out_of_order": bad}

# BAL-10 static card power ------------------------------------------------------
cards = json.load(open(DATA / "cards.json"))
num = lambda c, k: c.get(k) if isinstance(c.get(k), (int, float)) else 0
per = {c["card_id"]: (num(c, "self_plus") + num(c, "opp_minus") + num(c, "guard") + 1.5 * num(c, "draw") - 1.5 * num(c, "gaffe")) / max(num(c, "cost"), 1) for c in cards}
mu, sd = st.mean(per.values()), st.pstdev(per.values())
outliers = sorted([(c["card_id"], c["name_en"], c["suit"], c["tier"], round(per[c["card_id"]], 2), round((per[c["card_id"]] - mu) / sd, 2)) for c in cards if abs((per[c["card_id"]] - mu) / sd) >= 2.0], key=lambda x: -x[5])
suit_mean = {s: round(st.mean(per[c["card_id"]] for c in cards if c["suit"] == s), 2) for s in sorted(set(c["suit"] for c in cards))}
keys = ("self_plus", "opp_minus", "guard", "draw")
dominated = []
for a in cards:
    for b in cards:
        if a is b or a["suit"] != b["suit"]:
            continue
        if num(b, "cost") <= num(a, "cost") and all(num(b, k) >= num(a, k) for k in keys) and num(b, "gaffe") <= num(a, "gaffe") \
                and (num(b, "cost") < num(a, "cost") or any(num(b, k) > num(a, k) for k in keys) or num(b, "gaffe") < num(a, "gaffe")) \
                and not a.get("special") and not a.get("discard_to_play") and not a.get("discard_for_draw") \
                and not b.get("discard_to_play") and not b.get("discard_for_draw"):
            dominated.append((a["card_id"], a["name_en"], "by", b["card_id"], b["name_en"]))
            break
tier_mean = {t: round(st.mean(per[c["card_id"]] for c in cards if str(c["tier"]) == t), 2) for t in sorted(set(str(c["tier"]) for c in cards))}
out["BAL-10"] = {"mean": round(mu, 2), "sd": round(sd, 2), "outliers": outliers, "suit_mean": suit_mean,
                 "suit_spread": round(max(suit_mean.values()) / min(suit_mean.values()), 2),
                 "dominated": dominated, "tier_mean": tier_mean}

# Campaign runs (strategy bot) --------------------------------------------------
def runs(name):
    path = RES / name
    return [json.loads(l.split("RESULT ", 1)[-1]) for l in open(path) if l.strip()] if path.exists() else []
prot = [r for r in runs("strategy_protagonists.jsonl") if r["strategy"] == "baseline"]
allr = runs("strategy_all_pc02.jsonl")

# BAL-08 / BAL-09 from the baseline runs of all four protagonists
tally, suits = collections.Counter(), collections.Counter()
for r in prot:
    tally.update(r["card_tally"]); suits.update(r["suit_plays"])
mean_plays = sum(tally.values()) / len(cards)
out["BAL-08"] = {"runs": len(prot), "plays": sum(tally.values()), "mean_per_card": round(mean_plays, 1),
                 "over_3x": sorted([(c, n, round(n / mean_plays, 1)) for c, n in tally.items() if n > 3 * mean_plays], key=lambda x: -x[1]),
                 "never": sorted(c["card_id"] for c in cards if tally.get(c["card_id"], 0) == 0),
                 "owned_at_end": [r["owned_cards"] for r in prot]}
total = sum(suits.values())
out["BAL-09"] = {s: round(n / total, 4) for s, n in sorted(suits.items())}

# BAL-12 meta at ceiling (weekly series, weeks 1..30)
ceil = {}
for key in ("con", "rep", "party"):
    shares = []
    for r in prot:
        series = r["series"][1:]
        shares.append(sum(1 for w in series if w[key] >= 100) / len(series))
    ceil[key] = {"mean_share_at_100": round(st.mean(shares), 3), "max": round(max(shares), 3)}
    ceil[key]["final_values"] = [r[key] for r in prot]
# The frozen method is "level-ends": the playtest bot's ECON line after every level.
level_end = {}
for f in sorted(glob.glob(str(RES / "fullruns" / "econ_*.log"))):
    lines = [l for l in open(f) if "ECON level=" in l]
    for key in ("jiban", "rep", "party"):
        vals = [int(re.search(key + r"=(-?\d+)", l).group(1)) for l in lines]
        level_end.setdefault(key, []).append(sum(1 for v in vals if v >= 100) / max(len(vals), 1))
ceil["level_ends"] = {k: {"share_at_100_by_run": [round(x, 2) for x in v], "mean": round(st.mean(v), 3)} for k, v in level_end.items()}
ceil["party_at_or_above_90_week_ends"] = round(st.mean(sum(1 for w in r["series"][1:] if w["party"] >= 90) / 30 for r in prot), 3)
out["BAL-12"] = ceil

# BAL-13 organizations at the ceiling, from the playtest bot's ECON lines (per level-end)
org_share = collections.defaultdict(list)
org_low = collections.defaultdict(list)
for f in sorted(glob.glob(str(RES / "fullruns" / "econ_*.log"))):
    lines = [l for l in open(f) if "standings=" in l]
    counts, lows = collections.Counter(), collections.Counter()
    for l in lines:
        for pair in l.split("standings=")[1].strip().split(","):
            org, v = pair.split(":")
            if int(v) >= 100:
                counts[org] += 1
            if int(v) <= 5:
                lows[org] += 1
    for org in ["BO%02d" % i for i in range(1, 33)]:
        org_share[org].append(counts[org] / max(len(lines), 1))
        org_low[org].append(lows[org] / max(len(lines), 1))
out["BAL-13"] = {"runs": len(glob.glob(str(RES / "fullruns" / "econ_*.log"))),
                 "at_ceiling_90pct": sorted([(o, round(st.mean(v), 2)) for o, v in org_share.items() if v and st.mean(v) >= 0.90]),
                 "top_ceiling_share": sorted([(o, round(st.mean(v), 2)) for o, v in org_share.items() if v], key=lambda x: -x[1])[:6],
                 "near_zero_most_of_run": sorted([(o, round(st.mean(v), 2)) for o, v in org_low.items() if v and st.mean(v) >= 0.5])}

# BAL-16 dominant strategy
by = collections.defaultdict(list)
for r in allr:
    score = (min(r["funds"], 100000) / 100000 + r["es"] / 100 + r["party"] / 100) / 3
    by[r["strategy"]].append(score)
score = sorted(((s, st.mean(v), len(v)) for s, v in by.items()), key=lambda x: -x[1])
non_stress = [x for x in score if x[0] != "random_cards"]
med = st.median(x[1] for x in non_stress)
out["BAL-16"] = {"strategies": len(score), "runs": len(allr), "top5": [(s, round(v, 3), n) for s, v, n in score[:5]],
                 "median": round(med, 3), "best_over_median": round(score[0][1] / med, 3),
                 "single_suit_in_top3": [s for s, _, _ in score[:3] if s.endswith("_deck") and s.split("_")[0] in ("earnest", "emotional", "appeal", "data", "divisive", "duplicitous")],
                 "bottom3": [(s, round(v, 3)) for s, v, _ in score[-3:]]}

# BAL-17 dues, BAL-18 XP, BAL-21 run length
paid, owed, xp_end, per_week = [], [], [], []
for r in prot:
    weeks = [w for w in r["series"] if w["week"] >= 4]
    paid.append(sum(1 for w in weeks if w["week_dues"] <= 0 or w["week_paid"] >= w["week_dues"]) / max(len(weeks), 1))
    owed.append(r["dues_owed"]); xp_end.append(r["xp"])
    per_week.append({"pc": r["protagonist"], "levels": r["level_attempts"] / r["weeks"], "stages": r["stages"] / r["weeks"],
                     "combat": r["combat_stages_ended"] / r["weeks"], "wins": r["wins"], "losses": r["losses"]})
shop = json.load(open(DATA / "shop.json"))
levels = json.load(open(DATA / "levels.json"))
xp_prices = [v for row in shop for k, v in row.items() if "xp" in k.lower() and isinstance(v, (int, float))]
xp_prices += [v for row in levels for k, v in row.items() if k.startswith("unlock_cost") and isinstance(v, (int, float))]
out["BAL-17"] = {"runs": len(prot), "share_of_weeks_dues_paid_mean": round(st.mean(paid), 3), "min": round(min(paid), 3),
                 "dues_owed_at_week_30": sorted(owed), "weeks_overdue": sorted(r["weeks_overdue"] for r in prot)}
out["BAL-18"] = {"xp_at_week_30": sorted(xp_end), "median": st.median(xp_end), "dearest_xp_price": max(xp_prices) if xp_prices else None,
                 "xp_total_earned_median": st.median(r["xp_total"] for r in prot)}
out["BAL-21"] = {"per_week_mean": {k: round(st.mean(p[k] for p in per_week), 1) for k in ("levels", "stages", "combat")},
                 "stage_win_rate": round(sum(p["wins"] for p in per_week) / max(sum(p["wins"] + p["losses"] for p in per_week), 1), 3)}

# BAL-11 pick rate: what the bot's deck builder ended up owning (no target)
out["BAL-11"] = {"owned_cards_at_week_30": sorted(r["owned_cards"] for r in prot), "of": len(cards)}

# BAL-14 / BAL-15: static reward per hour by tier, and reward against measured difficulty
def rng_mid(v):
    if isinstance(v, dict) and "min" in v:
        return (v["min"] + v["max"]) / 2
    return v if isinstance(v, (int, float)) else 0
tiers = collections.defaultdict(list)
level_rows = []
for lv in levels:
    ids = [lv.get(f"stage_{i}") for i in range(1, 11) if lv.get(f"stage_{i}")]
    rows_ = [stages[i] for i in ids if i in stages]
    hours = sum(num(s, "time_units") for s in rows_)
    if not hours:
        continue
    funds = sum(num(s, "win_delta_yen") for s in rows_) + rng_mid(lv.get("bonus_win_range_yen"))
    xp = sum(num(s, "win_delta_xp") for s in rows_) + rng_mid(lv.get("bonus_win_range_xp"))
    combat = [gs[i]["rate"] for i in ids if i in gs]
    clear = 1.0
    for c in combat:
        clear *= c
    tiers[lv.get("tier")].append((funds / hours, xp / hours, hours))
    level_rows.append({"level": lv["level_id"], "tier": lv.get("tier"), "hours": hours, "funds_per_hour": funds / hours,
                       "xp_per_hour": xp / hours, "starter_clear_chance": clear if combat else None})
out["BAL-15"] = {str(t): {"levels": len(v), "funds_per_hour_median": round(st.median(x[0] for x in v)),
                           "xp_per_hour_median": round(st.median(x[1] for x in v), 1), "hours_median": st.median(x[2] for x in v)}
                 for t, v in sorted(tiers.items(), key=lambda x: str(x[0]))}
with_c = [r for r in level_rows if r["starter_clear_chance"] is not None]
hard = sorted(with_c, key=lambda r: r["starter_clear_chance"])
third = max(len(hard) // 3, 1)
out["BAL-14"] = {"levels_with_combat": len(with_c),
                 "hardest_third_funds_per_hour": round(st.median(r["funds_per_hour"] for r in hard[:third])),
                 "easiest_third_funds_per_hour": round(st.median(r["funds_per_hour"] for r in hard[-third:])),
                 "hardest_third_xp_per_hour": round(st.median(r["xp_per_hour"] for r in hard[:third]), 1),
                 "easiest_third_xp_per_hour": round(st.median(r["xp_per_hour"] for r in hard[-third:]), 1),
                 "hardest_third_clear": round(st.median(r["starter_clear_chance"] for r in hard[:third]), 2),
                 "easiest_third_clear": round(st.median(r["starter_clear_chance"] for r in hard[-third:]), 2)}

# Technical and invariants from the harness -------------------------------------
quiet = json.load(open(RES / "perf_quiet.json")) if (RES / "perf_quiet.json").exists() else None
allsims = [json.load(open(f)) for f in sorted(glob.glob(str(RES / "sim_*.json")))]
out["harness"] = {"runs": len(allsims), "fights": sum(r["n"] for s in allsims for r in s["rooms"] if not r.get("skipped")),
                  "violations": sum(len(s["violations"]) for s in allsims),
                  "violation_kinds": dict(collections.Counter(v["inv"] for s in allsims for v in s["violations"])),
                  "setup_problems": sum(r.get("setup_problems", 0) for s in allsims for r in s["rooms"]),
                  "determinism": [s["determinism"] for s in allsims][:1],
                  "determinism_all_same": all(s["determinism"].get("same_engine_seed_same_fight") for s in allsims),
                  "seating_same_under_global_seed": sum(1 for s in allsims if s["determinism"].get("same_global_seed_seats_same_opponent")),
                  "perf_quiet": quiet["perf"] if quiet else None,
                  "plays_timed": sum(s["perf"]["play_card_usec"]["n"] for s in allsims)}

json.dump(out, open(RES / "analysis.json", "w"), indent=1, default=str)
for key in ("BAL-01", "BAL-02", "BAL-03", "BAL-04", "BAL-05", "BAL-06", "BAL-07", "loss_causes_overall_greedy_starter", "loss_causes_overall_random_starter",
            "BAL-08", "BAL-09", "BAL-10", "BAL-11", "BAL-12", "BAL-13", "BAL-14", "BAL-15", "BAL-16", "BAL-17",
            "BAL-18", "BAL-20", "BAL-21", "harness"):
    print(f"\n== {key}\n{json.dumps(out[key], default=str)[:1500]}")
print("\n== families")
for r in out["families"]:
    f = lambda v: "  -  " if v is None else f"{v*100:5.1f}"
    print(f"{r['family'][:44]:44} rooms {r['rooms']:3}  starter {f(r['greedy_starter'])}  full {f(r['greedy_full'])}  random {f(r['random_starter'])}  gain {f(r['kit_gain'])}  {r['top_loss_cause']} {f(r['top_loss_share'])}")
