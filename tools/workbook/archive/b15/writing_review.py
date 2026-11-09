"""Writing review, group 1: apply the wording fixes (2026-11-09, Cameron).

Applies tools/workbook/archive/b15/changes.json (built by build_change_list.py
from the six reviewer ledgers and Cameron's decisions) to the workbook with
wbx.py only. Each edit is checked first: the cell must still hold the old text,
or the edit is refused and reported. Text goes in as an inline string; the
cell keeps its style.

Run from the repo root:
    python3 tools/workbook/archive/b15/build_change_list.py
    python3 tools/workbook/archive/b15/writing_review.py
    python3 tools/export_data.py --accept-wording
Archived copy: once applied, a second run finds nothing to do (every old text
is gone) and reports each edit as already applied.
"""
import json, sys, collections
sys.path.insert(0, "tools/workbook")
sys.path.insert(0, "tools/workbook/archive/b15")
from wbx import WB
from wbindex import norm

PATH = "design/Game_Workbook.xlsx"
changes = json.load(open("tools/workbook/archive/b15/changes.json", encoding="utf-8"))
w = WB(PATH)
rows = {}
done, already, refused = collections.Counter(), 0, []
for ch in changes:
    tab, r, c = ch["tab"], ch["row"], ch["col"]
    if tab not in rows:
        rows[tab] = w.rows(tab)
    now = rows[tab].get(r, {}).get(c)
    if now == ch["new"]:
        already += 1
        continue
    if norm(now) != norm(ch["old"]):
        refused.append((tab, r, c, now, ch["old"]))
        continue
    w.set_cell(tab, r, c, ch["new"])
    done[tab] += 1
w.save()
for tab, n in sorted(done.items()):
    print(f"  {tab}: {n} cells")
print(f"{sum(done.values())} cells changed, {already} already applied, {len(refused)} refused")
for x in refused[:20]:
    print("  refused (cell no longer holds the old text):", x[:3])
sys.exit(1 if refused else 0)
