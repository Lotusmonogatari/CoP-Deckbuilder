"""Item 4: every player-facing text row that names or implies a district place or a real company or brand.

One row per (row, field, place or brand). Kinds:
  place   a real place name (REAL_PLACES), or a generic word for a place type (strong words only: harbor, school,
          shrine ...). The 'proposed type and token' is a draft: {place:<type>}, {district} or {office_city} from
          the spec's token list, or 'keep' where a real name is a canon decision.
  brand   a real company, product or media name (REAL_BRANDS), with the Yezo brand from the spec's brand map where
          one exists.
Scope: strings, events and their choices, hosted events, level intros and thoughts, levels, stages, transitions,
visitor, visit and trade questions, staff tasks, ticker, notices, How to Play, shop, lobbyist lines, the room
question pools and every spoken cue (opponent, player, card).
"""
import collections
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *
from corpus import corpus
from textscan import *

DISTRICT_TOWNS = {"Wakkanai": "{office_city} (PC01)", "Tomakomai": "{office_city} (PC02)", "Mutsu": "{office_city} (PC04, one of three candidates)",
                  "Towada": "{office_city} (PC04, one of three candidates)", "Noheji": "{office_city} (PC04, one of three candidates)",
                  "Teine": "{office_city} (PC03, one of three candidates)", "Ishikari": "{office_city} (PC03, one of three candidates)"}
TOKEN_FOR_TYPE = {"town_hall": "{place:town_hall} or keep the town name", "capital": "keep (the capital or a national name)", "region": "keep (canon decision)",
                  "foreign": "keep (a foreign name)"}


def snippet(text, start, end):
    left = max(0, start - 28)
    right = min(len(text), end + 28)
    return ("..." if left else "") + text[left:right].replace("\n", " ") + ("..." if right < len(text) else "")


def scan(text):
    """[(kind, words, snippet, type_or_brand, token_or_note)] for one text."""
    out = []
    for name, rx in ((n, re.compile(r"(?<![A-Za-zĀ-ſ])" + re.escape(n) + r"(?![A-Za-zĀ-ſ])")) for n in REAL_PLACES):
        m = rx.search(text)
        if m:
            kind_type, note = REAL_PLACES[name]
            token = DISTRICT_TOWNS.get(name) or ("{place:%s}" % kind_type if kind_type in ARCHETYPES else TOKEN_FOR_TYPE.get(kind_type, "keep"))
            out.append(("place (real name)", name, snippet(text, m.start(), m.end()), kind_type, "%s; %s" % (token, note)))
    for pat, (what, note) in REAL_BRANDS.items():
        m = re.search(pat, text)
        if m:
            out.append(("brand (real)", m.group(0), snippet(text, m.start(), m.end()), what, note))
    for kind, words in generic_places(text, strong_only=True).items():
        m = re.search(re.escape(words[0]), text, re.I)
        out.append(("place (implied type)", ", ".join(words[:4]), snippet(text, m.start(), m.end()) if m else "", kind, "{place:%s}" % kind))
    for kind, words in uncataloged_places(text).items():
        m = re.search(re.escape(words[0]), text, re.I)
        out.append(("place (implied, NOT in the catalog)", ", ".join(words[:4]), snippet(text, m.start(), m.end()) if m else "", kind, "no archetype: see place_types.md"))
    return out


def main():
    rows = []
    counts = collections.Counter()
    for table, key, field, text in corpus():
        for kind, words, snip, ptype, token in scan(text):
            rows.append([table, key, field, words, snip, kind, ptype, token])
            counts[(table, kind)] += 1
    write_csv("place_references.csv", ["table", "key", "field", "the_words", "context", "kind", "proposed_place_type_or_brand", "proposed_token_or_note"], rows)
    by_kind = collections.Counter(r[5] for r in rows)
    print(dict(by_kind))
    names = collections.Counter(r[3] for r in rows if r[5] == "place (real name)")
    print(len(names), "distinct real place names; top:", names.most_common(15))


if __name__ == "__main__":
    main()
