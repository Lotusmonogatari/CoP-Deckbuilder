"""Follow-up to item 4 (2026-11-19): the part of place_references.csv that needs a person's decision, shorter.

place_references.csv has 14,131 rows, about 11,200 of them generic words in spoken cues. The rows that carry a decision
are the real place names and the real brands and festivals (1,174 hits). This groups them by text row (one line per
table, key and field, with every name found) and splits the casework tables (events, choices, visitor questions,
intros, shop, staff tasks) from the spoken and background tables (cues, question pools, transitions, ticker).
Reads place_references.csv; writes place_worklist.csv, place_worklist_casework.csv and place_worklist.md."""
import collections
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import OUT, read_csv_rows, write_csv, write_text

CASEWORK = {"events", "event_choices", "event_options", "hosted_events", "visitor_questions", "visit_questions", "visit_answers",
            "trade_questions", "lobbyist_lines", "level_intros", "level_intro_thoughts", "levels", "stages", "staff_tasks", "shop",
            "office_notices", "how_to_play", "strings", "visitors"}
HANDLING = {
    "capital": "Keep: Sapporo is the Capitol's city (canon).",
    "region": "Canon decision: keep the real region name or replace it.",
    "foreign": "Keep: a foreign country or region.",
    "town_hall": "A named town: a place token, or keep when the text is about that very town.",
    "landmark": "Canon decision, or a place token when it is a generic lake, strait or mountain.",
    "travel_route": "Canon decision: the Hokkaido Shinkansen is a bill name.",
}


def main():
    rows = read_csv_rows(OUT / "place_references.csv")
    real = [r for r in rows if r["kind"] in ("place (real name)", "brand (real)")]
    grouped = collections.OrderedDict()
    for r in real:
        key = (r["table"], r["key"], r["field"], r["kind"])
        entry = grouped.setdefault(key, {"words": [], "types": [], "context": r["context"]})
        if r["the_words"] not in entry["words"]:
            entry["words"].append(r["the_words"])
        if r["proposed_place_type_or_brand"] not in entry["types"]:
            entry["types"].append(r["proposed_place_type_or_brand"])
    header = ["table", "key", "field", "kind", "names found", "proposed type or note", "the line", "decision (Cameron)"]
    all_rows, casework_rows = [], []
    for (table, key, field, kind), entry in grouped.items():
        row = [table, key, field, kind, " | ".join(entry["words"]), " | ".join(entry["types"]), entry["context"], ""]
        all_rows.append(row)
        if table.split(".")[0] in CASEWORK:
            casework_rows.append(row)
    write_csv("place_worklist.csv", header, all_rows)
    write_csv("place_worklist_casework.csv", header, casework_rows)

    names = collections.Counter()
    name_type = {}
    for r in real:
        if r["kind"] == "place (real name)":
            names[r["the_words"]] += 1
            name_type[r["the_words"]] = r["proposed_place_type_or_brand"]
    by_table = collections.Counter(r["table"].split(".")[0] for r in real)
    casework_hits = sum(n for t, n in by_table.items() if t in CASEWORK)
    lines = ["# Place worklist: the rows that need a decision", "",
             "Follow-up to `place_references.csv` (2026-11-19). **That file has 14,131 rows because it also lists generic words** such as "
             "\"district\" and \"committee\" in the spoken cues. Only the real place names and the real brands and festivals need a person "
             "to decide. This is that part, grouped by text row: one line per table, key and field, with every name found, and a blank "
             "decision column. All proposals are drafts for Cameron.", "",
             "## Executive summary", "",
             "| | Hits | Text rows |", "|---|---|---|",
             f"| Real names and real brands | {len(real)} | {len(all_rows)} |",
             f"| In casework tables (events, choices, visitor questions, intros, shop, staff tasks, strings) | {casework_hits} | {len(casework_rows)} |",
             f"| In spoken and background tables (cues, question pools, transitions, ticker) | {len(real) - casework_hits} | {len(all_rows) - len(casework_rows)} |", "",
             "Start with `place_worklist_casework.csv` (the rows a player reads as events, questions and intros). The other file adds the spoken tables.", "",
             "## Where the hits are", "", "| Table | Hits |", "|---|---|"]
    for table, n in by_table.most_common():
        lines.append(f"| {table}{' (casework)' if table in CASEWORK else ''} | {n} |")
    lines += ["", "## The real names, by how often they appear", "",
              "| Name | Hits | Type | Suggested handling |", "|---|---|---|---|"]
    for name, n in names.most_common(40):
        kind = name_type[name]
        lines.append(f"| {name} | {n} | {kind} | {HANDLING.get(kind, 'Check the line.')} |")
    rest = len(names) - 40
    if rest > 0:
        lines.append(f"| ... {rest} more names | | | see the CSV |")
    lines += ["", "## The real brands and festivals (12 hits)", "",
              "These are mostly regional culture (Nebuta and Neputa festivals, Tsugaru-nuri lacquerware, the Yoitomake call, haskap berries), "
              "not company brands, so `yezo_brand_map.csv` (which replaces companies and venues) covers almost none of them. The one company "
              "name is New Chitose Airport (VQ26). Whether regional culture stays real or becomes Yezo's own is a canon decision.", "",
              "| Where | Words | Note |", "|---|---|---|"]
    for r in real:
        if r["kind"] == "brand (real)":
            lines.append(f"| {r['table']} {r['key']} | {r['the_words']} | {r['proposed_place_type_or_brand']} |")
    lines += ["", "## Decisions this asks for", "",
              "1. **Real region and nation names** (Hokkaido, Japan, Tsugaru, the Hokkaido Shinkansen): keep as real or replace with Yezo's. "
              "The names appear in bill titles and the ticker.",
              "2. **Named towns** (Hakodate, Otaru, Tomakomai, Aomori, Hirosaki ...): which text is about that town (keep) and which only needs "
              "\"a town\" (a place token later).",
              "3. **Regional culture** (the twelve brand and festival hits): real or Yezo's own.", ""]
    write_text("place_worklist.md", "\n".join(lines))


if __name__ == "__main__":
    main()
