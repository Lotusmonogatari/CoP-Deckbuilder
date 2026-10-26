"""Draws the two calendar icons (both with their name on the face) for the Era Name and Ainu calendar packages
(2026-10-26), in the palette and shape language of the existing item icons:
256x256, transparent, flat soft colours, a cream edge and a dark offset shadow.

    python3 tools/icons/make_calendar_icons.py

Writes assets/icons/calendar_era.png and calendar_ainu.png.
Text is set in Noto Sans JP (assets/fonts, SIL OFL).
"""
from PIL import Image, ImageDraw, ImageFont

PURPLE = (154, 120, 204, 255)
DARK = (79, 63, 143, 255)
CREAM = (255, 244, 220, 255)
ORANGE = (232, 100, 63, 255)
MAROON = (142, 47, 74, 255)
BLUE = (169, 182, 230, 255)
S = 4  # supersample
FONT = "assets/fonts/NotoSansJP[wght].ttf"


def font(size, weight=800):
    f = ImageFont.truetype(FONT, size * S)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def calendar(header_text, face_text, face_size, header_size, name):
    im = Image.new("RGBA", (256 * S, 256 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # offset shadow, body, cream face panel
    d.rounded_rectangle([46 * S, 52 * S, 222 * S, 222 * S], 22 * S, fill=DARK)
    d.rounded_rectangle([34 * S, 40 * S, 210 * S, 210 * S], 22 * S, fill=PURPLE)
    # header band
    d.rounded_rectangle([34 * S, 40 * S, 210 * S, 92 * S], 22 * S, fill=ORANGE)
    d.rectangle([34 * S, 70 * S, 210 * S, 92 * S], fill=ORANGE)
    # cream face
    d.rounded_rectangle([48 * S, 100 * S, 196 * S, 196 * S], 14 * S, fill=CREAM)
    # soft blue shade bottom-right of face, like the other icons
    d.rounded_rectangle([48 * S, 178 * S, 196 * S, 196 * S], 10 * S, fill=BLUE)
    d.rectangle([48 * S, 178 * S, 196 * S, 186 * S], fill=CREAM)
    # binder rings
    for x in (78, 166):
        d.rounded_rectangle([(x - 8) * S, 24 * S, (x + 8) * S, 62 * S], 8 * S, fill=MAROON)
        d.rounded_rectangle([(x - 5) * S, 27 * S, (x + 5) * S, 56 * S], 5 * S, fill=CREAM)
    if header_text:
        f = font(header_size)
        d.text((122 * S, 80 * S), header_text, font=f, fill=CREAM, anchor="mm")
    if face_text:
        f = font(face_size)
        d.text((122 * S, 148 * S), face_text, font=f, fill=PURPLE, anchor="mm")
    # sparkle
    for r, a in ((9, 255), (5, 255)):
        d.ellipse([(30 - r) * S, (36 - r) * S, (30 + r) * S, (36 + r) * S], fill=(255, 255, 255, a // 2))
    im = im.resize((256, 256), Image.LANCZOS)
    im.save(f"assets/icons/{name}.png")


# Era calendar: a blank calendar with 元号 on its face.
calendar("", "元号", 52, 0, "calendar_era")
# Ainu calendar: アイヌ on the face, the same way as the era calendar.
calendar("", "アイヌ", 40, 0, "calendar_ainu")
