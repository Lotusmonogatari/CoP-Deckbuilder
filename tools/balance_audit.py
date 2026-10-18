#!/usr/bin/env python3
"""Balance audit: finds lopsided elements across the game's mechanics.

    python3 tools/balance_audit.py [--logs design/bench/balance] [--out design/BALANCE_AUDIT.md]

Static half: reads data/*.json (cards, affinity, stages, opponents, questions,
organizations, bills, parties, shop, levels). Dynamic half: reads the logs
tools/balance_audit.sh wrote (stage win-rate sweeps, full-run economy traces,
card-play tallies). Every area ends in FLAGS: a severity, what is lopsided and
the evidence. The thresholds are all in THRESHOLDS below, so "lopsided" is a
number somebody chose and can change. Process: design/BALANCE_AUDIT_PROCESS.md.
Standard library only.
"""
import argparse, collections, glob, json, math, os, re, statistics, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
D = ROOT / "data"

THRESHOLDS = {
    "gini_high": 0.40,            # inequality across options of one mechanic
    "dominant_share": 0.25,       # one option holding this share of a total
    "outlier_z": 2.0,             # card power per energy, z-score
    "stage_starter_low": 0.15,    # first-time win rate below this: a wall
    "stage_starter_high": 0.95,   # above this: no challenge
    "stage_full_low": 0.50,       # a late, well-kitted player still loses this often
    "stage_full_high": 0.98,
    "kit_gap_min": 0.10,          # full kit should beat starter by this much
    "never_played_share": 0.0,
    "card_top_multiple": 3.0,     # a card played this many times the mean
    "org_cap_turn": 0.90,         # share of a run an organization sits at its ceiling
    "rewards_ratio": 3.0,         # reward per difficulty, family vs median
    "suit_spread": 1.35,          # best suit total power / worst
    "flip_share_low": 0.10, "flip_share_high": 0.60,
}
FLAGS = []   # (severity, area, message, evidence)


def flag(sev, area, msg, evidence=""):
    FLAGS.append((sev, area, msg, evidence))


def load(name):
    return json.load(open(D / f"{name}.json"))


def gini(values):
    v = sorted(x for x in values if x >= 0)
    n = len(v)
    if n == 0 or sum(v) == 0:
        return 0.0
    return sum((2 * (i + 1) - n - 1) * x for i, x in enumerate(v)) / (n * sum(v))


def table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


# --------------------------------------------------------------------------
# Static analyses
# --------------------------------------------------------------------------

def cards_section():
    cards, aff = load("cards"), {a["element"]: a["multipliers"] for a in load("affinity")}
    suits = [s["element"] for s in load("suits")]
    # Raw value: gain + attack points, plus guard and draw at assumed worth, minus gaffe.
    def value(c):
        return c["self_plus"] + c["opp_minus"] + 1.0 * c["guard"] + 1.5 * c["draw"] - 1.5 * c["gaffe"]
    rows, per_energy = [], {}
    for c in cards:
        e = max(c["cost"], 0.5)
        per_energy[c["card_id"]] = value(c) / e
    mu = statistics.mean(per_energy.values()); sd = statistics.pstdev(per_energy.values()) or 1
    by_suit = collections.defaultdict(list)
    for c in cards:
        by_suit[c["suit"]].append(per_energy[c["card_id"]])
        z = (per_energy[c["card_id"]] - mu) / sd
        if abs(z) >= THRESHOLDS["outlier_z"]:
            flag("Medium", "Cards", f"{c['card_id']} {c['name_en']} ({c['suit']}, tier {c['tier']}) is a power outlier",
                 f"{per_energy[c['card_id']]:.2f} value per energy vs mean {mu:.2f} (z {z:+.1f})")
    suit_rows = []
    for s in suits:
        v = by_suit[s]
        suit_rows.append((s, len(v), f"{statistics.mean(v):.2f}", f"{max(v):.2f}", f"{sum(1 for c in cards if c['suit']==s and c['gaffe']>0)}"))
    means = [statistics.mean(by_suit[s]) for s in suits]
    if max(means) / max(min(means), 0.01) > THRESHOLDS["suit_spread"]:
        hi, lo = suits[means.index(max(means))], suits[means.index(min(means))]
        flag("Medium", "Cards", f"Suit power is uneven: {hi} averages {max(means):.2f} per energy, {lo} {min(means):.2f}",
             "Gaffe-heavy suits pay for it in the gaffe meter, so check the table's gaffe column before acting")
    # Dominated cards: same suit, another card costs no more and is at least as good in every number
    dominated = []
    for a in cards:
        for b in cards:
            if a is b or a["suit"] != b["suit"]:
                continue
            ka = (a["self_plus"], a["opp_minus"], a["guard"], a["draw"], -a["gaffe"])
            kb = (b["self_plus"], b["opp_minus"], b["guard"], b["draw"], -b["gaffe"])
            if b["cost"] <= a["cost"] and all(y >= x for x, y in zip(ka, kb)) and ka != kb and not a["special"] and not b["special"]:
                dominated.append((a["card_id"], b["card_id"]))
    if dominated:
        flag("Medium", "Cards", f"{len(dominated)} cards are strictly worse than a same-suit card",
             "; ".join(f"{x} < {y}" for x, y in dominated[:8]))
    tier_rows = []
    for t in sorted(set(c["tier"] for c in cards)):
        v = [per_energy[c["card_id"]] for c in cards if c["tier"] == t]
        tier_rows.append((t, len(v), f"{statistics.mean(v):.2f}"))
    tier_means = {r[0]: float(r[2]) for r in tier_rows}
    ts = sorted(tier_means)
    if len(ts) > 1 and tier_means[ts[-1]] <= tier_means[ts[0]]:
        flag("High", "Cards", "Higher tiers are not stronger per energy: tier progression buys no power",
             str(tier_means))
    # Affinity
    aff_rows, rooms = [], sorted({k for m in aff.values() for k in m})
    for s in suits:
        vals = [aff[s][r] for r in rooms if r in aff[s]]
        aff_rows.append((s, f"{statistics.mean(vals):.2f}", sum(1 for v in vals if v >= 1.3), sum(1 for v in vals if v <= 0.7)))
    fav_counts = [r[2] for r in aff_rows]
    if max(fav_counts) > 2 * max(min(fav_counts), 1):
        flag("Medium", "Affinity", "Some suits are favored in far more rooms than others",
             ", ".join(f"{r[0]} {r[2]} favored / {r[3]} resisted" for r in aff_rows))
    best_per_room = collections.Counter()
    for r in rooms:
        top = max(suits, key=lambda s: aff[s].get(r, 1.0))
        best_per_room[top] += 1
    return {"suit_rows": suit_rows, "tier_rows": tier_rows, "aff_rows": aff_rows, "best_room": best_per_room, "per_energy": per_energy}


def stages_section():
    """Static difficulty: points the player must add per energy available.
    A `reset` stage (committees) refights from scratch with full energy and clock
    for each opponent, so it is need / one bout's energy. A `stream` or
    `continuous` stage shares one clock (and, in continuous, one energy pool)
    across its opponents, so it is need x opponents / that one budget. A single
    fight is need / its budget."""
    stages = [s for s in load("stages") if s["mode"] == "Combat"]
    rows = []
    for s in stages:
        pool = s.get("energy_pool")
        budget = (pool if pool else s["energy_per_turn"] * s["turn_limit"])
        need = (s["win_threshold"] or 0) - (s["player_start"] or 0)
        n_opp = (s["opponent_count"] or {}).get("max", 1) if isinstance(s["opponent_count"], dict) else 1
        mode = s.get("sequence_mode") or "single"
        total_need = need * n_opp if mode in ("stream", "continuous") else need
        reward = (s["win_delta_xp"] or 0) / 10 + (s["win_delta_yen"] or 0) / 5000 + (s["win_delta_jiban"] or 0) + (s["win_delta_reputation"] or 0) + (s["win_delta_party_support"] or 0)
        rows.append({"id": s["stage_id"], "name": s["name_en"], "need": total_need, "energy": budget,
                     "ppe": total_need / max(budget, 1), "reward": reward, "opp": n_opp, "mode": mode,
                     "gaffe": s["gaffe_limit"], "xp": s["win_delta_xp"] or 0, "model": s.get("bar_model") or "Shared_pool"})
    return rows


def questions_section():
    q = load("questions")
    P = {"S": 1, "M": 0, "W": -1}
    suits = [s["element"] for s in load("suits")]
    allq = [x for pool in q.values() for x in pool]
    # suit grade totals: is one suit the best answer too often?
    totals = {s: sum(P[x["grades"][s]] for x in allq) for s in suits}
    best = collections.Counter()
    for x in allq:
        top = max(P[x["grades"][s]] for s in suits)
        for s in suits:
            if P[x["grades"][s]] == top:
                best[s] += 1
    org = collections.defaultdict(lambda: {"pleased": 0, "opposed": 0})
    for x in allq:
        for b in x["pleases_boosters"] or []:
            org[b]["pleased"] += 1
        for b in x.get("displeases_boosters") or []:
            org[b]["opposed"] += 1
    names = {b["booster_id"]: b["name_en"] for b in load("boosters")}
    pl = {b: org[b]["pleased"] for b in names}
    g = gini(list(pl.values()))
    if g > THRESHOLDS["gini_high"]:
        flag("Medium", "Organizations", f"Question coverage is unequal across organizations (Gini {g:.2f})",
             f"most: {max(pl, key=pl.get)} {max(pl.values())}, least: {min(pl, key=pl.get)} {min(pl.values())}")
    low = [b for b, n in pl.items() if n < 15]
    if low:
        flag("Medium", "Organizations", f"{len(low)} organizations are pleased by fewer than 15 questions",
             ", ".join(f"{b} {pl[b]}" for b in low))
    top_share = max(pl.values()) / max(sum(pl.values()), 1)
    if top_share > THRESHOLDS["dominant_share"]:
        flag("Low", "Organizations", f"One organization takes {top_share:.0%} of all pleasing", f"{max(pl, key=pl.get)}")
    # Suit that is a strong answer in the most questions
    spread = max(best.values()) / max(min(best.values()), 1)
    return {"totals": totals, "best": best, "org": org, "names": names, "gini": g, "n": len(allq)}


def organizations_section():
    boosters = load("boosters")
    mods = {m["mod_id"]: m for m in load("modifiers")}
    links = load("standing_links") if (D / "standing_links.json").exists() else []
    rows = []
    for b in boosters:
        mm = [mods[m] for m in (b["linked_modifiers"] or []) if m in mods]
        cost = sum((m["reputation_cost"] or 0) + (m["jiban_cost"] or 0) + (m["funds_cost"] or 0) / 1000 for m in mm)
        rows.append((b["booster_id"], b["name_en"], b["tier"], b["starting_standing"], b.get("decay_percent"), b.get("party_lean_multiplier"),
                     ", ".join(m["effect_type"] for m in mm) or "-", f"{cost:.0f}"))
    # law effects
    law = load("law_effects")
    fav, ann = collections.Counter(), collections.Counter()
    for r in law:
        if r["outcome"] == "Passed" and r["timing"] in (None, "Once"):
            for e in r["effects"] or []:
                (fav if e["delta"] > 0 else ann)[e["target"]] += 1
    return {"rows": rows, "fav": fav, "ann": ann}


def bills_section():
    bills = load("floor_votes")
    parties = {p["party_id"]: p["name"] for p in load("parties")}
    seats = 101
    passed = 0
    marg = []
    proponents = collections.Counter()
    disp = collections.defaultdict(collections.Counter)
    for bid, b in bills.items():
        yes = sum(p["yes"] if "yes" in p else p.get("votes", [0, 0, 0])[0] for p in b["positions"]) if "yes" in b["positions"][0] or "votes" in b["positions"][0] else None
        proponents[b.get("proponent_party")] += 1
        for p in b["positions"]:
            disp[p["party_id"]][p["disposition"]] += 1
    return {"proponents": proponents, "disp": disp, "parties": parties, "n": len(bills), "sample": list(bills.values())[0]["positions"][0]}


def economy_static():
    levels = load("levels"); stages = {s["stage_id"]: s for s in load("stages")}
    xp_total = 0
    for lv in levels:
        for i in range(1, 11):
            sid = lv.get(f"stage_{i}")
            if sid in stages:
                xp_total += stages[sid]["win_delta_xp"] or 0
    cards = load("cards"); cost_all = sum(c["xp_to_unlock"] or 0 for c in cards)
    return {"levels": len(levels), "xp_per_pass": xp_total, "card_xp_total": cost_all}


# --------------------------------------------------------------------------
# Dynamic analyses
# --------------------------------------------------------------------------

def parse_sweeps(logdir):
    out = {"starter": collections.defaultdict(lambda: [0, 0, 0.0, 0.0, 0]), "full": collections.defaultdict(lambda: [0, 0, 0.0, 0.0, 0])}
    pat = re.compile(r"SWEEP stage=(\w+) won=(\d+) of=(\d+) cards=([\d.]+) turns=([\d.]+)")
    for path in glob.glob(os.path.join(logdir, "sweep_*.log")):
        kit = "starter" if "starter" in path else "full"
        for line in open(path, errors="replace"):
            m = pat.search(line)
            if m:
                a = out[kit][m.group(1)]
                a[0] += int(m.group(2)); a[1] += int(m.group(3)); a[2] += float(m.group(4)) * int(m.group(3)); a[3] += float(m.group(5)) * int(m.group(3)); a[4] += 1
    return out


def parse_full_runs(logdir):
    runs = {}
    econ = re.compile(r"ECON level=(\w+) attempt=(\d+) xp=(\d+) funds=(-?\d+) jiban=(-?\d+) rep=(-?\d+) party=(-?\d+) party_eff=(-?\d+) cards=(\d+) backing=(\d+) items=(\d+) standings=(\S*)")
    for path in sorted(glob.glob(os.path.join(logdir, "full_*.log"))):
        pc = Path(path).stem.split("_")[1]
        r = {"econ": [], "summary": {}, "tally": {}, "types": {}}
        for line in open(path, errors="replace"):
            m = econ.search(line)
            if m:
                st = {k: int(v) for k, v in (kv.split(":") for kv in m.group(12).split(",") if ":" in kv)}
                r["econ"].append({"level": m.group(1), "attempt": int(m.group(2)), "xp": int(m.group(3)), "funds": int(m.group(4)),
                                  "jiban": int(m.group(5)), "rep": int(m.group(6)), "party": int(m.group(7)), "party_eff": int(m.group(8)),
                                  "cards": int(m.group(9)), "backing": int(m.group(10)), "items": int(m.group(11)), "st": st})
            if "Level attempts:" in line:
                nums = re.findall(r"(\d+)", line); r["summary"].update(attempts=int(nums[0]), stages=int(nums[1]), wins=int(nums[2]), losses=int(nums[3]))
            if "Levels completed at least once" in line:
                r["summary"]["completed"] = [int(x) for x in re.findall(r"(\d+)", line)[:2]]
            if line.startswith("CARD_TALLY"):
                r["tally"] = {k: int(v) for k, v in re.findall(r'"(C\d+)": (\d+)', line)}
            if line.startswith("stage_type_results"):
                r["types"] = {k: (int(w), int(l)) for k, w, l in re.findall(r'"(ST\d+)": \{ "wins": (\d+), "losses": (\d+)', line)}
        runs[pc] = r
    return runs


# --------------------------------------------------------------------------
# Report
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--logs", default=str(ROOT / "design/bench/balance"))
    ap.add_argument("--out", default=str(ROOT / "design/BALANCE_AUDIT.md"))
    args = ap.parse_args()
    T = THRESHOLDS
    md = []
    add = md.append

    cs = cards_section()
    add("## 1. Cards and rhetorical styles\n")
    add(table(["Style", "Cards", "Mean value/energy", "Best card", "Gaffe cards"], cs["suit_rows"]))
    add("\nTier power (mean value per energy):\n")
    add(table(["Tier", "Cards", "Mean value/energy"], cs["tier_rows"]))
    add("\nStage affinity (how often each style is favored/resisted across rooms):\n")
    add(table(["Style", "Mean multiplier", "Favored rooms (>=1.3)", "Resisted rooms (<=0.7)"], cs["aff_rows"]))
    add("\nBest style per room: " + ", ".join(f"{k} {v}" for k, v in cs["best_room"].most_common()) + "\n")

    qs = questions_section()
    add("## 2. Questions, organizations and styles\n")
    add(f"{qs['n']} questions. Style totals (strong +1, weak -1 over every question): " + ", ".join(f"{k} {v:+d}" for k, v in qs["totals"].items()) + ".\n")
    best_total = sum(qs["best"].values())
    for s, n in qs["best"].items():
        if n / best_total > 0.30:
            flag("Medium", "Rhetoric", f"{s} is a top-graded answer in {n / best_total:.0%} of questions", f"counts: {dict(qs['best'])}")
    avg_best = best_total / 6
    if max(qs["totals"].values()) - min(qs["totals"].values()) > 0.35 * qs["n"]:
        hi = max(qs["totals"], key=qs["totals"].get); lo = min(qs["totals"], key=qs["totals"].get)
        flag("Medium", "Rhetoric", f"Question grading favors {hi} over {lo}", f"net {qs['totals'][hi]:+d} vs {qs['totals'][lo]:+d} over {qs['n']} questions")
    org_rows = []
    for b, name in qs["names"].items():
        o = qs["org"][b]
        org_rows.append((b, name, o["pleased"], o["opposed"]))
    org_rows.sort(key=lambda r: -r[2])
    add(table(["Org", "Name", "Questions pleasing", "Questions setting back"], org_rows))
    add(f"\nGini of pleasing across organizations: {qs['gini']:.2f}\n")

    og = organizations_section()
    add("## 3. Organizations, backings and bills\n")
    add(table(["Org", "Name", "Tier", "Start", "Decay %", "Lean x", "Backing effect", "Backing cost (points)"], og["rows"]))
    fav, ann = og["fav"], og["ann"]
    ids = [r[0] for r in og["rows"] if r[2] != "Party"]
    gap = [(i, fav[i], ann[i]) for i in ids]
    add("\nBills (Passed rows) favoring / annoying each non-Party organization: " + ", ".join(f"{i} {f}/{a}" for i, f, a in gap if abs(f - a) >= 5) + " (only |difference| >= 5 shown)\n")
    for i, f, a in gap:
        if f == 0 or a == 0:
            flag("Low", "Bills", f"{i} is only ever {'favored' if a == 0 else 'annoyed'} by bills", f"{f} favoring, {a} annoying")
        if f + a >= 8 and max(f, a) / max(min(f, a), 1) >= 3:
            flag("Low", "Bills", f"{i} is lopsided in bills: {f} favoring vs {a} annoying", "")

    bl = bills_section()
    add("## 4. Bills and parties\n")
    add(f"{bl['n']} bills. Proponents: " + ", ".join(f"{bl['parties'].get(k,k)} {v}" for k, v in bl["proponents"].most_common()) + "\n")
    drows = []
    for pid, c in bl["disp"].items():
        drows.append((bl["parties"].get(pid, pid), c["Supportive"], c["Opposed"], c["Neutral"]))
    add(table(["Party", "Supportive", "Opposed", "Neutral"], drows))
    pv = [c["Supportive"] + c["Opposed"] for c in bl["disp"].values()]
    pr = [c["Proponent"] if False else 0 for c in bl["disp"].values()]
    if bl["proponents"]:
        top = bl["proponents"].most_common(1)[0]
        if top[1] / bl["n"] > 0.25:
            flag("Low", "Bills", f"{bl['parties'].get(top[0], top[0])} proposes {top[1]} of {bl['n']} bills", "")
        for pid in bl["parties"]:
            if bl["proponents"].get(pid, 0) <= 2:
                flag("Low", "Bills", f"{bl['parties'][pid]} proposes only {bl['proponents'].get(pid, 0)} bills", "")
    for pid, c in bl["disp"].items():
        sup, opp = c["Supportive"], c["Opposed"]
        if min(sup, opp) and max(sup, opp) / min(sup, opp) > 1.8:
            flag("Low", "Parties", f"{bl['parties'].get(pid, pid)} is lopsided across bills: {sup} supportive vs {opp} opposed", "")

    # Stages: static
    stg = stages_section()
    ppes = [r["ppe"] for r in stg if r["model"] != "Survival" and r["energy"] > 0]
    add("## 5. Stages (static difficulty and reward)\n")
    add("Points the player must add per energy available (stream and continuous rooms need the gap once per opponent on one shared budget; reset rooms refight from scratch per opponent). Higher is harder.\n")
    srows = sorted(stg, key=lambda r: -r["ppe"])
    add(table(["Stage", "Name", "Sequence", "Need", "Energy", "Need/energy", "Opponents", "Win XP", "Reward index"],
              [(r["id"], r["name"], r["mode"], r["need"], r["energy"], f"{r['ppe']:.2f}", r["opp"], r["xp"], f"{r['reward']:.1f}") for r in srows[:14]]))
    fam_ppe = collections.defaultdict(list)
    for r in stg:
        fam_ppe[re.sub(r"(:.*$|\s+(on|at|for)\s+.*$)", "", r["name"])].append(r["ppe"])
    add("\nMean need/energy by family: " + ", ".join(f"{k} {statistics.mean(v):.2f}" for k, v in sorted(fam_ppe.items(), key=lambda kv: -statistics.mean(kv[1]))) + "\n")
    add("\n(top 14 hardest by need/energy.)\n")

    # Dynamic: sweeps
    sw = parse_sweeps(args.logs)
    fr = parse_full_runs(args.logs)
    add("## 6. Win rates by stage (bot sweeps)\n")
    if sw["starter"] and sw["full"]:
        names = {s["stage_id"]: s["name_en"] for s in load("stages")}
        rows = []
        fam = collections.defaultdict(list)
        grouped = {}
        for sid in sorted(sw["full"], key=lambda x: int(x[2:])):
            f = sw["full"][sid]; s = sw["starter"].get(sid, [0, 1, 0, 0, 0])
            fw, sw_ = f[0] / max(f[1], 1), s[0] / max(s[1], 1)
            rows.append((sid, names.get(sid, ""), f"{sw_:.0%}", f"{fw:.0%}", f"{fw - sw_:+.0%}", f"{f[2] / max(f[1], 1):.0f}", f"{f[3] / max(f[1], 1):.1f}"))
            name = names.get(sid, "")
            family = re.sub(r"(:.*$|\s+(on|at|for)\s+.*$)", "", name)
            fam[family].append((sid, sw_, fw))
            grouped.setdefault(family, collections.defaultdict(list))
            if sw_ < T["stage_starter_low"]:
                grouped[family]["wall"].append((sid, sw_, fw))
            if sw_ > T["stage_starter_high"]:
                grouped[family]["easy"].append((sid, sw_, fw))
            if fw < T["stage_full_low"]:
                grouped[family]["late"].append((sid, sw_, fw))
            if fw - sw_ < T["kit_gap_min"] and sw_ < 0.9:
                grouped[family]["flat"].append((sid, sw_, fw))
        add(table(["Stage", "Name", "Starter kit", "Full kit", "Kit gain", "Cards/fight", "Turns/fight"], rows))
        add("\nFamilies (average win rate across the family's rooms):\n")
        frows = []
        for family, items in sorted(fam.items()):
            frows.append((family, len(items), f"{statistics.mean(i[1] for i in items):.0%}", f"{statistics.mean(i[2] for i in items):.0%}",
                          f"{min(i[1] for i in items):.0%}-{max(i[1] for i in items):.0%}"))
        add(table(["Family", "Rooms", "Starter avg", "Full avg", "Starter range"], frows))
        for family, kinds in sorted(grouped.items()):
            total = len(fam[family])
            for kind, items in kinds.items():
                ev = ", ".join(f"{i[0]} {i[1]:.0%}->{i[2]:.0%}" for i in items[:6]) + (" ..." if len(items) > 6 else "")
                share = len(items) / total
                if kind == "wall":
                    flag("High" if all(i[2] < 0.5 for i in items) else "Medium", "Stages",
                         f"{family}: a first-time player almost never wins in {len(items)} of {total} rooms", ev)
                elif kind == "easy":
                    flag("Low" if total < 5 else "Medium", "Stages", f"{family}: no challenge for a first-time player in {len(items)} of {total} rooms", ev)
                elif kind == "late":
                    flag("High", "Stages", f"{family}: a fully kitted player still loses in {len(items)} of {total} rooms", ev)
                elif kind == "flat":
                    flag("Medium", "Progression", f"{family}: the full kit barely helps in {len(items)} of {total} rooms", ev)
        # How well does the static difficulty predict what the bot actually did?
        by_id = {r["id"]: r for r in stg}
        xs = [by_id[i[0]]["ppe"] for v in fam.values() for i in v if i[0] in by_id]
        ys = [i[1] for v in fam.values() for i in v if i[0] in by_id]
        rs = [by_id[i[0]]["reward"] for v in fam.values() for i in v if i[0] in by_id]
        def pearson(a_, b_):
            ma, mb = statistics.mean(a_), statistics.mean(b_)
            num = sum((x - ma) * (y - mb) for x, y in zip(a_, b_))
            den = math.sqrt(sum((x - ma) ** 2 for x in a_) * sum((y - mb) ** 2 for y in b_)) or 1
            return num / den
        r_pred = pearson(xs, ys)
        r_reward = pearson(xs, rs)
        add(f"\nValidation of the static difficulty model: correlation between need/energy and the starter-kit win rate is {r_pred:+.2f} (strongly negative means the static table predicts the fights). Correlation between difficulty and reward index is {r_reward:+.2f} (positive means harder rooms pay more).\n")
        if r_pred > -0.5:
            flag("Medium", "Method", "The static difficulty model does not predict win rates well", f"r = {r_pred:+.2f}: trust the sweeps, not the table")
        if r_reward < 0.3:
            flag("Medium", "Rewards", "Reward does not rise with difficulty across combat rooms", f"correlation {r_reward:+.2f} between need/energy and reward index")
        fam_reward = collections.defaultdict(list)
        for i, x in by_id.items():
            fam_reward[re.sub(r"(:.*$|\s+(on|at|for)\s+.*$)", "", x["name"])].append(x["reward"])
        add("Reward index by family (win XP/10 + Funds/5,000 + meta points): " + ", ".join(f"{k} {statistics.mean(v):.0f}" for k, v in sorted(fam_reward.items(), key=lambda kv: -statistics.mean(kv[1]))) + "\n")
        allstart = [i[1] for v in fam.values() for i in v]
        add(f"\nAll combat rooms: starter average {statistics.mean(allstart):.0%} (median {statistics.median(allstart):.0%}).\n")
    else:
        add("_No sweep logs found; run tools/balance_audit.sh._\n")

    # Dynamic: full runs
    add("## 7. Full runs: economy, standings and card use\n")
    if fr:
        srow = []
        for pc, r in fr.items():
            s = r["summary"]; e = r["econ"]
            last = e[-1] if e else {}
            srow.append((pc, s.get("attempts"), s.get("wins"), s.get("losses"), "/".join(str(x) for x in s.get("completed", [])),
                         last.get("xp"), last.get("funds"), last.get("cards"), last.get("backing"), last.get("party_eff")))
        add(table(["Protagonist", "Level attempts", "Stage wins", "Stage losses", "Levels done", "End XP", "End Funds", "Cards owned", "Backings", "Party opinion"], srow))
        # standings: share of levels each org sits at >=90 / <=10; mean
        names = {b["booster_id"]: b["name_en"] for b in load("boosters")}
        agg = collections.defaultdict(lambda: {"hi": 0, "lo": 0, "n": 0, "sum": 0, "max": 0})
        for r in fr.values():
            for e in r["econ"]:
                for b, v in e["st"].items():
                    a = agg[b]; a["n"] += 1; a["sum"] += v; a["max"] = max(a["max"], v)
                    a["hi"] += v >= 90; a["lo"] += v <= 10
        arows = []
        for b, a in sorted(agg.items()):
            hi, lo = a["hi"] / a["n"], a["lo"] / a["n"]
            arows.append((b, names.get(b, ""), f"{a['sum'] / a['n']:.0f}", a["max"], f"{hi:.0%}", f"{lo:.0%}"))
            if hi >= T["org_cap_turn"] * 0.5:
                flag("Medium", "Organizations", f"{b} {names.get(b,'')} sits at its ceiling in {hi:.0%} of level-ends", "standing stops mattering")
            if lo >= 0.5:
                flag("Medium", "Organizations", f"{b} {names.get(b,'')} sits near zero in {lo:.0%} of level-ends", "it can never be won over")
        unreachable = [b for b, v in agg.items() if v["max"] < 60]
        if unreachable:
            flag("Medium", "Organizations", f"{len(unreachable)} organizations never reached the 60 standing a backing needs, in four full runs",
                 ", ".join(f"{b} {names.get(b,'')} (peak {agg[b]['max']})" for b in sorted(unreachable)))
        reach_low = [b for b, v in agg.items() if v["sum"] / v["n"] < 30]
        if reach_low:
            flag("Low", "Organizations", f"{len(reach_low)} organizations average under 30 standing across the run", ", ".join(f"{b} {names.get(b,'')} ({agg[b]['sum'] / agg[b]['n']:.0f})" for b in sorted(reach_low)))
        add("\nOrganization standing at the end of every level (all four protagonists):\n")
        add(table(["Org", "Name", "Mean", "Peak", "Share of level-ends >= 90", "Share <= 10"], arows))
        # economy curve
        add("\nEconomy over the run (median across protagonists at the n-th level-end):\n")
        steps = [5, 10, 20, 40, 60, 80]
        erows = []
        for n in steps:
            pick = [r["econ"][n - 1] for r in fr.values() if len(r["econ"]) >= n]
            if pick:
                erows.append((n, f"{statistics.median(p['xp'] for p in pick):.0f}", f"{statistics.median(p['funds'] for p in pick):,.0f}",
                              f"{statistics.median(p['rep'] for p in pick):.0f}", f"{statistics.median(p['jiban'] for p in pick):.0f}",
                              f"{statistics.median(p['party_eff'] for p in pick):.0f}", f"{statistics.median(p['cards'] for p in pick):.0f}",
                              f"{statistics.median(p['backing'] for p in pick):.0f}", f"{statistics.median(p['items'] for p in pick):.0f}"))
        add(table(["Level-end #", "XP", "Funds", "Reputation", "Constituency", "Party opinion", "Cards", "Backings", "Items bought"], erows))
        for pc, r in fr.items():
            for key, label in (("rep", "Reputation"), ("jiban", "Constituency support"), ("party", "Party support")):
                vals = [e[key] for e in r["econ"]]
                if vals and sum(1 for v in vals if v >= 95) / len(vals) > 0.5:
                    flag("Medium", "Meta", f"{pc}: {label} sits at the ceiling for most of the run", f"{sum(1 for v in vals if v >= 95)}/{len(vals)} level-ends >= 95")
            items = r["econ"][-1]["items"] if r["econ"] else 0
            if items > 300:
                flag("Medium", "Shop", f"{pc}: the bot bought {items} items in one run", "items are cheap relative to income (consumables are free power)")
            xp = [e["xp"] for e in r["econ"]]
            if xp and max(xp) > 2500:
                flag("Low", "Economy", f"{pc}: XP piles up to {max(xp)} with nothing left to buy", "")
        # card usage
        tally = collections.Counter()
        for r in fr.values():
            tally.update(r["tally"])
        # The full-kit sweeps rebuild the strongest legal deck, so their tallies show
        # which cards a deck-builder keeps choosing (by the bot's own measure).
        for path in glob.glob(os.path.join(args.logs, "sweep_full_*.log")):
            for line in open(path, errors="replace"):
                if line.startswith("CARD_TALLY"):
                    tally.update({k: int(v) for k, v in re.findall(r'"(C\d+)": (\d+)', line)})
        cards = load("cards")
        total = sum(tally.values()) or 1
        mean = total / len(cards)
        crow = []
        by_suit_plays = collections.Counter()
        for c in sorted(cards, key=lambda c: -tally.get(c["card_id"], 0)):
            n = tally.get(c["card_id"], 0)
            by_suit_plays[c["suit"]] += n
            crow.append((c["card_id"], c["name_en"], c["suit"], c["tier"], c["cost"], n, f"{n / total:.1%}"))
            if n == 0:
                flag("Medium", "Cards", f"{c['card_id']} {c['name_en']} ({c['suit']}) was never played in four full runs", "dead card or never worth its cost")
            elif n > T["card_top_multiple"] * mean:
                flag("Medium", "Cards", f"{c['card_id']} {c['name_en']} ({c['suit']}) is played {n / mean:.1f}x the average card", f"{n} plays")
        add("\nCard play counts across the four full runs and two full-kit sweeps (the bot builds the strongest legal deck, so this shows what a deck-builder keeps choosing, not what a person would; top 12 and bottom 12):\n")
        add(table(["Card", "Name", "Style", "Tier", "Cost", "Plays", "Share"], crow[:12] + [("...",) * 7] + crow[-12:]))
        add("\nPlays by style: " + ", ".join(f"{k} {v / total:.0%}" for k, v in by_suit_plays.most_common()) + "\n")
        sg = gini([tally.get(c["card_id"], 0) for c in cards])
        add(f"Gini of card usage: {sg:.2f}\n")
        if sg > T["gini_high"]:
            flag("Medium", "Cards", f"Card use is concentrated (Gini {sg:.2f})", "a few cards do most of the work")
        top_suit = by_suit_plays.most_common(1)[0]
        if top_suit[1] / total > 0.28:
            flag("Medium", "Rhetoric", f"{top_suit[0]} makes up {top_suit[1] / total:.0%} of all plays", "one style is the default answer")
        # stage-type results from the full runs
        t = collections.defaultdict(lambda: [0, 0])
        for r in fr.values():
            for sid, (w, l) in r["types"].items():
                t[sid][0] += w; t[sid][1] += l
        lost = [(sid, w, l) for sid, (w, l) in t.items() if w + l >= 10 and l / (w + l) > 0.4]
        for sid, w, l in lost:
            flag("Medium", "Stages", f"{sid} was lost {l} of {w + l} times in full runs", "")
    else:
        add("_No full-run logs found._\n")

    ec = economy_static()
    add("## 8. Rewards and costs (static)\n")
    add(f"{ec['levels']} levels; one pass of every level pays about {ec['xp_per_pass']} XP from stage wins; unlocking every card costs {ec['card_xp_total']} XP.\n")
    shop = load("shop")
    srows = [(s["item_id"], s["name"][:38], s["cost_xp"], s["cost_yen"], s["duration"] or "-", s["use_in_stage"] or s["use_in_office"] or "-") for s in shop]
    add(table(["Item", "Name", "XP", "Yen", "Duration", "Use"], srows))

    # ---------------- flags ----------------
    order = {"High": 0, "Medium": 1, "Low": 2}
    FLAGS.sort(key=lambda f: (order[f[0]], f[1]))
    add("\n## 9. Flags\n")
    add(f"{len(FLAGS)} flags: " + ", ".join(f"{sum(1 for f in FLAGS if f[0] == s)} {s}" for s in order) + ".\n")
    add(table(["Severity", "Area", "What is lopsided", "Evidence"], [(f[0], f[1], f[2], f[3]) for f in FLAGS]))

    Path(args.out).write_text("# Balance audit (generated)\n\n" + "\n".join(md) + "\n")
    print(f"wrote {args.out}: {len(FLAGS)} flags")
    json.dump([dict(severity=a, area=b, message=c, evidence=d) for a, b, c, d in FLAGS], open(str(Path(args.out).with_suffix(".flags.json")), "w"), indent=1)


if __name__ == "__main__":
    main()
