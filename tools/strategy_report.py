#!/usr/bin/env python3
"""Reads the lines tools/strategy_playtest.gd wrote and prints the analysis as
Markdown tables (stdout). Usage:

    python3 tools/strategy_report.py design/bench/strategy_runs.jsonl [more.jsonl ...]

Sections: leaderboard, the three goals, how each strategy compares with the
baseline (in standard deviations), Election Strength parts, the dues curve,
levels (pay per hour), cards, items, events, promises, protagonists.
"""
import json
import sys
import statistics as st
from collections import defaultdict, Counter


def load(paths):
    runs = []
    for p in paths:
        for line in open(p):
            line = line.strip()
            if line:
                runs.append(json.loads(line))
    return runs


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else 0.0


def sd(xs):
    xs = list(xs)
    return st.pstdev(xs) if len(xs) > 1 else 0.0


def table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


def money(x):
    return f"{int(round(x)):,}"


def score(r):
    """The three goals on one 0-1 scale each, averaged."""
    return (r["es"] / 100.0 + r["party"] / 100.0 + min(r["funds"], 100000) / 100000.0) / 3.0


def total_earned(r):
    return sum(s.get("week_earned", 0) for s in r["series"])


def total_paid(r):
    return sum(s.get("week_paid", 0) for s in r["series"])


def by_strategy(runs, pc=None):
    groups = defaultdict(list)
    for r in runs:
        if pc and r["protagonist"] != pc:
            continue
        groups[r["strategy"]].append(r)
    return groups


def main():
    runs = load(sys.argv[1:])
    if not runs:
        print("no runs")
        return
    pcs = sorted({r["protagonist"] for r in runs})
    main_pc = Counter(r["protagonist"] for r in runs).most_common(1)[0][0]
    groups = by_strategy(runs, main_pc)
    base = groups.get("baseline", [])
    print(f"# Strategy playtest: {len(runs)} runs, {len(groups)} strategies (protagonist {main_pc}), "
          f"{runs[0]['horizon']} game weeks each\n")

    # ---- leaderboard
    rows = []
    for name, rs in groups.items():
        rows.append((mean(score(r) for r in rs), name, rs))
    rows.sort(reverse=True)
    print("## 1. Leaderboard (score = mean of Funds/100k, Election Strength/100, Party support/100)\n")
    out = []
    for i, (sc, name, rs) in enumerate(rows, 1):
        out.append([i, name, len(rs), f"{sc:.3f}", money(mean(r['funds'] for r in rs)),
                    money(mean(r['net_funds'] for r in rs)), f"{mean(r['es'] for r in rs):.1f}",
                    f"{mean(r['party'] for r in rs):.0f}", f"{sd(score(r) for r in rs):.3f}"])
    print(table(["#", "Strategy", "Runs", "Score", "Funds", "Funds after dues owed", "Election Str.", "Party", "Score sd"], out))
    print()

    # ---- best on each goal
    print("## 2. Best strategy on each goal\n")
    goals = [("Funds in hand", lambda r: r["funds"]), ("Funds after dues owed", lambda r: r["net_funds"]),
             ("Total Funds earned", total_earned), ("Election Strength", lambda r: r["es"]),
             ("Party support", lambda r: r["party"]), ("Dues paid in total", total_paid)]
    out = []
    for label, fn in goals:
        ranked = sorted(((mean(fn(r) for r in rs), n) for n, rs in groups.items()), reverse=True)
        top = ", ".join(f"{n} ({money(v) if abs(v) > 500 else f'{v:.1f}'})" for v, n in ranked[:3])
        worst = f"{ranked[-1][1]} ({money(ranked[-1][0]) if abs(ranked[-1][0]) > 500 else f'{ranked[-1][0]:.1f}'})"
        out.append([label, top, worst])
    print(table(["Goal", "Top three", "Worst"], out))
    print()

    # ---- differences from baseline
    if base:
        print("## 3. Against the baseline (difference in standard deviations of the baseline's own seed spread)\n")
        out = []
        for name, rs in sorted(groups.items()):
            if name == "baseline":
                continue
            cells = [name]
            for key, fn in (("Election Str.", lambda r: r["es"]), ("Party", lambda r: r["party"]),
                            ("Total earned", total_earned), ("Win rate", lambda r: r["wins"] / max(1, r["wins"] + r["losses"]))):
                b = [fn(r) for r in base]
                a = [fn(r) for r in rs]
                spread = max(sd(b), 1e-9) if key != "Total earned" else max(sd(b), 20000)
                if key == "Win rate":
                    spread = max(sd(b), 0.01)
                if key == "Election Str.":
                    spread = max(sd(b), 0.8)
                if key == "Party":
                    spread = max(sd(b), 3.0)
                diff = mean(a) - mean(b)
                z = diff / spread
                flag = "**" if abs(z) >= 2 else ""
                shown = f"{diff:+.2f}" if key == "Win rate" else (money(diff) if key == "Total earned" else f"{diff:+.1f}")
                cells.append(f"{flag}{shown} ({z:+.1f}σ){flag}")
            out.append(cells)
        print(table(["Strategy", "Election Str.", "Party", "Total Funds earned", "Win rate"], out))
        print("\nBold = more than two baseline standard deviations away (floors keep a tiny spread from exaggerating).\n")

    # ---- Election Strength parts
    print("## 4. What Election Strength is made of (mean points by part)\n")
    parts_order = ["district", "national", "constituency", "organizations", "war_chest", "experience", "record", "party"]
    out = []
    for sc, name, rs in rows[:5] + rows[-3:]:
        comp = defaultdict(list)
        for r in rs:
            for p in r["election_parts"]:
                comp[p["id"]].append(p["points"])
        maxes = {p["id"]: p["max"] for p in rs[0]["election_parts"]}
        out.append([name] + [f"{mean(comp[i]):.1f}/{maxes[i]:.0f}" for i in parts_order] + [f"{mean(r['es'] for r in rs):.1f}",
                    f"{mean(r['potential'] for r in rs):.1f}"])
    print(table(["Strategy"] + parts_order + ["ES", "Potential"], out))
    print()

    # ---- trajectories + dues
    print("## 5. Trajectories and the dues curve (all strategies pooled, mean by week)\n")
    weeks = sorted({s["week"] for r in runs for s in r["series"]})
    pick = [w for w in weeks if w % 5 == 0]
    out = []
    for w in pick:
        row = [s for r in runs if r["protagonist"] == main_pc for s in r["series"] if s["week"] == w]
        out.append([w, money(mean(s["funds"] for s in row)), f"{mean(s['es'] for s in row):.1f}",
                    f"{mean(s['pot'] for s in row):.1f}", f"{mean(s['party'] for s in row):.0f}",
                    money(mean(s.get("week_earned", 0) for s in row)), money(mean(s.get("week_dues", 0) for s in row)),
                    money(mean(s["dues_owed"] for s in row)), f"{mean(s['orgs_on_side'] for s in row):.1f}"])
    print(table(["Week", "Funds", "Election Str.", "Potential", "Party", "Earned that week", "Dues that week", "Dues owed", "Orgs on side"], out))
    paid_full = sum(1 for r in runs if r["dues_owed"] == 0)
    print(f"\nRuns that ended with no dues owed: {paid_full} of {len(runs)}. "
          f"Mean weeks overdue: {mean(r['weeks_overdue'] for r in runs):.1f} of {runs[0]['horizon']}.\n")
    # Party support vs dues
    buckets = defaultdict(list)
    for r in runs:
        for s in r["series"]:
            if s.get("week_dues") is not None and s["week"] > 0:
                buckets[min(s["party"] // 15 * 15, 90)].append((s["week_dues"], s.get("week_earned", 0), s["week_paid"]))
    out = []
    for b in sorted(buckets):
        v = buckets[b]
        out.append([f"{b}-{b + 14}", len(v), money(mean(x[0] for x in v)), money(mean(x[1] for x in v)), money(mean(x[2] for x in v))])
    print("Dues against Party support (every week of every run):\n")
    print(table(["Party support", "Weeks", "Mean dues", "Mean earned (capped)", "Mean paid"], out))
    print()

    # ---- levels
    print("## 6. Level choice: what each level pays per hour (all runs)\n")
    lv = defaultdict(lambda: Counter())
    for r in runs:
        for e in r["levels"]:
            c = lv[e["level"]]
            c["n"] += 1
            for k in ("hours", "funds", "party", "con", "rep", "xp", "dist", "nat", "stage_wins", "stage_losses"):
                c[k] += e[k]
            c["tier"] = e["tier"]
    rows_l = []
    for lid, c in lv.items():
        if c["n"] < 5:
            continue
        h = max(c["hours"], 1)
        rows_l.append((lid, c["tier"], c["n"], c["hours"] / c["n"], c["funds"] / h, c["party"] / h,
                       (c["dist"] + c["nat"] + c["con"]) / h, c["xp"] / h,
                       c["stage_wins"] / max(1, c["stage_wins"] + c["stage_losses"])))
    def fmt(rows_x):
        return [[l, t, n, f"{hh:.1f}", money(f), f"{p:.2f}", f"{e:.2f}", f"{x:.1f}", f"{w:.0%}"] for l, t, n, hh, f, p, e, x, w in rows_x]
    hdr = ["Level", "Tier", "Plays", "Hours each", "Funds/hour", "Party/hour", "Awareness+Const./hour", "XP/hour", "Stage win %"]
    print("Best by Funds per hour:\n")
    print(table(hdr, fmt(sorted(rows_l, key=lambda x: -x[4])[:8])))
    print("\nBest by Party support per hour:\n")
    print(table(hdr, fmt(sorted(rows_l, key=lambda x: -x[5])[:8])))
    print("\nBest by awareness + Constituency per hour:\n")
    print(table(hdr, fmt(sorted(rows_l, key=lambda x: -x[6])[:8])))
    print("\nWorst by Funds per hour (levels played at least 5 times):\n")
    print(table(hdr, fmt(sorted(rows_l, key=lambda x: x[4])[:6])))
    print("\nBy tier:\n")
    out = []
    for t in (0, 1, 2):
        sub = [x for x in rows_l if x[1] == t]
        if sub:
            out.append([t, len(sub), f"{mean(x[3] for x in sub):.1f}", money(mean(x[4] for x in sub)), f"{mean(x[5] for x in sub):.2f}",
                        f"{mean(x[6] for x in sub):.2f}", f"{mean(x[7] for x in sub):.1f}", f"{mean(x[8] for x in sub):.0%}"])
    print(table(["Tier", "Levels", "Hours each", "Funds/hour", "Party/hour", "Aware+Const./hour", "XP/hour", "Stage win %"], out))
    print()

    # ---- cards
    print("## 7. Cards\n")
    tally = Counter()
    suit_tally = Counter()
    deck_count = Counter()
    for r in runs:
        if r["strategy"] == "random_cards":
            continue
        for k, v in r["card_tally"].items():
            tally[k] += v
        for k, v in r["suit_plays"].items():
            suit_tally[k] += v
        for c in r["deck"]:
            deck_count[c] += 1
    cards = {c["card_id"]: c for c in json.load(open("data/cards.json"))}
    total = sum(tally.values()) or 1
    out = [[s, f"{v / total:.1%}"] for s, v in suit_tally.most_common()]
    print("Share of cards played by suit (all non-random runs):\n")
    print(table(["Suit", "Share of plays"], out))
    n_by_suit = Counter(c["suit"] for c in cards.values())
    print("\nCards in the game per suit: " + ", ".join(f"{s} {n}" for s, n in n_by_suit.items()) + "\n")
    hdr = ["Card", "Name", "Suit", "Cost", "Self+", "Opp-", "Guard", "Draw", "Gaffe", "Plays", "Share", "In final deck"]
    def crow(cid):
        c = cards.get(cid, {})
        return [cid, c.get("name_en", "?"), c.get("suit", "?"), c.get("cost"), c.get("self_plus"), c.get("opp_minus"),
                c.get("guard"), c.get("draw"), c.get("gaffe"), tally.get(cid, 0), f"{tally.get(cid, 0) / total:.1%}", deck_count.get(cid, 0)]
    print("Most played:\n")
    print(table(hdr, [crow(c) for c, _ in tally.most_common(10)]))
    never = [cid for cid in cards if tally.get(cid, 0) == 0]
    print(f"\nNever played in any run: {len(never)} of {len(cards)}: " + ", ".join(f"{c} {cards[c]['name_en']} ({cards[c]['suit']})" for c in never[:30]))
    print("\nLeast played (played at least once):\n")
    least = [(c, v) for c, v in sorted(tally.items(), key=lambda x: x[1]) if v > 0][:8]
    print(table(hdr, [crow(c) for c, _ in least]))
    print()
    print("Suit decks against the baseline (does a suit focus pay?):\n")
    out = []
    for name in sorted(groups):
        if name.endswith("_deck") and base:
            rs = groups[name]
            out.append([name, f"{mean(r['es'] for r in rs):.1f}", f"{mean(r['party'] for r in rs):.0f}", money(mean(total_earned(r) for r in rs)),
                        f"{mean(r['wins'] / max(1, r['wins'] + r['losses']) for r in rs):.1%}", f"{mean(r['gaffes'] for r in rs):.0f}"])
    out.append(["baseline", f"{mean(r['es'] for r in base):.1f}", f"{mean(r['party'] for r in base):.0f}", money(mean(total_earned(r) for r in base)),
                f"{mean(r['wins'] / max(1, r['wins'] + r['losses']) for r in base):.1%}", f"{mean(r['gaffes'] for r in base):.0f}"])
    print(table(["Deck", "Election Str.", "Party", "Total Funds earned", "Stage win rate", "Gaffes"], out))
    print()

    # ---- stage types
    print("## 8. Stage types: win rate (all runs)\n")
    stt = defaultdict(lambda: [0, 0])
    for r in runs:
        if r["strategy"] == "random_cards":
            continue
        for k, v in r["stage_type_results"].items():
            stt[k][0] += v.get("wins", 0)
            stt[k][1] += v.get("losses", 0)
    stages = {s["stage_id"]: s for s in json.load(open("data/stages.json"))}
    out = []
    for k, (w, l) in sorted(stt.items(), key=lambda x: x[1][0] / max(1, x[1][0] + x[1][1])):
        if w + l >= 20:
            out.append([k, stages.get(k, {}).get("name_en", "?"), stages.get(k, {}).get("mode", "?"), w + l, f"{w / (w + l):.0%}"])
    print("Lowest win rates:\n")
    print(table(["Stage", "Name", "Mode", "Fights", "Win rate"], out[:10]))
    print()

    # ---- items, backing, staff
    print("## 9. Items, backing and staff\n")
    out = []
    for name in ("baseline", "no_items", "no_backing", "heavy_backing", "no_staff", "no_patron", "dues_first"):
        rs = groups.get(name)
        if rs:
            out.append([name, f"{mean(r['items_bought'] for r in rs):.0f}", f"{mean(r['items_used'] for r in rs):.0f}",
                        f"{mean(r['backing_owned'] for r in rs):.0f}", f"{mean(r['staff'] for r in rs):.1f}",
                        f"{mean(r['es'] for r in rs):.1f}", f"{mean(r['party'] for r in rs):.0f}",
                        f"{mean(r['wins'] / max(1, r['wins'] + r['losses']) for r in rs):.1%}", money(mean(total_earned(r) for r in rs))])
    print(table(["Strategy", "Items bought", "Items used", "Backing owned", "Staff hired", "Election Str.", "Party", "Stage win rate", "Total Funds earned"], out))
    print()

    # ---- events
    print("## 10. Events (strategies that take them)\n")
    ev = defaultdict(lambda: Counter())
    for r in runs:
        for eid, rec in r["events"]["by_id"].items():
            for k, v in rec.items():
                ev[eid][k] += v
    events = {e["event_id"]: e for e in json.load(open("data/events.json"))}
    out = []
    for eid, c in sorted(ev.items(), key=lambda x: -(x[1]["ddist"] + x[1]["dnat"] + x[1]["dcon"]) / max(1, x[1]["n"])):
        e = events.get(eid, {})
        n = max(1, c["n"])
        out.append([eid, e.get("title", "?"), e.get("trigger", "?"), e.get("hours"), c["n"], c["arranged"], money(c["dfunds"] / n),
                    f"{c['ddist'] / n:+.1f}", f"{c['dnat'] / n:+.1f}", f"{c['dcon'] / n:+.1f}", f"{c['dparty'] / n:+.1f}"])
    print(table(["Event", "Title", "Trigger", "Hours", "Times", "Arranged", "Funds", "District", "National", "Constit.", "Party"], out[:12]))
    print("\nWorst:\n")
    print(table(["Event", "Title", "Trigger", "Hours", "Times", "Arranged", "Funds", "District", "National", "Constit.", "Party"], out[-6:]))
    print()

    # ---- promises
    print("## 11. Promises\n")
    out = []
    for name in ("promise_keeper", "promise_breaker", "promise_avoider", "frugal_visitors", "visitors_funds", "random_visitors", "baseline"):
        rs = groups.get(name)
        if rs:
            out.append([name, f"{mean(r['visitors']['promises_made'] for r in rs):.0f}", f"{mean(r['visitors']['kept'] for r in rs):.0f}",
                        f"{mean(r['promises_broken_unseen'] for r in rs):.0f}", f"{mean(r['visitors']['paid_hours'] for r in rs):.0f}",
                        f"{mean(r['visitors']['paid_funds'] for r in rs):.0f}", f"{mean(r['es'] for r in rs):.1f}",
                        f"{mean(r['party'] for r in rs):.0f}", f"{mean(r['rep'] for r in rs):.0f}"])
    print(table(["Strategy", "Promises made", "Kept", "Broken (unseen at end)", "Hours paid", "Funds paid", "Election Str.", "Party", "Reputation"], out))
    print()

    # ---- protagonists
    if len(pcs) > 1:
        print("## 12. Protagonists\n")
        out = []
        for pc in pcs:
            for name in sorted({r["strategy"] for r in runs if r["protagonist"] == pc}):
                rs = [r for r in runs if r["protagonist"] == pc and r["strategy"] == name]
                out.append([pc, name, len(rs), money(mean(r["funds"] for r in rs)), f"{mean(r['es'] for r in rs):.1f}",
                            f"{mean(r['party'] for r in rs):.0f}", f"{mean(score(r) for r in rs):.3f}",
                            f"{mean(r['wins'] / max(1, r['wins'] + r['losses']) for r in rs):.1%}"])
        print(table(["Protagonist", "Strategy", "Runs", "Funds", "Election Str.", "Party", "Score", "Stage win rate"], out))
        print()

    # ---- bots' own bugs
    bugs = Counter()
    for r in runs:
        for b in r["bugs"]:
            bugs[b.split("]")[-1][:140]] += 1
    print("## 12b. Drafted bills (component plan 4.9)\n")
    out = []
    for name, rs in groups.items():
        d = [r.get("drafts", {}) for r in rs]
        if not any(x.get("looks", 0) or x.get("started", 0) for x in d):
            continue
        tot = lambda k: sum(int(x.get(k, 0)) for x in d)
        refused = {}
        for x in d:
            for reason, n in (x.get("refused") or {}).items():
                refused[reason] = refused.get(reason, 0) + n
        top = max(refused.items(), key=lambda kv: kv[1])[0] if refused else ""
        out.append([name, tot("looks"), tot("started"), tot("lapsed"), tot("passed") + tot("failed"), tot("passed"),
                    f"{tot('visit_wins')} of {tot('visits')}", tot("trades"), top])
    if out:
        print(table(["Strategy", "Looks", "Drafted", "Lapsed at hearing", "Voted", "Passed", "Visits won", "Trades", "Most common refusal"], out))
    else:
        print("No strategy drafted.")
    print()

    print("## 13. Bugs and discrepancies the bot logged\n")
    if not bugs:
        print("None.\n")
    for b, n in bugs.most_common(10):
        print(f"- {n}x {b}")
    print(f"\nStalls (a week that stopped moving): {sum(r['stalls'] for r in runs)}")


if __name__ == "__main__":
    main()
