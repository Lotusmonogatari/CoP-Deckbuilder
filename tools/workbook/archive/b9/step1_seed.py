"""Patron Bills step 1: adds the four new tabs, the Component ID header on four
content tabs, and the Balance levers to the design workbook (raw XML, never
openpyxl). Seeds five organizations (BO05, BO07, BO10, BO24, BO30).

Run once from the repo root:  python3 tools/workbook/archive/b9/step1_seed.py
"""
import csv, shutil, sys
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b9")
from wbx import WB, add_sheet, n2col
from add_notes import add_notes
import patron_plan as P

PATH = "design/Game_Workbook.xlsx"
SEED = ["BO05", "BO07", "BO10", "BO24", "BO30"]
PIDS = {"Butsutou": "PT01", "Yezo Heritage Party": "PT02", "Frontier Party": "PT03",
        "Five Point Independents": "PT04", "Keizaijiyuutou": "PT05", "Country Initiative": "PT06"}
shutil.copy(PATH, "/tmp/before_patron_step1.xlsx")

# --- Party Values (long form of design/reference/party_values.tsv) -----------
rows = list(csv.reader(open("design/reference/party_values.tsv"), delimiter="\t"))
dims = rows[0][2:36]
pv = []
for r in rows[1:]:
    vals, pri, sal = r[2:36], r[36:70], r[70:104]
    for d, v, p_, s_ in zip(dims, vals, pri, sal):
        pv.append([PIDS[r[0]], d, int(v), int(p_), int(s_)])
add_sheet(PATH, "Party Values", ["Party ID", "Dimension", "Value", "Priority", "Salience"], pv, [10, 28, 8, 8, 9])

# --- Bill Components -----------------------------------------------------------
def tags(t): return "; ".join("%s %s" % (k, ("%+g" % v)) for k, v in t.items())
comp = []
for o in SEED:
    rival, ally, cs = P.ORGS[o]
    for i, (phrase, cmt, t) in enumerate(cs):
        gain = 3 if i == 0 else 2
        comp.append([P.comp_ids[(o, i)], o, "XYZ"[i], phrase[0].upper() + phrase[1:], phrase,
                     "Would %s." % phrase, cmt, tags(t), "%s +%d" % (o, gain), "%s -2" % rival, None, None, None])
add_sheet(PATH, "Bill Components", ["Component ID", "Owner", "Slot", "Short Label", "Phrase", "Description",
          "Hearing Committee", "Value Tags", "Gains", "Loses", "Excludes", "Each Level Effect", "Amend Options"],
          comp, [12, 8, 6, 34, 46, 50, 12, 46, 14, 14, 12, 16, 14])

# --- Patron Bills ---------------------------------------------------------------
pb = []
for o in SEED:
    rival, ally, cs = P.ORGS[o]
    for ki, (kind, idx) in enumerate((("Favor", [(o, 0), (o, 1)]), ("Flagship", [(o, 0), (o, 2), (ally, 0)])), start=1):
        phrases = [P.ORGS[k][2][i][0] for k, i in idx]
        pb.append(["PB%02d%d" % (int(o[2:]), ki), o, kind, None, "; ".join(P.comp_ids[x] for x in idx),
                   ally if kind == "Flagship" else None, "BT01" if kind == "Favor" else "BT02",
                   "{org} asks you to carry a bill: {bill}. Will you?",
                   "You take it on. {org} is counting on you.",
                   "You tell {org} you cannot carry it. They do not hide their disappointment.",
                   "The bill passes, and {org} will not forget who carried it.",
                   "The bill falls short, and {org} knows you tried.",
                   "Draft 2026-10-19: lines use {org} and {bill}; Cameron to rewrite."])
add_sheet(PATH, "Patron Bills", ["Patron Bill ID", "Organization", "Kind", "Threshold", "Components", "Ally", "Template ID",
          "Request Line", "Accept Line", "Decline Line", "Pass Line", "Fail Line", "Note"], pb,
          [14, 14, 10, 10, 22, 10, 10, 50, 40, 50, 46, 40, 40])

# --- Bill Level Templates -------------------------------------------------------
add_sheet(PATH, "Bill Level Templates", ["Template ID", "Kind", "Level Tier", "Stage 1", "Stage 2", "Stage 3", "Stage 4", "Stage 5", "Note"],
          [["BT01", "Favor", 1, "PATRON_MEETING", "HEARING", "VOTE", None, None,
            "Draft: a meeting with the organization, the committee hearing for the first component, the Floor Vote."],
           ["BT02", "Flagship", 2, "PATRON_MEETING", "HEARING", "PUBLIC", "CAUCUS", "VOTE",
            "Draft: adds a public room (Town Hall for a Constituency organization, Press Conference for a National one) and your own Party Caucus."]],
          [12, 10, 10, 18, 14, 14, 14, 14, 70])

# --- Component ID header on four content tabs -----------------------------------
from wbx import col2n
w = WB(PATH)
cid_cols = {}
for tab in ("Stage Questions", "Player Cues", "Opponent Cues", "Transition Dialogue"):
    hdr = w.rows(tab)[1]
    last = max(hdr, key=col2n)
    col = n2col(col2n(last) + 1)
    w.set_cell(tab, 1, col, "Component ID", style=w.sty(tab, last + "1"))
    cid_cols[tab] = col
    print(tab, "-> column", col)
# --- Balance levers -----------------------------------------------------------
LEV = [
 ("Patron: Favor Threshold", 50, "First-draft. Standing with an organization at or above this brings its Favor request (two of its own components)."),
 ("Patron: Flagship Threshold", 70, "First-draft. Standing at or above this, after the Favor request is resolved, brings its Flagship request (its own X and Z plus its ally's X)."),
 ("Patron: Requests Waiting At Once", 2, "First-draft. More requests wait in a queue."),
 ("Patron: Favor Decline Cost", 5, "First-draft. Standing lost with the organization when you decline a Favor request."),
 ("Patron: Flagship Decline Cost", 10, "First-draft. Standing lost with the organization when you decline a Flagship request."),
 ("Patron: Amend Reward Percent", 75, "First-draft. Rewards are this percent when you swap a component (Favor: one of two; Flagship: the ally's)."),
 ("Patron: Favor Pass Standing", 6, "First-draft. Patron standing gained when a Favor bill passes."),
 ("Patron: Flagship Pass Standing", 10, "First-draft. Patron standing gained when a Flagship bill passes."),
 ("Patron: Ally Pass Standing", 4, "First-draft. Ally standing gained when a Flagship bill passes."),
 ("Patron: Favor Rival Penalty", 2, "First-draft. Rival standing lost when a Favor bill passes."),
 ("Patron: Flagship Rival Penalty", 3, "First-draft. Rival standing lost when a Flagship bill passes."),
 ("Patron: Fail Standing", 2, "First-draft. Patron standing lost when its bill fails the vote."),
 ("Patron: Ally Fail Standing", 1, "First-draft. Ally standing lost when a Flagship bill fails the vote."),
 ("Patron: Free Backing Units", 30, "First-draft. Game-clock units the patron's backing is free after a Flagship bill passes."),
 ("Patron: Default Margin", 6, "First-draft. A patron bill's default Yes votes are held this many below the votes needed (51), turned into abstentions, so no patron bill passes without the player's influence."),
 ("Custom Law Scale Percent", 50, "First-draft. Percent of the components' organization effects that apply when a patron or custom bill passes or fails."),
]
for name, val, note in LEV:
    w.append_row("Balance", {"A": name, "B": val, "C": note}, style_row=w.last_data_row("Balance"))
w.save()

add_notes(PATH, [
 ("Stage Questions", cid_cols["Stage Questions"], "Optional. A question about one bill component (CBxx, from the Bill Components tab), asked in levels built from components. Needs no Stage ID or Bill ID of its own."),
 ("Player Cues", cid_cols["Player Cues"], "Optional. A cue about one bill component (CBxx). Said only in levels built from that component."),
 ("Opponent Cues", cid_cols["Opponent Cues"], "Optional. A cue about one bill component (CBxx). Said only in levels built from that component."),
 ("Transition Dialogue", cid_cols["Transition Dialogue"], "Optional. A line about one bill component (CBxx). Used between stages of a level built from that component."),
])
print("done")
