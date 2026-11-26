#!/usr/bin/env python3
"""P19 (2026-11-25, Cameron): the economy map. Catalogs every flow that moves a stock or an asset, links the stocks, finds the loops, and
prices a standard week, all from the exported data (data/*.json) plus one hand-kept file (design/economy/economy_flows_manual.csv).

    python3 tools/economy_map.py            # rewrite the four outputs in design/economy/
    python3 tools/economy_map.py --check    # exit 1 if the files on disk differ from a fresh run (verify.sh calls this)

Outputs (design/economy/):
    economy_catalog.csv   one row per flow (the data pass grouped by mechanic, plus the hand-kept code-pass rows)
    economy_links.csv     one row per cause-and-effect link between stocks (derived from the catalog's Inputs)
    economy_loops.md      every simple cycle of up to six links, marked R (reinforcing) or B (balancing), with the risky ones flagged
    economy_week.md       a standard week priced in hours-equivalent, forced sinks against faucets, and the levers not in the catalog
    economy_week.json     the same week's inputs and results, read by tests/test_economy_week.gd to check the dues formula against PartyDues

Tooling only: nothing here changes the game. Standard library only. The numbers named in the CONSTANTS block are Cameron's agreed standard
week (2026-11-24) and my draft frequencies (marked DRAFT); change them there.

Inputs column syntax (catalog and manual file): entries separated by ";", each  stock[sign]  or  stock[g: condition | side | sign]
  sign  + more of the input brings more of the result,  - brings less,  ~ both (a choice, left out of loops).
  g     a threshold switch: the condition, which side of the line ("low" or "high"), and the sign of the dependence on that side.
A converter has two rows sharing a Mechanic: the SPENDS row (the stock given up) and the GAINS row (what is gained; its Inputs name the
stock spent), so the link runs spent -> gained.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import math
import re
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
OUT = ROOT / "design" / "economy"
MANUAL = OUT / "economy_flows_manual.csv"
FILES = ["economy_catalog.csv", "economy_links.csv", "economy_loops.md", "economy_week.md", "economy_week.json"]

# ---------------------------------------------------------------------------
# CONSTANTS (the standard week, agreed 2026-11-24, and my DRAFT frequencies)
# ---------------------------------------------------------------------------
LEVEL_HOURS_PER_WEEK = 32          # work hours spent in levels
WIN_RATE = 0.92                    # share of rooms won
MID_PARTY_SUPPORT = 70             # mid-game Party support
MID_STAFF = [130000, 130000, 130000]   # three staff with this much invested each
EARLY_PARTY_SUPPORT = 40           # the early week
EARLY_STAFF = [40000, 40000]       # two hires at 40,000円
FUNDS_PER_HOUR = 8000              # hours-equivalent rates
XP_PER_HOUR = 20
POINT_HOURS = 1.0                  # one point of Constituency, Reputation, Party support or standing
AWARENESS_HOURS = 0.75             # one point of awareness
WEEKEND_HOUR_HOURS = 0.5
TARGET_SHARE = (0.35, 0.50)        # healthy forced Funds sinks as a share of Funds faucets
# DRAFT frequencies for flows with no rule-based rate (how many times a week; Cameron to correct):
WEEKLY_USES = {
    "event": 2.0,        # events answered (event_choices, events)
    "venue": 4.0,        # costed venue activities done
    "shop": 3.0,         # Marketplace purchases
    "staff_task": 10.0,  # staff tasks done well or badly
    "office": 2.0,       # other Office actions (Rhetoric Training, drafting, hosting)
    "bill": 0.5,         # bills carried to a vote
}
# DRAFT typical stock levels for the decay rows: points above the stock's start, and how many of the 32 organizations sit above theirs:
TYPICAL_ABOVE_START = {"constituency": 25, "reputation": 25, "org_standing": 10}
ORGS_ABOVE_START = 8

STOCKS = ["funds", "xp", "hours", "constituency", "reputation", "party_support", "awareness_district", "awareness_national",
          "org_standing", "party_standing", "election_strength", "segment_favorability"]
ASSETS = ["cards", "deck_slots", "backings", "items", "staff", "laws", "unlocked_levels", "tips", "codex", "cosmetics"]
HUB = "win_rate"
NODES = STOCKS + ASSETS + [HUB]
H_FACTOR = {"funds": 1.0 / FUNDS_PER_HOUR, "xp": 1.0 / XP_PER_HOUR, "hours": 1.0, "constituency": POINT_HOURS, "reputation": POINT_HOURS,
            "party_support": POINT_HOURS, "org_standing": POINT_HOURS, "party_standing": POINT_HOURS,
            "awareness_district": AWARENESS_HOURS, "awareness_national": AWARENESS_HOURS}

COLUMNS = ["Flow ID", "Mechanic type", "Mechanic", "Stock", "Class", "Amount", "Inputs", "Timing", "Control", "Typical per week (h-eq)",
           "Caps and limits", "Difficulty", "Source", "Status"]
MECHANIC_TYPES = {"room", "level", "office", "venue", "event", "bill", "week_end", "threshold", "difficulty"}
CLASSES = {"faucet", "sink", "converter", "gate", "multiplier", "decay"}
TIMINGS = {"card", "turn", "stage", "level", "day", "week", "once", "threshold"}
CONTROLS = {"chosen", "forced", "passive"}
STATUSES = {"live", "unused", "planned"}
LINK_COLUMNS = ["Link ID", "From", "To", "Sign", "Gate", "Through", "Timing", "Flow IDs"]

# Balance keys that are presentation, not economy: left out of "Levers not in the catalog" (counted, not listed).
IGNORE_PREFIXES = ("image_", "scroll_speed_", "characters_colour_", "haptics_", "text_scale_", "panel_", "cue_", "stage_continue_",
                   "scene_change_", "event_picture_", "news_ticker_", "transition_", "player_cues_", "opponent_cues_", "resign_swipe",
                   "resign_hold", "resign_fade", "resign_black", "ticker_", "calendar_start_", "starter_deck_", "tendency_",
                   "vote_projection_", "bill_positions_", "party_opinion_", "party_salience_", "member_stance_", "ally_neutral_band")


# ---------------------------------------------------------------------------
# Data and numbers
# ---------------------------------------------------------------------------
def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def num(value):
    """A number from a data cell, or None (blank, text)."""
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return None


def stats(values):
    """(median, min, max, n) of a list of numbers; None when empty."""
    values = [v for v in values if v is not None]
    if not values:
        return None
    return statistics.median(values), min(values), max(values), len(values)


def fmt(value: float) -> str:
    """A whole number with commas, or one decimal."""
    if abs(value - round(value)) < 1e-9:
        return f"{int(round(value)):,}"
    return f"{value:,.1f}"


def delta_of(cell):
    """The number in a reward's delta: a number, or the midpoint of a {min, max} range; None when it is neither."""
    if isinstance(cell, dict) and "min" in cell:
        return (cell["min"] + cell.get("max", cell["min"])) / 2
    return num(cell)


def heq(stock: str, amount: float):
    factor = H_FACTOR.get(stock)
    return None if factor is None else amount * factor


# --- The dues and wage formulas, re-implemented from scripts/rules/PartyDues.gd and StaffLoyalty.wage (tests/test_economy_week.gd
# runs the real GDScript on the same inputs and fails if these numbers differ). ---------------------------------------------------
def dues_cfg(balance: dict) -> dict:
    return {"base": int(balance.get("dues_base", 50000)), "reward_percent": float(balance.get("dues_reward_percent", 30)),
            "support_start": int(balance.get("dues_party_support_start", 40)),
            "support_step": max(1, int(balance.get("dues_party_support_step", 15))),
            "step_amount": int(balance.get("dues_step_amount", 50000)), "max_per_week": int(float(balance.get("funds_starting_cap", 100000)) * float(balance.get("dues_limit_cap_percent", 0)) / 100.0)}


def godot_round(x: float) -> int:
    """GDScript roundi: halves round away from zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def week_dues(cfg: dict, party_support: int, funds_earned: int, reduction: int = 0) -> int:
    steps = max(0, (party_support - cfg["support_start"]) // cfg["support_step"])
    base = max(0, cfg["base"] + steps * cfg["step_amount"])
    share = godot_round(max(0, funds_earned) * cfg["reward_percent"] / 100.0)
    total = base + share
    if cfg["max_per_week"] > 0:
        total = min(total, cfg["max_per_week"])
    return max(0, total - max(0, reduction))


def wage(invested: int, percent: float) -> int:
    return int(math.floor(invested * percent / 100.0))


# ---------------------------------------------------------------------------
# The standard week
# ---------------------------------------------------------------------------
def level_figures():
    """Per level: hours, room pay and level bonus (Funds and XP), from the stages and levels data."""
    stages = {s["stage_id"]: s for s in load("stages")}
    out = []
    for level in load("levels"):
        ids = [level.get(f"stage_{i}") for i in range(1, 11) if level.get(f"stage_{i}")]
        hours = sum(int(stages[i].get("time_units") or 1) if i in stages and stages[i].get("time_units") is not None else (1 if i in stages else 0) for i in ids)
        room_y = sum(num(stages[i].get("win_delta_yen")) or 0 for i in ids if i in stages)
        room_x = sum(num(stages[i].get("win_delta_xp")) or 0 for i in ids if i in stages)

        def mid(cell):
            return (cell["min"] + cell["max"]) / 2 if isinstance(cell, dict) and "min" in cell else 0
        out.append({"id": level["level_id"], "hours": hours, "room_yen": room_y, "room_xp": room_x,
                    "bonus_yen": mid(level.get("bonus_win_range_yen")), "bonus_xp": mid(level.get("bonus_win_range_xp"))})
    return [row for row in out if row["hours"] > 0]


def week_model(balance: dict) -> dict:
    """The standard and early weeks: earnings, dues, wages, the sink share."""
    levels = level_figures()
    per_hour_y = statistics.median([(l["room_yen"] + l["bonus_yen"]) / l["hours"] for l in levels if l["room_yen"] + l["bonus_yen"] > 0])
    per_hour_x = statistics.median([(l["room_xp"] + l["bonus_xp"]) / l["hours"] for l in levels if l["room_xp"] + l["bonus_xp"] > 0])
    earned_y = per_hour_y * LEVEL_HOURS_PER_WEEK * WIN_RATE
    earned_x = per_hour_x * LEVEL_HOURS_PER_WEEK * WIN_RATE
    room_total = sum(l["room_yen"] for l in levels)
    bonus_total = sum(l["bonus_yen"] for l in levels)
    room_share_y = room_total / (room_total + bonus_total) if room_total + bonus_total else 1.0
    room_x_total = sum(l["room_xp"] for l in levels)
    bonus_x_total = sum(l["bonus_xp"] for l in levels)
    room_share_x = room_x_total / (room_x_total + bonus_x_total) if room_x_total + bonus_x_total else 1.0
    cfg = dues_cfg(balance)
    percent = float(balance.get("staff_wage_percent", 10))
    weeks = {}
    for name, support, hires in (("standard", MID_PARTY_SUPPORT, MID_STAFF), ("early", EARLY_PARTY_SUPPORT, EARLY_STAFF)):
        dues = week_dues(cfg, support, int(round(earned_y)))
        wages = sum(wage(h, percent) for h in hires)
        weeks[name] = {"party_support": support, "invested": hires, "dues": dues, "wages": wages, "forced_funds": dues + wages,
                       "share": (dues + wages) / earned_y if earned_y else 0.0}
    stage_hours = [int(s.get("time_units") or 1) for s in load("stages") if s.get("time_units") is not None]
    hours_per_room = statistics.mean(stage_hours) if stage_hours else 1.0
    return {"per_hour_funds": per_hour_y, "per_hour_xp": per_hour_x, "earned_funds": earned_y, "earned_xp": earned_x,
            "room_share_funds": room_share_y, "room_share_xp": room_share_x, "levels": len(levels),
            "rooms_per_week": LEVEL_HOURS_PER_WEEK / hours_per_room, "hours_per_room": hours_per_room,
            "dues_cfg": cfg, "wage_percent": percent, "weeks": weeks}


# ---------------------------------------------------------------------------
# The data pass: one grouped row per mechanic and stock
# ---------------------------------------------------------------------------
def target_stock(target: str):
    """The stock a reward or cost target changes, or None for a stage bonus (energy, draw ...)."""
    t = str(target)
    if re.fullmatch(r"BO\d+", t) or t.startswith("TIER:"):
        return "org_standing"
    if t.startswith("SG"):
        return "segment_favorability"
    return {"Funds": "funds", "XP": "xp", "Reputation": "reputation", "Party support": "party_support",
            "Constituency support": "constituency", "Jiban": "constituency", "District Awareness": "awareness_district",
            "National Awareness": "awareness_national"}.get(t)


class Rows:
    """Collects data-pass rows, giving each an ID from FL001."""

    def __init__(self):
        self.rows = []

    def add(self, **row):
        row.setdefault("Typical per week (h-eq)", None)
        row.setdefault("Inputs", "")
        row.setdefault("Caps and limits", "")
        row.setdefault("Difficulty", "-")
        row.setdefault("Status", "live")
        row["Flow ID"] = f"FL{len(self.rows) + 1:03d}"
        self.rows.append(row)


def money(stock: str) -> str:
    return "円" if stock == "funds" else (" XP" if stock == "xp" else (" h" if stock == "hours" else ""))


def amount_text(label: str, st, stock: str, extra: str = "") -> str:
    median, low, high, n = st
    unit = money(stock)
    body = f"{label} median {fmt(median)}{unit}, {fmt(low)} to {fmt(high)}{unit} over {n}"
    return body + (f" {extra}" if extra else "")


def data_pass(model: dict, balance: dict) -> list:
    r = Rows()
    stages = load("stages")
    win_pay = "payout x 85/100/115% (difficulty_harder_reward_percent, difficulty_relaxed_reward_percent)"
    rooms = model["rooms_per_week"]
    loss_rooms = rooms * (1 - WIN_RATE)
    # Rooms: win pay by stock (weekly figure = the standard week's earnings split between room pay and level bonus).
    for column, stock in (("win_delta_yen", "funds"), ("win_delta_xp", "xp"), ("win_delta_jiban", "constituency"),
                          ("win_delta_reputation", "reputation"), ("win_delta_party_support", "party_support"),
                          ("win_delta_awareness_district", "awareness_district"), ("win_delta_awareness_national", "awareness_national")):
        values = [num(s.get(column)) for s in stages]
        values = [v for v in values if v is not None and v != 0]
        st = stats(values)
        if st is None:
            continue
        if stock == "funds":
            weekly = heq(stock, model["earned_funds"] * model["room_share_funds"])
        elif stock == "xp":
            weekly = heq(stock, model["earned_xp"] * model["room_share_xp"])
        else:
            weekly = heq(stock, st[0] * rooms * WIN_RATE * len(values) / len(stages))
        r.add(**{"Mechanic type": "room", "Mechanic": "Room win pay", "Stock": stock, "Class": "faucet",
                 "Amount": amount_text("per win,", st, stock, "rooms that pay it"),
                 "Inputs": "win_rate[+]", "Timing": "stage", "Control": "passive", "Typical per week (h-eq)": weekly,
                 "Caps and limits": "Funds limited by the Funds cap (funds_starting_cap, SH13); frozen at Party support 0",
                 "Difficulty": win_pay if stock in ("funds", "xp") else "-", "Source": f"data/stages.json {column}; MetaRules.apply_win_deltas"})
    for column, stock in (("loss_delta_yen", "funds"), ("loss_delta_xp", "xp"), ("loss_delta_jiban", "constituency"),
                          ("loss_delta_reputation", "reputation"), ("loss_delta_party_support", "party_support")):
        values = [v for v in (num(s.get(column)) for s in stages) if v is not None and v != 0]
        st = stats(values)
        if st is None:
            continue
        klass = "sink" if st[0] < 0 else "faucet"
        r.add(**{"Mechanic type": "room", "Mechanic": "Room loss delta", "Stock": stock, "Class": klass,
                 "Amount": amount_text("per loss,", st, stock), "Inputs": "win_rate[-]", "Timing": "stage", "Control": "passive",
                 "Typical per week (h-eq)": heq(stock, st[0] * loss_rooms * len(values) / len(stages)),
                 "Source": f"data/stages.json {column}; MetaRules.apply_loss_deltas"})
    hours = stats([num(s.get("time_units")) for s in stages if num(s.get("time_units")) is not None])
    r.add(**{"Mechanic type": "room", "Mechanic": "Room time", "Stock": "hours", "Class": "sink",
             "Amount": amount_text("per room,", hours, "hours", "stages"),
             "Timing": "stage", "Control": "chosen", "Typical per week (h-eq)": -float(LEVEL_HOURS_PER_WEEK),
             "Caps and limits": "40 work hours and 8 weekend hours a week", "Source": "data/stages.json time_units; TimeClock.units_for_stage"})

    # Levels: the end-of-level bonus.
    levels = load("levels")
    per_level_wins = model["rooms_per_week"] / max(1.0, statistics.mean([max(1, sum(1 for i in range(1, 11) if lv.get(f"stage_{i}"))) for lv in levels]))
    for column, stock in (("bonus_win_range_yen", "funds"), ("bonus_win_range_xp", "xp"), ("bonus_win_range_jiban", "constituency"),
                          ("bonus_win_range_reputation", "reputation"), ("bonus_win_range_party_support", "party_support")):
        mids = [(c["min"] + c["max"]) / 2 for c in (lv.get(column) for lv in levels) if isinstance(c, dict) and "min" in c and (c["max"] or c["min"])]
        st = stats(mids)
        if st is None:
            continue
        if stock == "funds":
            weekly = heq(stock, model["earned_funds"] * (1 - model["room_share_funds"]))
        elif stock == "xp":
            weekly = heq(stock, model["earned_xp"] * (1 - model["room_share_xp"]))
        else:
            weekly = heq(stock, st[0] * per_level_wins * WIN_RATE * len(mids) / len(levels))
        r.add(**{"Mechanic type": "level", "Mechanic": "End-of-level bonus", "Stock": stock, "Class": "faucet",
                 "Amount": amount_text("per level won, range midpoint", st, stock, "levels that pay it"), "Inputs": "win_rate[+]; unlocked_levels[+]",
                 "Timing": "level", "Control": "passive", "Typical per week (h-eq)": weekly,
                 "Difficulty": win_pay if stock in ("funds", "xp") else "-",
                 "Source": f"data/levels.json {column}; LevelBonus.preview, GameState._apply_level_bonus_win"})
    org_cols = [c for c in levels[0] if c.startswith("win_delta_bo")]
    mids = []
    for lv in levels:
        for c in org_cols:
            cell = lv.get(c)
            if isinstance(cell, dict) and "min" in cell and (cell["max"] or cell["min"]):
                mids.append((cell["min"] + cell["max"]) / 2)
    st = stats(mids)
    if st:
        r.add(**{"Mechanic type": "level", "Mechanic": "End-of-level organization standing", "Stock": "org_standing", "Class": "faucet",
                 "Amount": amount_text("per organization per level won, range midpoint", st, "org_standing"),
                 "Inputs": "win_rate[+]", "Timing": "level", "Control": "passive",
                 "Typical per week (h-eq)": heq("org_standing", st[0] * per_level_wins * WIN_RATE * len(mids) / max(1, len(levels))),
                 "Caps and limits": "standing gains shrink above 40 and 60 (booster_standing gain_bands)",
                 "Source": "data/levels.json win_delta_bo01..bo32; LevelBonus.preview"})

    # Shop: costs (converter) and the Funds cap.
    shop = load("shop")
    uses = WEEKLY_USES["shop"]
    price = "price x 100/115% (difficulty_harder_item_price_percent)"
    for column, stock in (("cost_yen", "funds"), ("cost_xp", "xp")):
        st = stats([v for v in (num(i.get(column)) for i in shop) if v])
        if st:
            r.add(**{"Mechanic type": "office", "Mechanic": "Marketplace purchase", "Stock": stock, "Class": "converter",
                     "Amount": "SPENDS " + amount_text("per item,", st, stock, "priced items"),
                     "Timing": "once", "Control": "chosen", "Typical per week (h-eq)": -heq(stock, st[0] * uses),
                     "Caps and limits": f"purchase_limit per item; about {uses:g} buys a week is a DRAFT frequency",
                     "Difficulty": price if stock == "funds" else "-", "Source": f"data/shop.json {column}; GameState.buy_item"})
    r.add(**{"Mechanic type": "office", "Mechanic": "Marketplace purchase", "Stock": "items", "Class": "converter",
             "Amount": "GAINS an item: a stage bonus (energy, draw, gaffe cap, tier standing), a staff item, a coupon or a one-use gift",
             "Inputs": "funds[+]; xp[+]", "Timing": "once", "Control": "chosen", "Source": "data/shop.json grants, staff_effect; GameState.use_item_in_stage",
             "Caps and limits": "stack_cap per item (default_consumable_stack_cap)"})
    caps = [num(i.get("funds_cap_increase")) for i in shop if num(i.get("funds_cap_increase"))]
    if caps:
        r.add(**{"Mechanic type": "office", "Mechanic": "Funds cap petition", "Stock": "funds", "Class": "multiplier",
                 "Amount": f"raises the Funds cap by {fmt(caps[0])}円 per purchase (SH13); the cap starts at funds_starting_cap",
                 "Inputs": "xp[+]", "Timing": "once", "Control": "chosen", "Source": "data/shop.json funds_cap_increase; GameState.buy_funds_cap",
                 "Caps and limits": "sanban Funds max 1,000,000円"})

    # Events.
    events = load("events")
    choices = load("event_choices")
    uses = WEEKLY_USES["event"]
    for column, stock, label in (("cost_funds", "funds", "event cost"), ("cost_xp", "xp", "event cost")):
        st = stats([v for v in (num(e.get(column)) for e in events) if v])
        if st:
            r.add(**{"Mechanic type": "event", "Mechanic": "Event cost", "Stock": stock, "Class": "sink",
                     "Amount": amount_text("per event,", st, stock), "Timing": "once", "Control": "chosen",
                     "Typical per week (h-eq)": -heq(stock, st[0] * uses * 0.5),
                     "Caps and limits": f"event_random_chance_percent, cooldown_hours; about {uses:g} events a week and half of them priced are DRAFT",
                     "Source": f"data/events.json {column}"})
    st = stats([num(e.get("hours")) for e in events if num(e.get("hours"))])
    if st:
        r.add(**{"Mechanic type": "event", "Mechanic": "Event time", "Stock": "hours", "Class": "sink",
                 "Amount": amount_text("per event,", st, "hours"), "Timing": "once", "Control": "chosen",
                 "Typical per week (h-eq)": -st[0] * uses, "Source": "data/events.json hours"})
    for column, stock in (("funds_delta", "funds"), ("xp_delta", "xp"), ("constituency_delta", "constituency"), ("reputation_delta", "reputation"),
                          ("party_support_delta", "party_support"), ("district_delta", "awareness_district"), ("national_delta", "awareness_national")):
        values = [v for v in (num(c.get(column)) for c in choices) if v]
        st = stats(values)
        if st:
            r.add(**{"Mechanic type": "event", "Mechanic": "Event choice result", "Stock": stock, "Class": "faucet" if st[0] >= 0 else "sink",
                     "Amount": amount_text("per choice,", st, stock, "choices that move it"), "Timing": "once", "Control": "chosen",
                     "Typical per week (h-eq)": heq(stock, st[0] * uses * len(values) / max(1, len(choices))),
                     "Source": f"data/event_choices.json {column}; EventEngine"})
    st = stats([num(c.get("funds_cost")) for c in choices if num(c.get("funds_cost"))])
    if st:
        r.add(**{"Mechanic type": "event", "Mechanic": "Event choice cost", "Stock": "funds", "Class": "sink",
                 "Amount": amount_text("per choice,", st, "funds"), "Timing": "once", "Control": "chosen",
                 "Typical per week (h-eq)": -heq("funds", st[0] * uses * 0.25), "Source": "data/event_choices.json funds_cost; GameState.commitment_label"})
    deltas = [delta_of(e.get("delta")) for c in choices for e in (c.get("rewards") or []) if target_stock(e.get("target", "")) == "org_standing"]
    deltas = [d for d in deltas if d is not None]
    st = stats(deltas)
    if st:
        r.add(**{"Mechanic type": "event", "Mechanic": "Event choice organization standing", "Stock": "org_standing", "Class": "faucet",
                 "Amount": amount_text("per organization touched,", st, "org_standing"), "Timing": "once", "Control": "chosen",
                 "Typical per week (h-eq)": heq("org_standing", sum(deltas) / max(1, len(choices)) * uses),
                 "Caps and limits": "diminishing gains (booster_standing gain_bands)", "Source": "data/event_choices.json rewards"})
    # Promises made in choices: the standing kept or broken.
    promises = sum(1 for c in choices if c.get("commitment"))
    r.add(**{"Mechanic type": "event", "Mechanic": "Promise kept or broken", "Stock": "org_standing", "Class": "faucet",
             "Amount": f"{promises} choices make a promise; kept pays promise_kept_standing, broken costs promise_broken_standing and promise_broken_reputation",
             "Timing": "once", "Control": "chosen", "Source": "data/event_choices.json commitment; GameState.keep_promise, _break_overdue_promises"})

    # Venues.
    venues = load("venue_activities")
    uses = WEEKLY_USES["venue"]
    for column, stock in (("funds", "funds"), ("xp", "xp")):
        st = stats([v for v in (num(a.get(column)) for a in venues) if v])
        if st:
            klass = "sink" if column == "funds" else "faucet"
            sign = -1 if column == "funds" else 1
            r.add(**{"Mechanic type": "venue", "Mechanic": "Venue activity", "Stock": stock, "Class": klass,
                     "Amount": amount_text("per use,", st, stock), "Timing": "day", "Control": "chosen",
                     "Typical per week (h-eq)": sign * heq(stock, st[0] * uses * 0.25),
                     "Caps and limits": f"per_day and per_week limits; about {uses:g} uses a week and a quarter of them paying this are DRAFT",
                     "Source": f"data/venue_activities.json {column}; GameState.do_activity"})
    st = stats([num(a.get("hours")) for a in venues if num(a.get("hours"))])
    if st:
        r.add(**{"Mechanic type": "venue", "Mechanic": "Venue activity", "Stock": "hours", "Class": "converter",
                 "Amount": "SPENDS " + amount_text("per use,", st, "hours"), "Timing": "day", "Control": "chosen",
                 "Typical per week (h-eq)": -st[0] * uses, "Caps and limits": "work hours on a weekday, weekend hours at the weekend (0.5 h each)",
                 "Source": "data/venue_activities.json hours; VenueRules.visit_cost"})
    rewards = [delta_of(e.get("delta")) for a in venues for e in (a.get("rewards") or []) if isinstance(e, dict) and target_stock(e.get("target", "")) == "org_standing"]
    st = stats([d for d in rewards if d is not None])
    if st:
        r.add(**{"Mechanic type": "venue", "Mechanic": "Venue activity", "Stock": "org_standing", "Class": "converter",
                 "Amount": "GAINS " + amount_text("standing per organization,", st, "org_standing"), "Inputs": "hours[+]", "Timing": "day",
                 "Control": "chosen", "Typical per week (h-eq)": heq("org_standing", st[0] * uses * 0.5),
                 "Caps and limits": "diminishing gains", "Source": "data/venue_activities.json rewards"})
    districts = stats([num(a.get("district_delta")) for a in venues if num(a.get("district_delta"))])
    if districts:
        r.add(**{"Mechanic type": "venue", "Mechanic": "Venue activity", "Stock": "awareness_district", "Class": "converter",
                 "Amount": "GAINS " + amount_text("per use,", districts, "awareness_district"), "Inputs": "hours[+]", "Timing": "day",
                 "Control": "chosen", "Typical per week (h-eq)": heq("awareness_district", districts[0] * uses * 0.1),
                 "Source": "data/venue_activities.json district_delta"})

    # Staff.
    staff = load("staff")
    hire = stats([num(s.get("hiring_cost_yen")) for s in staff if num(s.get("hiring_cost_yen"))])
    if hire:
        r.add(**{"Mechanic type": "office", "Mechanic": "Hire staff", "Stock": "funds", "Class": "converter",
                 "Amount": "SPENDS " + amount_text("per hire,", hire, "funds"), "Timing": "once", "Control": "chosen",
                 "Caps and limits": "staff slots (staff_slots_reputation_cost, staff_slots_maximum_purchases)", "Source": "data/staff.json hiring_cost_yen; GameState.hire_staff"})
        r.add(**{"Mechanic type": "office", "Mechanic": "Hire staff", "Stock": "staff", "Class": "converter",
                 "Amount": "GAINS a staff member: a Tier 0 reward, daily task work and Loyalty", "Inputs": "funds[+]", "Timing": "once",
                 "Control": "chosen", "Source": "data/staff.json tier_0_reward"})
    for column in ("upgrade_cost_0_to_1_yen", "upgrade_cost_1_to_2_yen", "firing_cost_yen"):
        st = stats([num(s.get(column)) for s in staff if num(s.get(column))])
        if st:
            r.add(**{"Mechanic type": "office", "Mechanic": "Staff " + ("firing" if "firing" in column else "upgrade"), "Stock": "funds",
                     "Class": "sink" if "firing" in column else "converter", "Amount": ("SPENDS " if "upgrade" in column else "") + amount_text("per person,", st, "funds"),
                     "Timing": "once", "Control": "chosen", "Source": f"data/staff.json {column}"})
    r.add(**{"Mechanic type": "office", "Mechanic": "Staff upgrade", "Stock": "staff", "Class": "converter",
             "Amount": "GAINS a higher Staff Rank: a larger Tier reward, more task blocks and bonus", "Inputs": "funds[+]", "Timing": "once",
             "Control": "chosen", "Source": "data/staff.json upgrade_cost_*; GameState.upgrade_staff_member"})
    tier_rewards = [delta_of(e.get("delta")) for s in staff for k in ("tier_0_reward", "tier_1_reward", "tier_2_reward") for e in (s.get(k) or [])
                    if isinstance(e, dict) and target_stock(e.get("target", "")) == "org_standing"]
    st = stats([d for d in tier_rewards if d is not None])
    if st:
        r.add(**{"Mechanic type": "office", "Mechanic": "Staff rank reward", "Stock": "org_standing", "Class": "faucet",
                 "Amount": amount_text("on hiring or promotion,", st, "org_standing"), "Timing": "once", "Control": "chosen",
                 "Source": "data/staff.json tier_*_reward"})
    # Staff tasks.
    tasks = load("staff_tasks")
    uses = WEEKLY_USES["staff_task"]
    for key, klass, label in (("strong_reward", "faucet", "strong fit"), ("poor_penalty", "sink", "poor fit"), ("due_penalty", "sink", "Due and not given")):
        count = sum(1 for t in tasks if t.get(key))
        if count:
            r.add(**{"Mechanic type": "office", "Mechanic": f"Staff task ({label})", "Stock": "constituency", "Class": klass,
                     "Amount": f"{count} of {len(tasks)} tasks name a {label} result, usually 1-2 points of one meter or XP; rewards are capped per day",
                     "Timing": "day", "Control": "forced" if key == "due_penalty" else "chosen",
                     "Typical per week (h-eq)": (1.0 if klass == "faucet" else -0.5) * uses * count / len(tasks) * 0.5,
                     "Caps and limits": "rewards capped per day (+/-2 meters, +3 XP); about 10 tasks a week is a DRAFT frequency",
                     "Source": f"data/staff_tasks.json {key}; StaffTasks.parse_effects"})

    # Backings: the reputation and Constituency price.
    mods = load("modifiers")
    for column, stock in (("reputation_cost", "reputation"), ("jiban_cost", "constituency"), ("funds_cost", "funds")):
        st = stats([v for v in (num(m.get(column)) for m in mods) if v])
        if st:
            r.add(**{"Mechanic type": "office", "Mechanic": "Backing purchase", "Stock": stock, "Class": "converter",
                     "Amount": "SPENDS " + amount_text("per backing,", st, stock, "backings that cost it"), "Timing": "once", "Control": "chosen",
                     "Caps and limits": "needs organization standing (required_standing 60); timed backings lapse", "Source": f"data/modifiers.json {column}; GameState.buy_modifier"})
    r.add(**{"Mechanic type": "office", "Mechanic": "Backing purchase", "Stock": "backings", "Class": "converter",
             "Amount": "GAINS a backing: a stage-start or card effect whose trigger organizations like the player",
             "Inputs": "reputation[+]; constituency[+]; funds[+]; org_standing[g: org_standing >= 60 | high | +]", "Timing": "once", "Control": "chosen",
             "Source": "data/modifiers.json; MetaRules.active_modifiers"})

    # Laws.
    laws = load("law_effects")
    for column, stock in (("funds", "funds"), ("xp", "xp"), ("constituency_support", "constituency"), ("reputation", "reputation"), ("party_support", "party_support")):
        st = stats([v for v in (num(l.get(column)) for l in laws) if v])
        if st:
            r.add(**{"Mechanic type": "bill", "Mechanic": "Law effect", "Stock": stock, "Class": "faucet",
                     "Amount": amount_text("per law,", st, stock, "laws that move it") + "; timing per row (Once or Every level)",
                     "Inputs": "laws[+]", "Timing": "level", "Control": "passive", "Source": f"data/law_effects.json {column}; StatuteBook"})
    # Cosmetics.
    for column, stock in (("cost_yen", "funds"), ("cost_xp", "xp")):
        st = stats([v for v in (num(c.get(column)) for c in load("cosmetic_packages")) if v])
        if st:
            r.add(**{"Mechanic type": "office", "Mechanic": "Cosmetic package", "Stock": stock, "Class": "converter",
                     "Amount": "SPENDS " + amount_text("per package,", st, stock), "Timing": "once", "Control": "chosen",
                     "Source": f"data/cosmetic_packages.json {column}"})
    r.add(**{"Mechanic type": "office", "Mechanic": "Cosmetic package", "Stock": "cosmetics", "Class": "converter",
             "Amount": "GAINS a look for the Office, music, calendar or UI style: no effect on strength", "Inputs": "funds[+]; xp[+]",
             "Timing": "once", "Control": "chosen", "Source": "data/cosmetic_packages.json"})
    return r.rows


# ---------------------------------------------------------------------------
# The hand-kept file and the week tokens
# ---------------------------------------------------------------------------
def week_tokens(model: dict, balance: dict, booster: dict, sanban: list) -> dict:
    """Values a manual row's 'Typical per week' may ask for with  =name  (in hours-equivalent per standard week)."""
    standard = model["weeks"]["standard"]
    mult = float(balance.get("week_decay_multiplier", 1))
    tokens = {"dues": -standard["dues"] / FUNDS_PER_HOUR, "wages": -standard["wages"] / FUNDS_PER_HOUR}
    for row in sanban:
        name = {"Constituency support": "constituency", "Reputation": "reputation"}.get(row.get("name_en"))
        if name and row.get("decay_percent") is not None:
            fraction = min(1.0, float(row["decay_percent"]) / 100.0 * mult)
            tokens["decay_" + name] = -TYPICAL_ABOVE_START[name] * fraction * POINT_HOURS
    percent = min(1.0, float(booster.get("decay_percent", 0)) / 100.0 * mult)
    tokens["decay_org"] = -TYPICAL_ABOVE_START["org_standing"] * percent * POINT_HOURS * ORGS_ABOVE_START
    tokens["dues_relief"] = 50000 / FUNDS_PER_HOUR
    tokens["ae06_xp"] = -50 / XP_PER_HOUR
    return tokens


def read_manual(tokens: dict) -> list:
    rows = []
    with MANUAL.open(encoding="utf-8", newline="") as handle:
        for raw in csv.DictReader(handle):
            row = {c: (raw.get(c) or "").strip() for c in COLUMNS}
            cell = row["Typical per week (h-eq)"]
            if cell.startswith("="):
                if cell[1:] not in tokens:
                    raise SystemExit(f"economy_flows_manual.csv: {row['Flow ID']} asks for the unknown token {cell}")
                row["Typical per week (h-eq)"] = tokens[cell[1:]]
            elif cell:
                row["Typical per week (h-eq)"] = float(cell)
            else:
                row["Typical per week (h-eq)"] = None
            rows.append(row)
    return rows


# ---------------------------------------------------------------------------
# Catalog, links, loops
# ---------------------------------------------------------------------------
INPUT_RE = re.compile(r"\s*([a-z_]+)\[(.*)\]\s*$")


def parse_inputs(text: str) -> list:
    """[(stock, sign, gate_condition, side)] from an Inputs cell."""
    found = []
    for part in [p for p in text.split(";") if p.strip()]:
        m = INPUT_RE.match(part)
        if not m:
            raise SystemExit(f"Inputs cell not understood: {part!r}")
        stock, body = m.group(1), m.group(2)
        if stock not in NODES:
            raise SystemExit(f"Inputs name an unknown stock: {stock!r}")
        if body.startswith("g:"):
            condition, side, sign = [x.strip() for x in body[2:].split("|")]
            found.append((stock, sign, condition, side))
        else:
            found.append((stock, body.strip(), "", ""))
    return found


def validate(rows: list) -> list:
    problems = []
    for row in rows:
        fid = row["Flow ID"]
        if not row["Stock"] or row["Stock"] not in NODES:
            problems.append(f"{fid}: Stock {row['Stock']!r} is empty or unknown")
        if not row["Source"]:
            problems.append(f"{fid}: no Source")
        for column, allowed in (("Class", CLASSES), ("Timing", TIMINGS), ("Control", CONTROLS), ("Status", STATUSES), ("Mechanic type", MECHANIC_TYPES)):
            if row[column] not in allowed:
                problems.append(f"{fid}: {column} {row[column]!r} is not one of {sorted(allowed)}")
    ids = [row["Flow ID"] for row in rows]
    if len(ids) != len(set(ids)):
        problems.append("Flow IDs are not unique")
    return problems


def build_links(rows: list) -> list:
    """One link per (from, to, sign, gate) from every row's Inputs, plus the hub links."""
    links = {}

    def add(frm, to, sign, gate, through, timing, fid):
        key = (frm, to, sign, gate)
        entry = links.setdefault(key, {"through": [], "timing": [], "flows": []})
        if through and through not in entry["through"]:
            entry["through"].append(through)
        if timing and timing not in entry["timing"]:
            entry["timing"].append(timing)
        if fid and fid not in entry["flows"]:
            entry["flows"].append(fid)

    for row in rows:
        for stock, sign, condition, side in parse_inputs(row["Inputs"]):
            gate = f"{condition} | {side} | {sign}" if condition else ""
            add(stock, row["Stock"], "g" if condition else sign, gate, row["Mechanic"], row["Timing"], row["Flow ID"])
    # The hub: every strength asset feeds win rate; win rate pays every stock a room or level pays; it moves standing both ways.
    for asset in ("cards", "items", "staff", "backings", "tips"):
        add(asset, HUB, "+", "", "strength in a fight", "stage", "")
    paid = sorted({row["Stock"] for row in rows if row["Mechanic type"] in ("room", "level") and row["Class"] == "faucet" and row["Stock"] != "org_standing"})
    for stock in paid:
        flows = [row["Flow ID"] for row in rows if row["Stock"] == stock and row["Mechanic type"] in ("room", "level") and row["Class"] == "faucet"]
        add(HUB, stock, "+", "", "room and level pay", "stage", ",".join(flows))
    add(HUB, "org_standing", "~", "", "answers please some organizations and annoy others (the bill lean)", "stage", "")
    return [{"from": k[0], "to": k[1], "sign": k[2], "gate": k[3], "through": "; ".join(v["through"]), "timing": slowest(v["timing"]),
             "flows": ",".join(sorted(set(",".join(v["flows"]).split(",")) - {""}))} for k, v in sorted(links.items())]


TIMING_ORDER = ["card", "turn", "stage", "day", "level", "week", "once", "threshold"]


def slowest(timings) -> str:
    timings = [t for t in timings if t]
    return max(timings, key=TIMING_ORDER.index) if timings else "stage"


def find_cycles(links: list, max_len: int = 6) -> list:
    """Every simple cycle of up to max_len links over the signed links (a '~' link is a choice and is left out)."""
    edges = [(i, l) for i, l in enumerate(links) if l["sign"] != "~"]
    out_edges = {}
    for i, l in edges:
        out_edges.setdefault(l["from"], []).append((i, l))
    order = {n: k for k, n in enumerate(NODES)}
    cycles = []

    def walk(start, node, path_edges, visited):
        for i, l in out_edges.get(node, []):
            target = l["to"]
            if target == start:
                cycles.append(path_edges + [i])
            elif target not in visited and order[target] > order[start] and len(path_edges) + 1 < max_len:
                walk(start, target, path_edges + [i], visited | {target})

    for node in NODES:
        walk(node, node, [], {node})
    return cycles


def edge_dependence(link: dict) -> str:
    """The sign of the dependence an edge carries when active: '+' or '-' (a gate carries its own on its active side)."""
    if link["sign"] == "g":
        return link["gate"].split("|")[-1].strip()
    return link["sign"]


def describe_loops(links: list, rows: list) -> dict:
    cycles = find_cycles(links)
    by_id = {r["Flow ID"]: r for r in rows}
    entries = []
    for edge_ids in cycles:
        chain = [links[i] for i in edge_ids]
        negatives = sum(1 for l in chain if edge_dependence(l) == "-")
        kind = "R" if negatives % 2 == 0 else "B"
        nodes = [l["from"] for l in chain]
        low = [l for l in chain if l["sign"] == "g" and l["gate"].split("|")[1].strip() == "low"]
        flows = sorted({f for l in chain for f in l["flows"].split(",") if f})
        entries.append({"nodes": nodes, "edges": edge_ids, "kind": kind, "low": bool(low), "timing": slowest([l["timing"] for l in chain]),
                        "flows": flows, "gates": [l["gate"].split("|")[0].strip() for l in chain if l["sign"] == "g"],
                        "text": " -> ".join(f"{l['from']} ({l['sign'] if l['sign'] != 'g' else 'g' + edge_dependence(l)})" for l in chain) + f" -> {nodes[0]}"})
    entries.sort(key=lambda e: (len(e["nodes"]), e["text"]))
    # Flags.
    b_stocks = set()
    for e in entries:
        if e["kind"] == "B":
            b_stocks.update(e["nodes"])
    for e in entries:
        e["unbraked"] = e["kind"] == "R" and not (set(e["nodes"]) & b_stocks)
        e["spiral"] = e["kind"] == "R" and e["low"]
    status = {}
    for row in rows:
        status.setdefault(row["Stock"], set()).add(row["Status"])
    has_out = {l["from"] for l in links}
    has_in = {l["to"] for l in links}
    dead = sorted(n for n in STOCKS + ASSETS if n not in has_out or status.get(n) == {"unused"})
    return {"entries": entries, "dead": dead, "has_in": has_in, "has_out": has_out, "status": status}


# Expected loops, matched by the stocks on a cycle and its kind: (name, kind, required nodes, a required self-loop or hop pair).
EXPECTED_LOOPS = [
    ("R1 deck", "R", ["xp", "cards", HUB]), ("R2 items and staff", "R", ["funds", "items", HUB]), ("R2b staff", "R", ["funds", "staff", HUB]),
    ("R3 backings", "R", ["org_standing", "backings", HUB]), ("R4 Reputation", "R", ["reputation", HUB]),
    ("R5 awareness (District)", "R", ["awareness_district", HUB]), ("R5 awareness (National)", "R", ["awareness_national", HUB]),
    ("R6 Party support / M09", "R", ["party_support", HUB]),
    ("B1 dues steps", "B", ["party_support", "funds"]), ("B2 dues share", "B", ["funds"]), ("B3 wages", "B", ["staff", "funds"]),
    ("B4 decay (Constituency)", "B", ["constituency"]), ("B4 decay (Reputation)", "B", ["reputation"]), ("B4 decay (organizations)", "B", ["org_standing"]),
    ("B5 Funds cap", "B", ["funds"]), ("B6 diminishing standing", "B", ["org_standing"]), ("B7 whip", "B", ["party_support"]),
    ("S1 Party support 0", "S", ["party_support", "funds"]), ("S2 District awareness <= 13", "S", ["awareness_district", "xp"]),
    ("S3 National awareness <= 20", "S", ["awareness_national", "org_standing"]),
]

EXPECTED_LINKS = [
    ("funds", HUB, "+"), ("funds", "funds", "-"), ("xp", HUB, "+"), ("xp", "funds", "+"), ("party_support", "funds", "-"),
    ("party_support", "funds", "g"), ("party_support", HUB, "g"), ("party_support", "party_support", "-"),
    ("awareness_district", HUB, "g"), ("awareness_national", HUB, "g"), ("awareness_district", "xp", "g"), ("awareness_district", "org_standing", "g"),
    ("awareness_national", "org_standing", "g"), ("awareness_national", "funds", "g"), ("org_standing", HUB, "g"),
    ("org_standing", "org_standing", "-"), ("org_standing", "org_standing", "~"), ("constituency", HUB, "g"),
    ("cards", HUB, "+"), ("items", HUB, "+"), ("staff", HUB, "+"), ("backings", HUB, "+"), ("tips", HUB, "+"),
    (HUB, "funds", "+"), (HUB, "xp", "+"), (HUB, "org_standing", "~"),
]


def expected_loops_found(analysis: dict) -> list:
    """For each expected loop name, whether some cycle of the right kind covers its stocks (a spiral is an R loop through a low gate)."""
    results = []
    for name, kind, required in EXPECTED_LOOPS:
        hit = None
        for e in analysis["entries"]:
            if not set(required) <= set(e["nodes"]):
                continue
            if kind == "S" and not e["spiral"]:
                continue
            if kind in ("R", "B") and e["kind"] != kind:
                continue
            if len(required) == 1 and len(e["nodes"]) != 1:
                continue
            hit = e
            break
        results.append((name, hit))
    return results


# ---------------------------------------------------------------------------
# Writers
# ---------------------------------------------------------------------------
def csv_text(columns: list, rows: list) -> str:
    buffer = io.StringIO(newline="")
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(columns)
    for row in rows:
        writer.writerow([cell_text(row.get(c)) for c in columns])
    return buffer.getvalue()


def cell_text(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        return f"{value:.1f}"
    return str(value)


def lever_report(rows: list, balance: dict, rules: dict) -> tuple:
    text = " ".join(" ".join([r["Amount"], r["Caps and limits"], r["Inputs"], r["Source"], r["Difficulty"]]) for r in rows).lower()
    missing, ignored = [], 0
    for source, keys in (("Balance", balance), ("Rules", rules)):
        for key in sorted(k for k in keys if not k.startswith("_")):
            if key.lower() in text:
                continue
            if key.startswith(IGNORE_PREFIXES):
                ignored += 1
                continue
            missing.append((source, key))
    return missing, ignored


def week_markdown(model: dict, rows: list, missing: list, ignored: int) -> str:
    std, early = model["weeks"]["standard"], model["weeks"]["early"]
    out = ["# Standard week, priced in hours-equivalent", "",
           "Generated by `tools/economy_map.py`; do not edit. Constants are named at the top of the script.", "",
           "## Inputs", "",
           f"- {LEVEL_HOURS_PER_WEEK} work hours in levels, {WIN_RATE:.0%} of rooms won; {model['rooms_per_week']:.1f} rooms a week at {model['hours_per_room']:.2f} h a room.",
           f"- Rates: {FUNDS_PER_HOUR:,}円 = 1 h; {XP_PER_HOUR} XP = 1 h; 1 point of Constituency, Reputation, Party support or standing = 1 h; 1 awareness point = {AWARENESS_HOURS} h; 1 weekend hour = {WEEKEND_HOUR_HOURS} h.",
           f"- Per-hour medians over {model['levels']} levels (room win pay plus level bonus, over level hours): {fmt(model['per_hour_funds'])}円 an hour, {fmt(model['per_hour_xp'])} XP an hour.",
           f"- Standard week: Party support {std['party_support']}, staff invested {', '.join(fmt(i) for i in std['invested'])}円. Early week: Party support {early['party_support']}, hires {', '.join(fmt(i) for i in early['invested'])}円.",
           "- Dues and wages use `PartyDues.week_dues` and `StaffLoyalty.wage` **re-implemented in this script**; `tests/test_economy_week.gd` runs the real GDScript on the same inputs (from `economy_week.json`) and fails if they differ.",
           "", "## Earnings", "",
           f"| | Funds | XP |", "| --- | ---: | ---: |",
           f"| Per level hour (median) | {fmt(model['per_hour_funds'])}円 | {fmt(model['per_hour_xp'])} |",
           f"| Week ({LEVEL_HOURS_PER_WEEK} h x {WIN_RATE:.0%}) | {fmt(model['earned_funds'])}円 | {fmt(model['earned_xp'])} |", ""]
    faucet_types = {}
    for row in rows:
        h = row["Typical per week (h-eq)"]
        if row["Class"] == "faucet" and h is not None and h > 0:
            faucet_types.setdefault(row["Mechanic type"], 0.0)
            faucet_types[row["Mechanic type"]] += h
    out += ["## 1. Faucets by mechanic type (h-eq a week)", "", "| Mechanic type | h-eq |", "| --- | ---: |"]
    for k in sorted(faucet_types):
        out.append(f"| {k} | {faucet_types[k]:.1f} |")
    out.append(f"| **total** | **{sum(faucet_types.values()):.1f}** |")
    forced = [r for r in rows if r["Control"] == "forced" and r["Class"] in ("sink", "decay") and r["Typical per week (h-eq)"] is not None]
    out += ["", "## 2. Forced sinks (h-eq a week)", "", "| Flow | Mechanic | Stock | h-eq |", "| --- | --- | --- | ---: |"]
    for r in sorted(forced, key=lambda r: r["Typical per week (h-eq)"]):
        out.append(f"| {r['Flow ID']} | {r['Mechanic']} | {r['Stock']} | {r['Typical per week (h-eq)']:.1f} |")
    out.append(f"| | **total** | | **{sum(r['Typical per week (h-eq)'] for r in forced):.1f}** |")
    chosen = [r for r in rows if r["Class"] in ("sink", "converter") and r["Control"] == "chosen"]
    out += ["", "## 3. Chosen sinks and converters (listed, not totaled)", "", "| Flow | Mechanic | Stock | Class | h-eq a week |", "| --- | --- | --- | --- | ---: |"]
    for r in chosen:
        h = r["Typical per week (h-eq)"]
        out.append(f"| {r['Flow ID']} | {r['Mechanic']} | {r['Stock']} | {r['Class']} | {'' if h is None else f'{h:.1f}'} |")
    out += ["", "## 4. Sink share: forced Funds sinks divided by Funds faucets", "",
            "| Week | Funds earned | Dues | Wages | Forced sinks | Share | Target 35-50% |", "| --- | ---: | ---: | ---: | ---: | ---: | --- |"]
    for label, w in (("Standard", std), ("Early", early)):
        ok = TARGET_SHARE[0] <= w["share"] <= TARGET_SHARE[1]
        out.append(f"| {label} | {fmt(model['earned_funds'])}円 | {fmt(w['dues'])}円 | {fmt(w['wages'])}円 | {fmt(w['forced_funds'])}円 | {w['share']:.0%} | {'in range' if ok else 'OUT of range'} |")
    out += ["", f"The dues limit (`dues_limit_cap_percent` of the Funds cap: {fmt(model['dues_cfg']['max_per_week'])}円 at the starting cap) holds the standard week's dues: "
            f"uncapped they would be {fmt(week_dues({**model['dues_cfg'], 'max_per_week': 0}, std['party_support'], int(round(model['earned_funds']))))}円.",
            "", "## Levers not in the catalog", "",
            f"Balance and Rules rows whose key is named in no catalog row's Amount, Caps, Inputs, Source or Difficulty (a warning, not a failure). "
            f"{ignored} presentation levers (images, scrolling, cue timing, colours and the like) are left out of this list.", ""]
    groups = {}
    for source, key in missing:
        groups.setdefault(key.split("_")[0], []).append(key)
    out.append(f"{len(missing)} levers in {len(groups)} groups (by the first word of the key):")
    out.append("")
    for word in sorted(groups):
        out.append(f"- **{word}** ({len(groups[word])}): " + ", ".join(f"`{k}`" for k in groups[word]))
    return "\n".join(out) + "\n"


def loops_markdown(analysis: dict, links: list, found: list) -> str:
    entries = analysis["entries"]
    out = ["# Loops in the economy links", "",
           "Generated by `tools/economy_map.py`; do not edit. A cycle with an even number of `-` links is **R** (reinforcing); an odd number is **B** (balancing). "
           "A gated link counts as the sign of its dependence on its active side (`g+` or `g-`). Mixed (`~`) links are left out.", "",
           f"{len(entries)} simple cycles of up to six links; {sum(1 for e in entries if e['kind'] == 'R')} R, {sum(1 for e in entries if e['kind'] == 'B')} B.", "",
           "## Expected loops", "", "| Loop | Found | Example |", "| --- | --- | --- |"]
    for name, hit in found:
        out.append(f"| {name} | {'yes' if hit else '**MISSING**'} | {hit['text'] if hit else ''} |")
    flagged = [e for e in entries if e["unbraked"] or e["spiral"]]
    low_gates = {}
    for e in entries:
        if e["spiral"]:
            for l in (links[i] for i in e["edges"]):
                if l["sign"] == "g" and l["gate"].split("|")[1].strip() == "low":
                    low_gates.setdefault(l["gate"].split("|")[0].strip(), []).append(e)
    out += ["", "## Flags", "",
            f"- **Unbraked R** (an R loop sharing no stock with any B loop): {sum(1 for e in entries if e['unbraked'])}",
            f"- **Spiral** (an R loop through a gate's low side): {sum(1 for e in entries if e['spiral'])}",
            f"- **Dead ends** (no link out, or status unused): {', '.join(analysis['dead']) or 'none'}", "",
            "## Spirals by low gate", "",
            "An R loop through the low side of a gate: the gate's penalty lowers the stock again. The shortest cycle through each is shown. "
            "Whether a forced recovery room (a Town Hall, the Steering Committee) acts as a brake is a design judgement: FL535 and FL506 are written as recoveries (`-`).", "",
            "| Low gate | R cycles through it | Shortest |", "| --- | ---: | --- |"]
    for gate in sorted(low_gates):
        shortest = min(low_gates[gate], key=lambda e: (len(e["nodes"]), e["text"]))
        out.append(f"| {gate} | {len(low_gates[gate])} | {shortest['text']} |")
    out += ["", "## Cycles with a flag", "", "| Kind | Flags | Path | Slowest | Flow IDs |", "| --- | --- | --- | --- | --- |"]
    for e in flagged:
        flags = ", ".join(f for f, on in (("unbraked R", e["unbraked"]), ("spiral", e["spiral"])) if on)
        out.append(f"| {e['kind']} | {flags} | {e['text']} | {e['timing']} | {', '.join(e['flows'])} |")
    out += ["", "## Every cycle", "", "| Kind | Path | Slowest | Flow IDs |", "| --- | --- | --- | --- |"]
    for e in entries:
        out.append(f"| {e['kind']} | {e['text']} | {e['timing']} | {', '.join(e['flows'])} |")
    return "\n".join(out) + "\n"


def run() -> tuple:
    """Everything the tool writes, as {filename: text}, plus the findings the report needs."""
    balance = load("balance")
    rules = load("rules")
    booster = load("booster_standing")
    model = week_model(balance)
    tokens = week_tokens(model, balance, booster, load("sanban"))
    rows = data_pass(model, balance) + read_manual(tokens)
    problems = validate(rows)
    if problems:
        raise SystemExit("economy_map: the catalog has problems:\n  " + "\n  ".join(problems))
    links = build_links(rows)
    for number, link in enumerate(links, 1):
        link["id"] = f"LK{number:03d}"
    analysis = describe_loops(links, rows)
    found = expected_loops_found(analysis)
    link_keys = {(l["from"], l["to"], l["sign"]) for l in links}
    missing_links = [k for k in EXPECTED_LINKS if k not in link_keys]
    missing, ignored = lever_report(rows, balance, rules)
    link_rows = [{"Link ID": l["id"], "From": l["from"], "To": l["to"], "Sign": l["sign"], "Gate": l["gate"], "Through": l["through"],
                  "Timing": l["timing"], "Flow IDs": l["flows"]} for l in links]
    week_json = {"standard": model["weeks"]["standard"], "early": model["weeks"]["early"], "funds_earned": int(round(model["earned_funds"])),
                 "wage_percent": model["wage_percent"], "dues_balance": {k: v for k, v in model["dues_cfg"].items()}}
    files = {"economy_catalog.csv": csv_text(COLUMNS, rows), "economy_links.csv": csv_text(LINK_COLUMNS, link_rows),
             "economy_loops.md": loops_markdown(analysis, links, found), "economy_week.md": week_markdown(model, rows, missing, ignored),
             "economy_week.json": json.dumps(week_json, indent=2, sort_keys=True) + "\n"}
    findings = {"rows": len(rows), "links": len(links), "cycles": len(analysis["entries"]), "found": found, "missing_links": missing_links,
                "missing_levers": missing, "ignored": ignored, "model": model, "dead": analysis["dead"], "analysis": analysis, "catalog": rows}
    return files, findings


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Catalog the economy's flows, links and loops (P19).")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="exit 1 if the outputs on disk differ from a fresh run")
    mode.add_argument("--write", action="store_true", help="rewrite the outputs (the default)")
    args = parser.parse_args(argv)
    files, findings = run()
    if args.check:
        stale = [name for name, text in files.items() if not (OUT / name).exists() or (OUT / name).read_text(encoding="utf-8") != text]
        if stale:
            print("economy_map: out of date: " + ", ".join(stale) + ". Run python3 tools/economy_map.py and commit the result.")
            return 1
        print(f"economy_map: up to date ({findings['rows']} flows, {findings['links']} links, {findings['cycles']} cycles).")
        return 0
    OUT.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        (OUT / name).write_text(text, encoding="utf-8", newline="")
    print(f"economy_map: wrote {len(files)} files to {OUT.relative_to(ROOT)}: {findings['rows']} flows, {findings['links']} links, {findings['cycles']} cycles.")
    for name, hit in findings["found"]:
        if hit is None:
            print(f"  expected loop not found: {name}")
    for link in findings["missing_links"]:
        print(f"  expected link not found: {link}")
    if findings["missing_levers"]:
        print(f"  warning: {len(findings['missing_levers'])} levers are named in no catalog row (see economy_week.md)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
