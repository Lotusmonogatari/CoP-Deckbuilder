"""Item uses (Cameron, 2026-11-16): adds the Shop column Uses (AR), gives the two
Kaiju-sized items 2 uses, replaces the 17 draft staff items SH36-SH52 with the six
office-supply items SH36-SH41. Idempotent: run from the repository root."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
rows = w.rows("Shop")
# Header for the new column.
if rows[1].get("AR") != "Uses":
    w.set_cell("Shop", 1, "AR", "Uses", style_from=1) if False else w.set_cell("Shop", 1, "AR", "Uses")
for sid in ("SH15", "SH17"):
    w.set_cell("Shop", w.find_row("Shop", sid), "AR", 2)
# Remove the drafts SH42-SH52 (bottom first), keep SH36-SH41 to be rewritten.
for n in range(52, 41, -1):
    sid = "SH%d" % n
    try:
        w.delete_row("Shop", w.find_row("Shop", sid))
    except (KeyError, StopIteration, TypeError):
        pass
ITEMS = [
    ("SH36", "Printer", "An Office item, 3 uses. When you use it, 3 more tasks are added to today's list, even past the week's usual maximum.", 15000, "Office", "ADD_TASKS", 3, 3),
    ("SH37", "Shredder", "An Office item, 3 uses. When you use it, up to 3 tasks that nobody has been given and that are not Due are cleared away, picked at random.", 12000, "Office", "CLEAR_TASKS", 3, 3),
    ("SH38", "Flex-Work", "A staff item, 3 uses. Today, the best-paying task the person you give it to completes pays double, and they gain 2 extra Loyalty.", 20000, "Person", "DOUBLE_BEST", 2, 3),
    ("SH39", "Priority Inbox", "An Office item, 1 use. When you use it, today's tasks are reshuffled, including the ones already given to staff.", 10000, "Office", "RESHUFFLE", None, 1),
    ("SH40", "Commendation Gift", "A staff item, 1 use. Today, the person you give it to gains or loses no Loyalty from an idle or overworked day.", 8000, "Person", "QUIET", None, 1),
    ("SH41", "Lunch Delivery", "A staff item, 1 use. Today, the person you give it to takes none of the penalties of a weak fit.", 6000, "Person", "NO_PENALTY", None, 1),
]
for sid, name, desc, price, slot, effect, value, uses in ITEMS:
    r = w.find_row("Shop", sid)
    cells = {"B": name, "C": desc, "E": price, "AM": effect, "AP": slot, "AQ": 1, "AR": uses}
    for col, v in cells.items():
        w.set_cell("Shop", r, col, v)
    w.set_cell("Shop", r, "AN", value if value is not None else "")
    w.set_cell("Shop", r, "AO", "")
    w.set_cell("Shop", r, "I", "")
w.save()
print("done")
