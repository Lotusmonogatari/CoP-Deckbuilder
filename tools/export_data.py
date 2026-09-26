#!/usr/bin/env python3
"""
Turns the design workbook into the JSON files the game reads.

    python3 tools/export_data.py

Reads  design/CoP_Starter_Card_Stage_Data.xlsx
Writes data/*.json
Prints a validation report, and exits non-zero if there are errors.

WHY THIS EXISTS
---------------
The workbook is the source of truth for every number, name and rule in the
game. The game itself can't read .xlsx, so this script converts each tab into
a plain JSON file. Nothing in the game hardcodes content; it all comes from
these files.

HOW TO ADD A COLUMN
-------------------
Add it in the workbook, then add one line to the matching SHEETS entry below
saying what the column is called in the spreadsheet, what to call it in JSON,
and what kind of value it holds. That's it.

The validation at the bottom is deliberately the same set of checks that
DataDB.gd runs inside the game, so a problem gets caught here — at your desk,
with a readable message — rather than as a crash on a phone.
"""

import json
import re
import sys
import unicodedata
from pathlib import Path

try:
    import openpyxl
except ImportError:
    sys.exit(
        "This script needs the 'openpyxl' library to read .xlsx files.\n"
        "Install it with:  python3 -m pip install openpyxl"
    )

REPO_ROOT = Path(__file__).resolve().parent.parent
WORKBOOK = REPO_ROOT / "design" / "CoP_Starter_Card_Stage_Data.xlsx"
DATA_DIR = REPO_ROOT / "data"

# Cells that mean "no value here". The workbook uses a few different spellings
# of "not applicable", and the brief says to treat them all as empty and work
# the real value out from the module or committee data at runtime.
#
# "majority" is in this list on purpose: it's how the Stages tab writes the
# win threshold for a committee stage, where the real number depends on how
# many members that particular committee has. The engine works it out as
# floor(size / 2) + 1 at battle setup.
NULL_TOKENS = {"", "-", "—", "–", "varies", "majority", "n/a", "na", "tbd", "none", "?"}


# ---------------------------------------------------------------------------
# Column types
# ---------------------------------------------------------------------------
# Each column in the config below says what kind of value it holds:
#
#   "str"   plain text, kept as written
#   "id"    an identifier such as C01 or ST02 — text, but whitespace-trimmed
#           and required to be non-empty
#   "int"   a whole number
#   "num"   a number that may have decimals
#   "pct"   a share written as a fraction (0.3 means 30%) — kept as a fraction
#   "list"  a comma-separated list of IDs, e.g. "M03, M04" -> ["M03", "M04"]
#   "json"  a cell holding a JSON value, e.g. an intent pattern array
#
# Any type may be empty unless it is the sheet's ID column.


def normalise_header(text):
    """
    Makes header matching forgiving about invisible differences.

    Spreadsheets pick up non-breaking spaces, and the workbook mixes three
    different dash characters (-, –, —, and the maths minus −). None of that
    should stop a column being found, so we flatten it all before comparing.
    """
    if text is None:
        return ""
    text = unicodedata.normalize("NFKC", str(text))
    text = text.replace("−", "-").replace("–", "-").replace("—", "-")
    text = text.replace(" ", " ")
    return re.sub(r"\s+", " ", text).strip().lower()


def slugify(text):
    """'Party support: allied buff (>)' -> 'party_support_allied_buff'."""
    text = unicodedata.normalize("NFKC", str(text)).strip()
    text = re.sub(r"\s*\([^)]*\)\s*$", "", text)     # drop a trailing (note)
    text = re.sub(r"[^0-9A-Za-z]+", "_", text)
    return text.strip("_").lower()


# ---------------------------------------------------------------------------
# What to export, tab by tab
# ---------------------------------------------------------------------------
# "columns" is a list of (spreadsheet header, JSON key, type).
# "id_pattern" filters out the summary rows at the bottom of a tab: only rows
#     whose first column looks like a real ID are kept. Rows that are skipped
#     are listed in the report so a typo'd ID can't disappear silently.
# "drop_rows" does the same job for tabs whose first column isn't an ID.
# "optional" names columns that may not exist yet; they export as null and
#     raise a warning rather than an error.

SHEETS = {
    "Suits": {
        "out": "suits.json",
        "key": "element",
        "columns": [
            ("Element (canon)", "element", "id"),
            ("Suit (JP)", "suit_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Gloss", "gloss", "str"),
            ("Card Design Template", "card_design_template", "str"),
        ],
    },
    # Who the player can be (2026-09-26 pull — was data/player.json, written
    # by hand, until now). Reshaped below (fold_player()) into
    # {"protagonists": [...]}: the four meta columns fold into one
    # starting_meta dict per row, matching what DataDB._load_protagonists()
    # has always expected. No "default protagonist" column — the first row
    # is the default, the same fallback _load_protagonists() already uses
    # when data/player.json's own default_protagonist is missing or unknown.
    "Player": {
        "out": "player_raw.json",
        "key": "player_id",
        "id_pattern": r"^PC\d+$",
        "columns": [
            ("player_id", "player_id", "id"),
            ("name_en", "name_en", "str"),
            ("party", "party", "str"),
            ("blurb", "blurb", "str"),
            ("Constituency support", "starting_jiban", "int"),
            ("Reputation", "starting_kanban", "int"),
            ("Funds", "starting_yen", "int"),
            ("Party support", "starting_party_support", "int"),
            ("starting_xp", "starting_xp", "int"),
            ("Gender", "gender", "str"),
            ("Committee", "committee", "str"),
            ("Positioning", "positioning", "str"),
            ("Element 1", "element_1", "str"),
            ("Element 2", "element_2", "str"),
            ("Region", "region", "str"),
            ("District Name", "district_name", "str"),
            ("District Type", "district_type", "str"),
        ],
    },
    # The Office's own dynamic flavor lines (design proposal, 2026-09-26):
    # a notice shows when its one condition (a staff role hired/not-hired, or
    # a meta variable's value against a threshold) is true. See
    # OfficeNotices.gd for how a row is checked and CLAUDE.md for the schema.
    "Office Notices": {
        "out": "office_notices.json",
        "key": "notice_id",
        "id_pattern": r"^ON\d+$",
        "columns": [
            ("notice_id", "notice_id", "id"),
            ("slot", "slot", "str"),
            ("condition_type", "condition_type", "str"),
            ("condition_target", "condition_target", "str"),
            ("condition_op", "condition_op", "str"),
            ("condition_value", "condition_value", "num"),
            ("text_en", "text_en", "str"),
        ],
    },
    # Every line the game says to the player. Cameron's to reword; the code
    # asks for a Key and never holds a sentence of its own. A key the code
    # asks for and this tab does not have is an ERROR, checked below, so a
    # typo is caught here rather than appearing on screen mid-playtest.
    # The five spoken lines a card can say when it is played. One row per
    # card, joined to Cards by Card ID. The word-count columns beside them
    # are Cameron's own check and are not exported.
    "Flavor Text": {
        "out": "card_cues.json",
        "key": "card_id",
        "id_pattern": r"^C\d+$",
        "columns": [
            ("Card ID", "card_id", "id"),
            ("Cue 1", "cue_1", "str"),
            ("Cue 2", "cue_2", "str"),
            ("Cue 3", "cue_3", "str"),
            ("Cue 4", "cue_4", "str"),
            ("Cue 5", "cue_5", "str"),
        ],
    },
    # Opponent Cues: what an opponent might say on their turn, drawn instead
    # of the narration sentence when a line exists (scripts/ui/OpponentCues.gd).
    # A row with no Opponent ID is the general pool every opponent with that
    # Suit draws from for that Verb; a row naming one or more opponents is a
    # bespoke line for them only, checked first, never blended with the
    # general pool. Not in this workbook pull yet (2026-09-24) — the feature
    # is new and Cameron has only seen a separate draft tab.
    "Opponent Cues": {
        "out": "opponent_cues.json",
        "key": "cue_id",
        "id_pattern": r"^OC\d+$",
        "optional_sheet": True,
        "columns": [
            ("Cue ID", "cue_id", "id"),
            ("Suit", "suit", "str"),
            ("Verb", "verb", "str"),
            # Blank = the general pool for this Suit; "OP03" or "OP03; OP07"
            # = a bespoke line for those opponents only.
            ("Opponent ID", "opponent_ids", "id_list"),
            ("Cue 1", "cue_1", "str"),
            ("Cue 2", "cue_2", "str"),
            ("Cue 3", "cue_3", "str"),
            ("Cue 4", "cue_4", "str"),
            ("Cue 5", "cue_5", "str"),
        ],
    },
    # Press Questions: 20 questions for the press conference stage type, each graded
    # S / M / W per suit. Reshaped below into one questions.json keyed by
    # stage type, so a stage draws from a pool rather than naming its own.
    "Press Questions": {
        "out": "q_press.json",
        "key": "q_id",
        "id_pattern": r"^[A-Z]\d+$",
        "columns": [
            ("Q ID", "q_id", "id"),
            ("Question", "text", "str"),
            ("Theme", "theme", "str"),
            ("Earnest", "earnest", "str"),
            ("Emotional", "emotional", "str"),
            ("Appeal", "appeal", "str"),
            ("Data Driven", "data_driven", "str"),
            ("Divisive", "divisive", "str"),
            ("Duplicitous", "duplicitous", "str"),
        ],
    },
    # Town Hall Questions: 20 questions for the town hall stage type, each graded
    # S / M / W per suit. Reshaped below into one questions.json keyed by
    # stage type, so a stage draws from a pool rather than naming its own.
    "Town Hall Questions": {
        "out": "q_town_hall.json",
        "key": "q_id",
        "id_pattern": r"^[A-Z]\d+$",
        "columns": [
            ("Q ID", "q_id", "id"),
            ("Question", "text", "str"),
            ("Theme", "theme", "str"),
            ("Earnest", "earnest", "str"),
            ("Emotional", "emotional", "str"),
            ("Appeal", "appeal", "str"),
            ("Data Driven", "data_driven", "str"),
            ("Divisive", "divisive", "str"),
            ("Duplicitous", "duplicitous", "str"),
        ],
    },
    # Lobbyist Questions: 20 questions for the lobbyist meeting stage type, each graded
    # S / M / W per suit. Reshaped below into one questions.json keyed by
    # stage type, so a stage draws from a pool rather than naming its own.
    "Lobbyist Questions": {
        "out": "q_lobbyist.json",
        "key": "q_id",
        "id_pattern": r"^[A-Z]\d+$",
        "columns": [
            ("Q ID", "q_id", "id"),
            ("Question", "text", "str"),
            ("Theme", "theme", "str"),
            ("Earnest", "earnest", "str"),
            ("Emotional", "emotional", "str"),
            ("Appeal", "appeal", "str"),
            ("Data Driven", "data_driven", "str"),
            ("Divisive", "divisive", "str"),
            ("Duplicitous", "duplicitous", "str"),
        ],
    },
    # Study Session Questions: 20 questions for the policy study stage type, each graded
    # S / M / W per suit. Reshaped below into one questions.json keyed by
    # stage type, so a stage draws from a pool rather than naming its own.
    "Study Session Questions": {
        "out": "q_study_session.json",
        "key": "q_id",
        "id_pattern": r"^[A-Z]\d+$",
        "columns": [
            ("Q ID", "q_id", "id"),
            ("Question", "text", "str"),
            ("Theme", "theme", "str"),
            ("Earnest", "earnest", "str"),
            ("Emotional", "emotional", "str"),
            ("Appeal", "appeal", "str"),
            ("Data Driven", "data_driven", "str"),
            ("Divisive", "divisive", "str"),
            ("Duplicitous", "duplicitous", "str"),
        ],
    },
    # Media Ambush Questions: 20 questions for the media ambush stage type, each graded
    # S / M / W per suit. Reshaped below into one questions.json keyed by
    # stage type, so a stage draws from a pool rather than naming its own.
    "Media Ambush Questions": {
        "out": "q_media_ambush.json",
        "key": "q_id",
        "id_pattern": r"^[A-Z]\d+$",
        "columns": [
            ("Q ID", "q_id", "id"),
            ("Question", "text", "str"),
            ("Theme", "theme", "str"),
            ("Earnest", "earnest", "str"),
            ("Emotional", "emotional", "str"),
            ("Appeal", "appeal", "str"),
            ("Data Driven", "data_driven", "str"),
            ("Divisive", "divisive", "str"),
            ("Duplicitous", "duplicitous", "str"),
        ],
    },
    # Which organisation cares about each question theme. A DRAFT: Claude
    # proposed the mapping and Cameron corrects it in the workbook. The Why
    # column is the reasoning, so a wrong row is obvious without reading the
    # questions. Only booster IDs that exist may be used — checked below.
    "Question Themes": {
        "out": "question_themes.json",
        "key": "theme",
        "columns": [
            ("Theme", "theme", "id"),
            # "BO01" or "BO01; BO02" — a strong answer on this theme can
            # please more than one organisation at once.
            ("Organisation", "pleases_boosters", "id_list"),
            ("Why (Claude's reasoning - correct freely)", "why", "str"),
        ],
    },
    "Text": {
        "out": "strings.json",
        "key": "key",
        "columns": [
            ("Key", "key", "id"),
            ("Where", "where", "str"),
            ("English", "english", "str"),
            ("Placeholders", "placeholders", "str"),
            ("Notes", "notes", "str"),
        ],
    },
    "Segments": {
        "out": "segments.json",
        "key": "segment_id",
        "id_pattern": r"^SG\d+$",
        "optional": ["Initial Favorability %"],
        "columns": [
            ("Segment ID", "segment_id", "id"),
            ("Segment (EN)", "name_en", "str"),
            ("Segment (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Description", "description", "str"),
            # Stored 0-100 (a percent), not a 0-1 fraction like the "pct"
            # columns elsewhere, since the workbook writes it as a whole number.
            ("Initial Favorability %", "initial_favorability_pct", "num"),
        ],
    },
    "Stages": {
        "out": "stages.json",
        "key": "stage_id",
        "id_pattern": r"^ST\d+$",
        # 2026-09-24: the "living rules set" columns proposed in
        # design/proposals/stage_rules_columns.md. Not in the workbook yet —
        # optional so their absence is a warning, not an error — but the
        # engine already reads every one of them where a stage carries it,
        # falling back to its old hardcoded behaviour where it does not.
        "optional": [
            "Bar Model", "Energy Mode", "Energy Pool", "Sequence Mode",
            "Opponent Count", "Question Pool", "Reputation Affects Start",
            "Reveal In Briefing", "Loss Ends Level",
        ],
        "columns": [
            ("Stage ID", "stage_id", "id"),
            ("Stage (EN)", "name_en", "str"),
            ("Stage (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Mode", "mode", "str"),
            ("Bar unit", "bar_unit", "str"),
            # "Numerical" / "Members" etc — describes how the bar reads, not
            # a starting value. Player/Opp start below carry the real numbers.
            ("Bar value", "bar_value_kind", "str"),
            ("Bar max", "bar_max", "int"),
            ("Win threshold", "win_threshold", "int"),
            ("Win %", "win_pct", "num"),
            ("Turn limit", "turn_limit", "int"),
            ("持ち時間 / turn (energy)", "energy_per_turn", "int"),
            ("Hand size", "hand_size", "int"),
            ("失言 gaffe limit", "gaffe_limit", "int"),
            ("Player start", "player_start", "int"),
            ("Opp start", "opp_start", "int"),
            ("% Press", "pct_press", "pct"),
            ("% Party Members", "pct_party_members", "pct"),
            ("% Constituents", "pct_constituents", "pct"),
            ("% Donors", "pct_donors", "pct"),
            ("% Bureaucrats", "pct_bureaucrats", "pct"),
            ("% Other", "pct_other", "pct"),
            ("Segment check", "segment_check", "num"),
            ("Favored suit", "favored_suit", "str"),
            ("Win ΔJiban", "win_delta_jiban", "int"),
            ("Win ΔYen", "win_delta_yen", "int"),
            ("Win ΔReputation", "win_delta_reputation", "int"),
            ("Win ΔXP", "win_delta_xp", "int"),
            ("Win ΔParty support", "win_delta_party_support", "int"),
            ("Loss ΔJiban", "loss_delta_jiban", "int"),
            ("Loss ΔYen", "loss_delta_yen", "int"),
            ("Loss ΔReputation", "loss_delta_reputation", "int"),
            ("Loss ΔXP", "loss_delta_xp", "int"),
            ("Loss ΔParty support", "loss_delta_party_support", "int"),
            # See design/proposals/stage_rules_columns.md for what each of
            # these replaces and the full default table for every existing
            # stage. Blank on a row is a deliberate "use the old hardcoded
            # rule for this one" — not an error.
            ("Bar Model", "bar_model", "str"),
            ("Energy Mode", "energy_mode", "str"),
            ("Energy Pool", "energy_pool", "int"),
            ("Sequence Mode", "sequence_mode", "str"),
            ("Opponent Count", "opponent_count", "range"),
            ("Question Pool", "question_pool", "str"),
            ("Reputation Affects Start", "reputation_affects_start", "str"),
            # Blank means "Yes" — a stage tells the player what is coming
            # unless it is explicitly marked to spring it on them instead.
            ("Reveal In Briefing", "reveal_in_briefing", "str"),
            # Blank means "Yes" — losing a stage ends the level, the game's
            # long-standing default. "No" is for a stage whose threshold is
            # only a bonus/penalty switch, not a stop sign: a press
            # conference or a media ambush that runs out of turns should
            # still apply its loss deltas, but the level goes on to the
            # next stage rather than sending the player back to the Office.
            ("Loss Ends Level", "loss_ends_level", "str"),
        ],
    },
    "Cards": {
        "out": "cards.json",
        "key": "card_id",
        "id_pattern": r"^C\d+$",
        # The card sheet was replaced wholesale on 2026-09-21 with Cameron's
        # 54-card slate. Gone with it: "Upgrade (+)" (the game has no upgrade
        # mechanic, so every card stands on its printed values), and the
        # Power Score / Power per Cost / Balance flag columns, which were
        # the balancing model's working-out rather than card data. They live
        # in design/CoP_Cards.xlsx if the model is ever revisited.
        #
        # "XP to unlock" is optional: the economy is being priced by
        # playtest rather than by the sheet, so a missing column is fine.
        "optional": ["XP to unlock", "Special", "Special value", "Special note"],
        "columns": [
            ("Card ID", "card_id", "id"),
            ("Name (EN)", "name_en", "str"),
            ("Name (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Suit (Element)", "suit", "str"),
            ("Suit (JP)", "suit_jp", "str"),
            ("Type", "type", "str"),
            ("Cost (持ち時間)", "cost", "int"),
            ("Self +", "self_plus", "int"),
            ("Opp −", "opp_minus", "int"),
            ("Guard", "guard", "int"),
            ("Draw", "draw", "int"),
            ("Gaffe +/−", "gaffe", "int"),
            ("Target segment", "target_segment", "str"),
            ("Effect text", "effect_text", "str"),
            ("Tier", "tier", "str"),
            ("XP to unlock", "xp_to_unlock", "int"),
            ("Special", "special", "str"),
            ("Special value", "special_value", "num"),
            ("Special note", "special_note", "str"),
        ],
    },
    "Modifiers": {
        "out": "modifiers.json",
        "key": "mod_id",
        "id_pattern": r"^M\d+$",
        "columns": [
            ("Mod ID", "mod_id", "id"),
            ("Name (EN)", "name_en", "str"),
            ("Name (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            # One or more SGxx (Segments) / BOxx (Boosters) IDs — "SG03" or
            # "SG03; BO04" — check each one's own prefix before looking it
            # up. Not every modifier has a trigger at all.
            ("Trigger segment or booster", "trigger_segment_or_booster", "id_list"),
            # Written as a whole number (15 means 15%), unlike the Stages
            # tab's "pct" columns — "num" here so the fraction warning
            # doesn't fire on every row.
            ("Trigger min %", "trigger_min_pct", "num"),
            ("Effect", "effect", "str"),
            ("Reputation cost to activate", "reputation_cost", "int"),
            ("Jiban cost to activate", "jiban_cost", "int"),
            ("Funds (Yen) cost to activate", "funds_cost", "int"),
            # Effect is display-only prose (CLAUDE.md §6). Effect Type is the
            # closed dispatch enum; read Target/Value per the type. See the
            # Claude Code data guide, Part 2.1.
            ("Effect Type", "effect_type", "str"),
            ("Effect Target", "effect_target", "str"),
            ("Effect Value", "effect_value", "num"),
        ],
    },
    "Boosters": {
        "out": "boosters.json",
        "key": "booster_id",
        "id_pattern": r"^BO\d+$",
        "columns": [
            ("Booster ID", "booster_id", "id"),
            ("Organization (EN)", "name_en", "str"),
            ("Organization (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Tier", "tier", "str"),
            ("Linked modifiers", "linked_modifiers", "list"),
        ],
    },
    # National Assembly Floor Voting (ST23, 2026-09-26): the six real-world
    # parties, their official colours, and (once Cameron fills it in) which
    # Opponents-tab row is each one's leader for that stage's portrait and
    # cue. Party Name must match the free-text "Party" column on Opponents/
    # Player exactly — checked below.
    "Parties": {
        "out": "parties.json",
        "key": "party_id",
        "id_pattern": r"^PT\d+$",
        "columns": [
            ("Party ID", "party_id", "id"),
            ("Party Name", "name", "str"),
            ("R", "r", "int"),
            ("G", "g", "int"),
            ("B", "b", "int"),
            # Blank until Cameron casts one — never guessed at (CLAUDE.md
            # §4: never invent canon characters). A blank leader is a
            # generic placeholder on screen, the same bargain every other
            # missing-art/missing-cast slot in this project gets.
            ("Leader Opp ID", "leader_opp_id", "str"),
            # The real Sep-18 session of parliament (2026-09-26, Cameron —
            # an earlier May-18 snapshot he sent was a prior, superseded
            # session). Fixed per party across every bill, not re-rolled per
            # vote — see design/FLOOR_VOTE_PROMPT.md's own open question,
            # now answered. Sums to CLAUDE.md §4's 101 seats.
            ("Seats", "seats", "int"),
        ],
    },
    # One row per level that has a Floor Vote stage — the bill's own name,
    # its scroll text, and the favorability swing each disposition earns
    # once the vote resolves. Most levels have none; export_data.py never
    # requires ST23 to appear anywhere just because a bill row exists (and
    # vice versa) — see the cross-check below.
    "Floor Vote Bills": {
        "out": "floor_vote_bills_raw.json",
        "key": "level_id",
        "id_pattern": r"^LV\d+$",
        "columns": [
            ("Level ID", "level_id", "id"),
            ("Bill Name (EN)", "bill_name", "str"),
            ("Bill Description (EN)", "bill_description", "str"),
            ("Favorability Delta (Supportive)", "favorability_delta_supportive", "int"),
            ("Favorability Delta (Opposed)", "favorability_delta_opposed", "int"),
            ("Favorability Delta (Neutral)", "favorability_delta_neutral", "int"),
        ],
    },
    # Six rows per bill above (one per party) — folded into that bill's own
    # "positions" list by fold_floor_votes() below, the same
    # bill-plus-positions shape Question Themes folds into each question.
    "Floor Vote Party Positions": {
        "out": "floor_vote_positions_raw.json",
        # No single-column unique key — one row per (Level ID, Party ID)
        # pair, folded into its bill's own "positions" list below.
        "columns": [
            ("Level ID", "level_id", "str"),
            ("Party ID", "party_id", "str"),
            ("Votes Yes", "votes_yes", "int"),
            ("Votes No", "votes_no", "int"),
            ("Votes Abstain", "votes_abstain", "int"),
            ("Disposition", "disposition", "str"),
            ("Cue Text", "cue_text", "str"),
        ],
    },
    "Opponents": {
        "out": "opponents.json",
        "key": "opp_id",
        "id_pattern": r"^OP\d+$",
        "columns": [
            ("Opp ID", "opp_id", "id"),
            ("Name", "name", "str"),
            # "N/A" for almost everyone — a formal post, e.g. "Minister of
            # Finance; Chair of the Committee on Finance" or "Prime
            # Minister; Leader of the Yezo Heritage Party", "; "-joined
            # when someone holds more than one at once (2026-09-26 pull).
            ("Title", "title", "str"),
            ("Gender", "gender", "str"),
            ("Party", "party", "str"),
            ("Party Acronym", "party_acronym", "str"),
            # A booster_id (2026-09-26 pull — restructured from free-text
            # committee names, which moved to the new Role column below).
            # Checked against boosters.json below the table.
            ("Affiliation", "affiliation", "str"),
            # Free text: a committee name for most MPs, or a plain role like
            # "Journalist", "Constituent", "Student" for the non-MP opponents
            # a Non-combat stage draws (Town Hall, Media Ambush, Lobbyist
            # Meeting). Was folded into Affiliation before 2026-09-26.
            ("Role", "role", "str"),
            # "; "-separated STxx list — an opponent can appear in several
            # stages. A committee stage's roster is every opponent whose
            # Stage list names that STxx (Cameron, 2026-09-22); there is no
            # separate committee roster tab any more.
            ("Stage", "stages", "stage_list"),
            ("Suit 1", "suit_1", "str"),
            ("Suit 2", "suit_2", "str"),
            ("Suit 3", "suit_3", "str"),
            # Range-strings: "min-max" rolls between them, a bare number is
            # both min and max, and "0" is the hard sentinel "never uses
            # this move" (not a move that always rolls zero). See the data
            # guide, Part 2.3.
            ("Intent Pattern Range for Attack", "intent_attack_range", "range"),
            ("Intent Pattern Range for Gain", "intent_gain_range", "range"),
            ("Intent Pattern Range for Block", "intent_block_range", "range"),
        ],
    },
    # Levels replace what used to be called "Modules" — Cameron's term for a
    # sequence of linked stages is now "Level" throughout (2026-09-22);
    # "module" survives only as a description of how a level is built, not
    # as data. There's no separate Committee tab any more either: a
    # committee-stage roster is read off the Opponents tab instead (every
    # opponent whose Stage list names that STxx).
    # 2026-09-22: Cameron confirmed the workbook's 30-row LV01-30 table is now
    # the real level data. His old hand-written levels.json (LV01-06, nested
    # stage/opponent objects) was a draft and has been retired — this tab now
    # writes straight to data/levels.json.
    "Levels": {
        "out": "levels.json",
        "key": "level_id",
        "id_pattern": r"^LV\d+$",
        "columns": [
            ("Level ID", "level_id", "id"),
            ("Level Description", "description", "str"),
            ("Cooldown Period  (# of other levels to play before this level is available to play again)",
             "cooldown", "int"),
            ("Level Tier", "tier", "int"),
            ("Cost in XP to Unlock if Policy Research Assistant is Vacant", "unlock_cost_vacant", "int"),
            ("Cost in XP to Unlock if Policy Research Assistant is Tier 0", "unlock_cost_tier_0", "int"),
            ("Cost in XP to Unlock if Policy Research Assistant is Tier 1", "unlock_cost_tier_1", "int"),
            ("Cost in XP to Unlock if Policy Research Assistant is Tier 2", "unlock_cost_tier_2", "int"),
            ("Stage ID for Part 1", "stage_1", "str"),
            ("Stage ID for Part 2", "stage_2", "str"),
            ("Stage ID for Part 3", "stage_3", "str"),
            ("Stage ID for Part 4", "stage_4", "str"),
            ("Stage ID for Part 5", "stage_5", "str"),
            ("Stage ID for Part 6", "stage_6", "str"),
            ("Stage ID for Part 7", "stage_7", "str"),
            ("Stage ID for Part 8", "stage_8", "str"),
            ("Stage ID for Part 9", "stage_9", "str"),
            ("Stage ID for Part 10", "stage_10", "str"),
            ("Bonus  Win Range ΔJiban", "bonus_win_range_jiban", "range"),
            ("Bonus  Win Range ΔYen", "bonus_win_range_yen", "range"),
            ("Bonus  Win Range ΔReputation", "bonus_win_range_reputation", "range"),
            ("Bonus  Win Range ΔXP", "bonus_win_range_xp", "range"),
            ("Bonus  Win Range ΔParty support", "bonus_win_range_party_support", "range"),
            ("Win ΔBO01", "win_delta_bo01", "range"),
            ("Win ΔBO02", "win_delta_bo02", "range"),
            ("Win ΔBO03", "win_delta_bo03", "range"),
            ("Win ΔBO04", "win_delta_bo04", "range"),
            ("Win ΔBO05", "win_delta_bo05", "range"),
            ("Win ΔBO06", "win_delta_bo06", "range"),
            ("Win ΔBO07", "win_delta_bo07", "range"),
            ("Win ΔBO08", "win_delta_bo08", "range"),
            ("Win ΔBO09", "win_delta_bo09", "range"),
            ("Win ΔBO10", "win_delta_bo10", "range"),
            ("Win ΔBO11", "win_delta_bo11", "range"),
            ("Win ΔBO12", "win_delta_bo12", "range"),
            ("Win ΔBO13", "win_delta_bo13", "range"),
            ("Win ΔBO14", "win_delta_bo14", "range"),
            ("Win ΔBO15", "win_delta_bo15", "range"),
            ("Win ΔBO16", "win_delta_bo16", "range"),
        ],
    },
    # 3 roles (Policy Research Assistant, Media Spokesperson, District
    # Representative) x 7 starting/upgrade tier configs each. The Reward
    # columns are free text ("+2 for BO05; +2 for SG01", or "N/A") — parsed
    # into a list of {delta, target} at export time, per the data guide §2.5.
    "Staff": {
        "out": "staff.json",
        "key": "staff_id",
        "id_pattern": r"^SF\d+$",
        "columns": [
            ("Staff ID", "staff_id", "id"),
            ("Staff Role", "role", "str"),
            ("Name", "name", "str"),
            ("Starting Tier for Staff Role", "starting_tier", "int"),
            ("Highest Upgradable Tier for Staff Role", "highest_tier", "int"),
            ("Hiring Cost from Funds (Yen)", "hiring_cost_yen", "int"),
            ("Cost to Upgrade from Tier 0 to Tier 1 from Funds (Yen)", "upgrade_cost_0_to_1_yen", "int"),
            ("Cost to Upgrade from Tier 1 to Tier 2 from Funds (Yen)", "upgrade_cost_1_to_2_yen", "int"),
            ("Firing Cost from Funds (Yen)", "firing_cost_yen", "int"),
            ("Staff Role Tier 0 Reward", "tier_0_reward", "reward_list"),
            ("Staff Role Tier 1 Reward", "tier_1_reward", "reward_list"),
            ("Staff Role Tier 2 Reward", "tier_2_reward", "reward_list"),
        ],
    },
    # Bonus Condition 1/2 are free text in three shapes (a staff-tier gate,
    # an unlock gate, a stacking-buff rule) plus literal "N/A" — not a fixed
    # grammar like the reward/range fields, so they export as-is (data guide
    # §2.6). Classifying them is engine work, not exporter work.
    "Shop": {
        "out": "shop.json",
        "key": "item_id",
        "id_pattern": r"^SH\d+$",
        # 2026-09-25: "Grants" is optional — nothing in the workbook sets it
        # yet, so the whole shop is still an existing-code gap (no purchase
        # path exists, and Description is display-only prose, same rule as
        # Modifiers' Effect column — never parsed). Blank on a row means
        # "not structured yet", the same "optional means Cameron hasn't
        # gotten to it" convention as the Stages living-rules columns.
        "optional": ["Grants", "Icon", "Use In Office", "Use In Stage", "Duration",
                     "Uses Per Turn", "Stack Cap", "Purchase Limit", "Player Choice",
                     "Bonus 1 Role", "Bonus 1 Min Tier", "Bonus 1 Amount",
                     "Bonus 2 Role", "Bonus 2 Min Tier", "Bonus 2 Amount",
                     "Bonus 3 Role", "Bonus 3 Min Tier", "Bonus 3 Amount", "Card Tier",
                     "Level Tier", "Unlocks Recruitment Tier", "Funds Cap Increase"],
        "columns": [
            ("Item ID", "item_id", "id"),
            ("Item Name", "name", "str"),
            ("Description", "description", "str"),
            ("Purchase Cost from XP", "cost_xp", "int"),
            ("Purchase Cost from Funds (Yen)", "cost_yen", "int"),
            ("Bonus Condition 1", "bonus_condition_1", "str"),
            ("Bonus Condition 2", "bonus_condition_2", "str"),
            # Same "BO05 +1; SG02 -3; M12" shape as a Visitor's Reward
            # column (target_delta_list) — what buying (or being granted)
            # this item actually DOES. A target naming another SHxx is
            # allowed by this column's own format, but GameState refuses to
            # chase it at apply time (a recursion guard, not an export-time
            # one) — an item cannot grant itself or another item, only
            # boosters/modifiers/segments. An item with no structured effect
            # yet (every real row today) still shows its Description prose;
            # it just has nothing to apply.
            ("Grants", "grants", "target_delta_list"),
            # The inventory columns (design/proposals/inventory.md, Cameron
            # 2026-09-25) — every one of them per item, so what an item can
            # do and where is a workbook edit, never a code change.
            #   Icon            file name in assets/icons/, without ".png"
            #   Use In Office   Yes/No: can the Use button work in the Office
            #   Use In Stage    Yes/No: can it work during a stage
            #   Duration        Stage or Level: how long its stage effects last
            #   Uses Per Turn   how often it may be used in one turn (blank = 1)
            #   Stack Cap       most the player may hold (blank = no cap)
            #   Purchase Limit  most that may be bought per level (blank = no
            #                   limit); resets when a level concludes
            ("Icon", "icon", "str"),
            ("Use In Office", "use_in_office", "str"),
            ("Use In Stage", "use_in_stage", "str"),
            ("Duration", "duration", "str"),
            ("Uses Per Turn", "uses_per_turn", "int"),
            ("Stack Cap", "stack_cap", "int"),
            ("Purchase Limit", "purchase_limit", "int"),
            # 2026-09-25 follow-up. "Player Choice": Yes means Use asks
            # WHICH of Grants' pool/tier the effect lands on (SH25/26,
            # "player-selected" in their own Description) instead of picking
            # one at random (SH01-03, "randomly-selected"). "Bonus N Role/
            # Min Tier/Amount": an extra delta layered onto the base Grants
            # effect once the named Staff role (Ledger.STAFF_ROLES) is hired
            # at or above that tier — SH01-03 work without the role; having
            # it adds this on top. Each row's Amount is what THAT row adds
            # beyond a lower row already counted, not the running total (see
            # Items.staff_bonus_rows()'s own comment). Up to 3 rows, blank
            # Role means that row is unused.
            ("Player Choice", "player_choice", "str"),
            ("Bonus 1 Role", "bonus_1_role", "str"),
            ("Bonus 1 Min Tier", "bonus_1_min_tier", "int"),
            ("Bonus 1 Amount", "bonus_1_amount", "int"),
            ("Bonus 2 Role", "bonus_2_role", "str"),
            ("Bonus 2 Min Tier", "bonus_2_min_tier", "int"),
            ("Bonus 2 Amount", "bonus_2_amount", "int"),
            ("Bonus 3 Role", "bonus_3_role", "str"),
            ("Bonus 3 Min Tier", "bonus_3_min_tier", "int"),
            ("Bonus 3 Amount", "bonus_3_amount", "int"),
            # 2026-09-26, Cameron: SH27-29 ("Purchase Random Tier N Card")
            # were bought-then-unusable — Use In Office/Stage both blank
            # ("No") and Grants empty, so nothing about buying one did
            # anything, matching their own Description's "takes effect
            # immediately": they were never meant to sit in the inventory
            # and be Used at all. This is that immediate effect, in the
            # same spirit as Grants but not shaped like it (a random
            # UNOWNED card of a tier is not a standing delta) — blank on
            # every other row, 1/2/3 on SH27/28/29.
            ("Card Tier", "card_tier", "int"),
            # 2026-09-26 follow-up, same reason and same shape as Card Tier:
            # SH13/14 ("Unlock Tier N Level") and SH19 ("Increase Office
            # Funds Cap") were the same kind of bought-then-unusable gap.
            # SH18 ("Unlock New Staff Recruitment Tier") described a gate
            # that did not exist anywhere in the Staff system yet — Cameron
            # settled it as "a candidate's own highest_tier must be at or
            # below GameState.staff_recruitment_tier", raised by 1 here.
            ("Level Tier", "level_tier", "int"),
            ("Unlocks Recruitment Tier", "unlocks_recruitment_tier", "str"),
            ("Funds Cap Increase", "funds_cap_increase", "int"),
        ],
    },
    # 2026-09-25: replaces the old 2-choice/raw-delta sketch (CLAUDE.md's
    # original §8 Office Hours brief). Cameron's real design: multiple
    # choice, several possible questions per visitor (the linked "Visitor
    # Questions" tab below), and rewards/penalties that move a Booster
    # standing, grant a Modifier, or grant a Shop item — not raw meta-
    # variable deltas. See design/proposals/office_hours.md.
    "Visitors": {
        "out": "visitors.json",
        "key": "visitor_id",
        "id_pattern": r"^VI\d+$",
        "optional_sheet": True,
        "columns": [
            ("Visitor ID", "visitor_id", "id"),
            ("Visitor (EN)", "name_en", "str"),
            ("Visitor (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Role", "title", "str"),
            # Same convention as Opponents' own "Stage" column: which STxx
            # this visitor can be drawn for.
            ("Stage", "stages", "stage_list"),
            # "BO05 +1; M12; SH04" — a booster standing bump, a modifier
            # grant, a shop item grant, any mix, in one cell. Which kind
            # each target is comes from its own ID prefix at runtime
            # (RewardTargets.kind_of()), not from a separate column.
            ("Reward", "reward", "target_delta_list"),
            # Same format, applied on a wrong answer instead of a right one
            # — typically a negative delta against a booster ("BO05 -2"),
            # not a Sanban meta-variable hit.
            ("Penalty", "penalty", "target_delta_list"),
        ],
    },
    # One row = one possible exchange; many rows can share a Visitor ID —
    # the "several questions per visitor" shape, resolved by drawing one at
    # battle setup the same way BattleEngine._draw_questions() already
    # draws from a stage's question pool.
    "Visitor Questions": {
        "out": "visitor_questions.json",
        "key": "question_id",
        "id_pattern": r"^VQ\d+$",
        "optional_sheet": True,
        "columns": [
            ("Question ID", "question_id", "id"),
            # "VI01" or "VI01; VI02" — one question several visitors can
            # equally ask, not one row per visitor.
            ("Visitor ID", "visitor_ids", "id_list"),
            ("Question text", "question_text", "str"),
            ("Choice A", "choice_a", "str"),
            ("Choice B", "choice_b", "str"),
            ("Choice C", "choice_c", "str"),
            ("Choice D", "choice_d", "str"),
            ("Correct Choice", "correct_choice", "str"),
            ("Response - Right", "response_right", "str"),
            ("Response - Wrong", "response_wrong", "str"),
            ("Reaction - Right", "reaction_right", "str"),
            ("Reaction - Wrong", "reaction_wrong", "str"),
        ],
    },
    # "Fed by" and the Critical tier are gone from this tab — the 4 Sanban
    # variables now carry only one consequence threshold on each side.
    "Sanban": {
        "out": "sanban.json",
        "key": "variable",
        "drop_rows": set(),
        "columns": [
            ("Variable", "name_en", "str"),
            ("JP", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Start", "start", "int"),
            ("Min", "min", "int"),
            ("Max", "max", "int"),
            ("Low threshold", "low_threshold", "int"),
            ("Low consequence", "low_consequence", "str"),
            ("HighThreshold", "high_threshold", "int"),
            ("High consequence", "high_consequence", "str"),
        ],
    },
}

# Tabs that are documentation, a derived view, or a production tracker.
# They are deliberately not exported; the game never reads them.
NOT_EXPORTED = {
    "README": "documentation",
    "Tone Guide": "writing guidance for the cues, for Cameron not the game",
    "CardStage": "a derived view — the engine recomputes this from cards + affinity",
    "Assets": "art production tracker, not game data",
}


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

class Report:
    """Collects everything worth telling Cameron, then prints it in one block."""

    def __init__(self):
        self.errors = []    # must be fixed — the game will not work
        self.warnings = []  # known gaps — the game works but something is missing
        self.notes = []     # things that happened, for reassurance

    def error(self, where, message):
        self.errors.append(f"{where}: {message}")

    def warn(self, where, message):
        self.warnings.append(f"{where}: {message}")

    def note(self, message):
        self.notes.append(message)

    def print(self):
        print("\n" + "=" * 70)
        print("DATA VALIDATION REPORT")
        print("=" * 70)

        for line in self.notes:
            print(f"  {line}")

        if self.warnings:
            print(f"\n  {len(self.warnings)} warning(s) — the game runs, but these are gaps:")
            for line in self.warnings:
                print(f"    ! {line}")

        if self.errors:
            print(f"\n  {len(self.errors)} ERROR(S) — these must be fixed in the workbook:")
            for line in self.errors:
                print(f"    X {line}")
        else:
            print("\n  No errors. Every cross-reference in the workbook resolves.")

        print("=" * 70 + "\n")


# ---------------------------------------------------------------------------
# Reading cells
# ---------------------------------------------------------------------------

def is_null(value):
    if value is None:
        return True
    return str(value).strip().lower() in NULL_TOKENS


def coerce(value, kind, where, report):
    """Turns one spreadsheet cell into the right kind of JSON value."""
    if is_null(value):
        return None

    text = str(value).strip()

    if kind in ("str", "id"):
        return text

    if kind == "list":
        # "M03, M04" -> ["M03", "M04"]
        return [part.strip() for part in text.split(",") if part.strip()]

    if kind in ("stage_list", "id_list"):
        # "ST10; ST01; ST02; ST06" -> ["ST10", "ST01", "ST02", "ST06"]. Same
        # split either name: "stage_list" predates this one and several
        # columns already use it, so it stays rather than being renamed.
        return [part.strip() for part in text.split(";") if part.strip()]

    if kind == "range":
        # The range-string convention shared by Levels and Opponents (data
        # guide §2.3): "min-max" rolls between them, a bare number is both
        # min and max, and a bare "0" is the hard sentinel "never happens" —
        # not a roll that always comes out zero — so it exports as null,
        # the same as N/A.
        stripped = text.rstrip("%").strip()
        if stripped == "0":
            return None
        match = re.match(r"^(-?\d+)\s*-\s*(-?\d+)$", stripped)
        if match:
            return {"min": int(match.group(1)), "max": int(match.group(2))}
        try:
            value = int(round(float(stripped)))
        except ValueError:
            report.error(where, f"is not a range, a number, or '0' ({text!r})")
            return None
        return {"min": value, "max": value}

    if kind == "reward_list":
        # "+2 for BO05; +2 for SG01" -> [{"delta": 2, "target": "BO05"}, ...]
        # (data guide §2.5). "N/A" is already None by the time we get here.
        rewards = []
        for clause in text.split(";"):
            clause = clause.strip()
            if not clause:
                continue
            match = re.match(r"^([+-]?\d+)\s+for\s+(\S+)$", clause, re.IGNORECASE)
            if not match:
                report.error(where, f"reward clause {clause!r} doesn't match '+N for <ID>'")
                continue
            rewards.append({"delta": int(match.group(1)), "target": match.group(2)})
        return rewards

    if kind == "target_delta_list":
        # "BO05 +1; M12 -2; SH04; BO01 +1-6" -> [{"target": "BO05", "delta": 1},
        # {"target": "M12", "delta": -2}, {"target": "SH04", "delta": None},
        # {"target": "BO01", "delta": {"min": 1, "max": 6}}]
        #
        # Cameron's own format (2026-09-25), for the Office Hours Visitors
        # tab's Reward/Penalty columns: unlike "reward_list" above (Staff's
        # "+N for <ID>", one fixed sign of thing per column), a single cell
        # here can mix targets AND signs together — a visitor's Reward
        # column can read "BO05 +1", a Penalty column "BO05 -2" — because
        # which kind of thing a target IS (a booster standing bump, a
        # modifier grant, a shop item) is read from its own ID prefix at
        # runtime, not from this column. A target's delta is one of three
        # shapes: absent (a modifier/shop item is granted outright, not
        # incremented — "M12" alone is valid), a single fixed signed number
        # ("+1", "-2"), or a range to roll at apply time ("+1-6", same
        # "min-max" shape the "range" kind above already uses elsewhere,
        # with an optional leading "+" as pure decoration — "1-6" means the
        # same thing). Rolling a range delta is the applying code's job
        # (mirroring how BattleSetup._opponent_count() rolls its own range),
        # not this exporter's — this only ever produces the {"min","max"}
        # shape, never a rolled number.
        entries = []
        for clause in text.split(";"):
            clause = clause.strip()
            if not clause:
                continue
            head_match = re.match(r"^(\S+)(?:\s+(.+))?$", clause)
            if not head_match:
                report.error(where,
                    f"target clause {clause!r} doesn't match '<ID>', '<ID> +N', or '<ID> min-max'")
                continue
            target, rest = head_match.group(1), head_match.group(2)
            # A pool: "BO01|BO02|BO03 +1" — one of these is picked at random
            # when the entry is applied (Cameron, 2026-09-25: the pool is set
            # in the cell, the code only picks). Exported as "target_pool"
            # rather than "target", so nothing can mistake the whole string
            # for a single ID.
            head = {"target": target}
            if "|" in target:
                pool = [part.strip() for part in target.split("|") if part.strip()]
                if not pool:
                    report.error(where, f"target clause {clause!r} has an empty pool")
                    continue
                head = {"target_pool": pool}
            if rest is None:
                entries.append({**head, "delta": None})
                continue
            rest = rest.strip()
            range_match = re.match(r"^\+?(-?\d+)\s*-\s*(-?\d+)$", rest)
            if range_match:
                entries.append({
                    **head,
                    "delta": {"min": int(range_match.group(1)), "max": int(range_match.group(2))},
                })
                continue
            fixed_match = re.match(r"^([+-]\d+)$", rest)
            if fixed_match:
                entries.append({**head, "delta": int(fixed_match.group(1))})
                continue
            report.error(where,
                f"target clause {clause!r} doesn't match '<ID>', '<ID> +N', or '<ID> min-max'")
        return entries

    if kind == "json":
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            report.error(where, f"is not valid JSON ({exc.msg}): {text!r}")
            return None

    # Numbers. Excel hands back floats for everything, so an "int" column
    # arrives as 3.0 and needs rounding back to 3.
    try:
        number = float(text)
    except ValueError:
        report.error(where, f"should be a number but reads {text!r}")
        return None

    if kind == "int":
        if abs(number - round(number)) > 1e-9:
            report.warn(where, f"expected a whole number, got {number} — rounded to {round(number)}")
        return int(round(number))

    if kind == "pct" and number > 1.0:
        report.warn(
            where,
            f"is {number}, but shares are stored as fractions (0.3 means 30%). "
            "Divide it by 100 in the workbook.",
        )

    return number


def read_table(sheet, config, sheet_name, report):
    """Reads one ordinary tab into a list of dictionaries."""
    rows = list(sheet.iter_rows(values_only=True))
    if not rows:
        report.error(sheet_name, "the tab is empty")
        return []

    headers = [normalise_header(cell) for cell in rows[0]]
    optional = {normalise_header(name) for name in config.get("optional", [])}

    # Work out which spreadsheet column each JSON key comes from.
    column_index = {}
    for header, key, kind in config["columns"]:
        wanted = normalise_header(header)
        if wanted in headers:
            column_index[key] = (headers.index(wanted), kind)
        elif wanted in optional:
            column_index[key] = (None, kind)   # exports as null
            report.warn(
                sheet_name,
                f"column '{header}' is not in the workbook yet, so every "
                f"'{key}' is empty. See design/proposals/ for the proposed version.",
            )
        else:
            report.error(sheet_name, f"expected a column called '{header}' and could not find it")
            column_index[key] = (None, kind)

    id_pattern = config.get("id_pattern")
    drop_rows = config.get("drop_rows")
    records, skipped = [], []

    for row_number, row in enumerate(rows[1:], start=2):
        if row is None or all(is_null(cell) for cell in row):
            continue

        first = "" if row[0] is None else str(row[0]).strip()

        if drop_rows is not None and first in drop_rows:
            continue
        if id_pattern and not re.match(id_pattern, first):
            # A row with a blank first cell is a summary or spacer row at the
            # bottom of a tab — not worth mentioning. A row with something in
            # it might be a mistyped ID, so that one gets reported.
            if first:
                skipped.append(f"row {row_number} ({first!r})")
            continue

        record = {}
        for header, key, kind in config["columns"]:
            index, kind = column_index[key]
            cell = None if index is None or index >= len(row) else row[index]
            record[key] = coerce(cell, kind, f"{sheet_name} row {row_number}, '{header}'", report)
        records.append(record)

    if skipped:
        # These are almost always the summary rows at the bottom of a tab.
        # Listed rather than dropped in silence, so a mistyped ID is visible.
        report.note(
            f"{sheet_name}: skipped {len(skipped)} non-data row(s): {', '.join(skipped)}"
        )

    return records


def _as_int_pair(first, second):
    """Returns (int, int) if both cells are whole numbers, otherwise None."""
    try:
        if is_null(first) or is_null(second):
            return None
        return int(round(float(str(first).strip()))), int(round(float(str(second).strip())))
    except ValueError:
        return None


def read_balance(sheet, report):
    """
    The Balance tab is a list of levers, not a table, and it has two small
    sub-tables embedded in it. This turns it into one object:

        { "w_self": 1, ..., "xp_tiers": {...}, "committee_size_bands": {...} }
    """
    levers, xp_tiers, size_bands = {}, {}, {}
    section = None

    for row_number, row in enumerate(sheet.iter_rows(values_only=True), start=1):
        if row is None or all(is_null(cell) for cell in row):
            continue

        label = "" if row[0] is None else str(row[0]).strip()
        if not label or label == "Lever":
            continue

        value = row[1] if len(row) > 1 else None

        # Section headers announce the two sub-tables.
        if label.upper() == "XP TIER TABLE":
            section = "xp"
            continue
        if label.upper().startswith("COMMITTEE SIZE BY DIFFICULTY"):
            section = "bands"
            continue

        where = f"Balance row {row_number}, '{label}'"

        if section == "xp" and re.match(r"^(Starter|Tier \d+)$", label):
            xp_tiers[label] = coerce(value, "int", where, report)
            continue

        if section == "bands" and len(row) > 2:
            # A band row is "Easy | 3 | 5" — a label and two whole numbers.
            # The lever that follows the sub-table has a sentence in the third
            # column, so checking both cells are numbers is what tells the two
            # apart. Tested quietly: a non-match just falls through to a lever.
            band = _as_int_pair(row[1], row[2])
            if band is not None:
                size_bands[label] = {"min": band[0], "max": band[1]}
                continue

        # Anything else is an ordinary lever. Leaving the section marker set
        # would swallow later levers, so clear it once we're past a sub-table.
        section = None
        number = coerce(value, "num", where, report)
        # Levers like "Starter deck size" are counts. Writing them as 12
        # rather than 12.0 keeps the JSON readable; the decimals that matter
        # (weights, shares) are untouched.
        if isinstance(number, float) and number.is_integer():
            number = int(number)
        levers[slugify(label)] = number

    levers["xp_tiers"] = xp_tiers
    levers["committee_size_bands"] = size_bands
    return levers


def read_lists(sheet, report):
    """
    The Lists tab holds the dropdown options for the rest of the workbook —
    one independent list per column, each a different length. Exported so the
    validator can check spelling against the same options you see in Excel.
    """
    rows = list(sheet.iter_rows(values_only=True))
    if not rows:
        report.error("Lists", "the tab is empty")
        return {}

    headers = [None if cell is None else str(cell).strip() for cell in rows[0]]
    lists = {}
    for index, header in enumerate(headers):
        if not header:
            continue
        values = []
        for row in rows[1:]:
            cell = row[index] if index < len(row) else None
            if not is_null(cell):
                values.append(str(cell).strip())
        lists[slugify(header)] = values
    return lists


# ---------------------------------------------------------------------------
# Cross-reference validation
# ---------------------------------------------------------------------------
# Everything below answers one question: does every ID in the workbook point
# at something that actually exists? A card whose suit is misspelled, a module
# naming an opponent who isn't in the roster — these are the mistakes that are
# invisible in a spreadsheet and fatal in a game.

def ids_from(records, key):
    return {r[key] for r in records if r.get(key)}


def validate(data, report):
    suits = ids_from(data["suits"], "element")
    stage_ids = ids_from(data["stages"], "stage_id")
    segment_names = {r["name_en"] for r in data["segments"] if r.get("name_en")}
    segment_ids = ids_from(data["segments"], "segment_id")
    card_ids = ids_from(data["cards"], "card_id")
    mod_ids = ids_from(data["modifiers"], "mod_id")
    booster_ids = ids_from(data["boosters"], "booster_id")
    opp_ids = ids_from(data["opponents"], "opp_id")
    level_ids = ids_from(data["levels"], "level_id")
    staff_ids = ids_from(data["staff"], "staff_id")
    party_ids = ids_from(data.get("parties", []), "party_id")
    party_names = {r["name"] for r in data.get("parties", []) if r.get("name")}
    # The Balance tab's XP-tier sub-table is gone from this workbook pull, so
    # this is always empty for now, and the card-tier check below is skipped.
    tier_names = set(data["balance"].get("xp_tiers", {}).keys())
    lists = data.get("lists", {})

    # --- duplicate IDs -----------------------------------------------------
    for name, key in [
        ("cards", "card_id"), ("stages", "stage_id"), ("segments", "segment_id"),
        ("modifiers", "mod_id"), ("boosters", "booster_id"), ("opponents", "opp_id"),
        ("suits", "element"), ("levels", "level_id"), ("staff", "staff_id"),
        ("shop", "item_id"), ("parties", "party_id"),
    ]:
        seen = set()
        for record in data[name]:
            value = record.get(key)
            if value in seen:
                report.error(name, f"{key} '{value}' appears more than once")
            seen.add(value)

    # --- cards -------------------------------------------------------------
    for card in data["cards"]:
        cid = card["card_id"]
        if card["suit"] not in suits:
            report.error("cards", f"{cid} has suit '{card['suit']}', which is not in the Suits tab")
        if card["target_segment"] and card["target_segment"] != "Any":
            if card["target_segment"] not in segment_names:
                report.error(
                    "cards",
                    f"{cid} targets segment '{card['target_segment']}', "
                    "which is not in the Segments tab",
                )
        if card["tier"] and tier_names and card["tier"] not in tier_names:
            report.error(
                "cards",
                f"{cid} has tier '{card['tier']}', which is not in the Balance XP tier table",
            )
        if card["type"] and lists.get("types") and card["type"] not in lists["types"]:
            report.error("cards", f"{cid} has type '{card['type']}', which is not in the Lists tab")
        if card["cost"] is None:
            report.error("cards", f"{cid} has no cost")

    # --- affinity ----------------------------------------------------------
    for row in data["affinity"]:
        if row["element"] not in suits:
            report.error("affinity", f"'{row['element']}' is not in the Suits tab")
        for stage_id in row["multipliers"]:
            if stage_id not in stage_ids:
                report.error("affinity", f"column '{stage_id}' is not a stage in the Stages tab")

    combat_stages = {r["stage_id"] for r in data["stages"] if r.get("mode") == "Combat"}
    covered = set()
    for row in data["affinity"]:
        covered |= set(row["multipliers"].keys())
    for stage_id in sorted(combat_stages - covered):
        report.error("affinity", f"combat stage {stage_id} has no affinity column")
    for element in sorted(suits):
        if element not in {r["element"] for r in data["affinity"]}:
            report.error("affinity", f"suit '{element}' has no affinity row")

    # --- stages ------------------------------------------------------------
    for stage in data["stages"]:
        sid = stage["stage_id"]
        if stage["favored_suit"] and stage["favored_suit"] not in suits:
            report.error("stages", f"{sid} favours '{stage['favored_suit']}', which is not a suit")

        mix = stage["segment_mix"]
        # "% Other" isn't a segment (no matching Segments row), but it's
        # still part of the audience and belongs in the 100% check.
        total = sum(v for v in mix.values() if v is not None) + (stage.get("pct_other") or 0)
        if mix and abs(total - 1.0) > 0.001:
            report.error(
                "stages",
                f"{sid} audience shares add up to {total:.0%}, not 100%",
            )

        if stage["mode"] == "Combat":
            for field in ("turn_limit", "energy_per_turn", "hand_size", "gaffe_limit"):
                if stage[field] is None:
                    report.error("stages", f"{sid} is a combat stage but has no {field}")
            for field in ("bar_max", "win_threshold", "player_start", "opp_start"):
                if stage[field] is None:
                    report.warn(
                        "stages",
                        f"{sid} has no {field} — it must be resolved from the module "
                        "or committee data at battle setup",
                    )

    # --- modifiers ---------------------------------------------------------
    valid_effect_types = {
        "RESOURCE_BONUS_ON_WIN", "STAGE_START_BONUS", "HAND_SIZE_BONUS",
        "GAFFE_LIMIT_BONUS", "UNLOCK_DISCOUNT", "FUNDS_INCOME_FREEZE",
    }
    for mod in data["modifiers"]:
        mid = mod["mod_id"]
        triggers = mod["trigger_segment_or_booster"] or []
        for trigger in triggers:
            if trigger.startswith("SG") and trigger not in segment_ids:
                report.error(
                    "modifiers",
                    f"{mid} triggers on segment '{trigger}', which is not in the Segments tab",
                )
            elif trigger.startswith("BO") and trigger not in booster_ids:
                report.error(
                    "modifiers",
                    f"{mid} triggers on booster '{trigger}', which is not in the Boosters tab",
                )
            elif not trigger.startswith("SG") and not trigger.startswith("BO"):
                report.error(
                    "modifiers",
                    f"{mid} has trigger '{trigger}', which is neither an SGxx segment "
                    "nor a BOxx booster ID",
                )
        if mod["trigger_min_pct"] is None and triggers:
            report.warn(
                "modifiers",
                f"{mid} names a trigger but no trigger min % — "
                "treated as always active once its other condition is met",
            )
        if mod["effect_type"] and mod["effect_type"] not in valid_effect_types:
            report.error(
                "modifiers",
                f"{mid} has Effect Type '{mod['effect_type']}', which is not one of "
                f"{sorted(valid_effect_types)} (data guide §2.1)",
            )
        if mod["effect_type"] in ("STAGE_START_BONUS", "HAND_SIZE_BONUS", "GAFFE_LIMIT_BONUS"):
            if mod["effect_target"] not in stage_ids:
                report.error(
                    "modifiers",
                    f"{mid} ({mod['effect_type']}) targets '{mod['effect_target']}', "
                    "which is not a stage in the Stages tab",
                )
        if mod["effect_type"] == "RESOURCE_BONUS_ON_WIN":
            if mod["effect_target"] not in ("XP", "Yen", "Jiban", "PartySupport"):
                report.error(
                    "modifiers",
                    f"{mid} (RESOURCE_BONUS_ON_WIN) targets '{mod['effect_target']}', "
                    "which is not one of XP/Yen/Jiban/PartySupport",
                )

    # --- boosters ----------------------------------------------------------
    for booster in data["boosters"]:
        for mod_id in booster["linked_modifiers"] or []:
            if mod_id not in mod_ids:
                report.error(
                    "boosters",
                    f"{booster['booster_id']} links modifier '{mod_id}', "
                    "which is not in the Modifiers tab",
                )

    # --- opponents -----------------------------------------------------------
    for opp in data["opponents"]:
        oid = opp["opp_id"]
        for field in ("suit_1", "suit_2", "suit_3"):
            if opp[field] and opp[field] not in suits:
                report.error("opponents", f"{oid} has {field} '{opp[field]}', which is not a suit")
        # Affiliation is a booster_id since the 2026-09-26 pull. Caught one
        # real mistake this way already: 12 Yezo Heritage Party MPs pointed
        # at BO19-BO30, IDs nothing else in the Boosters tab uses — a
        # party-member row should point at BO17 (Member of Parliament) like
        # every other MP, the same as Cameron confirmed for that batch.
        if opp["affiliation"] and opp["affiliation"] not in booster_ids:
            report.error(
                "opponents",
                f"{oid} has Affiliation '{opp['affiliation']}', which is not in the Boosters tab",
            )
        for stage_id in opp["stages"] or []:
            if stage_id not in stage_ids:
                report.error(
                    "opponents",
                    f"{oid} is listed for stage '{stage_id}', which is not in the Stages tab",
                )
        if not opp["stages"]:
            report.warn("opponents", f"{oid} has no Stage listed, so they never appear in a level")

    # --- opponent cues -------------------------------------------------------
    # lean_down was removed as a game mechanic (2026-09-24, IntentRunner.gd)
    # — a Verb outside these three is either a typo or a stale reference to it.
    valid_verbs = {"attack", "gain", "block"}
    for cue in data.get("opponent_cues", []):
        cue_id = cue["cue_id"]
        if cue["suit"] not in suits:
            report.error(
                "opponent_cues",
                f"{cue_id} has suit '{cue['suit']}', which is not in the Suits tab",
            )
        if cue["verb"] not in valid_verbs:
            report.error(
                "opponent_cues",
                f"{cue_id} has verb '{cue['verb']}', which must be attack, gain, or block",
            )
        for opp_id in cue["opponent_ids"] or []:
            if opp_id not in opp_ids:
                report.error(
                    "opponent_cues",
                    f"{cue_id} names opponent '{opp_id}', which is not in the Opponents tab",
                )
        if not any(cue.get(f"cue_{i}") for i in range(1, 6)):
            report.warn("opponent_cues", f"{cue_id} has no cue lines written")

    # --- parties ---------------------------------------------------------------
    for party in data.get("parties", []):
        pid = party["party_id"]
        for channel in ("r", "g", "b"):
            value = party.get(channel)
            if value is not None and not (0 <= value <= 255):
                report.error("parties", f"{pid} has {channel.upper()} {value}, outside 0-255")
        leader = party.get("leader_opp_id")
        if leader and leader not in opp_ids:
            report.error(
                "parties",
                f"{pid} names leader '{leader}', which is not in the Opponents tab",
            )
        if not leader:
            report.warn("parties", f"{pid} has no Leader Opp ID yet, so its screen shows a placeholder")
        if party.get("seats") is not None and party["seats"] < 0:
            report.error("parties", f"{pid} has {party['seats']} seats, which is negative")

    total_seats = sum(p.get("seats") or 0 for p in data.get("parties", []))
    if total_seats and total_seats != 101:
        report.warn(
            "parties", f"seats add up to {total_seats}, not the 101-seat house CLAUDE.md §4 fixes",
        )

    # --- floor votes (ST23, National Assembly Floor Voting) -------------------
    vote_stage_ids = {s["stage_id"] for s in data["stages"] if s.get("mode") == "Vote"}
    dispositions = {"Supportive", "Opposed", "Neutral"}
    for level_id, bill in data.get("floor_votes", {}).items():
        if level_id not in level_ids:
            report.error(
                "Floor Vote Bills", f"names level '{level_id}', which is not in the Levels tab",
            )
            continue
        seen_parties = set()
        for position in bill["positions"]:
            party_id = position.get("party_id")
            if party_id not in party_ids:
                report.error(
                    "Floor Vote Party Positions",
                    f"{level_id} names party '{party_id}', which is not in the Parties tab",
                )
                continue
            seen_parties.add(party_id)
            if position.get("disposition") not in dispositions:
                report.error(
                    "Floor Vote Party Positions",
                    f"{level_id}/{party_id} has disposition '{position.get('disposition')}', "
                    "which must be Supportive, Opposed, or Neutral",
                )
            for vote_field in ("votes_yes", "votes_no", "votes_abstain"):
                value = position.get(vote_field)
                if value is not None and value < 0:
                    report.error(
                        "Floor Vote Party Positions",
                        f"{level_id}/{party_id} has a negative {vote_field}",
                    )
        for missing in party_ids - seen_parties:
            report.warn(
                "Floor Vote Party Positions",
                f"{level_id} has no row for party '{missing}' — that party sits out this vote",
            )
        level = next((lv for lv in data["levels"] if lv["level_id"] == level_id), {})
        level_stages = {level.get(f"stage_{n}") for n in range(1, 11)}
        if not level_stages & vote_stage_ids:
            report.warn(
                "Floor Vote Bills",
                f"{level_id} has a bill, but its own stage list has no Floor Vote (Vote-mode) stage",
            )
    for level in data["levels"]:
        lid = level["level_id"]
        level_stages = {level.get(f"stage_{n}") for n in range(1, 11)}
        if (level_stages & vote_stage_ids) and lid not in data.get("floor_votes", {}):
            report.error(
                "levels", f"{lid} places a Floor Vote stage but has no row in Floor Vote Bills",
            )

    # --- visitors ------------------------------------------------------------
    for visitor in data.get("visitors", []):
        vid = visitor["visitor_id"]
        if visitor.get("segment") and visitor["segment"] not in segment_names:
            report.error(
                "visitors",
                f"{vid} names segment '{visitor['segment']}', which is not in the Segments tab",
            )

    # --- levels --------------------------------------------------------------
    booster_delta_keys = [f"win_delta_bo{n:02d}" for n in range(1, 17)]
    for level in data["levels"]:
        lid = level["level_id"]
        stage_slots = [level[f"stage_{n}"] for n in range(1, 11) if level.get(f"stage_{n}")]
        if not stage_slots:
            report.error("levels", f"{lid} names no stages at all")
        for slot in stage_slots:
            if slot not in stage_ids:
                report.error("levels", f"{lid} uses stage '{slot}', which does not exist")
        for key in booster_delta_keys:
            bo_id = "BO" + key[-2:]
            if level.get(key) is not None and bo_id not in booster_ids:
                report.error("levels", f"{lid} has a '{key}' column, but {bo_id} is not in the Boosters tab")

    # --- staff ---------------------------------------------------------------
    for member in data["staff"]:
        sfid = member["staff_id"]
        for tier_key in ("tier_0_reward", "tier_1_reward", "tier_2_reward"):
            for reward in member.get(tier_key) or []:
                target = reward["target"]
                if target.startswith("BO") and target not in booster_ids:
                    report.error(
                        "staff", f"{sfid} {tier_key} rewards booster '{target}', which does not exist",
                    )
                elif target.startswith("SG") and target not in segment_ids:
                    report.error(
                        "staff", f"{sfid} {tier_key} rewards segment '{target}', which does not exist",
                    )
                elif not target.startswith("BO") and not target.startswith("SG"):
                    report.error(
                        "staff",
                        f"{sfid} {tier_key} rewards '{target}', which is neither a BOxx "
                        "booster nor an SGxx segment",
                    )

    # --- shop ------------------------------------------------------------------
    for item in data["shop"]:
        if item["cost_xp"] is None and item["cost_yen"] is None:
            report.warn("shop", f"{item['item_id']} has no XP or Yen cost set")

    # --- sanban ------------------------------------------------------------
    for variable in data["sanban"]:
        label = variable["name_en"]
        if variable["start"] is None or variable["min"] is None or variable["max"] is None:
            report.error("sanban", f"{label} is missing a start, min or max")
        elif not (variable["min"] <= variable["start"] <= variable["max"]):
            report.error(
                "sanban",
                f"{label} starts at {variable['start']}, outside its range of "
                f"{variable['min']}-{variable['max']}",
            )

    missing_special = [c["card_id"] for c in data["cards"]
                       if c.get("special") is None and "if " in (c.get("effect_text") or "").lower()]
    if missing_special:
        report.warn(
            "cards",
            f"{len(missing_special)} card(s) describe a conditional effect but have no "
            f"'special' value, so the condition does nothing: {', '.join(missing_special)}",
        )

    # --- rules.json --------------------------------------------------------
    expected_flags = {
        "turn_limit_outcome": ["loss", "highest_support_wins", "tie_retry"],
        "opponent_can_win_by_threshold": [True, False],
        "opponent_engine": ["intent_patterns", "deck_ai"],
        "press_answer_timer": [True, False],
        "discard_hand_end_of_turn": [True, False],
        "open_card_collection": [True, False],
        "level_gating_enabled": [True, False],
    }
    flags = data.get("rules", {})
    for flag, allowed in expected_flags.items():
        if flag not in flags:
            report.error("rules.json", f"flag '{flag}' is missing")
        elif flags[flag] not in allowed:
            report.error(
                "rules.json",
                f"flag '{flag}' is set to {flags[flag]!r}; allowed values are {allowed}",
            )

    # Every opponent without a pattern of their own falls back to this one, so
    # a mistake here would break every battle in the game at the same time.
    known_verbs = {"attack", "gain", "block"}
    pattern = flags.get("default_intent_pattern")
    if pattern is None:
        report.error("rules.json", "flag 'default_intent_pattern' is missing")
    elif not isinstance(pattern, list) or not pattern:
        report.error("rules.json", "'default_intent_pattern' must be a non-empty list of moves")
    else:
        for index, move in enumerate(pattern, start=1):
            if not isinstance(move, list) or len(move) < 2:
                report.error(
                    "rules.json",
                    f"default_intent_pattern move {index} should be a verb and a "
                    'number, such as ["attack", 6]',
                )
            elif move[0] not in known_verbs:
                report.error(
                    "rules.json",
                    f"default_intent_pattern move {index} uses '{move[0]}', which is "
                    f"not one of {sorted(known_verbs)}",
                )


# ---------------------------------------------------------------------------
# Derived fields
# ---------------------------------------------------------------------------
# A couple of places in the workbook name a segment in words ("Press") where
# the engine wants its ID ("SG01"). Resolving that here, once, keeps the
# lookup out of the game code.

# ---------------------------------------------------------------------------
# Does every line the code asks for actually exist?
# ---------------------------------------------------------------------------

TEXT_KEY_CALLS = [
    re.compile(r'Text\.say\(\s*"([^"]+)"'),      # GDScript
    re.compile(r'Text\.has\(\s*"([^"]+)"'),
    re.compile(r"\bT\(\s*'([^']+)'"),           # the browser build's shorthand
    # A key handed to a helper rather than straight to the lookup — the room
    # brief passes its labels to _bullet(), for instance. Recognised by the
    # shape of a key (dotted, lower case) rather than by the call around it,
    # because there is no end of helpers a key might travel through. The
    # worst a false match can do is suppress a "nothing asks for this" note.
    re.compile(r'["\']([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)["\']'),
]

# Where a key is built at runtime rather than written out, the code says so
# with this marker and the check skips the line instead of guessing.
TEXT_DYNAMIC = "text-key-built-at-runtime"


def check_text_keys(data, report):
    """Every key the code asks for must be a row in the Text tab.

    This is the safety net that makes the wording safe to hand over. A key
    that has no row shows up on screen as the key itself, which is the kind
    of thing a playtester finds and nobody else does — so it is an ERROR
    here, in the report Cameron already reads after every export.

    A row nothing asks for is only a warning: it is probably a typo in the
    Key column, but it might equally be a line written ahead of the screen
    that will use it.
    """
    rows = data.get("strings")
    if rows is None:
        return

    in_sheet = {str(row.get("key", "")) for row in rows}
    asked_for = {}

    searched = list(REPO_ROOT.glob("scripts/**/*.gd"))
    for path in searched:
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            if TEXT_DYNAMIC in line:
                continue
            # Comments explain the lookup and quote example keys, so reading
            # them would report lines nothing actually asks for. A docstring
            # showing Text.say("narration.gaffe") is documentation, not a use.
            stripped = line.lstrip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            for pattern in TEXT_KEY_CALLS:
                for key in pattern.findall(line):
                    asked_for.setdefault(key, []).append(
                        f"{path.relative_to(REPO_ROOT)}:{number}")

    # A plural is two rows, key.one and key.other, and the code asks for the
    # bare key. Either shape satisfies the other, so fold them together
    # before comparing or every plural reads as both missing and unused.
    def satisfied(key):
        return key in in_sheet or (
            key + ".one" in in_sheet and key + ".other" in in_sheet)

    def wanted(row_key):
        if row_key in asked_for:
            return True
        base, _, suffix = row_key.rpartition(".")
        return suffix in ("one", "other") and base in asked_for

    for key in sorted(k for k in asked_for if not satisfied(k)):
        report.error("Text tab",
                     f"the code asks for '{key}' and the tab has no such Key "
                     f"({asked_for[key][0]})")

    for key in sorted(k for k in in_sheet if not wanted(k)):
        report.note(f"Text tab: nothing asks for '{key}' yet")

    # A placeholder the row uses but does not declare is a warning, because
    # the Placeholders column is what tells Cameron what he may move around.
    for row in rows:
        used = set(re.findall(r"\{(\w+)\}", str(row.get("english", ""))))
        declared = {p.strip() for p in str(row.get("placeholders") or "").split(",") if p.strip()}
        for name in sorted(used - declared):
            report.warn("Text tab",
                        f"'{row.get('key')}' uses {{{name}}} but does not list it "
                        f"in Placeholders")

    if in_sheet:
        report.note(f"Text tab: {len(in_sheet)} lines, {len(asked_for)} asked for by the code")


# ---------------------------------------------------------------------------
# The wording snapshot
# ---------------------------------------------------------------------------
# tests/wording_snapshot.json is a copy of every line the game says, as it
# read the last time somebody deliberately accepted a change.
#
# Its job is to make an ACCIDENTAL reword loud and a DELIBERATE one easy. A
# code change that quietly alters what the player reads shows up as a failing
# test naming the line. Cameron rewording a line on purpose runs
#
#     python3 tools/export_data.py --accept-wording
#
# which records the new wording, and git then shows exactly what changed.

SNAPSHOT = REPO_ROOT / "tests" / "wording_snapshot.json"


# The four standing names are BOTH display text and lookup keys. They are
# shown on screen, and they are how the code reaches into sanban.json and
# into the run's meta dictionary — GameState asks for meta["Funds"],
# MetaRules files a win delta under "Reputation", and so on.
#
# So renaming one in the Sanban tab is not a wording change: it silently
# disconnects the code from the variable. Checked here so a rename is an
# error at Cameron's desk with a readable message, rather than a stage
# quietly paying out nothing.
#
# To rename one for real, change it here and in the Sanban tab together,
# and say so — the files that use each name are listed beside it.
STANDING_NAMES = {
    "Constituency support": "MetaRules, LevelRunner",
    "Reputation": "MetaRules, LevelRunner, BattleSetup, BattleEngine",
    "Funds": "MetaRules, LevelRunner, GameState, OfficeScreen",
    "Party support": "MetaRules, LevelRunner",
}


def fold_player(data, report):
    """The Player tab (2026-09-26 pull) becomes {"protagonists": [...]},
    with the four meta columns folded into one starting_meta dict per row —
    the shape DataDB._load_protagonists() has always expected, back when
    data/player.json was written by hand. No default_protagonist: the first
    row is the default, the same fallback _load_protagonists() already uses
    when one is missing or names an unknown player_id.
    """
    rows = data.pop("player_raw", [])
    protagonists = []
    for row in rows:
        protagonists.append({
            "player_id": row["player_id"],
            "name_en": row["name_en"],
            "party": row["party"],
            "blurb": row["blurb"],
            "starting_meta": {
                "Constituency support": row["starting_jiban"],
                "Reputation": row["starting_kanban"],
                "Funds": row["starting_yen"],
                "Party support": row["starting_party_support"],
            },
            "starting_xp": row["starting_xp"],
            "gender": row["gender"],
            "committee": row["committee"],
            "positioning": row["positioning"],
            "element_1": row["element_1"],
            "element_2": row["element_2"],
            "region": row["region"],
            "district_name": row["district_name"],
            "district_type": row["district_type"],
        })
    if not protagonists:
        report.error("Player", "no protagonists found")
    data["player"] = {"protagonists": protagonists}


def fold_floor_votes(data, report):
    """Folds Floor Vote Bills + Floor Vote Party Positions into
    data/floor_votes.json, keyed by level_id — {"LV07": {bill fields...,
    "positions": [{party fields...}, ...]}}. Same bill-plus-rows shape
    fold_questions() gives each question its "asked_by", but the join key
    here is level_id rather than a computed stage type, since a Floor Vote
    is ST23 (National Assembly Floor Voting) played generically wherever a
    level places it — the bill itself, not the stage, is what's specific to
    that level (CLAUDE.md §7.5's committee stages are the same idea: a
    generic stage, a level-specific roster).
    """
    bills = data.pop("floor_vote_bills_raw", [])
    positions = data.pop("floor_vote_positions_raw", [])

    by_level = {}
    for bill in bills:
        level_id = bill["level_id"]
        entry = dict(bill)
        entry["positions"] = []
        by_level[level_id] = entry

    for position in positions:
        level_id = position.get("level_id")
        if level_id not in by_level:
            report.error(
                "Floor Vote Party Positions",
                f"names level '{level_id}', which has no row in Floor Vote Bills",
            )
            continue
        by_level[level_id]["positions"].append(position)

    data["floor_votes"] = by_level


# Which stage type each question tab belongs to. The tabs are named for the
# room; stage_types.json names the type. One place holds the join.
QUESTION_TABS = {
    "q_press": "press_conference",
    "q_town_hall": "town_hall",
    "q_lobbyist": "lobbyist_meeting",
    "q_study_session": "policy_study",
    "q_media_ambush": "media_ambush",
}

SUIT_COLUMNS = ["earnest", "emotional", "appeal", "data_driven",
                "divisive", "duplicitous"]


def fold_questions(data, report):
    """Five question tabs become one questions.json, keyed by stage type.

    A stage draws its questions from the pool for its type rather than
    naming them itself, so a new question is one row in the workbook.
    Each question grades all six suits S (strong), M (medium) or W (weak).
    """
    suit_names = {row["element"].lower().replace(" ", "_"): row["element"]
                  for row in data.get("suits", []) if row.get("element")}

    by_theme = {row["theme"]: (row.get("pleases_boosters") or [])
                for row in data.get("question_themes", [])}
    booster_ids = {row["booster_id"] for row in data.get("boosters", [])}
    for theme, boosters in sorted(by_theme.items()):
        for booster in boosters:
            if booster not in booster_ids:
                report.error("Question Themes",
                             f"'{theme}' names organisation '{booster}', "
                             f"which is not in the Boosters tab")

    # Who asks (2026-09-26, Cameron: "the databook is the governing data" —
    # call an opponent up by their own Stage ID, never a hand-maintained
    # placeholder roster or a text description). Every opponent whose own
    # Stage list names the room's STxx is eligible to ask there, the exact
    # same dynamic pool BattleSetup._opponents_for() draws FIGHTERS from —
    # a press conference draws its questioners from ordinary committee MPs
    # this way (most have ST04 alongside their real committee), a Town Hall
    # from constituents (ST05), Media Ambush from journalists (ST19), a
    # Lobbyist Meeting from lobbyists (ST20). No Role check: the Stage ID is
    # what governs eligibility everywhere else in this project, so it is
    # what governs it here too.
    stage_id_by_pool = {}
    for stage in data.get("stages", []):
        pool_name = stage.get("question_pool")
        if pool_name:
            stage_id_by_pool[pool_name] = stage["stage_id"]
    # ST05 Town Hall has no "question_pool" column of its own in the
    # workbook (BattleSetup.QUESTION_POOL_BY_STAGE's own fallback covers the
    # same gap on the GDScript side) — the one stage_type this can't read
    # off data["stages"] today.
    stage_id_by_pool.setdefault("town_hall", "ST05")

    reporters_by_pool = {}
    for stage_type, stage_id in stage_id_by_pool.items():
        askers = sorted(
            row["opp_id"] for row in data.get("opponents", [])
            if stage_id in (row.get("stages") or [])
        )
        reporters_by_pool[stage_type] = askers

    pools = {}
    for source, stage_type in QUESTION_TABS.items():
        reporters = reporters_by_pool.get(stage_type, [])
        rows = data.pop(source, [])
        pool = []
        for row in rows:
            grades = {}
            for column in SUIT_COLUMNS:
                grade = str(row.get(column) or "").strip().upper()
                if grade not in ("S", "M", "W"):
                    report.error(stage_type,
                                 f"question {row.get('q_id')} grades "
                                 f"{column} as '{grade}' — it must be S, M or W")
                    continue
                # Back under the suit's own name, so the engine can look a
                # card's suit up directly.
                grades[suit_names.get(column, column)] = grade
            if len(grades) == len(SUIT_COLUMNS):
                theme = row.get("theme", "")
                question = {
                    "id": row["q_id"],
                    "text": row.get("text", ""),
                    "theme": theme,
                    "grades": grades,
                }
                if by_theme.get(theme):
                    question["pleases_boosters"] = by_theme[theme]
                elif theme:
                    report.warn(stage_type,
                                f"question {row['q_id']} has the theme "
                                f"'{theme}', which no row in Question Themes "
                                f"maps to an organisation — a strong answer "
                                f"will please nobody")
                if reporters:
                    question["asked_by"] = reporters[len(pool) % len(reporters)]
                pool.append(question)
        pools[stage_type] = pool
        report.note(f"{stage_type}: {len(pool)} questions in the pool")

    data["questions"] = pools
    # The mapping has been folded in; it is not a file of its own.
    data.pop("question_themes", None)


def check_standing_names(data, report):
    in_sheet = {str(row.get("name_en", "")).strip() for row in data.get("sanban", [])}
    if not in_sheet:
        return
    for name, used_by in STANDING_NAMES.items():
        if name not in in_sheet:
            report.error("Sanban",
                         f"'{name}' is not in the tab any more. That name is a "
                         f"lookup key as well as display text — {used_by} reach "
                         f"the variable by it — so renaming it here alone stops "
                         f"the code finding it. Ask for the rename rather than "
                         f"making it in the workbook.")


def check_wording_snapshot(data, report, accept=False):
    lines = {str(row.get("key", "")): str(row.get("english", ""))
             for row in data.get("strings", []) if row.get("key")}
    if not lines:
        return

    if accept:
        SNAPSHOT.parent.mkdir(exist_ok=True)
        write_json(SNAPSHOT, dict(sorted(lines.items())))
        report.note(f"Wording: snapshot updated — {len(lines)} lines recorded")
        return

    if not SNAPSHOT.exists():
        report.note("Wording: no snapshot yet — run with --accept-wording to record one")
        return

    recorded = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    changed = sorted(k for k in lines if k in recorded and lines[k] != recorded[k])
    added = sorted(k for k in lines if k not in recorded)
    gone = sorted(k for k in recorded if k not in lines)

    if not (changed or added or gone):
        return

    for key in changed:
        report.note(f"Wording: '{key}' now reads \"{lines[key]}\" "
                    f"(was \"{recorded[key]}\")")
    for key in added:
        report.note(f"Wording: '{key}' is new")
    for key in gone:
        report.note(f"Wording: '{key}' is gone")
    report.note("Wording: if those were your edits, run "
                "'python3 tools/export_data.py --accept-wording' to record them")


def add_segment_ids(data, report):
    by_name = {r["name_en"]: r["segment_id"] for r in data["segments"] if r.get("name_en")}

    # Stages: turn the "% Press"-style columns into one keyed object. "%
    # Other" has no matching Segments row — it's the audience share outside
    # the 5 tracked segments, so it stays a plain field on the stage rather
    # than joining the mix.
    for stage in data["stages"]:
        mix = {}
        for name, segment_id in by_name.items():
            column = f"pct_{slugify(name)}"
            if column in stage:
                if stage[column] is not None:
                    mix[segment_id] = stage.pop(column)
                else:
                    stage.pop(column)
        stage["segment_mix"] = mix

    # Modifiers: "Trigger segment or booster" already holds one or more SGxx
    # / BOxx IDs directly, so each is sorted by its own prefix rather than a
    # name being resolved. A modifier is active if ANY of its segments meets
    # its trigger_min_pct (MetaRules.active_modifiers) — "SG03; SG05" means
    # either audience, not both at once.
    for mod in data["modifiers"]:
        triggers = mod.get("trigger_segment_or_booster") or []
        mod["trigger_segment_ids"] = [t for t in triggers if t.startswith("SG")]
        mod["trigger_booster_ids"] = [t for t in triggers if t.startswith("BO")]

    # Cards: same, with "Any" meaning no particular segment.
    for card in data["cards"]:
        segment = card.get("target_segment")
        card["target_segment_id"] = None if segment in (None, "Any") else by_name.get(segment)


def apply_staff_names(data, report):
    """Fill in blank Staff names from the hand-written data/staff_names.json.

    The workbook's Name column is empty for all 21 Staff rows today (see
    data/staff_names.json's _README). The workbook always wins: a row whose
    Name cell is non-blank is left exactly as read. A row that is still blank
    is filled from the fallback file and NOTEd, not warned about — this is
    expected until Cameron types names into the workbook, not a gap.
    """
    staff = data.get("staff")
    if not staff:
        return

    names_path = DATA_DIR / "staff_names.json"
    if not names_path.exists():
        report.warn("staff", "data/staff_names.json is missing — every blank Name stays blank")
        return

    fallback = json.loads(names_path.read_text(encoding="utf-8")).get("names", {})
    used_fallback = []
    for member in staff:
        if is_null(member.get("name")):
            sfid = member["staff_id"]
            if sfid in fallback:
                member["name"] = fallback[sfid]
                used_fallback.append(sfid)
            else:
                report.warn("staff", f"{sfid} has no Name in the workbook and no "
                            "fallback in data/staff_names.json")
    if used_fallback:
        report.note(
            f"staff: {len(used_fallback)} name(s) came from data/staff_names.json "
            f"(the workbook's own Name column is still blank for these): "
            f"{', '.join(used_fallback)}",
        )


def reshape_affinity(rows):
    """
    Turns the affinity grid into one row per suit with its stage multipliers
    grouped together, which is how the battle engine looks them up.
    """
    reshaped = []
    for row in rows:
        multipliers = {key: value for key, value in row.items()
                       if key != "element" and value is not None}
        reshaped.append({"element": row["element"], "multipliers": multipliers})
    return reshaped


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def write_json(path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    report = Report()

    if not WORKBOOK.exists():
        sys.exit(f"Cannot find the workbook at {WORKBOOK}")

    print(f"Reading {WORKBOOK.relative_to(REPO_ROOT)}")
    # data_only=True gives us the values Excel calculated, so formula columns
    # such as Power Score and Difficulty mod come across as numbers.
    workbook = openpyxl.load_workbook(WORKBOOK, data_only=True, read_only=True)

    present = set(workbook.sheetnames)
    # Balance, Affinity and Lists are expected too — they just have their own
    # readers below rather than an entry in SHEETS.
    expected = set(SHEETS) | set(NOT_EXPORTED) | {"Balance", "Affinity", "Lists"}
    for tab in sorted(present - expected):
        report.warn("workbook", f"tab '{tab}' is not recognised and was not exported")
    for tab in sorted(expected - present):
        if SHEETS.get(tab, {}).get("optional_sheet") or tab in NOT_EXPORTED:
            # NOT_EXPORTED tabs were never required to exist — only skipped
            # when they do.
            report.note(f"{tab}: tab not in the workbook — see design/proposals/")
        elif tab == "Lists":
            # Dropped from the workbook (2026-09-22). Every validation check
            # that used it already degrades to "skipped" without it.
            report.note("Lists: tab not in the workbook — checks that used it were skipped")
        else:
            report.error("workbook", f"tab '{tab}' is missing from the workbook")

    data = {}
    DATA_DIR.mkdir(exist_ok=True)

    # The ordinary table tabs.
    for sheet_name, config in SHEETS.items():
        if sheet_name not in present:
            continue
        records = read_table(workbook[sheet_name], config, sheet_name, report)
        data[config["out"].replace(".json", "")] = records

    # The three tabs that need their own reader.
    data["balance"] = read_balance(workbook["Balance"], report) if "Balance" in present else {}
    data["lists"] = read_lists(workbook["Lists"], report) if "Lists" in present else {}

    affinity_config = {
        "columns": [("Element", "element", "id")],
        "drop_rows": {"Stage name →", "Column average"},
    }
    if "Affinity" in present:
        # The stage columns aren't known ahead of time — they're whatever
        # stages the tab has — so they're read from the header row.
        header = [normalise_header(c) for c in next(workbook["Affinity"].iter_rows(values_only=True))]
        for index, cell in enumerate(header):
            if index == 0 or not cell:
                continue
            affinity_config["columns"].append((cell.upper(), cell.upper(), "num"))
        data["affinity"] = reshape_affinity(
            read_table(workbook["Affinity"], affinity_config, "Affinity", report)
        )
    else:
        data["affinity"] = []

    workbook.close()

    # rules.json is written by hand, not generated. It is read here only so
    # the validator can check its flags.
    rules_path = DATA_DIR / "rules.json"
    if rules_path.exists():
        raw = json.loads(rules_path.read_text(encoding="utf-8"))
        data["rules"] = {k: v["value"] if isinstance(v, dict) and "value" in v else v
                         for k, v in raw.items() if not k.startswith("_")}
    else:
        report.error("rules.json", "is missing — it holds the open-design switches")
        data["rules"] = {}

    add_segment_ids(data, report)
    apply_staff_names(data, report)
    fold_player(data, report)
    fold_questions(data, report)
    fold_floor_votes(data, report)
    validate(data, report)
    check_text_keys(data, report)
    check_standing_names(data, report)
    check_wording_snapshot(data, report, accept="--accept-wording" in sys.argv)

    written = 0
    for name, payload in sorted(data.items()):
        if name == "rules":
            continue  # hand-written, never overwritten
        write_json(DATA_DIR / f"{name}.json", payload)
        count = len(payload) if isinstance(payload, list) else len(payload.keys())
        print(f"  wrote data/{name}.json  ({count} {'rows' if isinstance(payload, list) else 'entries'})")
        written += 1

    for tab, reason in NOT_EXPORTED.items():
        report.note(f"{tab}: not exported — {reason}")
    report.note(f"{written} JSON files written to data/")

    report.print()
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
