#!/usr/bin/env python3
"""Summarizes the touch-target audit (MC²T, 2026-11-06).

Run tools/ui_target_audit.tscn first (see tools/ui_target_audit.gd); it writes
JSON with the size of every tappable control in the game's base pixels (1080
wide). The game stretches that width to the phone's width, so one base pixel is
dp = device width in dp / 1080. This script converts to dp, iOS points and
millimetres and compares against the published minimums:

  iOS Human Interface Guidelines   44 x 44 pt   (390 pt wide iPhone)
  Material Design                  48 x 48 dp   (360 and 412 dp wide phones)
  WCAG 2.2 SC 2.5.8 (AA)           24 x 24 CSS px

Only the smaller side of a target is judged: a wide, short button is as hard to
hit vertically as a small one.

    python3 tools/ui_target_audit.py design/review/mc2t_targets.json [--write out.md]
"""
import collections
import json
import statistics
import sys

BASE_W = 1080.0
PHONE_MM = 68.0                      # physical width of a typical 6.1" phone
STANDARDS = [                        # (name, size in device units, device width in that unit)
    ("iOS 44 pt", 44.0, 390.0),
    ("Material 48 dp (412 dp phone)", 48.0, 412.0),
    ("Material 48 dp (360 dp phone)", 48.0, 360.0),
    ("WCAG 24 px (412 dp phone)", 24.0, 412.0),
]


def to_px(size_units, width_units):
    return size_units * BASE_W / width_units


def md_row(cells):
    return "| " + " | ".join(str(c) for c in cells) + " |"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    write = None
    if "--write" in sys.argv:
        write = sys.argv[sys.argv.index("--write") + 1]
        args = [a for a in args if a != write]
    rows = json.load(open(args[0]))
    for r in rows:
        r["m"] = min(r["w"], r["h"])
    out = []
    out.append("# Touch-target audit")
    out.append("")
    out.append(f"{len(rows)} visible tappable controls on {len({r['screen'] for r in rows})} screens and panels. "
               f"Base width {int(BASE_W)} px = a phone's full width; at 390 pt, 412 dp and 360 dp that makes one base "
               f"pixel {390/BASE_W:.3f} pt, {412/BASE_W:.3f} dp and {360/BASE_W:.3f} dp, and on a {PHONE_MM:.0f} mm wide "
               f"phone {PHONE_MM/BASE_W:.3f} mm. The smaller side of each target is judged.")
    out.append("")
    out.append("## Thresholds in base pixels")
    out.append("")
    out.append(md_row(["Standard", "Minimum", "In base px", "Millimetres"]))
    out.append(md_row(["---"] * 4))
    for name, size, width in STANDARDS:
        px = to_px(size, width)
        out.append(md_row([name, f"{size:g}", f"{px:.0f}", f"{px * PHONE_MM / BASE_W:.1f}"]))
    out.append("")
    ios_px = to_px(44, 390)
    mat_px = to_px(48, 412)
    wcag_px = to_px(24, 412)
    out.append("## By screen")
    out.append("")
    out.append(md_row(["Screen", "Targets", "Smallest side (px / dp@412)", "Median (px)", f"Under iOS 44 pt (<{ios_px:.0f} px)", f"Under WCAG 24 px (<{wcag_px:.0f} px)"]))
    out.append(md_row(["---"] * 6))
    by_screen = collections.OrderedDict()
    for r in rows:
        by_screen.setdefault(r["screen"], []).append(r)
    total_bad = 0
    for screen, items in by_screen.items():
        ms = [i["m"] for i in items]
        bad = sum(1 for m in ms if m < ios_px)
        worse = sum(1 for m in ms if m < wcag_px)
        total_bad += bad
        out.append(md_row([screen, len(items), f"{min(ms):.0f} / {min(ms) * 412 / BASE_W:.0f}",
                           f"{statistics.median(ms):.0f}", f"{bad} ({100 * bad // len(items)}%)", worse]))
    out.append("")
    out.append(f"**{total_bad} of {len(rows)} targets ({100 * total_bad // len(rows)}%) are below the iOS 44 pt minimum.**")
    out.append("")
    out.append("## By kind of control")
    out.append("")
    out.append(md_row(["Control", "Count", "Smallest side px (dp@412)", "Median px", "Under iOS 44 pt"]))
    out.append(md_row(["---"] * 5))
    kinds = collections.defaultdict(list)
    for r in rows:
        kinds[r["script"] or r["class"]].append(r["m"])
    for kind, ms in sorted(kinds.items(), key=lambda kv: -len(kv[1])):
        out.append(md_row([kind, len(ms), f"{min(ms):.0f} ({min(ms) * 412 / BASE_W:.0f})", f"{statistics.median(ms):.0f}",
                           sum(1 for m in ms if m < ios_px)]))
    out.append("")
    out.append("## The 20 smallest distinct controls")
    out.append("")
    out.append(md_row(["Screen", "Control", "Text or name", "Size px (w x h)", "Smaller side dp@412", "mm"]))
    out.append(md_row(["---"] * 6))
    seen = set()
    shown = 0
    for r in sorted(rows, key=lambda r: r["m"]):
        key = (r["script"] or r["class"], r["text"] or r["name"], round(r["w"]), round(r["h"]))
        if key in seen:
            continue
        seen.add(key)
        out.append(md_row([r["screen"], r["script"] or r["class"], (r["text"] or r["name"]).replace("|", "/"),
                           f"{r['w']:.0f} x {r['h']:.0f}", f"{r['m'] * 412 / BASE_W:.0f}", f"{r['m'] * PHONE_MM / BASE_W:.1f}"]))
        shown += 1
        if shown >= 20:
            break
    text = "\n".join(out) + "\n"
    if write:
        open(write, "w").write(text)
    print(text)


if __name__ == "__main__":
    main()
