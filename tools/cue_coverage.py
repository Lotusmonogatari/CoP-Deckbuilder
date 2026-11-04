#!/usr/bin/env python3
"""How many more opponent bill lines each pool needs so a level's 30
opponent turns do not repeat a line (2026-11-04, Cameron).

Simulates many random 30-turn stretches of every bill level, from the real
data: the stages in order, who may be seated, each opponent's style weights
(55/30/10, 5% another style), their move pattern, their side of the bill
(scripts/rules/MemberStance.gd) and the player's own lean, Support or Oppose
at random. Then, for each pool (bill or bill part, style, move), it finds the
line count that covers the chosen share of stretches with no repeat, and
prints the pools that fall short, by side.

A pool's lines by side and who may say them (MemberStance.sides()):
    Neutral  everyone
    For      a supporter facing a player who opposes the bill
    Against  a critic facing a player who supports it
    Ally     a supporter or critic facing a player on their own side

Drafted and sponsored bills are built at runtime, so they are simulated
roughly: a random two or three parts from one organization, random party
leanings, the Bill Level Templates' stages. Their parts carry attack lines
only, so only attack pools are counted.

    python3 tools/cue_coverage.py               # summary at 90% for bills
    python3 tools/cue_coverage.py --pct 85 --parts-pct 80 --list
    python3 tools/cue_coverage.py --json out.json   # every short pool

Reads data/*.json only; changes nothing.
"""
import argparse
import collections
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SUITS = ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]
VERBS = ("attack", "gain", "block")
TURNS = 30
SPLIT_PERCENT = 30
FOR, AGAINST, ALLY, NEUTRAL = "For", "Against", "Ally", "Neutral"
FIXED = {"PATRON_MEETING": "ST20", "CAUCUS": "ST03", "STEERING": "ST08", "MP_FIGHT": "ST261"}


def load(name):
    return json.loads((DATA / name).read_text())


class World:
    def __init__(self):
        self.levels = load("levels.json")
        self.stages = {s["stage_id"]: s for s in load("stages.json")}
        self.opponents = load("opponents.json")
        self.bills = load("floor_votes.json")
        self.parties = load("parties.json")
        self.party_by_name = {p["name"]: p for p in self.parties}
        self.cues = load("opponent_cues.json")
        self.laws = load("law_effects.json")
        self.components = {c["component_id"]: c for c in load("bill_components.json")}
        self.templates = load("bill_level_templates.json")
        self.balance = load("balance.json")
        self.split = int(self.balance.get("member_stance_split_party_abstain_percent", SPLIT_PERCENT)
                         if isinstance(self.balance, dict) else SPLIT_PERCENT)
        # Current lines per (scope, suit, verb) by side.
        self.have = collections.defaultdict(collections.Counter)
        self.shared_ally = collections.Counter()   # (suit, verb) -> lines
        for row in self.cues:
            scopes = (row.get("bill_ids") or []) + (row.get("component_ids") or [])
            if not scopes and not row.get("opponent_ids"):
                for i in range(1, 6):
                    if row.get(f"cue_{i}") and row.get(f"cue_{i}_side") == ALLY:
                        self.shared_ally[(row["suit"], row["verb"])] += 1
            if not scopes or row.get("opponent_ids"):
                continue
            for i in range(1, 6):
                if not row.get(f"cue_{i}"):
                    continue
                side = row.get(f"cue_{i}_side") or NEUTRAL
                for scope in scopes:
                    self.have[(scope, row["suit"], row["verb"])][side] += 1
        self.seatable = collections.defaultdict(list)
        for o in self.opponents:
            for sid in o.get("stages") or []:
                self.seatable[sid].append(o)
        self.party_members = collections.defaultdict(list)
        for o in self.opponents:
            if o.get("party"):
                self.party_members[o["party"]].append(o)

    # --- MemberStance, in Python -------------------------------------------
    def stake(self, bill_id):
        net = collections.Counter()
        for row in self.laws:
            if row.get("bill_id") == bill_id and row.get("outcome") == "Passed":
                for e in row.get("effects") or []:
                    d = e.get("delta")
                    d = (d["min"] + d["max"]) / 2 if isinstance(d, dict) else (d or 0)
                    net[e.get("target")] += d
        return {k for k, v in net.items() if v > 0}, {k for k, v in net.items() if v < 0}

    def argued(self, o, positions, supporters, opposers, rng):
        party = self.party_by_name.get(o.get("party") or "")
        pos = None
        if party:
            pos = next((p for p in positions if p["party_id"] == party["party_id"]), None)
        if not pos:
            a = o.get("affiliation")
            return FOR if a in supporters else AGAINST if a in opposers else ""
        d = pos.get("disposition")
        y, n, ab = (pos.get("votes_yes") or 0), (pos.get("votes_no") or 0), (pos.get("votes_abstain") or 0)
        t = y + n + ab
        leader = party.get("leader_opp_id") == o["opp_id"]
        if not leader and (d == "Neutral" or (t and ab * 100 >= self.split * t)):
            r = rng.random() * t if t else 0
            return FOR if r < y else AGAINST if r < y + n else ""
        return {"Supportive": FOR, "Opposed": AGAINST}.get(d, "")


def verbs_of(o):
    v = [k for k, f in (("attack", "intent_attack_range"), ("gain", "intent_gain_range"),
                        ("block", "intent_block_range")) if o.get(f)]
    return v or list(VERBS)


def suit_of(o, rng):
    r = rng.random()
    own = [o.get("suit_1"), o.get("suit_2"), o.get("suit_3")]
    if r < .55 and own[0]:
        return own[0]
    if r < .85 and own[1]:
        return own[1]
    if r < .95 and own[2]:
        return own[2]
    return rng.choice([s for s in SUITS if s not in own] or SUITS)


def speaker_class(argued, player_side):
    if not argued:
        return "n"
    return "ally" if argued == player_side else "opp"


def run_stretch(world, rng, seats, positions, supporters, opposers, player_side, scopes, verbs_counted):
    """One 30-turn stretch: draws per (pool key) -> Counter of speaker class.
    `seats` is a list of (stage, opponents) in order. A pool key is
    (scope label, suit, verb)."""
    draws = collections.defaultdict(collections.Counter)
    left = TURNS
    for stage, people in seats:
        for o in people:
            cls = speaker_class(world.argued(o, positions, supporters, opposers, rng), player_side)
            vs = verbs_of(o)
            for t in range(min(int(stage.get("turn_limit") or 6), left)):
                verb = vs[t % len(vs)]
                if verb in verbs_counted:
                    draws[(scopes, suit_of(o, rng), verb)][cls] += 1
                left -= 1
            if left <= 0:
                return draws
    return draws


def pick_seated(world, rng, stage_id):
    stage = world.stages.get(stage_id)
    if not stage or stage.get("mode") != "Combat":
        return None
    pool = world.seatable.get(stage_id, [])
    if not pool:
        return None
    oc = stage.get("opponent_count")
    n = rng.randint(oc["min"], oc["max"]) if isinstance(oc, dict) else 1
    return stage, rng.sample(pool, min(n, len(pool)))


def bill_runs(world, runs, rng):
    """Yield (pool key, side, Counter) for every written bill level."""
    for lv in world.levels:
        slots = [lv.get(f"stage_{i}") for i in range(1, 11) if lv.get(f"stage_{i}")]
        bill_id = next((x for x in slots if str(x).startswith("BI")), None)
        if not bill_id or bill_id not in world.bills:
            continue
        positions = world.bills[bill_id].get("positions") or []
        sup, opp = world.stake(bill_id)
        for _ in range(runs):
            seats = [s for s in (pick_seated(world, rng, x) for x in slots) if s]
            side = rng.choice([FOR, AGAINST])
            d = run_stretch(world, rng, seats, positions, sup, opp, side, (bill_id,), VERBS)
            for suit in SUITS:
                for verb in VERBS:
                    yield (bill_id, suit, verb), side, d.get(((bill_id,), suit, verb), collections.Counter())


def part_runs(world, runs, rng):
    """Yield (pool key, side, Counter) for random drafted / sponsored bills.
    A pool here is one part's (component, suit, attack) — a composed bill's
    pool is the sum of its parts', so each part's draws are split evenly."""
    by_owner = collections.defaultdict(list)
    for cid, c in world.components.items():
        by_owner[c["owner"]].append(cid)
    owners = sorted(by_owner)
    supporters_of = {}
    for cid, c in world.components.items():
        supporters_of[cid] = ({g["target"] for g in c.get("gains") or []},
                              {g["target"] for g in c.get("loses") or []})
    for _ in range(runs * 50):
        owner = rng.choice(owners)
        ids = rng.sample(by_owner[owner], min(rng.choice([2, 3]), len(by_owner[owner])))
        template = rng.choice(world.templates)
        hearing = world.components[ids[0]].get("hearing_stage")
        public = rng.choice([template.get("public_room_constituency"), template.get("public_room_national")])
        slot_ids = []
        for i in range(1, 9):
            token = template.get(f"stage_{i}")
            if token == "HEARING":
                slot_ids.append(hearing)
            elif token == "PUBLIC":
                slot_ids.append(public)
            elif token == "MP_VISIT":
                if rng.random() < (template.get("visit_chance_percent") or 50) / 100:
                    slot_ids.append("MP_FIGHT")
            elif token in FIXED:
                slot_ids.append(FIXED[token])
        positions = [{"party_id": p["party_id"],
                      "disposition": rng.choice(["Supportive", "Opposed", "Neutral"]),
                      "votes_yes": 10, "votes_no": 10, "votes_abstain": 0} for p in world.parties]
        sup = set().union(*(supporters_of[c][0] for c in ids))
        opp = set().union(*(supporters_of[c][1] for c in ids))
        seats = []
        for sid in slot_ids:
            if sid == "MP_FIGHT":
                party = rng.choice(world.parties)["name"]
                if world.party_members[party]:
                    seats.append((world.stages["ST261"], [rng.choice(world.party_members[party])]))
                continue
            s = pick_seated(world, rng, sid)
            if s:
                seats.append(s)
        side = rng.choice([FOR, AGAINST])
        d = run_stretch(world, rng, seats, positions, sup, opp, side, tuple(ids), ("attack",))
        for suit in SUITS:
            got = d.get((tuple(ids), suit, "attack"), collections.Counter())
            # Spread the bill's draws over its parts: each part must carry its
            # share, rounded up.
            share = collections.Counter({k: -(-v // len(ids)) for k, v in got.items()})
            for cid in ids:
                yield (cid, suit, "attack"), side, share


def percentile(values, pct):
    values = sorted(values)
    return values[int(pct / 100 * (len(values) - 1))] if values else 0


def needs(world, samples, pct):
    """Per pool: new lines by side, so `pct`% of stretches never repeat."""
    per = collections.defaultdict(lambda: collections.defaultdict(list))
    for key, side, c in samples:
        n, o, a = c["n"], c["opp"], c["ally"]
        per[key]["n"].append(n)
        per[key][f"no|{side}"].append(n + o)
        per[key][f"na|{side}"].append(n + a)
        per[key][f"all|{side}"].append(n + o + a)
    out = {}
    for key, lists in per.items():
        have = world.have[key]
        N, F, A = have[NEUTRAL], have[FOR], have[AGAINST]
        L = have[ALLY] + world.shared_ally[(key[1], key[2])]
        add = collections.Counter()
        add[NEUTRAL] = max(0, percentile(lists["n"], pct) - N)
        N2 = N + add[NEUTRAL]
        # A player who opposes meets For speakers; one who supports, Against.
        add[FOR] = max(0, percentile(lists[f"no|{AGAINST}"], pct) - N2 - F)
        add[AGAINST] = max(0, percentile(lists[f"no|{FOR}"], pct) - N2 - A)
        ally_need = max(percentile(lists[f"na|{FOR}"], pct), percentile(lists[f"na|{AGAINST}"], pct)) - N2 - L
        add[ALLY] = max(0, ally_need)
        for p_side, o_side in ((FOR, AGAINST), (AGAINST, FOR)):
            have_all = N2 + have[o_side] + add[o_side] + L + add[ALLY]
            add[ALLY] += max(0, percentile(lists[f"all|{p_side}"], pct) - have_all)
        if sum(add.values()):
            out[key] = add
    return out


def summarize(title, short, frames_by, ally_by):
    """Neutral, For and Against are written per pool; Ally lines are shared by
    every bill, so a style x move needs only its largest Ally shortfall."""
    total = collections.Counter()
    for (scope, suit, verb), add in short.items():
        total.update({k: v for k, v in add.items() if k != ALLY})
        ally_by[(suit, verb)] = max(ally_by[(suit, verb)], add[ALLY])
    print(f"\n{title}: {len(short)} short pools, {sum(total.values())} new pool lines "
          + ", ".join(f"{s} {total[s]}" for s in (NEUTRAL, FOR, AGAINST)))
    by_suit = collections.defaultdict(collections.Counter)
    frames = collections.Counter()
    for (scope, suit, verb), add in short.items():
        by_suit[suit].update({k: v for k, v in add.items() if k != ALLY})
        for side, v in add.items():
            if side == ALLY:
                continue
            frames[(suit, verb, side)] = max(frames[(suit, verb, side)], v)
    for suit in SUITS:
        c = by_suit[suit]
        print(f"  {suit:12} " + "  ".join(f"{s[:3]} {c[s]:4}" for s in (NEUTRAL, FOR, AGAINST, ALLY))
              + f"   = {sum(c.values())}")
    print(f"  frames needed (style x move x side, largest shortfall): {sum(frames.values())}")
    frames_by.update({k: max(frames_by[k], v) for k, v in frames.items()})


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pct", type=int, default=90, help="share of stretches with no repeat, bills")
    ap.add_argument("--parts-pct", type=int, default=None, help="the same for bill parts (default: --pct)")
    ap.add_argument("--runs", type=int, default=300, help="stretches per bill level")
    ap.add_argument("--seed", type=int, default=11)
    ap.add_argument("--list", action="store_true", help="print every short pool")
    ap.add_argument("--json", help="write every short pool to this file")
    args = ap.parse_args()
    world = World()
    rng = random.Random(args.seed)
    bills = needs(world, list(bill_runs(world, args.runs, rng)), args.pct)
    parts = needs(world, list(part_runs(world, args.runs, rng)), args.parts_pct or args.pct)
    frames = collections.Counter()
    ally = collections.Counter()
    summarize(f"Written bills at {args.pct}%", bills, frames, ally)
    summarize(f"Bill parts at {args.parts_pct or args.pct}%", parts, frames, ally)
    pool_lines = sum(v for a in list(bills.values()) + list(parts.values()) for k, v in a.items() if k != ALLY)
    print(f"\nShared Ally lines needed (every bill): {sum(ally.values())}")
    for suit in SUITS:
        print(f"  {suit:12} " + "  ".join(f"{v} {ally[(suit, v)]:3}" for v in VERBS))
    print(f"\nAll: {pool_lines} new pool lines + {sum(ally.values())} shared Ally lines, "
          f"{sum(frames.values())} pool frames")
    if args.list:
        for key, add in sorted({**bills, **parts}.items()):
            print("  ", "|".join(key), dict(add))
    if args.json:
        Path(args.json).write_text(json.dumps(
            [{"scope": k[0], "suit": k[1], "verb": k[2], "add": dict(v)} for k, v in {**bills, **parts}.items()],
            indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
