#!/usr/bin/env python3
"""Staff task expansion, phases 3 to 5 data (Cameron, 2026-11-16;
design/proposals/STAFF_TASKS_EXPANSION_2026-11-16.md): the Staff Task Drivers
tab, the Shop's Staff Effect columns and the new staff items, gift tastes on
the Staff tab, and a task-pool effect on two example event choices. All names,
numbers and sentences are Claude's draft for Cameron to rewrite. Run once.
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

# --- Drivers ----------------------------------------------------------------
DRIVER_HEADERS = ["Driver ID", "Note", "Variable", "Test", "Threshold", "Family", "Add Min", "Add Max", "Cap"]
DRIVERS = [
    ["DR01", "Party dues are owed", "dues_owed", "Is true", "", "Administration", 1, 2, 2],
    ["DR02", "Promises are waiting", "open_promises", "Per", 2, "Correspondence", 1, 1, 2],
    ["DR03", "The district has gone quiet", "district_awareness", "At most", 25, "Constituents", 1, 2, 2],
    ["DR04", "The district is watching", "district_awareness", "At least", 65, "Constituents", 1, 1, 1],
    ["DR05", "The district press is watching", "district_awareness", "At least", 65, "Press", 1, 1, 1],
    ["DR06", "The nation is watching", "national_awareness", "At least", 65, "Press", 1, 2, 2],
    ["DR07", "Your name needs repair", "reputation", "At most", 30, "Press", 1, 2, 2],
    ["DR08", "Invitations are arriving", "reputation", "At least", 60, "Meetings", 1, 1, 1],
    ["DR09", "Constituents are restless", "constituency_support", "At most", 15, "Constituents", 1, 2, 2],
    ["DR10", "A bill is in progress", "level_in_progress", "Is true", "", "Analysis", 1, 2, 2],
    ["DR11", "The office is sour", "avg_staff_loyalty", "At most", 29, "Chores", 1, 1, 1],
    ["DR12", "Monday's letters", "weekday", "Equals", 1, "Correspondence", 1, 1, 1],
    ["DR13", "Friday's filing", "weekday", "Equals", 5, "Administration", 1, 1, 1],
    ["DR14", "The party is restless", "party_support", "At most", 25, "Meetings", 1, 1, 1],
]

# --- Shop ---------------------------------------------------------------------
SHOP_COLS = {"AM": "Staff Effect", "AN": "Staff Value", "AO": "Staff Target", "AP": "Staff Slot", "AQ": "Staff Days"}
# id, name, description, funds, icon, effect, value, target, slot, days
NEW_ITEMS = [
    ("SH36", "Press Kit", "A staff item. Today, the person you give it to counts as a strong fit for Press tasks.", 15000, "PRESS_KIT", "STRONG_FAMILY", "", "Press", "Person", 1),
    ("SH37", "Policy Binder", "A staff item. Today, the person you give it to counts as a strong fit for Analysis tasks.", 15000, "POLICY_BINDER", "STRONG_FAMILY", "", "Analysis", "Person", 1),
    ("SH38", "Ward Map", "A staff item. Today, the person you give it to counts as a strong fit for Constituents tasks.", 15000, "WARD_MAP", "STRONG_FAMILY", "", "Constituents", "Person", 1),
    ("SH39", "Style Guide", "A staff item. Today, the person you give it to counts as a strong fit for Correspondence tasks.", 15000, "STYLE_GUIDE", "STRONG_FAMILY", "", "Correspondence", "Person", 1),
    ("SH40", "Meeting Folder", "A staff item. Today, the person you give it to counts as a strong fit for Meetings tasks.", 15000, "MEETING_FOLDER", "STRONG_FAMILY", "", "Meetings", "Person", 1),
    ("SH41", "Filing Kit", "A staff item. Today, the person you give it to counts as a strong fit for Administration tasks.", 15000, "FILING_KIT", "STRONG_FAMILY", "", "Administration", "Person", 1),
    ("SH42", "Cleaning Cart", "A staff item. Today, the person you give it to counts as a strong fit for Chores tasks.", 10000, "CLEANING_CART", "STRONG_FAMILY", "", "Chores", "Person", 1),
    ("SH43", "Training Voucher", "A staff item. Today, the rewards from the strong-fit tasks of the person you give it to are half as big again.", 20000, "TRAINING_VOUCHER", "REWARD_MULT", 150, "", "Person", 1),
    ("SH44", "Quiet Desk Pass", "A staff item. Today, the person you give it to gains or loses no Loyalty from an idle or overworked day.", 12000, "QUIET_DESK_PASS", "QUIET", "", "", "Person", 1),
    ("SH45", "Press Subscription", "An Office item. The next day's tasks include 2 more Press tasks.", 10000, "PRESS_SUBSCRIPTION", "POOL_FAMILY", 2, "Press", "Office", 1),
    ("SH46", "Constituent Hotline Sign", "An Office item. The next day's tasks include 2 more Constituents tasks.", 10000, "HOTLINE_SIGN", "POOL_FAMILY", 2, "Constituents", "Office", 1),
    ("SH47", "Reading Stack", "An Office item. The next day's tasks include 2 more Analysis tasks.", 10000, "READING_STACK", "POOL_FAMILY", 2, "Analysis", "Office", 1),
    ("SH48", "Outsourcing Contract", "An Office item. For the next 3 days, 2 fewer Administration tasks.", 25000, "OUTSOURCING_CONTRACT", "POOL_FAMILY", -2, "Administration", "Office", 3),
    ("SH49", "Do Not Disturb Sign", "An Office item. The next day's tasks include 2 fewer Meetings tasks.", 10000, "DO_NOT_DISTURB", "POOL_FAMILY", -2, "Meetings", "Office", 1),
    ("SH50", "Chore Rota", "An Office item. The next day's tasks include 3 fewer Chores tasks.", 8000, "CHORE_ROTA", "POOL_FAMILY", -3, "Chores", "Office", 1),
    ("SH51", "Overflow Tray", "An Office item. The next day may deliver up to 3 more tasks.", 15000, "OVERFLOW_TRAY", "POOL_MAX", 3, "", "Office", 1),
    ("SH52", "Triage Desk", "An Office item. The next day delivers up to 3 fewer tasks.", 20000, "TRIAGE_DESK", "POOL_MAX", -3, "", "Office", 1),
]
# existing items that become staff items (effect, value, slot)
EXISTING = {"SH04": ("HOURS", 1), "SH05": ("HOURS", 1), "SH15": ("HOURS", 2), "SH17": ("HOURS", 2)}
GIFTS = ["SH25", "SH26", "SH27", "SH28", "SH29", "SH30", "SH31", "SH32", "SH33"]

# --- Gift tastes (draft): likes, dislikes, like / neutral / dislike Loyalty -------
TASTE_HEADERS = {"P": "Gift Likes", "Q": "Gift Dislikes", "R": "Gift Like Loyalty",
                 "S": "Gift Neutral Loyalty", "T": "Gift Dislike Loyalty"}

BALANCE = [
    ("Staff Gift: Like Loyalty", 12, "Loyalty when a person is given a gift they like (used when their own cell is blank)."),
    ("Staff Gift: Neutral Loyalty", 4, "Loyalty from a gift they neither like nor dislike."),
    ("Staff Gift: Dislike Loyalty", -4, "Loyalty from a gift they dislike."),
]
# event choices that change the next day's tasks: (event, choice, family, change, days)
EVENT_POOL = [("EV84", "A", "Meetings", 2, 1), ("EV55", "A", "Press", 2, 1)]


def main():
    w = WB("design/Game_Workbook.xlsx")

    # Shop: columns, new items, existing items
    for col, header in SHOP_COLS.items():
        w.set_cell("Shop", 1, col, header, style_from=1)
    rows = {v.get("A"): r for r, v in w.rows("Shop").items()}
    for sid, name, desc, funds, icon, effect, value, target, slot, days in NEW_ITEMS:
        if sid in rows:
            continue
        r = w.copy_row("Shop", "SH25", {
            "Item ID": sid, "Item Name": name, "Description": desc, "Purchase Cost from XP": 0,
            "Purchase Cost from Funds (Yen)": funds, "Icon": None,  # no picture yet: the blue square shows; name the file in the Icon cell when drawn
             "Stack Cap": 3,
            "Inventory (Personal/Office)": None})
        for col, v in (("AM", effect), ("AN", value), ("AO", target), ("AP", slot), ("AQ", days)):
            if v != "":
                w.set_cell("Shop", r, col, v, style_from=2)
    rows = {v.get("A"): r for r, v in w.rows("Shop").items()}
    for sid, (effect, value) in EXISTING.items():
        w.set_cell("Shop", rows[sid], "AM", effect, style_from=2)
        w.set_cell("Shop", rows[sid], "AN", value, style_from=2)
        w.set_cell("Shop", rows[sid], "AP", "Person", style_from=2)
        w.set_cell("Shop", rows[sid], "AQ", 1, style_from=2)
    for sid in GIFTS:
        w.set_cell("Shop", rows[sid], "AM", "GIFT", style_from=2)
        w.set_cell("Shop", rows[sid], "AP", "Person", style_from=2)
        w.set_cell("Shop", rows[sid], "AQ", 1, style_from=2)

    # Staff: gift tastes
    for col, header in TASTE_HEADERS.items():
        w.set_cell("Staff", 1, col, header, style_from=1)
    like_loyalty = [8, 10, 12, 15]
    staff_rows = [(r, v) for r, v in w.rows("Staff").items() if v.get("A", "").startswith("SF")]
    for index, (r, v) in enumerate(staff_rows):
        likes = [GIFTS[(index * 2) % 9], GIFTS[(index * 2 + 3) % 9]]
        dislike = GIFTS[(index * 2 + 5) % 9]
        if dislike in likes:
            dislike = GIFTS[(index * 2 + 7) % 9]
        w.set_cell("Staff", r, "P", ", ".join(likes), style_from=2)
        w.set_cell("Staff", r, "Q", dislike, style_from=2)
        w.set_cell("Staff", r, "R", like_loyalty[index % 4], style_from=2)
        w.set_cell("Staff", r, "S", 2 + index % 4, style_from=2)
        w.set_cell("Staff", r, "T", -(2 + (index * 3) % 7), style_from=2)

    # Event Choices: task-pool effect columns and two draft examples
    for col, header in (("W", "Task Pool Family"), ("X", "Task Pool Change"), ("Y", "Task Pool Days")):
        w.set_cell("Event Choices", 1, col, header, style_from=1)
    for r, v in w.rows("Event Choices").items():
        for event, choice, family, change, days in EVENT_POOL:
            if v.get("A") == event and v.get("B") == choice:
                w.set_cell("Event Choices", r, "W", family, style_from=2)
                w.set_cell("Event Choices", r, "X", change, style_from=2)
                w.set_cell("Event Choices", r, "Y", days, style_from=2)

    balance_rows = {v.get("A"): r for r, v in w.rows("Balance").items()}
    for name, value, note in BALANCE:
        if name in balance_rows:
            w.set_cell("Balance", balance_rows[name], "B", value)
            w.set_cell("Balance", balance_rows[name], "C", note)
        else:
            w.append_row("Balance", {"A": name, "B": value, "C": note}, style_row=w.last_data_row("Balance"))
    w.save()
    if "Staff Task Drivers" not in list(WB("design/Game_Workbook.xlsx").sheet):
        add_sheet("design/Game_Workbook.xlsx", "Staff Task Drivers", DRIVER_HEADERS, DRIVERS,
                  widths=[9, 34, 22, 10, 10, 18, 9, 9, 6])
    print("ok")


if __name__ == "__main__":
    main()
