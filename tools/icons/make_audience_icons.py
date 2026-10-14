#!/usr/bin/env python3
"""Draws the five audience icons (SG01-SG05) in the house style.

    python3 tools/icons/make_audience_icons.py <output folder>

Same recipe as the hand-drawn organisation icons: a flat base shape, a darker
bevel along the lower right, a thin cream rim along the upper left, one white
sparkle. Drawn at 4x and shrunk, so edges are smooth. 256x256 RGBA, transparent.
Run tools/merge_icons.py on the folder afterwards.
"""
import math, sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024  # working size (4x)
CREAM = (255, 244, 220); TEAL = (54, 169, 156); DTEAL = (27, 95, 115)
ORANGE = (232, 100, 63); MAROON = (142, 47, 74); GOLD = (242, 181, 68)
BRONZE = (184, 105, 31); LAV = (169, 182, 230); WHITE = (255, 255, 255)
BEVEL, RIM = 16, 7


def new_mask():
    return Image.new("L", (S, S), 0)


def mask(fn):
    m = new_mask(); fn(ImageDraw.Draw(m)); return m


def shift(m, dx, dy):
    return ImageChops.offset(m, dx, dy)


def paint(canvas, m, color):
    canvas.paste(Image.new("RGBA", (S, S), color + (255,)), (0, 0), m)


def obj(canvas, m, base, shade, rim=True, bevel=BEVEL):
    """One flat object: cream rim (upper left), shade, base."""
    if rim:
        paint(canvas, shift(m, -RIM, -RIM), CREAM)
    paint(canvas, m, shade)
    top = ImageChops.multiply(m, shift(m, -bevel, -bevel))
    paint(canvas, top, base)


def flat(canvas, m, color):
    paint(canvas, m, color)


def rrect(box, r):
    return mask(lambda d: d.rounded_rectangle(box, r, fill=255))


def circle(cx, cy, r):
    return mask(lambda d: d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255))


def poly(points):
    return mask(lambda d: d.polygon(points, fill=255))


def bar(x0, y0, x1, y1, w):
    """A thick rounded line."""
    def f(d):
        d.line((x0, y0, x1, y1), fill=255, width=w)
        d.ellipse((x0 - w / 2, y0 - w / 2, x0 + w / 2, y0 + w / 2), fill=255)
        d.ellipse((x1 - w / 2, y1 - w / 2, x1 + w / 2, y1 + w / 2), fill=255)
    return mask(f)


def star(cx, cy, r, points=5, inner=0.45, rot=-90):
    pts = []
    for i in range(points * 2):
        rad = r if i % 2 == 0 else r * inner
        a = math.radians(rot + i * 180 / points)
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return poly(pts)


def sparkle(canvas, cx, cy, r=46):
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gm = star(cx, cy, r * 1.6, 4, 0.18, -90)
    glow.paste(Image.new("RGBA", (S, S), WHITE + (150,)), (0, 0), gm.filter(ImageFilter.GaussianBlur(14)))
    canvas.alpha_composite(glow)
    paint(canvas, star(cx, cy, r, 4, 0.2, -90), WHITE)


def blank():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


# ---------------------------------------------------------------- the five
def sg01_press():
    c = blank()
    # notebook (gold) with spiral rings, page lines
    obj(c, rrect((250, 170, 700, 860), 56), GOLD, BRONZE)
    for y in (330, 470, 610):
        flat(c, rrect((350, y, 610, y + 34), 17), CREAM)
    flat(c, rrect((350, 740, 520, 774), 17), CREAM)
    for y in (260, 400, 540, 680, 800):
        obj(c, rrect((205, y - 24, 305, y + 24), 24), CREAM, LAV, rim=False, bevel=8)
    # pen (orange-red) across the front, cream tip
    x0, y0, x1, y1, w = 640, 880, 860, 400, 96
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy); ux, uy = dx / n, dy / n; px, py = -uy, ux
    body = poly([(x0 + px * w / 2, y0 + py * w / 2), (x0 - px * w / 2, y0 - py * w / 2),
                 (x1 - px * w / 2, y1 - py * w / 2), (x1 + px * w / 2, y1 + py * w / 2)])
    tip = poly([(x0 + px * w / 2, y0 + py * w / 2), (x0 - px * w / 2, y0 - py * w / 2),
                (x0 - ux * 90, y0 - uy * 90)])
    obj(c, body, ORANGE, MAROON)
    flat(c, tip, CREAM)
    flat(c, bar(x1 - ux * 30 + px * 12, y1 - uy * 30 + py * 12, x1 - ux * 150 + px * 12,
                y1 - uy * 150 + py * 12, 22), CREAM)
    sparkle(c, 215, 150)
    return c


def sg02_party_members():
    c = blank()
    # ribbon tails (gold)
    obj(c, poly([(330, 560), (520, 610), (440, 950), (385, 860), (300, 925)]), GOLD, BRONZE)
    obj(c, poly([(700, 560), (510, 610), (590, 950), (645, 860), (730, 925)]), GOLD, BRONZE)
    # scalloped rosette (orange-red)
    def rose(d):
        cx, cy = 512, 420
        for i in range(14):
            a = math.radians(i * 360 / 14)
            x, y = cx + 245 * math.cos(a), cy + 245 * math.sin(a)
            d.ellipse((x - 105, y - 105, x + 105, y + 105), fill=255)
        d.ellipse((cx - 250, cy - 250, cx + 250, cy + 250), fill=255)
    obj(c, mask(rose), ORANGE, MAROON, bevel=22)
    obj(c, circle(512, 420, 190), CREAM, LAV, rim=False, bevel=14)
    obj(c, circle(512, 420, 150), ORANGE, MAROON, rim=False, bevel=12)
    obj(c, star(512, 418, 105), GOLD, BRONZE, rim=False, bevel=9)
    sparkle(c, 225, 190)
    return c


def person(c, cx, head_y, head_r, body_top, body_w, body_bottom, base, shade):
    obj(c, circle(cx, head_y, head_r), base, shade, bevel=12)
    def body(d):
        r = body_w / 2
        d.ellipse((cx - r, body_top, cx + r, body_top + 2 * r), fill=255)
        d.rectangle((cx - r, body_top + r, cx + r, body_bottom), fill=255)
    obj(c, mask(body), base, shade, bevel=18)


def sg03_constituents():
    c = blank()
    person(c, 245, 440, 78, 560, 300, 880, TEAL, DTEAL)
    person(c, 780, 440, 78, 560, 300, 880, TEAL, DTEAL)
    person(c, 512, 330, 108, 470, 380, 880, TEAL, DTEAL)
    # a gold badge on the centre figure's chest
    obj(c, star(512, 640, 70), GOLD, BRONZE, rim=False, bevel=7)
    sparkle(c, 365, 250)
    return c


def sg04_donors():
    c = blank()
    obj(c, rrect((120, 300, 790, 820), 44), ORANGE, MAROON)
    # cream flap with a fold line
    obj(c, poly([(135, 318), (775, 318), (455, 640)]), CREAM, LAV, rim=False, bevel=14)
    # gold wax seal
    obj(c, circle(455, 640, 88), GOLD, BRONZE, bevel=10)
    flat(c, circle(455, 640, 44), BRONZE)
    flat(c, circle(455, 640, 32), GOLD)
    # one coin, lower right
    obj(c, circle(770, 720, 150), CREAM, LAV, bevel=14)
    obj(c, circle(770, 720, 112), GOLD, BRONZE, rim=False, bevel=10)
    flat(c, poly([(770, 640), (850, 720), (770, 800), (690, 720)]), CREAM)
    flat(c, poly([(770, 668), (822, 720), (770, 772), (718, 720)]), GOLD)
    sparkle(c, 190, 235)
    return c


def sg05_bureaucrats():
    c = blank()
    # papers sticking out of the folder
    obj(c, rrect((250, 190, 760, 520), 36), CREAM, LAV)
    for y in (280, 370):
        flat(c, rrect((340, y, 640, y + 30), 15), TEAL)
    # folder: tab + body (teal)
    obj(c, rrect((120, 400, 330, 520), 40), TEAL, DTEAL, bevel=12)
    obj(c, rrect((120, 450, 900, 880), 52), TEAL, DTEAL)
    # an official stamp mark, orange-red ring and star
    ring = ImageChops.subtract(circle(640, 670, 150), circle(640, 670, 112))
    flat(c, ring, ORANGE)
    flat(c, star(640, 668, 70), ORANGE)
    flat(c, bar(255, 600, 450, 600, 30), CREAM)
    flat(c, bar(255, 690, 450, 690, 30), CREAM)
    flat(c, bar(255, 780, 380, 780, 30), CREAM)
    sparkle(c, 175, 340)
    return c


ICONS = {"SG01": sg01_press, "SG02": sg02_party_members, "SG03": sg03_constituents,
         "SG04": sg04_donors, "SG05": sg05_bureaucrats}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
    for name, fn in ICONS.items():
        fn().resize((256, 256), Image.LANCZOS).save(out / f"{name}.png")
        print("wrote", out / f"{name}.png")
