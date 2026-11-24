#!/usr/bin/env python3
"""P17 (2026-11-24, Cameron): dues and wages (Balance), the three Commission prices, the Paid Train Ticket's standing, event costs and
EV04's rewards. Room pay and level bonuses are tools/economy_apply.py. Run once from the repo root:
    python3 tools/workbook/archive/p17_economy_build.py
Then python3 tools/export_data.py (must say "No errors"). The Text and description edits are Claude's drafts for Cameron."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")


def cell(sheet, key_col, key, col):
    """(row number, current value) of `col` on the row whose `key_col` cell is `key`."""
    row = w.find_row(sheet, key, key_col)
    return row, w.rows(sheet)[row].get(col)


# --- Step 4: Balance ----------------------------------------------------------------------------------------------------------------
BALANCE = [
    ("Dues: Reward Percent", 15, "Cameron 2026-10-23; 30 to 15 on 2026-11-02; 15 to 10 on 2026-11-10; 10 to 15 on 2026-11-24 (P17 economy review). Percent of the Funds earned Monday to Friday that week that is added to the dues."),
    ("Dues: Step Amount", 5000, "Cameron 2026-10-23; 50,000 to 10,000 on 2026-11-10; 10,000 to 5,000 on 2026-11-24 (P17). Yen added to the base dues for each step."),
    ("Staff Wage: Percent", 10, "Weekly wage as a percent of everything invested in the person (hire plus upgrades). 10 to 15 on 2026-11-16 (rubric R4.4); 15 back to 10 on 2026-11-24 (P17 economy review)."),
]
for lever, value, note in BALANCE:
    row = w.find_row("Balance", lever)
    w.set_cell("Balance", row, "B", value, style_from=row)
    w.set_cell("Balance", row, "C", note, style_from=row)
# The new row, beside the other dues rows.
w.append_row("Balance", {"A": "Dues: Max Per Week", "B": 90000,
                         "C": "Cameron 2026-11-24 (P17). The most the party asks in one week's dues (base, steps and share together), before the National-awareness relief takes its part off. 0 or blank: no limit."},
             style_row=w.last_data_row("Balance"))

# --- Step 5: Shop -------------------------------------------------------------------------------------------------------------------
for item, price in (("SH01", 12000), ("SH02", 24000), ("SH03", 24000)):
    row = w.find_row("Shop", item)
    w.set_cell("Shop", row, "E", price, style_from=row)
row = w.find_row("Shop", "SH42")
w.set_cell("Shop", row, "H", "BO14 +1", style_from=row)
w.set_cell("Shop", row, "C", "A paid seat on the express, used for a trip or a mixed level's travel instead of the rail pass. The hours are the same. "
           "The Commuter Committee notices when a member pays their own fare: +1 standing with it on every use.", style_from=row)

# --- Step 5: Events (Cost (Funds)) --------------------------------------------------------------------------------------------------
for event, cost in (("EV03", 10000), ("EV05", 15000), ("EV06", 20000), ("EV31", 6000), ("EV35", 10000)):
    row = w.find_row("Events", event)
    w.set_cell("Events", row, "G", cost, style_from=row)

# --- Step 5: EV04's positive District, National and Reputation rewards times four --------------------------------------------------
def times_four(text):
    """'4-6' -> '16-24'; a range with a negative end ('-2-0') or a non-range is left as it is."""
    if text is None or str(text).strip() == "":
        return text
    s = str(text).strip()
    if s.startswith("-"):
        return s
    parts = s.split("-")
    try:
        nums = [int(p) for p in parts]
    except ValueError:
        return s
    return "-".join(str(n * 4) for n in nums)


rows = w.rows("Event Choices")
for number, cells in rows.items():
    if cells.get("A") != "EV04":
        continue
    for col in ("I", "K", "L"):          # Reputation Δ, District Awareness Δ, National Awareness Δ
        old = cells.get(col)
        new = times_four(old)
        if new != old:
            w.set_cell("Event Choices", number, col, new, style_from=number)

# --- Text: the dues screen names the weekly limit when it holds the dues down -------------------------------------------------------
w.append_row("Text", {"A": "office.week_cost_limit", "B": "Week-end costs: the party's weekly limit on dues is holding this week's dues down",
                      "C": "The party never asks for more than {yen}円 in dues in a week.", "D": "yen",
                      "E": "P17 (2026-11-24): Claude's draft for Cameron to reword."}, style_row=w.last_data_row("Text"))
w.save()
print("workbook updated")
