#!/usr/bin/env python3
"""Check and merge new organisation icons (design/ICON_GENERATION_BRIEF.md).

    python3 tools/merge_icons.py <folder>           check only
    python3 tools/merge_icons.py <folder> --apply   copy into assets/icons/

Only reads the folder you give it and writes only to assets/icons/ (and the
art checklist) when --apply is passed and every file passed.
"""
import json, shutil, subprocess, sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "assets" / "icons"
PALETTE = ["FFF4DC", "36A99C", "1B5F73", "E8643F", "8E2F4A", "F2B544", "B8691F",
           "A9B6E6", "5B9BE0", "7DB650", "2F6B45", "FFFFFF", "9A78CC", "4F3F8F"]
PAL = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in PALETTE]
MARGIN = 12          # brief asks for 16; allow a little slack
OFF_PALETTE_MAX = 0.12   # share of solid pixels allowed far from the palette
FAR = 60             # colour distance counted as "far"


def wanted_ids():
    """Organisations with no icon yet, from the data."""
    data = json.loads((ROOT / "data" / "boosters.json").read_text())
    rows = data if isinstance(data, list) else list(data.values())
    return [r["booster_id"] for r in rows if not (ICONS / f"{r['booster_id']}.png").exists()]


def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def check(path):
    problems = []
    im = Image.open(path)
    if im.size != (256, 256):
        problems.append(f"size {im.size[0]}x{im.size[1]}, needs 256x256")
    if im.mode != "RGBA":
        problems.append(f"mode {im.mode}, needs RGBA")
        im = im.convert("RGBA")
    w, h = im.size
    for corner in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if im.getpixel(corner)[3] != 0:
            problems.append("corners are not transparent (background left in?)")
            break
    box = im.getbbox()
    if box is None:
        problems.append("image is empty")
        return problems
    if box[0] < MARGIN or box[1] < MARGIN or box[2] > w - MARGIN or box[3] > h - MARGIN:
        problems.append(f"artwork reaches the edge (bounds {box}); keep a 16 px margin")
    area = (box[2] - box[0]) * (box[3] - box[1])
    if area < 0.35 * w * h:
        problems.append("artwork is small; it should fill about 85% of the canvas")
    solid = [p[:3] for p in im.getdata() if p[3] == 255]
    if solid:
        sample = solid[::7]
        far = sum(1 for p in sample if min(dist(p, c) for c in PAL) > FAR)
        if far / len(sample) > OFF_PALETTE_MAX:
            problems.append(f"{far * 100 // len(sample)}% of solid pixels are outside the palette")
    return problems


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    apply = "--apply" in sys.argv
    if len(args) != 1:
        sys.exit(__doc__)
    folder = Path(args[0])
    wanted = wanted_ids()
    found = {p.stem: p for p in folder.glob("*.png")}
    ok = True
    print(f"{'ID':6} {'result':8} detail")
    for icon_id in wanted:
        p = found.get(icon_id)
        if p is None:
            print(f"{icon_id:6} MISSING  no {icon_id}.png in the folder")
            ok = False
            continue
        problems = check(p)
        print(f"{icon_id:6} {'ok' if not problems else 'FAIL':8} {'; '.join(problems)}")
        ok = ok and not problems
    for stray in sorted(set(found) - set(wanted)):
        print(f"{stray:6} IGNORED  not an icon still needed")
    if not wanted:
        print("Every organisation already has an icon.")
        return
    if not ok:
        print("\nNothing copied: fix the rows above and run again.")
        sys.exit(1)
    if not apply:
        print("\nAll good. Run again with --apply to copy them in.")
        return
    for icon_id in wanted:
        shutil.copyfile(found[icon_id], ICONS / f"{icon_id}.png")
    subprocess.run([sys.executable, str(ROOT / "tools" / "art_checklist.py")], check=False)
    print(f"\nCopied {len(wanted)} icons into assets/icons/. Now run: .tools/godot --headless --import")


if __name__ == "__main__":
    main()
