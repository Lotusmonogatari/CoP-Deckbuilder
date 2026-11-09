"""Writing review group 2, item 7 (2026-11-09, Cameron decisions #32, #67).
A new room, ST289 Candidate Selection Committee, copied from the Party Caucus (ST03:
own party only, the same rules, rewards and audience, the caucus picture), and a new
one-stage Tier 1 level, LV114 Candidate Selection Interview, built like LV86 (Office
Hours): Tier 1 unlock costs like the other Tier 1 levels (150 / 100 / 50 / 10 XP),
cooldown 96, no discovery needed, a purpose line said by the Policy Research
Assistant. The ten candidate-selection questions S573-S582 move from every Party
Caucus to this room only. The same ten caucus members who sit in ST03 are seated
here, four player transition thoughts that fit any party room are shared with it,
and its Affinity column copies the Party Caucus. Japanese name and romaji, the level
name and the purpose line are drafts for Cameron. Run from the repo root."""
import sys; sys.path.insert(0, "tools/workbook")
from wbx import WB
w = WB("design/Game_Workbook.xlsx")
NEW_ST, NEW_LV = "ST289", "LV114"
assert all(v.get("A") != NEW_ST for v in w.rows("Stages").values())
assert all(v.get("A") != NEW_LV for v in w.rows("Levels").values())

# 1. The room.
w.copy_row("Stages", "ST03", {"A": NEW_ST, "B": "Candidate Selection Committee", "C": "候補者選考委員会",
                              "D": "Kōhosha Senkō Iinkai", "W": 1, "X": "—", "AX": "ST03"})
# 2. Affinity: the Party Caucus column, copied.
aff = w.rows("Affinity")
src = [k for k, v in aff[1].items() if v == "ST03"][0]
last = max(aff[1], key=lambda c: (len(c), c))
from wbx import col2n, n2col
newc = n2col(col2n(last) + 1)
w.set_cell("Affinity", 1, newc, NEW_ST, style_from=1)
for r in range(2, 8):
    w.set_cell("Affinity", r, newc, float(aff[r][src]) if "." in aff[r][src] else int(aff[r][src]))
w.set_cell("Affinity", 9, newc, "Candidate Selection Committee")
# 3. People: everyone who sits in the Party Caucus sits here too.
for r, v in w.rows("Opponents").items():
    stages = [s.strip() for s in (v.get("I") or "").split(";") if s.strip()]
    if "ST03" in stages and NEW_ST not in stages:
        w.set_cell("Opponents", r, "I", v["I"] + "; " + NEW_ST)
# 4. Questions S573-S582: this room only.
for n in range(573, 583):
    r = w.find_row("Stage Questions", f"S{n}")
    w.set_cell("Stage Questions", r, "B", NEW_ST)
# 5. Transitions: shared player thoughts that fit any party room, and the caucus picture.
for td in ("TD1296", "TD1298", "TD1299", "TD1301"):
    r = w.find_row("Transition Dialogue", td)
    w.set_cell("Transition Dialogue", r, "C", w.rows("Transition Dialogue")[r]["C"] + "; " + NEW_ST)
tb = [v["A"] for v in w.rows("Transition Backgrounds").values() if v.get("A", "").startswith("TB")]
nxt = "TB%d" % (max(int(t[2:]) for t in tb) + 1)
w.copy_row("Transition Backgrounds", "TB78", {"A": nxt, "B": NEW_ST, "C": "ST03"})
# 6. The level.
w.copy_row("Levels", "LV86", {"A": NEW_LV, "B": "Candidate Selection Interview", "C": 96, "D": 1,
                              "E": 150, "F": 100, "G": 50, "H": 10, "I": NEW_ST, "BF": None,
                              "BK": "The party's candidate selection committee wants to hear your case before it decides.",
                              "BL": "Policy Research Assistant"})
w.save()
print("added", NEW_ST, NEW_LV, nxt, "affinity column", newc)
