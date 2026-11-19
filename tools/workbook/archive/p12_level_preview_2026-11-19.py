#!/usr/bin/env python3
"""P12 (2026-11-19): the level preview's Text rows and UI Styles tokens. Claude's draft for Cameron to rewrite.
Run from the repo root; it refuses to run twice (a key that is already there stops it before anything is saved).
Then: python3 tools/export_data.py --accept-wording"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-19 P12 level preview (Claude's draft)"

# The briefing's palette, from the P12 mockups (design/proposals/img/level_preview). Group colour, names brief_*.
TOKENS = {
    "woodblock": {"brief_ground": "#EFE4CF", "brief_on_ground": "#1C1A17", "brief_on_ground_muted": "#463F36",
                  "brief_card": "#F8F1E3", "brief_ink": "#1C1A17", "brief_muted": "#4E463C", "brief_tile": "#EFE4CF",
                  "brief_accent": "#22305A", "brief_on_accent": "#F8F1E3", "brief_hot": "#C23B22"},
    "living_office": {"brief_ground": "#2B1D12", "brief_on_ground": "#FFF8EC", "brief_on_ground_muted": "#E8DAC3",
                      "brief_card": "#FFF8EC", "brief_ink": "#2B1D12", "brief_muted": "#5C4A38", "brief_tile": "#F3E4C8",
                      "brief_accent": "#FFD58A", "brief_on_accent": "#2B1D12", "brief_hot": "#FFD58A"},
    "broadcast": {"brief_ground": "#0B1220", "brief_on_ground": "#F4F1EA", "brief_on_ground_muted": "#C3C9D6",
                  "brief_card": "#141E33", "brief_ink": "#F4F1EA", "brief_muted": "#B9C0CF", "brief_tile": "#0E1728",
                  "brief_accent": "#E3B341", "brief_on_accent": "#0B1220", "brief_hot": "#E3B341"},
}

# key, where, English, placeholders
ROWS = [
    ("briefing.meta", "Level briefing, under the title: the level's tier and how many rooms it has", "Tier {tier} · {count} rooms", "tier, count"),
    ("briefing.meta.one", "Level briefing, under the title, a level with one room", "Tier {tier} · 1 room", "tier"),
    ("briefing.purpose", "Level briefing, what the level is for, said by a staff member", "{speaker}: “{line}”", "speaker, line"),
    ("briefing.purpose_plain", "Level briefing, what the level is for with no staff to say it (narration)", "“{line}”", "line"),
    ("briefing.back_levels", "Level briefing, the link at the top that goes back to the level list", "Levels", ""),
    ("briefing.badge_hours", "Level briefing, the word under the hours number in the badge", "hours", ""),
    ("briefing.badge_hours.one", "Level briefing, the word under the hours number in the badge, one hour", "hour", ""),
    ("briefing.week_left", "Level briefing, the work week's hours left before this level", "This week: {count} hours left", "count"),
    ("briefing.week_left.one", "Level briefing, the work week's hours left before this level, one hour", "This week: 1 hour left", ""),
    ("briefing.weekend_left", "Level briefing, the weekend's hours left before this level", "This weekend: {count} hours left", "count"),
    ("briefing.weekend_left.one", "Level briefing, the weekend's hours left before this level, one hour", "This weekend: 1 hour left", ""),
    ("briefing.week_after", "Level briefing, the hours left once this level is played", "{count} left after this level", "count"),
    ("briefing.win_every_room", "Level briefing, heading of the totals card: what winning every room pays", "If you win every room", ""),
    ("briefing.bonus_range", "Level briefing, a total's level bonus when it is a range; {low} and {high} carry their signs", "{low} to {high} bonus", "low, high"),
    ("briefing.bonus_fixed", "Level briefing, a total's level bonus when it is one amount; {amount} carries its sign", "{amount} bonus", "amount"),
    ("briefing.how_it_pays", "Level briefing, the note in the totals card saying when rooms and the bonus pay", "Each room pays when you win it. The bonus is paid when you win the level.", ""),
    ("briefing.tile_xp", "Level briefing, the label of the XP tile in the totals card", "XP Growth", ""),
    ("briefing.orgs_if_win", "Level briefing, heading of the organizations card", "Organizations, if you win", ""),
    ("briefing.rooms_in_order", "Level briefing, heading of the timeline of rooms", "Rooms, in order", ""),
    ("briefing.room_line", "Level briefing, a room's kind and length on its block", "{kind} · {hours}", "kind, hours"),
    ("briefing.kind_conversation", "Level briefing, a room of the Office Hours kind (no cards)", "Conversation", ""),
    ("briefing.kind_debate", "Level briefing, a card battle room", "Debate", ""),
    ("briefing.kind_vote", "Level briefing, the Floor Vote room", "Vote", ""),
    ("briefing.kind_visit", "Level briefing, a member visit room", "Member visit", ""),
    ("briefing.kind_trade", "Level briefing, a lobbyist trade room", "Trade", ""),
    ("briefing.hour_mark", "Level briefing, hours as a short mark on the timeline ruler and a room's block", "{count} h", "count"),
    ("briefing.finish_bonus", "Level briefing, the marker at the end of the timeline", "Level bonus, paid when you win the level", ""),
    ("briefing.range", "Level briefing, an organization's standing range in the organizations card; {low} and {high} carry their signs", "{low} to {high}", "low, high"),
    ("briefing.go_in_hours", "Level briefing, the Go in button with the level's length", "Go in · {count} hours", "count"),
    ("briefing.go_in_hours.one", "Level briefing, the Go in button with the level's length, one hour", "Go in · 1 hour", ""),
]

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")
    for key, *_ in ROWS:
        try:
            w.find_row("Text", key)
            raise SystemExit("already there: " + key)
        except KeyError:
            pass
    text_style = w.last_data_row("Text")
    for key, where, english, placeholders in ROWS:
        cells = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            cells["D"] = placeholders
        w.append_row("Text", cells, style_row=text_style)
    ui_style = w.last_data_row("UI Styles")
    number = int(w.rows("UI Styles")[ui_style]["A"][2:])
    for style, tokens in TOKENS.items():
        for token, value in tokens.items():
            number += 1
            w.append_row("UI Styles", {"A": "US%03d" % number, "B": style, "C": "colour", "D": token, "E": value,
                                       "F": "P12 level preview palette (mockups, 2026-11-19). Claude's draft."}, style_row=ui_style)
    w.save()
    print("added %d Text rows and %d tokens" % (len(ROWS), sum(len(t) for t in TOKENS.values())))
