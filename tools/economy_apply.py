#!/usr/bin/env python3
"""P17 economy pass (2026-11-24, Cameron): room pay and level completion bonuses, written into the workbook with wbx.

The standard: ONE HOUR of play at standard difficulty pays HOURLY_FUNDS yen and HOURLY_XP XP. A room pays hours x rate x its
difficulty factor; a level adds a completion bonus by tier. The pass can be rerun after content changes:

    python3 tools/economy_apply.py              # apply, using the starter-kit sweep in design/bench/balance
    python3 tools/economy_apply.py --dry-run    # show the bands and the totals, change nothing
    python3 tools/economy_apply.py --bands bands.json   # use a saved band table instead of the sweep logs

Then python3 tools/export_data.py (must say "No errors").

Fixed by decision (Cameron, 2026-11-24), never changed here:
  * a room that pays 0 or blank Funds today stays at 0 Funds (a room that pays neither Funds nor XP is left whole);
  * Vote, Visit and Trade rooms (factor 0) and every column except Win Funds and Win XP;
  * a level whose rooms pay 0 Funds keeps a blank Funds bonus.
"""
import argparse
import collections
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "workbook"))
from wbx import WB          # noqa: E402
import balance_audit        # noqa: E402

# --- The rates (named constants, so a rerun after content changes is one command) ---------------------------------------------
HOURLY_FUNDS = 8000                 # yen for one hour at standard difficulty
HOURLY_XP = 20                      # XP for one hour at standard difficulty
FUNDS_ROUND = 1000                  # room Funds round to this
TIER_BONUS_PERCENT = {0: None, 1: 10, 2: 25}   # level completion bonus: share of the rooms' total; tier 0 has none
BONUS_FUNDS_ROUND = 1000
# Starter-kit win rate -> (band, factor); the first line a rate reaches wins.
BANDS = [(0.85, "Easy", 0.8), (0.60, "Standard", 1.0), (0.30, "Hard", 1.25), (0.0, "Very hard", 1.5)]
FACTOR_NONCOMBAT = 0.8              # non-combat rooms that pay Funds or XP today
FACTOR_UNCOVERED_COMBAT = 1.0       # a combat type the sweep did not cover
ZERO_MODES = {"Vote", "Visit", "Trade"}   # floor vote, member visit, lobbyist trade: factor 0, unchanged
STAGES, LEVELS = "Stages", "Levels"
SWEEP_DIR = ROOT / "design" / "bench" / "balance"


def room_type(name):
    """The stage name before ' on ', ' for ', ' with ' or ':' (Party Caucus on Rural Hospitals -> Party Caucus)."""
    return re.split(r"\s+(?:on|for|with)\s+|:", name)[0].strip()


def band_for(rate):
    for floor, label, factor in BANDS:
        if rate >= floor:
            return label, factor
    return BANDS[-1][1], BANDS[-1][2]


def num(value):
    """A workbook cell as a number (blank or text -> None)."""
    if value is None or str(value).strip() == "":
        return None
    try:
        return float(str(value).replace(",", ""))
    except ValueError:
        return None


def starter_rates(stage_rows):
    """{room type: mean starter-kit win rate over its combat stages in the sweep}, and the number of stages measured."""
    sweeps = balance_audit.parse_sweeps(str(SWEEP_DIR))["starter"]
    per_type = collections.defaultdict(list)
    for stage_id, row in stage_rows.items():
        measured = sweeps.get(stage_id)
        if measured and measured[1] > 0:
            per_type[row["type"]].append(measured[0] / measured[1])
    return {t: sum(v) / len(v) for t, v in per_type.items()}, {t: len(v) for t, v in per_type.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--bands", help="a saved {room type: [rate, band, factor]} JSON instead of the sweep logs")
    ap.add_argument("--save-bands", default=str(ROOT / "design" / "bench" / "p17_bands.json"))
    args = ap.parse_args()

    wb = WB(str(ROOT / "design" / "Game_Workbook.xlsx"))
    rows = wb.rows(STAGES)
    header = rows[1]
    col = {name: letter for letter, name in header.items()}
    c_id, c_name, c_mode = col["Stage ID"], col["Stage (EN)"], col["Mode"]
    c_funds, c_xp, c_units = col["Win ΔYen"], col["Win ΔXP"], col["Time Units"]

    stages = {}
    for number, cells in rows.items():
        if number == 1 or not cells.get(c_id):
            continue
        stages[cells[c_id]] = {"row": number, "name": cells.get(c_name, ""), "type": room_type(cells.get(c_name, "")),
                               "mode": cells.get(c_mode, ""), "funds": num(cells.get(c_funds)) or 0.0,
                               "xp": num(cells.get(c_xp)) or 0.0, "hours": num(cells.get(c_units))}

    if args.bands:
        saved = json.load(open(args.bands))
        rates = {t: v[0] for t, v in saved.items()}
        counts = {}
    else:
        rates, counts = starter_rates(stages)

    # --- The band of each combat room type ------------------------------------------------------------------------------------
    bands = {}
    for stage in stages.values():
        t = stage["type"]
        if stage["mode"] == "Combat" and t in rates and t not in bands:
            label, factor = band_for(rates[t])
            bands[t] = [round(rates[t], 3), label, factor, counts.get(t, 0)]
    Path(args.save_bands).parent.mkdir(parents=True, exist_ok=True)
    json.dump(bands, open(args.save_bands, "w"), indent=1)

    def factor_for(stage):
        if stage["mode"] in ZERO_MODES:
            return 0.0
        if stage["funds"] <= 0 and stage["xp"] <= 0:
            return None                    # pays neither today: left whole
        if stage["mode"] == "Non-combat":
            return FACTOR_NONCOMBAT
        if stage["type"] in bands:
            return bands[stage["type"]][2]
        return FACTOR_UNCOVERED_COMBAT

    # --- Step 2: room pay -------------------------------------------------------------------------------------------------------
    changes, new_pay, report_types = [], {}, collections.defaultdict(list)
    for stage_id, stage in stages.items():
        factor = factor_for(stage)
        hours = stage["hours"] if stage["hours"] is not None else 1.0      # blank time units means 1 hour
        funds, xp = stage["funds"], stage["xp"]
        if factor:
            if funds > 0:
                funds = round(hours * HOURLY_FUNDS * factor / FUNDS_ROUND) * FUNDS_ROUND
            xp = round(hours * HOURLY_XP * factor)
        new_pay[stage_id] = (funds, xp)
        if (funds, xp) != (stage["funds"], stage["xp"]):
            changes.append((stage_id, stage["row"], funds, xp))
        if factor:
            report_types[stage["type"]].append((funds, xp))
    if not args.dry_run:
        for stage_id, row, funds, xp in changes:
            wb.set_cell(STAGES, row, c_funds, int(funds), style_from=row)
            wb.set_cell(STAGES, row, c_xp, int(xp), style_from=row)

    # --- Step 3: level completion bonus -----------------------------------------------------------------------------------------
    lrows = wb.rows(LEVELS)
    lcol = {name.replace("  ", " "): letter for letter, name in lrows[1].items()}
    l_id, l_tier = lcol["Level ID"], lcol["Level Tier"]
    l_yen, l_xp = lcol["Bonus Win Range ΔYen"], lcol["Bonus Win Range ΔXP"]
    slot_cols = [letter for letter, name in lrows[1].items() if name.startswith("Stage ID for Part")]
    level_totals, level_changes, hours_by_level = [], [], {}
    for number, cells in lrows.items():
        if number == 1 or not cells.get(l_id):
            continue
        tier = int(num(cells.get(l_tier)) or 0)
        funds_total, xp_total, hours_total = 0.0, 0.0, 0.0
        for letter in slot_cols:
            stage_id = (cells.get(letter) or "").strip()
            if stage_id in new_pay:                     # a bill slot or a blank one counts as the Floor Vote room (pays 0)
                funds_total += new_pay[stage_id][0]
                xp_total += new_pay[stage_id][1]
                h = stages[stage_id]["hours"]
                hours_total += h if h is not None else 1.0
            elif stage_id and stage_id.upper() != "N/A":   # a bill slot is the Floor Vote room (pays 0, takes its hours)
                floor = stages.get("ST23", {}).get("hours")
                hours_total += floor if floor is not None else 1.0
        share = TIER_BONUS_PERCENT.get(tier)
        if share is None:
            new_yen, new_xp = "", ""                    # tier 0: no bonus
        else:
            # A level whose Funds bonus is 0 or blank today keeps it blank, whatever its rooms pay (Cameron: no Funds where none are paid).
            had_funds_bonus = (num((cells.get(l_yen) or "").split("-")[-1]) or 0) > 0
            bonus_funds = round(funds_total * share / 100.0 / BONUS_FUNDS_ROUND) * BONUS_FUNDS_ROUND if funds_total > 0 and had_funds_bonus else 0
            bonus_xp = round(xp_total * share / 100.0)
            new_yen = str(int(bonus_funds)) if bonus_funds > 0 else ""
            new_xp = str(int(bonus_xp)) if bonus_xp > 0 else ""
        level_totals.append((cells[l_id], tier, funds_total, xp_total, hours_total, new_yen, new_xp))
        if not args.dry_run:
            wb.set_cell(LEVELS, number, l_yen, new_yen, style_from=number)
            wb.set_cell(LEVELS, number, l_xp, new_xp, style_from=number)
        level_changes.append(cells[l_id])
    if not args.dry_run:
        wb.save()

    # --- Report -------------------------------------------------------------------------------------------------------------------
    print("Room type bands (starter-kit sweep):")
    for t, (rate, label, factor, n) in sorted(bands.items(), key=lambda kv: kv[1][0], reverse=True):
        print(f"  {t:34s} {rate:5.0%} over {n:3d} stage(s)  {label:9s} x{factor}")
    print(f"\nStages changed: {len(changes)} of {len(stages)}   Levels rewritten: {len(level_changes)}")
    total_funds = sum(t[2] + (int(t[5]) if t[5] else 0) for t in level_totals)
    total_xp = sum(t[3] + (int(t[6]) if t[6] else 0) for t in level_totals)
    print(f"Total level pay (rooms + completion bonus): {total_funds:,.0f}円 and {total_xp:,.0f} XP over {len(level_totals)} levels")
    per_hour = sorted((t[2] + (int(t[5]) if t[5] else 0)) / t[4] for t in level_totals if t[2] > 0 and t[4] > 0)
    if per_hour:
        lo, hi = per_hour[int(len(per_hour) * 0.1)], per_hour[int(len(per_hour) * 0.9) - 1]
        print(f"Funds per hour, middle 80% of the {len(per_hour)} levels that pay Funds: {lo:,.0f} to {hi:,.0f}円")
    print("\nMedian room pay by type:")
    for t, pays in sorted(report_types.items()):
        funds = sorted(p[0] for p in pays)
        xps = sorted(p[1] for p in pays)
        print(f"  {t:34s} {funds[len(funds) // 2]:>8,.0f}円 {xps[len(xps) // 2]:>5d} XP  ({len(pays)} rooms)")
    if args.dry_run:
        print("\n(dry run: nothing was written)")


if __name__ == "__main__":
    main()
