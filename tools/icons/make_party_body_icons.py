#!/usr/bin/env python3
"""Draws the Party Activists (BO31) and Candidate Selection Committee (BO32)
icons in the house style (2026-10-18). Reuses the helpers of
make_audience_icons.py.

    python3 tools/icons/make_party_body_icons.py <output folder>

BO31: a raised fist with a flame at the wrist. BO32: a ballot paper with a
magnifying glass over it. Run tools/merge_icons.py on the folder afterwards.
"""
import math, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from make_audience_icons import *  # noqa: F401,F403
from make_audience_icons import (S, CREAM, TEAL, DTEAL, ORANGE, MAROON, GOLD, BRONZE, LAV,
    WHITE, Image, ImageChops, ImageDraw, blank, obj, flat, rrect, circle, poly, bar,
    star, sparkle, mask, shift, paint)


def flame(cx, top, bottom, half, lean=0):
    """A teardrop flame: round at the bottom, a sharp tip that leans."""
    peak = max(4 * (t / 400) ** 0.5 * (1 - t / 400) ** 1.3 for t in range(1, 400))
    left, right = [], []
    n = 60
    for i in range(n + 1):
        t = i / n
        w = half * 4 * t ** 0.5 * (1 - t) ** 1.3 / peak
        y = bottom - (bottom - top) * t
        x = cx + lean * t ** 2
        left.append((x - w, y))
        right.append((x + w, y))
    return poly(left + right[::-1])


def bo31_activists():
    c = blank()
    # the wrist and forearm
    obj(c, rrect((385, 560, 645, 760), 40), ORANGE, MAROON, bevel=14)
    # the fist: a block with four knuckles along the top
    knuckles = mask(lambda d: [d.ellipse((x - 66, 190, x + 66, 330), fill=255) for x in (382, 474, 566, 658)])
    block = rrect((316, 260, 724, 620), 74)
    fist = ImageChops.lighter(block, knuckles)
    obj(c, fist, ORANGE, MAROON)
    # finger divisions and the thumb across the front
    for x in (428, 520, 612):
        flat(c, bar(x, 300, x, 420, 9), MAROON)
    thumb = rrect((286, 450, 590, 575), 60)
    obj(c, thumb, ORANGE, MAROON, bevel=12)
    # the flame at the base of the wrist: three tongues, hottest in the middle
    flat(c, flame(400, 690, 925, 70, -20), GOLD)
    flat(c, flame(630, 700, 925, 70, 25), GOLD)
    flat(c, flame(515, 640, 960, 135, 18), GOLD)
    flat(c, flame(515, 760, 950, 85, 10), ORANGE)
    flat(c, flame(515, 840, 940, 42, 4), CREAM)
    sparkle(c, 800, 200)
    return c


def bo32_committee():
    c = blank()
    # the ballot paper
    obj(c, rrect((170, 120, 720, 880), 60), TEAL, DTEAL)
    flat(c, rrect((250, 200, 640, 260), 22), CREAM)
    for i, y in enumerate((340, 500, 660)):
        flat(c, rrect((250, y, 330, y + 80), 14), CREAM)
        flat(c, rrect((370, y + 20, 640, y + 60), 20), CREAM)
    # a check in the middle box
    tick = poly([(262, 540), (285, 515), (300, 540), (330, 500), (350, 520), (300, 575)])
    flat(c, tick, ORANGE)
    # the magnifying glass over the lower right
    handle = poly([(700, 700), (760, 640), (940, 820), (880, 880)])
    obj(c, handle, BRONZE, (120, 70, 20), rim=False, bevel=10)
    ring = ImageChops.subtract(circle(640, 620, 215), circle(640, 620, 160))
    lens = circle(640, 620, 160)
    paint(c, lens, LAV)
    obj(c, ring, GOLD, BRONZE, bevel=14)
    # what the lens shows: a bigger check box
    flat(c, rrect((590, 560, 700, 670), 18), CREAM)
    flat(c, poly([(605, 620), (630, 595), (648, 625), (685, 575), (705, 595), (650, 660)]), ORANGE)
    sparkle(c, 330, 215)
    return c


ICONS = {"BO31": bo31_activists, "BO32": bo32_committee}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
    for name, fn in ICONS.items():
        fn().resize((256, 256), Image.LANCZOS).save(out / f"{name}.png")
        print("wrote", out / f"{name}.png")
