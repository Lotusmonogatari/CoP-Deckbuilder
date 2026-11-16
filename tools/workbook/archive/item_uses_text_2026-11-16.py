#!/usr/bin/env python3
"""Text rows for items with uses and the six office-supply items (Cameron,
2026-11-16). Claude's draft. Safe to run again: existing keys are overwritten."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-16 item uses (Cameron). Claude's draft."
ROWS = [
    ("assign.gift_title", "Staff Assignments, what items did, heading", "Office notes", ""),
    ("assign.uses_left", "Staff item card, uses left on the next copy", "· {left} uses left", "left"),
    ("assign.uses_left_one", "Staff item card, one use left on the next copy", "· 1 use left", ""),
    ("assign.item_cap_add", "Staff item card, adds tasks", "Adds {count} tasks", "count"),
    ("assign.item_cap_clear", "Staff item card, clears tasks", "Clears up to {count} tasks", "count"),
    ("assign.item_cap_reshuffle", "Staff item card, reshuffles the day", "Reshuffles today", ""),
    ("assign.item_cap_double", "Staff item card, best task pays double", "Best task pays double", ""),
    ("assign.item_cap_nopenalty", "Staff item card, no weak-fit penalty", "No weak-fit penalty", ""),
    ("assign.item_desc_add", "Item popup, adds tasks", "Used at once: adds {count} more tasks to today's list, even past the week's usual maximum.", "count"),
    ("assign.item_desc_clear", "Item popup, clears tasks", "Used at once: clears up to {count} tasks that nobody has been given and that are not Due, picked at random.", "count"),
    ("assign.item_desc_reshuffle", "Item popup, reshuffles the day", "Used at once: today's tasks are drawn again, including the ones already given to staff. Items given to people stay with them.", ""),
    ("assign.item_desc_double", "Item popup, best task pays double", "Today, the best-paying task that person completes pays double, and they gain {count} extra Loyalty.", "count"),
    ("assign.item_desc_nopenalty", "Item popup, no weak-fit penalty", "Today, that person takes none of the penalties of a weak fit.", ""),
    ("assign.item_uses_line", "Item popup, uses left", "Uses left: {left} of {full}. It is thrown away when they run out.", "left, full"),
    ("assign.office_use_now", "Item popup, button for an Office item that acts at once", "Use now", ""),
    ("assign.use_instant_rule", "Item popup, an Office item that acts at once", "It acts as soon as you use it and costs one use.", ""),
    ("assign.use_added", "Office note, the Printer", "{item} added {count} tasks to today's list.", "item, count"),
    ("assign.use_cleared", "Office note, the Shredder", "{item} cleared {count} tasks that nobody had been given.", "item, count"),
    ("assign.use_reshuffled", "Office note, the Priority Inbox", "{item} reshuffled today's tasks. Tasks you had given out are back in the list.", "item"),
    ("assign.office_nothing", "Item popup, refusal, nothing for the item to act on", "No task qualifies: each is given out or Due.", ""),
    ("assign.tile_nothing", "Item popup, refusal, short", "Nothing to clear", ""),
    ("assign.office_no_tasks", "Item popup, refusal, no tasks today", "Today has no tasks.", ""),
    ("item.worn_out", "Office note, an item with uses ran out", "Your {item} wore out and was thrown away.", "item"),
    ("item.uses_line", "Inventory, uses left on one copy", "Uses left: {left} of {full}", "left, full"),
    ("item.uses_copies", "Inventory, uses left on several copies", "Uses left, copy by copy: {list}", "list"),
    ("shop.item_uses", "Marketplace, an item's uses", "{count} uses", "count"),
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
