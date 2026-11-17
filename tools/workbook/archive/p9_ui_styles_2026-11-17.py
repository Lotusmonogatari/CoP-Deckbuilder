#!/usr/bin/env python3
"""P9 (UI styles), 2026-11-17: adds the UI Style column and two packages to the
Cosmetic Packages tab, and the UI Styles token tab (seeded from
design/proposals/ui_styles_tokens_2026-11-17.json). Run once from the repo root.
Safe to run again: it skips what exists."""
import json
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

PATH = "design/Game_Workbook.xlsx"
TOKENS = json.load(open("design/proposals/ui_styles_tokens_2026-11-17.json"))

NOTE = "Claude's draft, 2026-11-17 (P9)"


def token_rows():
    rows, n = [], 0
    for style in ("living_office", "broadcast", "woodblock"):
        block = TOKENS[style]
        for group in ("colour", "font", "size_pt", "radius_px", "slant_px", "border_px"):
            for name, value in (block.get(group) or {}).items():
                n += 1
                rows.append(["US%03d" % n, style, group, name, value, ""])
        for name in ("support_count", "cue", "hand"):
            if name in block:
                n += 1
                rows.append(["US%03d" % n, style, "layout", name, block[name], ""])
    shared = TOKENS["shared"]
    for name in ("touch_target_min_pt", "contrast_text_min", "contrast_icon_min", "play_lift_px"):
        n += 1
        rows.append(["US%03d" % n, "shared", "shared", name, shared[name], ""])
    return rows


def main():
    w = WB(PATH)
    if "UI Styles" not in w.sheet:
        w.save()
        add_sheet(PATH, "UI Styles",
                  ["Token ID", "Style", "Group", "Token", "Value", "Notes"],
                  token_rows(), widths=[10, 14, 12, 22, 34, 40])
        w = WB(PATH)
    # The UI Style column (O) on Cosmetic Packages.
    heads = w.rows("Cosmetic Packages")[1]
    if "O" not in heads:
        w.set_cell("Cosmetic Packages", 1, "O", "UI Style")
    by_key = {v.get("A"): r for r, v in w.rows("Cosmetic Packages").items()}
    new = [("CP07", "Broadcast", "ブロードキャスト", "Political drama on air: gold rules, captions and big cut-ins.", "broadcast"),
           ("CP08", "Woodblock", "木版", "A printed Yezo: washi, indigo and seal stamps.", "woodblock")]
    for pid, name, jp, desc, style in new:
        values = {"A": pid, "B": name, "C": jp, "D": desc, "F": 1, "O": style}
        if pid in by_key:
            continue
        w.append_row("Cosmetic Packages", values, style_row=w.last_data_row("Cosmetic Packages"))
    w.save()
    print("ok")


if __name__ == "__main__":
    main()
