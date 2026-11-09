"""Writing review group 2, item H, data part (2026-11-09, Cameron decisions #58, #68).
Tags the topic-room player lines PL169-PL528 in the Player Cues Stance column, with
the words bill rows already use: Support (the lines argue for the bill's topic),
Oppose (against it), blank (fits either side). A row is one style and move with five
lines, so the tag is per row, judged from its lines:
  Support: Appeal gain ("Ordinary people want action on ..."), Data Driven gain
           ("Studies on ... support this"), Duplicitous gain ("Everyone agrees on ...").
  Oppose:  Emotional attack ("Tell that to those hurt by ..."), Data Driven attack
           ("What is the real cost of ..."), Divisive attack ("... serves insiders"),
           Duplicitous attack ("Who benefits from ..., really?").
  Blank:   every other row (honesty, feeling, crowds and blocks fit either side).
The Political Donation Transparency rooms (ST46-ST49) talk about the thing the bill
restricts, so their tags follow that: criticizing political donations argues FOR
the bill. Also adds the Balance row "Player Cues: Room Line Chance" = 25 that
CardCues.gd reads. Drafts for Cameron. Run from the repo root."""
import sys; sys.path.insert(0, "tools/workbook")
from collections import Counter
from wbx import WB

TAG = {("Appeal", "gain"): "Support", ("Data Driven", "gain"): "Support", ("Duplicitous", "gain"): "Support",
       ("Emotional", "attack"): "Oppose", ("Data Driven", "attack"): "Oppose",
       ("Divisive", "attack"): "Oppose", ("Duplicitous", "attack"): "Oppose"}
DONATIONS = {("Appeal", "gain"): "Support", ("Emotional", "attack"): "Support",
             ("Divisive", "attack"): "Support", ("Duplicitous", "attack"): "Support",
             ("Duplicitous", "gain"): "Oppose"}

w = WB("design/Game_Workbook.xlsx")
T = "Player Cues"
n = Counter()
for r, v in w.rows(T).items():
    cid = v.get("A", "")
    if not (cid.startswith("PL") and cid[2:].isdigit() and 169 <= int(cid[2:]) <= 528):
        continue
    assert not v.get("K"), (cid, v.get("K"))
    table = DONATIONS if "ST46" in v.get("D", "") else TAG
    tag = table.get((v["B"], v["C"]))
    if tag:
        w.set_cell(T, r, "K", tag, style_from=r)
    n[tag or "blank"] += 1

B = "Balance"
w.copy_row(B, "Player Cues: Full Bill Name Chance", {
    "A": "Player Cues: Room Line Chance", "B": 25,
    "C": "Cameron 2026-11-09. Percent of the player's lines in a bill level drawn from the room's own topic "
         "lines (Player Cues with a Stage ID and a matching or blank Stance) instead of the bill's lines; 0 turns it off."})
w.save()
print(dict(n))
