#!/usr/bin/env python3
"""Fill design/ART_PROMPT_TEMPLATE.md's slots from the data files.

Usage:  python3 tools/art_prompt.py character PC02 OP14
        python3 tools/art_prompt.py card C11
        python3 tools/art_prompt.py background ST02
Prints one ready-to-paste prompt per ID. Slots the data cannot know
(appearance, outfit, scene, mood) stay as {SLOTS} for the designer.
Reads data/*.json only; writes nothing.
"""
import json, sys, pathlib

D = pathlib.Path(__file__).resolve().parent.parent / "data"
EXPRESSIONS = {
    "neutral": "relaxed, listening",
    "attacking": "leaning in, pointed gesture, about to press the point",
    "guarding": "arms folded or hands raised, bracing",
    "gaining": "open hand, rallying, confident",
    "damaged": "flinching, hand to chest or brow, losing the room",
}
SUIT_MOOD = {
    "Earnest": "warm, steady light", "Emotional": "soft, close, intimate",
    "Appeal": "open, crowd, bright", "Data Driven": "clean, cool, ordered",
    "Divisive": "hard contrast, sharp angles", "Duplicitous": "shadow, half-hidden, sly",
}
STYLE = "STYLE: {HOUSE_STYLE}\nCANON GUARD: fictional nation Yezo; no real people or logos; no readable text anywhere."


def rows(name):
    d = json.load(open(D / f"{name}.json", encoding="utf-8"))
    if isinstance(d, dict):
        d = next((v for v in d.values() if isinstance(v, list) and v and isinstance(v[0], dict)), [])
    return [r for r in d if isinstance(r, dict)]


def find(name, key, ident):
    return next((r for r in rows(name) if r.get(key) == ident), None)


def clean(v, default):
    return default if v in (None, "", "varies") else str(v)


def character(ident):
    kind = {"PC": ("player", "player_id"), "OP": ("opponents", "opp_id"),
            "SF": ("staff", "staff_id"), "VI": ("visitors", "visitor_id")}[ident[:2]]
    r = find(*kind, ident)
    if not r:
        return f"# {ident}: not found in data"
    name = r.get("name_en") or r.get("name") or ident
    role = clean(r.get("title") or r.get("role"), "{ROLE}")
    out = []
    for ex, line in EXPRESSIONS.items():
        out.append(
            f"## {ident}_{ex}.png\n{STYLE}\n"
            f"Full-body standing portrait of {name}, { {'M':'male','F':'female'}.get(r.get('gender'), '{GENDER}') }, {role}, "
            f"{clean(r.get('party'), 'no party')}.\n"
            f"Appearance: {{APPEARANCE}}. Outfit: {{OUTFIT}}.\n"
            f"Expression and pose: {line}.\n"
            "Canvas 1024 x 1536, head to feet in frame, centred, transparent background. "
            "Same face and outfit as the other expressions of this character.\n")
    return "\n".join(out)


def card(ident):
    r = find("cards", "card_id", ident)
    if not r:
        return f"# {ident}: not found in data"
    return (f"## {ident}.png\n{STYLE}\n"
            f"Illustration for the rhetoric card \"{r['name_en']}\" ({r['suit']} suit, {r['type']}). "
            f"Effect in plain words: {str(r.get('effect_text')).rstrip('.')}.\nScene: {{SCENE}}. "
            f"Suit mood: {SUIT_MOOD.get(r['suit'], '{SUIT_MOOD}')}.\n"
            "Canvas 1024 x 768, one clear focal point, readable as a thumbnail, "
            "nothing important in the outer 5%.\n")


def background(ident):
    r = find("stages", "stage_id", ident)
    if not r:
        return f"# {ident}: not found in data"
    return (f"## {ident}.png\n{STYLE}\n"
            f"Empty room for the stage \"{r['name_en']}\" ({r['mode']}): {{PLACE}}. Mood: {{MOOD}}.\n"
            "Canvas 1080 x 2340 portrait, no people, calmer and darker lower third, "
            "open upper-middle for two characters in the bottom corners.\n")


MAKERS = {"character": character, "card": card, "background": background}

if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in MAKERS:
        sys.exit(__doc__)
    for i in sys.argv[2:]:
        print(MAKERS[sys.argv[1]](i))
