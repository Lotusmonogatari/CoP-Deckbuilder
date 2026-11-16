#!/usr/bin/env python3
"""Event delegation (Cameron, 2026-11-16): two columns on Event Choices (Delegate
Role, Delegate Blocks), the role each existing "send a staff member" choice
suits (Claude's draft, for Cameron to change), and three Balance rows. Safe to
run again."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

R, M, D = "Policy Research Assistant", "Media Spokesperson", "District Representative"
ROLES = {
    "EV02B": D, "EV13B": D, "EV15B": D, "EV17C": D, "EV37C": D, "EV48B": D, "EV49B": D, "EV50B": D,
    "EV51B": M, "EV52B": M, "EV53B": D, "EV54B": M, "EV55B": M, "EV56B": D, "EV57B": D, "EV58B": D,
    "EV59B": R, "EV60B": R, "EV61B": R, "EV65C": D, "EV66B": D, "EV67B": D, "EV68B": D, "EV69B": D,
    "EV70B": D, "EV71C": D, "EV72B": D, "EV73B": M, "EV78B": R, "EV81C": D, "EV83B": R, "EV84B": R,
    "EV85B": M, "EV86B": R, "EV87B": D, "EV88B": R, "EV89B": R, "EV90B": R, "EV91B": R, "EV92B": R,
    "EV93B": D, "EV94B": R,
}
BALANCE = [
    ("Staff Delegate: Hours Percent", 50, "A delegated event takes this percent of its hours from you (rounded down)."),
    ("Staff Delegate: Fair Gain Percent", 50, "A fair-fit delegate earns this percent of the choice's gains (rounded down)."),
    ("Staff Delegate: Loyalty", 1, "Loyalty a person gains for a strong-fit delegated event, or loses for a poor-fit one."),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    w.set_cell("Event Choices", 1, "U", "Delegate Role", style_from=1)
    w.set_cell("Event Choices", 1, "V", "Delegate Blocks", style_from=1)
    done = 0
    for row, values in w.rows("Event Choices").items():
        key = values.get("A", "") + values.get("B", "")
        if key in ROLES:
            w.set_cell("Event Choices", row, "U", ROLES[key], style_from=2)
            done += 1
    assert done == len(ROLES), (done, len(ROLES))
    rows = w.rows("Balance")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for name, value, note in BALANCE:
        if name in by_key:
            w.set_cell("Balance", by_key[name], "B", value)
            w.set_cell("Balance", by_key[name], "C", note)
        else:
            w.append_row("Balance", {"A": name, "B": value, "C": note}, style_row=w.last_data_row("Balance"))
    w.save()
    print("ok", done)

if __name__ == "__main__":
    main()
