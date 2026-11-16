#!/usr/bin/env python3
"""Text rows for staff wages and Loyalty (Cameron, 2026-11-16). Claude's draft.
Safe to run again: existing keys are overwritten."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-16 staff wages and Loyalty (Cameron). Claude's draft."
ROWS = [
    ("record.cause_staff_wages", "Reason: staff wages", "your staff wages", ""),
    ("staff.quit_never_returns", "Office · Staff, a candidate who resigned", "They resigned and will not come back.", ""),
    ("staff.upgrade_refused_restless", "Office · Staff profile, upgrade refused for low Loyalty", "{name} is too unsettled for a promotion. Raise their Loyalty first.", "name"),
    ("staff.raise_pay_done", "Office · Staff profile, raise pay already used", "Their pay is already raised this week", ""),
    ("staff.thank_done", "Office · Staff profile, thank-you already given", "You already thanked them this week", ""),
    ("staff.thank_reputation", "Office · Staff profile, thank-you needs Reputation", "Needs Reputation {count} to thank them in public", "count"),
    ("staff.thank_hours", "Office · Staff profile, thank-you needs hours", "Needs {count} hours free", "count"),
    ("staff.summary", "Office · Staff, line under a hired person", "{word} · wage {yen}円 a week", "word, yen"),
    ("staff.word_devoted", "Staff Loyalty word, 80 and up", "Devoted", ""),
    ("staff.word_steady", "Staff Loyalty word, steady", "Steady", ""),
    ("staff.word_restless", "Staff Loyalty word, under the restless line", "Restless", ""),
    ("staff.word_leaving", "Staff Loyalty word, about to leave", "About to leave", ""),
    ("staff.loyalty_heading", "Office · Staff profile, heading", "Loyalty and pay", ""),
    ("staff.why_none", "Office · Staff profile, before the first week end", "Loyalty first moves at the week's end.", ""),
    ("staff.why_heading", "Office · Staff profile, why Loyalty moved", "Why it moved at the last week's end:", ""),
    ("staff.why_paid", "Office · Staff profile, wage paid", "Wage paid in full: {count}", "count"),
    ("staff.why_missed", "Office · Staff profile, wage missed", "Wage not paid: {count}", "count"),
    ("staff.why_affinity", "Office · Staff profile, standing with their allied organizations", "Your standing with the organizations they care about: {count}", "count"),
    ("staff.why_tenure", "Office · Staff profile, time with the office", "Time with your office: {count}", "count"),
    ("staff.why_pride", "Office · Staff profile, promoted", "Promoted since they joined: {count}", "count"),
    ("staff.why_tasks", "Office · Staff profile, daily tasks", "Daily tasks: {count}", "count"),
    ("staff.why_total", "Office · Staff profile, total", "Total: {count}", "count"),
    ("staff.raise_pay_button", "Office · Staff profile, button", "Raise pay this week ({yen}円, Loyalty {count})", "yen, count"),
    ("staff.thank_button", "Office · Staff profile, button", "Thank them in public ({hours} hours, Loyalty {count})", "hours, count"),
    ("staff.fire_ally_note", "Office · fire confirmation, standing cost", "Firing also costs standing with {names}.", "names"),
    ("staff.week_paid", "New week popup, staff wages", "Staff wages paid: {yen}円.", "yen"),
    ("staff.week_missed", "New week popup, wages not paid", "Not paid this week: {names}. Their Loyalty falls.", "names"),
    ("staff.week_rank_lost", "New week popup, rank lost", "{names} lost a rank because wages were late. Their rank rewards are gone until you buy the rank again.", "names"),
    ("staff.week_quit", "New week popup, a resignation", "{name} resigned for good. Reputation {rep}; standing falls with {allies}.", "name, rep, allies"),
    ("staff.week_warning", "Week over popup, wages may not be covered", "Staff wages this week: {yen}円. Funds after the party dues may not cover them.", "yen"),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Text")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for key, where, english, placeholders in ROWS:
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
