"""Item 5: the place types the content actually needs, against the spec's 24 archetypes (place_types.md).

Counts are TEXT ROWS (a row is one table row and field) that hit a type, so a row naming a harbor twice counts once.
Strong words are place nouns (harbor, school, shrine); weak words are people and activities that imply a place
(students, fishermen); real names map to a type through lexicon.REAL_PLACES.
"""
import collections
import csv
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *
from corpus import corpus
from textscan import *


def main():
    strong = collections.Counter(); weak = collections.Counter(); uncat = collections.Counter(); real_by_type = collections.Counter()
    casework = collections.Counter(); casework_uncat = collections.Counter(); casework_real = collections.Counter()
    CASEWORK = {"events", "event_choices", "hosted_events", "event_options", "visitor_questions"}
    by_table = collections.defaultdict(collections.Counter)
    example = {}
    real_names = collections.Counter()
    n_rows = 0
    for table, key, field, text in corpus():
        n_rows += 1
        s = generic_places(text, strong_only=True)
        a = generic_places(text, strong_only=False)
        for kind in s:
            if table in CASEWORK:
                casework[kind] += 1
            strong[kind] += 1
            by_table[kind][table] += 1
            example.setdefault(kind, (table, key, ", ".join(s[kind][:3])))
        for kind in a:
            if kind not in s:
                weak[kind] += 1
        for kind in uncataloged_places(text):
            if table in CASEWORK:
                casework_uncat[kind] += 1
            uncat[kind] += 1
            example.setdefault("U:" + kind, (table, key, ", ".join(uncataloged_places(text)[kind][:3])))
        for name, kind, _note in real_places(text):
            if table in CASEWORK:
                casework_real[kind] += 1
            real_by_type[kind] += 1
            real_names[name] += 1
    catalog = read_csv_rows(PROPOSALS / "place_catalog_by_pc.csv")
    first_col = list(catalog[0].keys())[0]
    cat_types = []
    for r in catalog:
        m = re.search(r"\(([a-z_]+)\)", r[first_col])
        if m:
            cat_types.append(m.group(1))
    lines = ["# Place types the content needs, against the spec's 24 archetypes", "",
             "Method: every player-facing text row (%d rows from strings, events and choices, level intros and thoughts, stage names, transitions, "
             "visitor, visit and trade questions, staff tasks, the ticker, notices, How to Play, the shop, the room question pools and every spoken cue) "
             "is matched against the word lists in `audit/two_offices/lexicon.py`. **Strong** = a place noun (harbor, school, shrine); **weak** = a person or "
             "activity that implies a place (students, fishermen, harvest); **real names** = a place name found in the text, mapped to the type it "
             "would use. A row counts once per type however many times it says the word. These are drafts for Cameron: a word list finds candidates, "
             "it does not read context (for example 'plant' may be a factory or a seedling). **The 'all rows' counts include law and cue text** "
             "(the Ainu Heritage Act, the Shinkansen act, the Chishima island acts, spoken cues): that is text ABOUT a topic, not a district place the "
             "player stands in. The **casework** column (events, event choices, hosted events, visitor questions) is what a place catalog has to serve.\n" % n_rows,
             "## The 24 archetypes: how much text points at each", "",
             "| Archetype | Casework rows (events, choices, hosted, visitor questions) | All strong rows | Weak rows | Real names mapped to it (all rows / casework) | Example |", "|---|---|---|---|---|---|"]
    order = sorted(ARCHETYPES, key=lambda k: -(casework[k] + casework_real[k]))
    for kind in order:
        ex = example.get(kind)
        lines.append("| %s | %d | %d | %d | %d / %d | %s |" % (kind, casework[kind], strong[kind], weak[kind], real_by_type[kind], casework_real[kind], ("%s %s: %s" % ex) if ex else ""))
    unused = [k for k in ARCHETYPES if casework[k] + casework_real[k] < 5]
    lines += ["", "**Catalog types that little or no casework uses today** (fewer than 5 casework rows by strong words and real names): %s. "
              "Several are needed by the new levels anyway (energy site, travel route, community hall, ski area, island). Islands appear only in the "
              "Rishiri text VQ380 used to carry, which is generic now." % ", ".join("`%s`" % k for k in unused), "",
              "**Archetypes in the spec but not in the catalog CSV's first column:** %s." % (", ".join(sorted(set(ARCHETYPES) - set(cat_types))) or "none"),
              "**Archetypes in the catalog CSV that are not in this audit's list:** %s." % (", ".join(sorted(set(cat_types) - set(ARCHETYPES))) or "none"), "",
              "## Place words the text uses that the catalog has no type for", "",
              "These are nouns for places that district text names or implies but that none of the 24 archetypes covers. Each is a candidate for a "
              "new type, or for deciding the text should use an existing one (a library is a community hall, a street is a market, a road is a travel route).", "",
              "| Candidate type | Casework rows | All rows | Example words | Where first seen | Suggestion |", "|---|---|---|---|---|---|"]
    suggestion = {
        "airport": "Probably a new type, `airport`: the Chitose and flight lines; PC03 and PC04 would have different airports. Or fold into `travel_route`.",
        "post_office": "Rare. `town_hall` (public office) or keep generic.",
        "police_or_fire": "Public-safety places. Fold into `town_hall` (a public office) unless events need them.",
        "bank_or_credit_union": "Money text, mostly loans. A generic word, not a named place: leave as is.",
        "library": "Spec: Policy Study in a local library or community room: fold into `community_hall` or add `library`.",
        "road_or_bridge": "Streetlight and pothole events: a District street. Candidate `street` type, or `market` (shopping street) for lanes.",
        "street_or_neighborhood": "Many district events happen 'on the street' or 'in the neighborhood'. A candidate `street` type, which is also what the OUT_STREET backgrounds show.",
        "housing": "Houses, apartments and villages: the casework (an empty house, a fence). Generic: leave as `{district}`.",
        "care_facility": "Care homes and nurseries. Fold into `hospital` or add `care_home`.",
        "sports_venue": "Sumo, sports teams, arenas. A candidate `venue`, or fold into `community_hall`.",
        "restaurant_or_inn": "Dinners, breakfasts, a restaurant. The DINING background exists. A candidate `restaurant`.",
        "newsroom_or_studio": "Radio and newspaper places. Capitol-side outlets are Yezo brands (Sapporo Broadcasting Center); a local radio station is a District place: candidate `radio_station`.",
        "river_or_flood_works": "Floods, ditches, dikes. Fold into `landmark` (river) or `farmland`.",
        "forest_or_wildlife": "Bears and crows and wilderness text. Candidate `forest`; or fold into `mountain` and `park`.",
    }
    for kind, n in sorted(uncat.items(), key=lambda kv: -casework_uncat[kv[0]]):
        ex = example.get("U:" + kind, ("", "", ""))
        lines.append("| `%s` | %d | %d | %s | %s %s | %s |" % (kind, casework_uncat[kind], n, ex[2], ex[0], ex[1], suggestion.get(kind, "")))
    lines += ["", "## Real place names in the text, by how many rows name them", "",
              "| Name | Rows | Mapped type | Note |", "|---|---|---|---|"]
    for name, n in real_names.most_common():
        kind, note = REAL_PLACES[name]
        lines.append("| %s | %d | %s | %s |" % (name, n, kind, note))
    # Catalog names that already appear in the text.
    catalog_names = set()
    for r in catalog:
        for col in list(r.keys())[1:]:
            for part in re.split(r";|, | and ", r[col] or ""):
                part = re.sub(r"\(.*?\)", "", part).strip()
                if len(part) > 5 and part not in ("None", "Open"):
                    catalog_names.add(part)
    texts = [t for _a, _b, _c, t in corpus()]
    present = []
    for name in sorted(catalog_names):
        hits = sum(1 for t in texts if name in t)
        if hits:
            present.append((name, hits))
    lines += ["", "## Names from the catalog that are already in game text", ""]
    if present:
        lines += ["| Catalog name | Rows |", "|---|---|"] + ["| %s | %d |" % p for p in present]
    else:
        lines.append("None: no complete catalog name appears word for word in the text. The text names other real towns (see above) and generic places.")
    # Real brand counterparts from the brand map.
    brands = read_csv_rows(PROPOSALS / "yezo_brand_map.csv")
    cols = list(brands[0].keys())
    counter_col = [c for c in cols if "counterpart" in c.lower() or "real" in c.lower()][0]
    found = []
    for r in brands:
        for part in re.split(r";|, ", r[counter_col]):
            part = re.sub(r"\(.*?\)", "", part).strip()
            if len(part) > 4:
                hits = sum(1 for t in texts if part.lower() in t.lower())
                if hits:
                    found.append((part, hits, r[cols[0]]))
    lines += ["", "## Real brands from the spec's brand map that appear in game text", ""]
    if found:
        lines += ["| Real name | Rows | Yezo brand proposed |", "|---|---|---|"] + ["| %s | %d | %s |" % f for f in found]
    else:
        lines.append("None. The text already uses invented outlet brands (Sapporo Digital Networks, Sapporo Broadcasting Center, Yezo Political Insider, Yezo News Nightly, Yezo Artisans Guild). "
                     "The real names it does carry are places and cultural references (see place_references.csv, kind brand), not companies from the brand map.")
    write_text("place_types.md", "\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
