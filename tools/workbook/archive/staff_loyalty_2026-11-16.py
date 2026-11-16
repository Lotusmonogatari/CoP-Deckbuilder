#!/usr/bin/env python3
"""Staff wages and Loyalty (Cameron, 2026-11-16): Balance rows, severance 3x
hire price, and Text rows. Safe to run again: existing rows are overwritten.

    python3 tools/workbook/archive/staff_loyalty_2026-11-16.py
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

BALANCE = [
    ("Staff Wage: Percent", 10, "Weekly wage as a percent of everything invested in the person (hire plus upgrades). Cameron 2026-11-16."),
    ("Staff Raise Pay: Multiple Percent", 150, "Raising a person's pay for the week pays this percent of their wage."),
    ("Staff Raise Pay: Loyalty", 10, "One-time Loyalty from raising pay."),
    ("Staff Thank In Public: Loyalty", 5, "One-time Loyalty from a public thank-you."),
    ("Staff Thank In Public: Hours", 3, "Hours a public thank-you takes."),
    ("Staff Thank In Public: Minimum Reputation", 40, "Reputation needed to thank someone in public."),
    ("Staff Loyalty: Start", 30, "Loyalty of a new hire. Cameron 2026-11-16."),
    ("Staff Loyalty: Paid Bonus", 2, "Weekly Loyalty when the wage is paid in full."),
    ("Staff Loyalty: Missed Penalty", 20, "Weekly Loyalty lost when the wage is missed. Draft."),
    ("Staff Loyalty: Affinity Pivot", 50, "Standing with the person's allied organizations above or below which Loyalty rises or falls."),
    ("Staff Loyalty: Affinity Points Step", 10, "Standing points per affinity step."),
    ("Staff Loyalty: Affinity Step", 2, "Weekly Loyalty per affinity step. Cameron 2026-11-16."),
    ("Staff Loyalty: Tenure Weeks Per Point", 4, "+1 Loyalty every this many weeks worked. Draft."),
    ("Staff Loyalty: Tenure Cap", 10, "Most tenure points a person can earn in total. Draft."),
    ("Staff Loyalty: Rank Pride", 2, "Weekly Loyalty for a person promoted above the rank they were hired at. Draft."),
    ("Staff Loyalty: Restless Below", 30, "Under this a person is Restless: Strong-fit tasks count as Fair, item boosts halve, upgrades refused. Cameron 2026-11-16."),
    ("Staff Loyalty: Leaving Below", 15, "Under this a person is About to leave: Fair-fit tasks count as Poor too."),
    ("Staff Loyalty: Devoted From", 80, "At or above this the word is Devoted."),
    ("Staff Loyalty: Rank Loss Below", 15, "A missed wage that leaves Loyalty under this costs one rank. Cameron 2026-11-16."),
    ("Staff Loyalty: Quit At", 0, "At or below this the person resigns for good."),
    ("Staff Loyalty: After Rank Loss", 35, "Loyalty a person restarts at after losing a rank. Draft."),
    ("Staff Loyalty: Weekly Gain Cap", 15, "Most Loyalty a week's formula can add. Draft."),
    ("Staff Loyalty: Weekly Loss Cap", 30, "Most Loyalty a week's formula can take. Draft."),
    ("Staff Quit: Reputation", 15, "Reputation lost when a person resigns. Cameron 2026-11-16."),
    ("Staff Quit: Ally Standing", 20, "Standing lost with each ally organization, times its weight, when a person resigns. Cameron 2026-11-16."),
    ("Staff Fire: Ally Standing", 3, "Standing lost with each ally organization, times its weight, when you fire a person. Draft."),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Balance")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for name, value, note in BALANCE:
        if name in by_key:
            w.set_cell("Balance", by_key[name], "B", value)
            w.set_cell("Balance", by_key[name], "C", note)
        else:
            w.append_row("Balance", {"A": name, "B": value, "C": note}, style_row=w.last_data_row("Balance"))
    # Severance is now three times the hiring price (the Staff tab's own column).
    for r, v in w.rows("Staff").items():
        if v.get("A", "").startswith("SF"):
            w.set_cell("Staff", r, "M", int(float(v["G"])) * 3)
    r = by_key.get("Staff: Severance Share")
    if r:
        w.set_cell("Balance", r, "B", 3)
        w.set_cell("Balance", r, "C", "Severance is 3 x the hiring price (Cameron, 2026-11-16). Used only when a staff row has no Firing Cost.")
    w.save()
    print("ok")

if __name__ == "__main__":
    main()
