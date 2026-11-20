#!/usr/bin/env python3
"""Cleanup (Cameron, 2026-11-20: "execute the cleanup"): removes the Text rows the redesigned level briefing (P12) no longer
asks for, now that the old Level Bonus block (LevelBonusView) is gone. Then:
python3 tools/export_data.py --accept-wording"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

KEYS = ["briefing.level_hours", "briefing.level_hours.one", "briefing.stage_hours", "briefing.stage_hours.one",
        "briefing.stage_fallback", "briefing.total_rewards", "briefing.rewards", "briefing.bullet", "briefing.level_bonus",
        "briefing.level_bonus_orgs", "briefing.xp_growth_range", "reward.delta_range", "reward.chip_range", "office.go_in"]

w = WB("design/Game_Workbook.xlsx")
removed = []
for key in KEYS:
    rows = w.rows("Text")
    header = rows[min(rows)]
    key_col = [c for c, t in header.items() if str(t).strip().lower() in ("key", "text key", "id")][0] if any(
        str(t).strip().lower() in ("key", "text key", "id") for t in header.values()) else "A"
    found = [n for n, r in rows.items() if n != min(rows) and str(r.get(key_col)) == key]
    if not found:
        print("not found (already gone?):", key)
        continue
    w.delete_row("Text", found[0])
    removed.append(key)
w.save()
print("removed", len(removed), "rows")
