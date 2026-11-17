#!/usr/bin/env python3
"""Text rows for panel P4 (information standards), 2026-11-17. Claude's draft for Cameron.
Safe to run again: existing keys are overwritten."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-17 panel P4 (Claude's draft)"
ROWS = [
    ("office.week_cost_heading", "Week-over popup, what going home costs, heading", "If you pay dues and go home", ""),
    ("office.week_cost_dues", "Week-over popup, this week's dues", "Party dues this week: {yen}円.", "yen"),
    ("office.week_cost_dues_parts", "Week-over popup, how the dues are made up", "That is {base}円 for your Party support plus {share}円, a share of the {earned}円 you earned this week.", "base, share, earned"),
    ("office.week_cost_relief", "Week-over popup, National awareness relief", "National awareness has already taken {yen}円 off.", "yen"),
    ("office.week_cost_carried", "Week-over popup, dues carried over", "Still owed from earlier weeks: {yen}円.", "yen"),
    ("office.week_cost_wages", "Week-over popup, staff wages", "Staff wages: {yen}円 for {count} staff.", "yen, count"),
    ("office.week_cost_funds", "Week-over popup, Funds before and after", "Funds now: {now}円. After dues and wages: {after}円.", "now, after"),
    ("office.week_cost_short", "Week-over popup, dues cannot be paid in full", "Your Funds fall {yen}円 short of the dues. That amount stays owed to the party.", "yen"),
    ("office.week_cost_penalty", "Week-over popup, what unpaid dues cost", "Unpaid dues cost {support} Party support, {hq_n} standing with {hq} and {selection_n} with {selection}.", "support, hq, hq_n, selection, selection_n"),
    ("office.week_cost_backings", "Week-over popup, backings withdrawn", "The party also withdraws these backings: {names}.", "names"),
    ("office.week_cost_settle", "Week-over popup, standing settles back", "Over the week, standing with organizations you did not move settles back toward where it started.", ""),
    ("draft.cost_over_limit", "Draft a Bill, the cost is above the Funds limit", "Drafting costs {funds}円, more than your Funds limit of {limit}円, so you cannot afford it yet. Buy the {petition} in the Marketplace to raise the limit.", "funds, limit, petition"),
    ("shop.funds_over_limit", "Marketplace, an item priced above the Funds limit", "Costs {price}円, more than your Funds limit of {limit}円. Buy the {petition} to raise the limit.", "price, limit, petition"),
    ("shop.funds_limit_note", "Marketplace, header note at the Funds limit (Cameron's wording)", "Earnings exceed the approved limit. Request a Funds cap increase. Excess funds go to the parliament pension program.", ""),
]


# Which item of panel P4 each row belongs to (so each item's commit carries only its own rows).
ITEM = {"office.week_cost": 1, "draft.cost_over_limit": 2, "shop.funds_over_limit": 2, "shop.funds_limit_note": 3,
        "assign.office_note": 6, "inventory.staff_screen_only": 6}


def item_of(key):
    for prefix, item in ITEM.items():
        if key.startswith(prefix):
            return item
    return 0


def main():
    import os
    wanted = [int(x) for x in os.environ.get("P4_ITEMS", "").split(",") if x.strip()]
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Text")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for key, where, english, placeholders in ROWS:
        if wanted and item_of(key) not in wanted:
            continue
        values = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            values["D"] = placeholders
        if key in by_key:
            for col, value in values.items():
                w.set_cell("Text", by_key[key], col, value)
        else:
            w.append_row("Text", values, style_row=w.last_data_row("Text"))
    w.save()
    print("ok", len(ROWS))


if __name__ == "__main__":
    main()
