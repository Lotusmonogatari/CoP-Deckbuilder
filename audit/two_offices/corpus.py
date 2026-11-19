"""The player-facing text corpus: (table, key, field, text) for every table the audit covers."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *


def corpus():
    out = []

    def add(table, key, field, text):
        if isinstance(text, str) and text.strip():
            out.append((table, str(key), field, text))

    for r in load("strings"):
        add("strings", r["key"], "english", r.get("english"))
    for r in load("events"):
        add("events", r["event_id"], "title", r.get("title")); add("events", r["event_id"], "flavor", r.get("flavor"))
    for r in load("event_choices"):
        k = "%s.%s" % (r["event_id"], r["choice"])
        for f in ("choice_text", "result_text", "promise_kept_text"):
            add("event_choices", k, f, r.get(f))
    for r in load("hosted_events"):
        for f in ("title", "intro", "prompt_1", "prompt_2", "prompt_3"):
            add("hosted_events", r["hosted_id"], f, r.get(f))
    for r in load("event_options"):
        k = "%s.%s.%s" % (r["hosted_id"], r["step"], r["option_id"])
        for f in ("choice_text", "flavor", "promise_kept_text"):
            add("event_options", k, f, r.get(f))
    for r in load("level_intros"):
        add("level_intros", "%s.%s" % (r["level_id"], r["role"]), "cue_text", r.get("cue_text"))
    for r in load("level_intro_thoughts"):
        add("level_intro_thoughts", r["level_id"], "thought_text", r.get("thought_text"))
    for r in load("levels"):
        add("levels", r["level_id"], "description", r.get("description")); add("levels", r["level_id"], "purpose", r.get("purpose"))
    for r in load("stages"):
        add("stages", r["stage_id"], "name_en", r.get("name_en"))
    for r in load("transition_dialogue"):
        add("transition_dialogue", r["transition_dialogue_id"], "character_line_en", r.get("character_line_en"))
        add("transition_dialogue", r["transition_dialogue_id"], "player_reply_en", r.get("player_reply_en"))
    for r in load("visitor_questions"):
        k = r["question_id"]
        add("visitor_questions", k, "question_text", r.get("question_text"))
        for L in "abcd":
            for f in ("choice_", "response_", "promise_kept_text_"):
                add("visitor_questions", k, f + L, r.get(f + L))
        for f in ("response_right", "response_wrong"):
            add("visitor_questions", k, f, r.get(f))
    for r in load("visit_questions"):
        add("visit_questions", r["question_id"], "text_en", r.get("text_en"))
    for r in load("trade_questions"):
        add("trade_questions", r["question_id"], "text_en", r.get("text_en"))
    for r in load("visit_answers"):
        for f, v in r.items():
            if isinstance(v, str) and f not in ("reply_kind", "style"):
                add("visit_answers", r.get("answer_id") or r.get("reply_kind") or "?", f, v)
    for r in load("staff_tasks"):
        for f in ("title", "context"):
            add("staff_tasks", r["task_id"], f, r.get(f))
    for r in load("office_ticker"):
        add("office_ticker", r["ticker_id"], "text_en", r.get("text_en"))
    for r in load("office_notices"):
        add("office_notices", r["notice_id"], "text_en", r.get("text_en"))
    for r in load("how_to_play"):
        for f in ("heading_en", "body_en", "caption"):
            add("how_to_play", r["entry_id"], f, r.get(f))
    for r in load("shop"):
        add("shop", r["item_id"], "name", r.get("name")); add("shop", r["item_id"], "description", r.get("description"))
    for r in load("visitors"):
        add("visitors", r["visitor_id"], "title", r.get("title"))
    for r in load("lobbyist_lines"):
        add("lobbyist_lines", r["line_id"], "line_en", r.get("line_en"))
    for r in load("reaction_lines"):
        add("reaction_lines", r["level"], "line", r.get("line"))
    # Spoken cues (large): opponents, player, cards.
    for r in load("opponent_cues"):
        for i in range(1, 8):
            add("opponent_cues", r["cue_id"], "cue_%d" % i, r.get("cue_%d" % i))
    for r in load("player_cues"):
        for i in range(1, 8):
            add("player_cues", r["cue_id"], "cue_%d" % i, r.get("cue_%d" % i))
    for r in load("card_cues"):
        for i in range(1, 8):
            add("card_cues", r["card_id"], "cue_%d" % i, r.get("cue_%d" % i))
    q = load("questions")
    for pool, rows in q.items():
        if isinstance(rows, list):
            for r in rows:
                add("questions." + pool, r.get("id"), "text", r.get("text"))
    return out


if __name__ == "__main__":
    c = corpus()
    import collections
    print(len(c), collections.Counter(t for t, *_ in c).most_common())
