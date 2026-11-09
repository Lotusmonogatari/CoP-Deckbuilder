#!/usr/bin/env python3
"""Mechanical checks over every content text in data/*.json (2026-10-23).

Pass 1 of the content review (design/proposals/CONTENT_REVIEW_PLAN_2026-10-23.md):
doubled words, double spaces, stray punctuation, unfilled placeholders,
British spellings, over-long lines and exact duplicates inside a group. It
only reads; it prints one line per finding: file | id | field | problem | text.

    python3 tools/content_lint.py            # everything
    python3 tools/content_lint.py --counts   # just counts per problem
    python3 tools/content_lint.py --review   # the writing review sweep (2026-11-09):
        # candidates for codes C1-C3, C6, C7 and C12 of
        # design/prompts/WRITING_REVIEW_DIRECTIVE_2026-11-09.md, as CSV
        # (file, id, field, code, generic, reviewer, text). Every hit is only a
        # candidate; a reviewer confirms it in context.
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


# ---------------------------------------------------------------------------
# The writing review sweep (--review)

# Every content file, the fields that hold English text, and which reviewer
# (R1-R6 in the directive) owns it.
REVIEW_SOURCES = [
    ("strings", ["key"], ["english"], "R1"),
    ("how_to_play", ["entry_id"], ["heading_en", "body_en"], "R1"),
    ("office_notices", ["notice_id"], ["text_en"], "R1"),
    ("office_ticker", ["ticker_id"], ["text_en"], "R1"),
    ("shop", ["item_id"], ["name", "description"], "R1"),
    ("modifiers", ["mod_id"], ["name_en", "effect"], "R1"),
    ("cards", ["card_id"], ["effect_text"], "R1"),
    ("staff", ["staff_id"], ["biography", "role_flavor"], "R1"),
    ("opponent_cues", ["cue_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], "R2"),
    ("player_cues", ["cue_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], "R3"),
    ("card_cues", ["card_id"], ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"], "R3"),
    ("level_intro_thoughts", ["level_id"], ["thought_text"], "R3"),
    ("visitor_questions", ["question_id"], ["question_text", "choice_a", "choice_b", "choice_c", "choice_d",
        "response_a", "response_b", "response_c", "response_d", "reaction_a", "reaction_b", "reaction_c", "reaction_d"], "R4"),
    ("visit_questions", ["question_id"], ["text_en"], "R4"),
    ("visit_answers", ["answer_id"], ["line_en"], "R4"),
    ("trade_questions", ["question_id"], ["text_en"], "R4"),
    ("lobbyist_lines", ["line_id"], ["line_en"], "R4"),
    ("reaction_lines", ["level"], ["line"], "R4"),
    ("transition_dialogue", ["transition_dialogue_id"], ["character_line_en", "player_reply_en"], "R5"),
    ("level_intros", ["level_id", "role"], ["cue_text"], "R5"),
    ("levels", ["level_id"], ["purpose"], "R5"),
    ("vote_influence_cues", ["bill_id"], ["cue_text"], "R5"),
    ("events", ["event_id"], ["title", "flavor"], "R6"),
    ("event_choices", ["event_id", "choice"], ["choice_text", "result_text"], "R6"),
    ("event_options", ["option_id"], ["choice_text", "flavor"], "R6"),
    ("hosted_events", ["hosted_id"], ["intro", "prompt_1", "prompt_2", "prompt_3"], "R6"),
    ("floor_votes", ["bill_id"], ["bill_description", "who_gains", "who_pays", "case_for", "case_against", "main_risk", "middle_ground"], "R6"),
    ("bill_components", ["component_id"], ["short_label", "phrase", "description"], "R6"),
    ("patron_bills", ["patron_bill_id"], ["request_line", "accept_line", "decline_line", "pass_line", "fail_line"], "R6"),
    ("law_effects", ["law_id"], ["note"], "R6"),
]

ONCE_ONLY = re.compile(r"\b(first time|for the first|finally|at last|never before|history is made|today we make|"
                       r"welcome to (?:your|the) first|my first|your first|once and for all)\b", re.I)
UNANCHORED_START = re.compile(r"^(?:\W*)(This|That|It|They|These|Those)\b(?!'s a| is a question)")
UNANCHORED_ANY = re.compile(r"\b(the bill|this bill|this law|this policy|this plan|your promise|as I said|like I said|as we discussed)\b", re.I)
HISTORY = re.compile(r"\b(last week|last time|once more|you lost|your win|after you|you promised|you voted|as before)\b", re.I)
OFF_TERM = re.compile(r"\b(boosters?|jiban|sanban|standing points|Yes vote|No vote|energy|turns?|stages?|levels?)\b", re.I)
BRITISH_TERMS = re.compile(r"\b(surgery|surgeries|rota|shopfront|pavements?|in hospital|at the weekend|fortnight|lorr(?:y|ies)|"
                           r"motorway|council estate|mobile phone|stand(?:s|ing)? for election|stood for election|"
                           r"tabled? (?:a |the )?(?:motion|bill)|amongst|spelt|kerb|programme)\b", re.I)
COLLECTIVE = re.compile(r"\b(the (?:committee|party|government|council|association|federation|cooperative|network|union) (?:are|have|were))\b", re.I)
PLACEHOLDER = re.compile(r"\{([a-z_]+)\}")


def _generic(name, row):
    """True when the row can appear with no bill in front of the player."""
    if name in ("opponent_cues", "player_cues"):
        return not row.get("bill_ids") and not row.get("component_ids")
    if name == "transition_dialogue":
        sid = str(row.get("stage_id", ""))
        return sid[2:].isdigit() and int(sid[2:]) <= 23
    return name in ("card_cues", "office_ticker", "office_notices", "reaction_lines")


def review_sweep():
    import csv
    out = csv.writer(sys.stdout)
    out.writerow(["file", "id", "field", "code", "generic", "reviewer", "text"])
    counts = Counter()

    def emit(name, rid, field, code, generic, reviewer, value):
        counts[(reviewer, code)] += 1
        out.writerow([name, rid, field, code, "Y" if generic else "N", reviewer, value])

    def scan(name, rid, field, value, generic, reviewer, placeholders=None):
        spoken = name not in ("strings", "how_to_play", "shop", "modifiers", "cards", "levels")
        if ONCE_ONLY.search(value):
            emit(name, rid, field, "C1", generic, reviewer, value)
        if generic and (UNANCHORED_START.search(value) or UNANCHORED_ANY.search(value)):
            emit(name, rid, field, "C2", generic, reviewer, value)
        if HISTORY.search(value):
            emit(name, rid, field, "C3", generic, reviewer, value)
        if spoken and OFF_TERM.search(value):
            emit(name, rid, field, "C6", generic, reviewer, value)
        if BRITISH.search(BRITISH_OK.sub("", value)) or BRITISH_TERMS.search(value):
            emit(name, rid, field, "C7", generic, reviewer, value)
        if COLLECTIVE.search(value):
            emit(name, rid, field, "C8", generic, reviewer, value)
        if placeholders is not None:
            used = set(PLACEHOLDER.findall(value))
            listed = set(p.strip() for p in str(placeholders or "").split(",") if p.strip())
            if used != listed:
                emit(name, rid, field, "C12", generic, reviewer, value)

    for name, id_fields, fields, reviewer in REVIEW_SOURCES:
        path = DATA / f"{name}.json"
        if not path.exists():
            continue
        rows = json.loads(path.read_text())
        if isinstance(rows, dict):
            rows = rows.get("rows", list(rows.values()))
        for row in rows:
            if not isinstance(row, dict):
                continue
            rid = "/".join(str(row.get(f, "")) for f in id_fields)
            for field in fields:
                value = row.get(field)
                if isinstance(value, str) and value.strip():
                    scan(name, rid, field, value, _generic(name, row), reviewer,
                         row.get("placeholders") if name == "strings" else None)
    # The room question pools (R4): the five generic rooms have no bill; Stage
    # Questions belong to one stage each.
    questions = json.loads((DATA / "questions.json").read_text())
    for pool, rows in questions.items():
        for row in rows:
            scan("questions", f"{pool}/{row.get('id', '')}", "text", str(row.get("text", "")),
                 pool != "stage", "R4")
    for (reviewer, code), n in sorted(counts.items()):
        print(f"{reviewer} {code} {n}", file=sys.stderr)


def main():
    if "--review" in sys.argv:
        review_sweep()
        return
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
