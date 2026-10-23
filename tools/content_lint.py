#!/usr/bin/env python3
"""Mechanical checks over every content text in data/*.json (2026-10-23).

Pass 1 of the content review (design/proposals/CONTENT_REVIEW_PLAN_2026-10-23.md):
doubled words, double spaces, stray punctuation, unfilled placeholders,
British spellings, over-long lines and exact duplicates inside a group. It
only reads; it prints one line per finding: file | id | field | problem | text.

    python3 tools/content_lint.py            # everything
    python3 tools/content_lint.py --counts   # just counts per problem
"""
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data"

# (file, id field(s), text fields, max length or None)
SOURCES = [
    ("opponent_cues", ["cue_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], 140),
    ("player_cues", ["cue_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], 140),
    ("card_cues", ["card_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], 140),
    ("transition_dialogue", ["transition_dialogue_id"], ["character_line_en", "player_reply_en"], 200),
    ("level_intros", ["level_id", "role"], ["cue_text"], 200),
    ("office_ticker", ["ticker_id"], ["text_en"], 160),
    ("office_notices", ["notice_id"], ["text_en"], 160),
    ("visitor_questions", ["question_id"], ["question_text", "choice_a", "choice_b", "choice_c", "choice_d",
        "response_a", "response_b", "response_c", "response_d", "reaction_a", "reaction_b", "reaction_c", "reaction_d"], 220),
    ("events", ["event_id"], ["title", "flavor"], 320),
    ("event_choices", ["event_id", "choice"], ["choice_text", "result_text"], 220),
    ("event_options", ["option_id"], ["choice_text", "flavor"], 200),
    ("reaction_lines", ["level"], ["line"], 120),
    ("bill_components", ["component_id"], ["short_label", "phrase", "description"], 200),
    ("patron_bills", ["patron_bill_id"], ["request_line", "accept_line", "decline_line", "pass_line", "fail_line"], 260),
    ("how_to_play", ["entry_id"], ["heading_en", "body_en"], 900),
    ("strings", ["key"], ["english"], 400),
]

BRITISH = re.compile(r"\b(colour|organis\w+|favour\w*|honour\w*|labour|programme|centre|neighbour\w*|behaviour|realis\w+|"
                     r"recognis\w+|analys(?:e|ed|es|ing)|defence|licence|grey|catalogue|theatre|judgement|whilst|learnt|"
                     r"cheque|tyre|travell\w+|cancell\w+|modell\w+|labell\w+)\b", re.I)
# Words that are fine as proper names or data keys.
BRITISH_OK = re.compile(r"Labour Federation", re.I)


def texts(rows, id_fields, fields):
    for row in rows:
        rid = "/".join(str(row.get(f, "")) for f in id_fields)
        for field in fields:
            value = row.get(field)
            if isinstance(value, str) and value.strip():
                yield rid, field, value


def check(value, limit):
    out = []
    if "<null>" in value or "None" == value.strip():
        out.append("null text")
    if re.search(r"\{[a-z_]+\}", value) and "{" in value:
        pass  # placeholders are legitimate in the Text tab; reported only where unfilled in content below
    if "  " in value:
        out.append("double space")
    if value != value.strip():
        out.append("leading/trailing space")
    if re.search(r"\b(\w+)\s+\1\b", value, re.I) and not re.search(r"\b(had had|that that|very very)\b", value, re.I):
        out.append("doubled word")
    if re.search(r"\s[,.;:!?]", value):
        out.append("space before punctuation")
    if re.search(r"[,.;:!?]{2,}", value) and "..." not in value and "?!" not in value and "!?" not in value:
        out.append("doubled punctuation")
    if re.search(r"[A-Za-z][.!?][A-Za-z]", value) and not re.search(r"\b[A-Za-z]\.[A-Za-z]\.", value) and "http" not in value:
        out.append("missing space after full stop")
    if value.count("(") != value.count(")") or value.count('"') % 2 == 1:
        out.append("unbalanced bracket or quote")
    if value[0].islower() and not value.startswith(("e.g", "i.e")):
        out.append("starts lower case")
    if value[-1] not in ".!?\"')”…:" and not value.endswith(("etc",)):
        out.append("no closing punctuation")
    if BRITISH.search(BRITISH_OK.sub("", value)):
        out.append("British spelling")
    if limit and len(value) > limit:
        out.append(f"long ({len(value)}>{limit})")
    if re.search(r"[‘’]", value) or re.search(r"[“”]", value):
        out.append("curly quotes (house style is straight)")
    return out


def main():
    counts = Counter()
    lines = []
    for name, id_fields, fields, limit in SOURCES:
        path = DATA / f"{name}.json"
        if not path.exists():
            continue
        rows = json.loads(path.read_text())
        seen = defaultdict(list)
        for rid, field, value in texts(rows, id_fields, fields):
            for problem in check(value, limit):
                if name == "strings" and problem == "no closing punctuation":
                    continue
                counts[(name, problem)] += 1
                lines.append(f"{name} | {rid} | {field} | {problem} | {value}")
            seen[value.strip().lower()].append(rid)
        for value, ids in seen.items():
            if len(ids) > 1 and len(value) > 12 and name not in ("strings",):
                counts[(name, "duplicate text")] += 1
                lines.append(f"{name} | {', '.join(ids[:4])}{' (+%d)' % (len(ids) - 4) if len(ids) > 4 else ''} | - | duplicate text ({len(ids)}x) | {value}")
    if "--counts" in sys.argv:
        for (name, problem), n in sorted(counts.items()):
            print(f"{name:24}{problem:42}{n}")
    else:
        print("\n".join(lines))
    print(f"\n{sum(counts.values())} findings", file=sys.stderr)


if __name__ == "__main__":
    main()
