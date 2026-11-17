#!/usr/bin/env python3
"""Text rows for P9 (UI styles and End of Week Payments), 2026-11-17. Claude's draft for Cameron.
Safe to run again: existing keys are overwritten. Set P9_GROUPS=a,b to add only some groups."""
import os
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-17 panel P9 (Claude's draft)"
GROUPS = {
 "payments": [
  ("office.week_payments_title", "Office, End of Week Payments box title and breakdown heading", "End of Week Payments", ""),
  ("office.week_payments_parts", "Office, End of Week Payments box, the two parts", "Dues {dues} · Wages {wages}", "dues, wages"),
  ("office.week_payments_parts_none", "Office, End of Week Payments box, no staff hired", "Dues {dues} · Staff wages · none", "dues"),
  ("office.week_payments_no_staff", "End of Week Payments breakdown, no staff hired", "Staff wages · none", ""),
  ("office.week_payments_short", "Office, End of Week Payments box and breakdown, Funds short", "Funds are short by {amount}. Unpaid: {who}.", "amount, who"),
  ("office.week_payments_unpaid_dues", "End of Week Payments, the word for unpaid dues in the Unpaid list", "party dues", ""),
  ("week_end.breakdown_dues", "End of Week Payments breakdown, this week's dues", "Party dues", ""),
  ("week_end.breakdown_owed", "End of Week Payments breakdown, dues still owed from earlier weeks", "Still owed from earlier weeks", ""),
  ("week_end.breakdown_wage", "End of Week Payments breakdown, one person's wage", "{name}'s wage", "name"),
  ("week_end.breakdown_wage_raised", "End of Week Payments breakdown, one person's raised wage", "{name}'s wage (raised)", "name"),
  ("week_end.breakdown_total", "End of Week Payments breakdown, the total", "Total", ""),
  ("week_end.breakdown_after", "End of Week Payments breakdown, Funds left after paying", "Office funds after paying", ""),
  ("week_end.breakdown_unpaid_wage", "End of Week Payments breakdown, what a missed wage costs", "A wage that is not paid costs that person {count} Loyalty.", "count"),
 ],
 "zoom": [
  ("zoom.note_heading", "Battle, card zoom, note under the card: heading", "If you play it now", ""),
  ("zoom.note_line", "Battle, card zoom, note under the card: what it does here and what it costs", "{result} · costs {cost} of {energy} energy", "result, cost, energy"),
 ],
 "levels": [
  ("office.level_hours_line", "Levels list, under each level's name: how long it takes", "{count} hours", "count"),
 ],
 "styles": [
  ("shop.tab_styles", "Marketplace, third tab: the Office styles", "Office styles", ""),
  ("shop.styles_blurb", "Marketplace, Office styles tab, intro", "How your office and your debates look. Living Office is included.", ""),
  ("shop.style_living_name", "Office styles, the free default style's name", "Living Office", ""),
  ("shop.style_living_desc", "Office styles, the free default style's one-line description", "Your office is the menu. Debates show the room as seats won and lost.", ""),
  ("shop.style_in_use", "Office styles, the style in use", "In use", ""),
  ("shop.style_included", "Office styles, the free style is included", "Included", ""),
  ("shop.style_use", "Office styles, switch to an owned style (button)", "Use this style", ""),
  ("shop.style_unlock", "Office styles, unlock a style (button) with its price", "Unlock · {price}", "price"),
  ("shop.style_footer", "Office styles tab, footer", "Once unlocked, change styles here or in Administration › Appearance and Music. Card fronts and backs look the same in every style.", ""),
  ("office.cosmetics_slot_ui_style", "Administration, Appearance and Music, the Office style row", "Office style", ""),
 ],
}


def main():
    wanted = [g for g in os.environ.get("P9_GROUPS", "").split(",") if g.strip()]
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Text")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for group, items in GROUPS.items():
        if wanted and group not in wanted:
            continue
        for key, where, english, placeholders in items:
            values = {"A": key, "B": where, "C": english, "E": NOTE}
            if placeholders:
                values["D"] = placeholders
            if key in by_key:
                for col, value in values.items():
                    w.set_cell("Text", by_key[key], col, value)
            else:
                w.append_row("Text", values, style_row=w.last_data_row("Text"))
    w.save()
    print("ok")


if __name__ == "__main__":
    main()
