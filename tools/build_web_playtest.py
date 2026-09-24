#!/usr/bin/env python3
"""Builds the web playtest page.

    python3 tools/build_web_playtest.py

Reads web/src/ and every data/*.json, and writes one self-contained HTML file
to web/playtest.html. That file is what gets published as an Artifact, so
Cameron can play the level on a phone without installing Godot.

WHY THIS EXISTS
The Godot project is the game. This page is a mirror of it, and the whole
point of building it with a script is that the DATA never has to be copied by
hand: change a number in the workbook, re-export, re-run this, and the page
matches. Only the rules are hand-maintained in both places, and web/src/
tests.js re-runs the engine's assertions in the page so that if the two ever
drift apart it says so.
"""

import base64
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
ASSET_DIR = REPO_ROOT / "assets"
SRC_DIR = REPO_ROOT / "web" / "src"
OUTPUT = REPO_ROOT / "web" / "playtest.html"

# Only what the playtest level actually reads. Loading the whole workbook
# would work, but a page carrying data nothing uses invites the two to drift
# apart without anybody noticing.
NEEDED = [
    "affinity",
    "balance",
    "booster_standing",
    "modifiers",
    "boosters",
    "card_cues",
    "cards",
    "journalists",
    "level_opponent_overrides",
    "levels",
    "opponents",
    "player",
    "playtest_cards",
    "playtest_level",
    "questions",
    "stage_types",
    "rules",
    "sanban",
    "segments",
    "stages",
    "strings",
    "suits",
]

# 2026-09-22 workbook: a committee stage's roster is every opponent eligible
# for that STxx (opponents.json's own "stages" list), not a row in a retired
# committee.json. This is BattleEngine.gd's/DataDB.gd's own fixed list,
# copied here rather than derived, for the same reason DataDB.gd keeps its
# own copy: nothing in stages.json tells the two kinds of stage apart (ST18
# and ST21 have the same bar_unit/bar_value_kind shape), so it has to be
# written down somewhere, and every place that needs it keeps the same list.
COMMITTEE_STAGE_IDS = {
    "ST01", "ST09", "ST10", "ST11", "ST12", "ST13", "ST14", "ST15", "ST16",
    "ST17", "ST18",
}


def read_json(name: str):
    path = DATA_DIR / f"{name}.json"
    if not path.exists():
        sys.exit(f"Missing {path}. Run: python3 tools/export_data.py")
    return json.loads(path.read_text(encoding="utf-8"))


def strip_docs(value):
    """Drops the "_README" and "_note" keys the hand-written files carry.

    They are there for whoever opens the file, not for the game, and they are
    a noticeable share of the bytes in playtest_level.json.
    """
    if isinstance(value, dict):
        return {k: strip_docs(v) for k, v in value.items() if not k.startswith("_")}
    if isinstance(value, list):
        return [strip_docs(item) for item in value]
    return value


def flatten_rules(raw: dict) -> dict:
    """rules.json keeps each switch beside notes explaining the options.

    The game only needs the chosen value. Same as DataDB._flatten_rules.
    """
    flat = {}
    for key, entry in raw.items():
        if key.startswith("_"):
            continue
        flat[key] = entry["value"] if isinstance(entry, dict) and "value" in entry else entry
    return flat


def fill_name_tokens(level: dict, player: dict) -> dict:
    """Substitutes {party} in stage names with the player's actual party.

    The caucus is the player's OWN party's caucus, so its name has to follow
    whoever the protagonist turns out to be - and CLAUDE.md still lists the
    protagonist's party as an open decision. Writing a party name into
    playtest_level.json would quietly settle it.

    Same as DataDB._fill_name_tokens, and done here for the same reason: this
    script is the web build's data loader, so by the time the page sees a
    stage the token is already gone.
    """
    party = str(player.get("party", "")).strip()

    for stage in level.get("stages", []):
        name_en = stage.get("name_en", "")
        if "{party}" not in name_en:
            continue
        if party:
            stage["name_en"] = name_en.replace("{party}", party)
        else:
            # No party settled yet. "Party Caucus" reads worse than plain
            # "Caucus", so the token takes its trailing space with it.
            stage["name_en"] = name_en.replace("{party} ", "").replace("{party}", "").strip()

    return level


def default_protagonist(player_file: dict) -> dict:
    """player.json lists four protagonists; the page plays as the default one.

    The page has no New Game screen, so it is always whoever
    default_protagonist names - the same one the Godot build starts as.
    """
    protagonists = player_file.get("protagonists", [])
    wanted = player_file.get("default_protagonist", "")
    for entry in protagonists:
        if entry.get("player_id") == wanted:
            return entry
    return protagonists[0] if protagonists else {}


def _intent_pattern_from_ranges(opponent: dict) -> list:
    """The [verb, low, high] pattern IntentRunner wants, off one opponent's
    three intent_*_range columns.

    Ported from DataDB.gd's `_intent_pattern_from_ranges` (2026-09-22
    workbook). A verb whose range is null is left out of the pattern
    entirely — the hard sentinel for "this opponent never does this move" —
    rather than turned into a [verb, 0, 0] move, which IntentRunner's own
    zero rule would read as a different fact (a real range that happens to
    roll 0-0).
    """
    pattern = []
    for verb, key in [
        ("attack", "intent_attack_range"),
        ("gain", "intent_gain_range"),
        ("block", "intent_block_range"),
    ]:
        r = opponent.get(key)
        if isinstance(r, dict) and "min" in r:
            pattern.append([verb, int(r["min"]), int(r["max"])])
    return pattern


def _opponent_with_pattern(opponent: dict) -> dict:
    """An opponent row, with its intent_pattern built if it does not already
    carry one. Mirrors DataDB.gd's `get_opponent()`.
    """
    if opponent.get("intent_pattern") is not None:
        return opponent
    pattern = _intent_pattern_from_ranges(opponent)
    if not pattern:
        return opponent
    filled = dict(opponent)
    filled["intent_pattern"] = pattern
    return filled


def _eligible_opponents_by_stage(opponents: list) -> dict:
    """Every opponent, grouped by every STxx their own "stages" list names,
    each one already carrying its built intent_pattern (see
    _opponent_with_pattern's own note on why that matters), sorted by opp_id
    for a stable, deterministic pick. Mirrors BattleSetup.gd's
    `eligible_opponents()`.
    """
    by_stage: dict = {}
    for opponent in opponents:
        filled = _opponent_with_pattern(opponent)
        for stage_id in opponent.get("stages", []) or []:
            by_stage.setdefault(stage_id, []).append(filled)
    for rows in by_stage.values():
        rows.sort(key=lambda o: str(o.get("opp_id", "")))
    return by_stage


def _resolve_pin(level_id: str, stage_id: str, slot: int, overrides: list,
                  opponents_by_id: dict) -> dict:
    """The hand-written pin for one level+slot from
    data/level_opponent_overrides.json, honoured only when it names someone
    really eligible for that stage. Mirrors BattleSetup.gd's
    `_resolve_pin()` — an invalid or ineligible pin is a printed note, not a
    crash, and falls back to the dynamic pick.
    """
    row = next((r for r in overrides
                if str(r.get("level_id", "")) == level_id and int(r.get("slot", -1)) == slot),
               None)
    if row is None:
        return {}

    opp_id = str(row.get("opp_id", ""))
    pinned = opponents_by_id.get(opp_id)
    if not pinned:
        print(f"  ! level_opponent_overrides.json pins unknown opponent "
              f"{opp_id!r} for {level_id} slot {slot}")
        return {}
    if stage_id not in (pinned.get("stages", []) or []):
        print(f"  ! level_opponent_overrides.json pins {opp_id} to {level_id} "
              f"slot {slot} ({stage_id}), but they are not eligible there. "
              f"Falling back to the dynamic pick.")
        return {}
    return _opponent_with_pattern(pinned)


def resolve_workbook_level(level: dict, stages_by_id: dict, by_stage: dict,
                            opponents_by_id: dict, overrides: list, player: dict) -> dict:
    """Expands one of levels.json's 30 flat rows (stage_1..stage_10, no
    opponent column) into the { level_id, stages: [...] } shape web/src/ui.js
    already expects a level to have.

    This is the web-build mirror of scripts/BattleSetup.gd's
    `expand_level()`. Each entry in "stages" is a full stages.json row (so
    segment_mix and every win_delta_*/loss_delta_* field ui.js already reads
    is present) plus:
        seq                1, 2, 3... in stage_1..stage_10 order, skipping nulls
        opponents          [the opponent] for an ordinary combat stage, or
                            [the chair] for a committee stage
        committee_members  the rest of the roster, for a committee stage

    Who fights whom is not in the workbook: an ordinary stage's opponent is
    whoever is eligible for that STxx (lowest opp_id as the tie-breaker), and
    a committee's chair is chosen the same way, unless
    level_opponent_overrides.json pins one. See BattleSetup.gd's own comments
    on `_opponent_for()`/`_committee_for()` for why this is dynamic rather
    than stored per level.
    """
    level_id = str(level.get("level_id", ""))
    stages = []

    for slot in range(1, 11):
        raw_stage_id = level.get(f"stage_{slot}")
        if not raw_stage_id:
            continue
        stage_id = str(raw_stage_id).strip()
        if not stage_id:
            continue

        base = stages_by_id.get(stage_id)
        if base is None:
            print(f"  ! {level_id} names stage {stage_id!r} at slot {slot}, "
                  f"which does not exist. Skipped.")
            continue

        stage = json.loads(json.dumps(base))   # a plain deep copy
        stage["seq"] = len(stages) + 1
        eligible = by_stage.get(stage_id, [])

        if stage_id in COMMITTEE_STAGE_IDS:
            pinned = _resolve_pin(level_id, stage_id, slot, overrides, opponents_by_id)
            chair = pinned or (eligible[0] if eligible else {})
            members = list(eligible)
            if pinned and not any(m.get("opp_id") == pinned.get("opp_id") for m in members):
                members.append(pinned)
            members = [m for m in members if m.get("opp_id") != chair.get("opp_id")]
            stage["opponents"] = [chair] if chair else []
            stage["committee_members"] = members
            if not eligible:
                print(f"  ! {level_id}'s committee stage {stage_id!r} (slot {slot}) "
                      f"has no eligible opponents in opponents.json")
        else:
            pinned = _resolve_pin(level_id, stage_id, slot, overrides, opponents_by_id)
            opponent = pinned or (eligible[0] if eligible else {})
            stage["opponents"] = [opponent] if opponent else []
            stage["committee_members"] = []
            if not eligible and not pinned:
                print(f"  ! {level_id}'s stage {stage_id!r} (slot {slot}) has no "
                      f"eligible opponent in opponents.json, so it cannot be "
                      f"fought until level_opponent_overrides.json pins one or "
                      f"the workbook adds one.")

        stages.append(stage)

    if not stages:
        print(f"  ! {level_id} names no playable stages at all. Skipped from the web build.")
        return {}

    built = dict(level)
    built["stages"] = stages
    # levels.json carries no name_en/name_jp/blurb — a workbook level row is
    # just which stages it plays, in order. This is a DISPLAY decision, not a
    # data one: the "description" column reads as a short title already
    # ("Talking with Constituents", "Meeting Lobbyists"), so it stands in for
    # name_en, there is no Japanese to show, and the blurb becomes the plain
    # run of stage names — the closest thing to "what this level holds" that
    # exists without inventing flavour text on Cameron's behalf.
    built["name_en"] = str(level.get("description", "") or level_id)
    built["name_jp"] = ""
    built["blurb"] = " → ".join(str(s.get("name_en", s.get("stage_id", ""))) for s in stages)
    return fill_name_tokens(built, player)


def resolve_workbook_levels(levels: list, stages: list, opponents: list,
                             overrides: list, player: dict) -> list:
    stages_by_id = {str(s.get("stage_id", "")): s for s in stages}
    opponents_by_id = {str(o.get("opp_id", "")): o for o in opponents}
    by_stage = _eligible_opponents_by_stage(opponents)

    out = []
    for level in levels:
        built = resolve_workbook_level(level, stages_by_id, by_stage, opponents_by_id,
                                        overrides, player)
        if built:
            out.append(built)
    return out


def build_data() -> dict:
    raw = {name: read_json(name) for name in NEEDED}
    raw["player"] = default_protagonist(raw["player"])

    cards = list(raw["cards"])
    # Hand-written playtest cards are appended to the workbook's, exactly as
    # DataDB does it, so everything downstream treats them as ordinary cards.
    cards.extend(raw["playtest_cards"].get("cards", []))

    # 2026-09-22 workbook: modifiers.json carries its own effect_type /
    # effect_target / effect_value columns now (see ModifierEffects.gd), so
    # there is no more hand-written modifier_effects.json bridge to load —
    # web/src/engine.js's own ModifierEffects port dispatches on those
    # columns directly.

    return strip_docs({
        "affinity": raw["affinity"],
        "balance": raw["balance"],
        "booster_standing": raw["booster_standing"],
        "modifiers": raw["modifiers"],
        "boosters": raw["boosters"],
        "cards": cards,
        "journalists": raw["journalists"].get("journalists", []),
        "player": raw["player"],
        # The 30 workbook levels, each stage expanded with its opponent(s) or
        # committee roster worked out the same way BattleSetup.gd's
        # expand_level() does — see resolve_workbook_levels()'s own notes.
        "levels": resolve_workbook_levels(
            raw["levels"], raw["stages"], raw["opponents"],
            raw["level_opponent_overrides"].get("overrides", []),
            raw["player"]),
        "playtest_level": fill_name_tokens(raw["playtest_level"], raw["player"]),
        "rules": flatten_rules(raw["rules"]),
        "sanban": raw["sanban"],
        "segments": raw["segments"],
        # Every line the game says, from the workbook's Text tab. The page
        # looks these up exactly as the Godot build does, so rewording one in
        # the spreadsheet changes both rather than only one of them.
        "strings": raw["strings"],
        # The questions each kind of room can ask, and the five spoken lines
        # each card has. Both Cameron's writing, both from the workbook.
        "questions": raw["questions"],
        "card_cues": raw["card_cues"],
        # Only what a playtest stage borrows: the audience mix of the canon
        # stage it is modelled on (plus its "% Other" share, which is part of
        # the same 100% but not one of segment_mix's own rows — see
        # BattleSetup.gd's with_audience() and engine.js's own copy of it).
        # The rest of a stage row is not used here.
        "stages": [
            {
                "stage_id": row["stage_id"],
                "segment_mix": row.get("segment_mix", {}),
                "pct_other": row.get("pct_other", 0.0),
            }
            for row in raw["stages"]
        ],
        "suits": raw["suits"],
    })


def data_uri(relative: str) -> str:
    """Reads an asset and returns it as a data: URI.

    The page has to be ONE file - Cameron opens it from a link on a phone,
    with no server to fetch a second request from - so the card frames are
    carried inside it rather than referenced. They are the only art the page
    has; everything else is still a labelled placeholder block.
    """
    path = ASSET_DIR / relative
    if not path.exists():
        sys.exit(f"Missing {path}")
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def read_source(name: str) -> str:
    path = SRC_DIR / name
    if not path.exists():
        sys.exit(f"Missing {path}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    data = build_data()

    # "</script" inside a string would close the surrounding tag early. The
    # JSON stays valid either way because < is the same character.
    data_json = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    data_json = data_json.replace("</", "<\\/")

    page = read_source("index.html")
    for marker, replacement in [
        ("/*{{DATA}}*/ {}", data_json),
        ("/*{{FRAME_FRONT}}*/", data_uri("cards/frame_front_shoji.png")),
        ("/*{{FRAME_BACK}}*/", data_uri("cards/frame_back_shoji.png")),
        ("/*{{ENGINE}}*/", read_source("engine.js")),
        ("/*{{TESTS}}*/", read_source("tests.js")),
        ("/*{{UI}}*/", read_source("ui.js")),
    ]:
        if marker not in page:
            sys.exit(f"index.html has no {marker} to fill in")
        page = page.replace(marker, replacement, 1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(page, encoding="utf-8")

    size_kb = len(page.encode("utf-8")) / 1024
    print(f"  {OUTPUT.relative_to(REPO_ROOT)}  {size_kb:.0f} KB")
    stages = sum(len(level["stages"]) for level in data["levels"])
    print(f"  {len(data['cards'])} cards, {len(data['levels'])} levels, "
          f"{stages} stages, {len(data['journalists'])} reporters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
