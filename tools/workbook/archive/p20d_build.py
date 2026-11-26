#!/usr/bin/env python3
"""P20 phase D (2026-11-26, Cameron): the selection, poll and end-of-run cards' extra Text rows, the committee's organization as a Rules row, and the
Stepping Aside scene (DS25 / EV134) for the cycle the player does not run in. Run once from the repo root, then python3 tools/export_data.py
--accept-wording. The prompt's own rows (selection.*, poll.*, game_over.*, run_end.*) came with phase A."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P20 phase D (2026-11-26); a draft for Cameron to edit."
w = WB("design/Game_Workbook.xlsx")
texts = {
    "selection.tag": "Candidate selection",
    "selection.score_line": "Committee score: {score} of 100",
    "selection.part_line": "{name}: {value}",
    "selection.intro": "The committee has read your file.",
    "selection.not_selected_note": "Your own campaign is closed. The campaign staff have gone home.",
    "selection.selected_note": "The campaign goes on. Sengoku no Hi is waiting.",
    "poll.tag": "Poll",
    "poll.trend_first": "The first poll of this campaign.",
    "poll.trend_up": "Up from the last poll, which read about {last}.",
    "poll.trend_down": "Down from the last poll, which read about {last}.",
    "poll.trend_same": "About where the last poll left you ({last}).",
    "poll.final": "The final poll before Sengoku no Hi.",
    "poll.movers_heading": "What moved",
    "game_over.tag": "The end",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P20 campaign: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": NOTE}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)

# Rules: the organization the Candidate Selection Committee is (its standing is a third of the committee's influence part)
w.append_row("Rules", {"A": "campaign_committee_org", "B": "BO32", "C": "an organization ID",
                       "D": "The organization that stands for the Candidate Selection Committee (its standing with the player counts toward the selection score).",
                       "F": "P20 phase D (2026-11-26, Cameron)."})

# Stepping Aside: EV134 (Dated 27.10.11, Capitol) and its scene DS25
last = w.last_data_row("Events")
w.append_row("Events", {"A": "EV134", "B": "Stepping Aside",
                        "C": "The party's notice of candidates goes up on the board outside the Capitol, and your name is not on it. You chose that some time ago. There is still a campaign to run; it just isn't yours.",
                        "D": "Dated", "E": "Weekday", "F": 1, "O": "27.10.11", "R": "Capitol"}, style_row=last - 1)
last = w.last_data_row("Event Choices")
w.append_row("Event Choices", {"A": "EV134", "B": "A", "C": "Go to work", "D": "You go back to your desk. The telephone is already ringing.", "Z": "Capitol"}, style_row=last - 1)
last = w.last_data_row("Decision Scenes")
w.append_row("Decision Scenes", {"A": "DS25", "B": "EV134", "C": "Mandatory", "D": "27.10.11", "F": "Capitol", "I": "neutral", "V": "Campaign",
                                 "O": "P20 phase D (2026-11-26). Stepping Aside: narration only, no speaker. Claude's draft for Cameron to rewrite."}, style_row=last - 1)
w.save()
print("Text rows", added)
