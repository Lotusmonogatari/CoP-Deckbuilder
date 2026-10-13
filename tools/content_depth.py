#!/usr/bin/env python3
"""The three-times rule (Cameron, 2026-10-13): every room should hold at least
three times as much content as an average run is likely to meet, counting
general content and the room's own together. If a room asks 10 questions it
needs 30 to draw from.

Reads data/*.json (run tools/export_data.py first) and, for every Combat room:

  questions     asked per run (the turn limit) against the questions it can draw
                (its Question Pool plus any Stage Questions naming it)
  people        opponents seated for the room against the people who may appear
  player cues   lines a (suit, verb) moment can say against three times the
                moments of that kind in a run (cards played / 18). A cell with no
                room-specific row says the played card's own five lines instead
  opponent cues the same, for the opponent's turns
  transitions   exchanges that can play before the room (only if it shows one)

Cards played and turns ended come from tools/measure_plays.sh
(design/bench/plays_per_stage.json: a well-equipped bot, so a generous figure).

Usage:  python3 tools/content_depth.py [--md] [--fail-under 3] [--rooms ST05,ST24]
"""
import json, math, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
D = ROOT / "data"
SUITS = ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]
VERBS = ["attack", "gain", "block"]
POOL_BY_STAGE = {"ST04": "press_conference", "ST05": "town_hall", "ST19": "media_ambush",
                 "ST20": "lobbyist_meeting", "ST21": "policy_study"}
FACTOR = 3.0
CARD_LINES = 5          # a card's own Flavor Text lines
DECK = 15


def load(name, default):
    p = D / name
    return json.loads(p.read_text()) if p.exists() else default


def rows(x):
    return x if isinstance(x, list) else list(x.values())


def blank(v):
    return v is None or str(v).strip() == ""


def nlines(r):
    return sum(1 for i in range(1, 6) if not blank(r.get(f"cue_{i}")))


def main():
    stages = [s for s in rows(load("stages.json", [])) if s.get("mode") == "Combat"]
    questions = load("questions.json", {})
    opponents = rows(load("opponents.json", []))
    pcues = rows(load("player_cues.json", []))
    ocues = rows(load("opponent_cues.json", []))
    tdial = load("transition_dialogue.json", [])
    plays = load("../design/bench/plays_per_stage.json", {})
    cost = [c["cost"] for c in rows(load("cards.json", [])) if c.get("cost") is not None]
    avg_cost = sum(cost) / max(len(cost), 1)
    only = None
    fail_under = FACTOR
    if "--rooms" in sys.argv:
        only = set(sys.argv[sys.argv.index("--rooms") + 1].split(","))
    if "--fail-under" in sys.argv:
        fail_under = float(sys.argv[sys.argv.index("--fail-under") + 1])

    out = []
    for st in stages:
        sid = st["stage_id"]
        if only and sid not in only:
            continue
        turns = int(st.get("turn_limit") or 1)
        pool_name = st.get("question_pool") or POOL_BY_STAGE.get(sid)
        pool = questions.get(pool_name, []) if pool_name else []
        own = [q for q in questions.get("stage", []) if sid in (q.get("stage_ids") or [])]
        texts = {q["text"] for q in pool} | {q["text"] for q in own}
        avail_q = len(texts)
        asked = turns
        q_ratio = avail_q / asked if avail_q else None

        cnt = st.get("opponent_count")
        need_opp = int(cnt.get("max", 1)) if isinstance(cnt, dict) else int(cnt or 1)
        seated = sum(1 for o in opponents if sid in (o.get("stages") or []))
        p_ratio = seated / max(need_opp, 1)

        meas = plays.get(sid)
        if meas:
            cards, ends = meas["cards"], meas["turns"]
        else:
            en = st.get("energy_pool") if st.get("energy_mode") == "pool" else (st.get("energy_per_turn") or 3)
            cards = (turns * (en or 3)) / avg_cost if st.get("energy_mode") != "pool" else (en or 12) / avg_cost
            ends = turns
        cards, ends = max(cards, 1.0), max(ends, 1.0)

        def cell_lines(table, suit, verb, key_is_opp=False):
            have = 0
            for r in table:
                if r.get("suit") != suit:
                    continue
                if key_is_opp and r.get("opponent_ids"):
                    continue
                v = r.get("verb")
                if not blank(v) and v != verb:
                    continue
                stg = r.get("stage_ids") or []
                if sid in stg:
                    have += nlines(r)
            return have

        def general_lines(table, suit, verb, key_is_opp=False):
            have = 0
            for r in table:
                if r.get("suit") != suit or (key_is_opp and r.get("opponent_ids")):
                    continue
                v = r.get("verb")
                if not blank(v) and v != verb:
                    continue
                if not (r.get("stage_ids") or []):
                    have += nlines(r)
            return have

        # player cues: room rows win; else any-stage Player Cues rows; else the card's own lines
        p_min, p_src = None, "card text"
        written = 0
        for suit in SUITS:
            for verb in VERBS:
                lines = cell_lines(pcues, suit, verb)
                if lines == 0:
                    lines = general_lines(pcues, suit, verb)
                if lines:
                    written += 1
                    need = FACTOR * cards / 18.0
                    r_ = lines / need
                else:
                    need = FACTOR * cards / DECK
                    r_ = CARD_LINES / need
                p_min = r_ if p_min is None else min(p_min, r_)
        pc_ratio = p_min * FACTOR if p_min is not None else None   # ratio against 1x of the encounter
        pc_cells = f"{written}/18 written"

        o_min = None
        for suit in SUITS:
            for verb in VERBS:
                lines = cell_lines(ocues, suit, verb, True) or general_lines(ocues, suit, verb, True)
                need = FACTOR * ends / 9.0
                r_ = lines / need if need else 99
                o_min = r_ if o_min is None else min(o_min, r_)
        oc_ratio = o_min * FACTOR

        shows = str(st.get("show_transition") or "").strip().lower() == "yes"
        ex = [d for d in tdial if blank(d.get("stage_id")) or d.get("stage_id") == sid]
        t_ratio = len(ex) if shows else None   # one beat per entry: lines available per beat

        out.append(dict(stage=sid, name=st.get("name_en"), asked=asked, avail_q=avail_q, q=q_ratio,
                        seated=seated, need_opp=need_opp, people=p_ratio,
                        cards=cards, pcue=pc_ratio, pcells=pc_cells, ends=ends, ocue=oc_ratio,
                        trans=t_ratio))

    def fmt(v):
        return "n/a" if v is None else f"{v:.1f}x"

    flag = lambda v: v is not None and v < fail_under
    md = "--md" in sys.argv
    head = ["Room", "Questions (asked / can draw)", "People (seated / needed)", "Player cues", "Opponent cues", "Transitions"]
    lines = []
    bad = 0
    for r in out:
        cols = [f"{r['stage']} {r['name']}",
                f"{r['asked']} / {r['avail_q']} = {fmt(r['q'])}" + (" LOW" if flag(r['q']) else ""),
                f"{r['seated']} / {r['need_opp']} = {fmt(r['people'])}" + (" LOW" if flag(r['people']) else ""),
                f"{fmt(r['pcue'])} ({r['pcells']}, {r['cards']:.0f} plays)" + (" LOW" if flag(r['pcue']) else ""),
                f"{fmt(r['ocue'])}" + (" LOW" if flag(r['ocue']) else ""),
                (f"{r['trans']} lines" + (" LOW" if flag(r['trans']) else "")) if r['trans'] is not None else "off"]
        bad += sum(1 for k in ("q", "people", "pcue", "ocue", "trans") if flag(r[k]))
        lines.append(cols)
    if md:
        print("| " + " | ".join(head) + " |")
        print("|" + "---|" * len(head))
        for c in lines:
            print("| " + " | ".join(c) + " |")
    else:
        w = [max(len(x[i]) for x in lines + [head]) for i in range(len(head))]
        for c in [head] + lines:
            print("  ".join(c[i].ljust(w[i]) for i in range(len(head))))
    print(f"\n{bad} measure(s) below {fail_under:g}x across {len(out)} room(s).")
    sys.exit(1 if bad and "--fail-under" in sys.argv else 0)


main()
