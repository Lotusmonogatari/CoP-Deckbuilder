"""Influence building step B: the MP visit (2026-10-19). Adds two stages
(ST260 Member Visit, ST261 Member Fight) with their Affinity columns, the
MP_VISIT template token (Bill Level Templates gets Stage 6-8 and Visit Parties),
the Visit Questions and Visit Answers tabs, Text rows and Balance levers.
Raw XML only. Run once from the repo root."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet, replace_sheet_data, n2col, col2n

PATH = "design/Game_Workbook.xlsx"

def num(v):
    try:
        f = float(v)
        return int(f) if f == int(f) and "." not in str(v) else f
    except (TypeError, ValueError):
        return v

w = WB(PATH)
# ---- Affinity: two new stage columns (copies of ST07 and ST03)
aff = w.rows("Affinity")
hdr = aff[1]
last = max(hdr, key=lambda c: col2n(c))
src_col = {hdr[c]: c for c in hdr}
new_cols = {}
for k, (sid, base, name) in enumerate((("ST260", "ST07", "Member Visit"), ("ST261", "ST03", "Win Over a Member"))):
    col = n2col(col2n(last) + 1 + k)
    new_cols[sid] = col
    sty = lambda r: w.sty("Affinity", f"{last}{r}")
    w.set_cell("Affinity", 1, col, sid, style=sty(1))
    bc = src_col[base]
    vals = []
    for r in range(2, 8):
        v = num(aff[r][bc]); vals.append(v)
        w.set_cell("Affinity", r, col, v, style=sty(r))
    w.set_cell("Affinity", 9, col, name, style=sty(9))
    w.set_cell("Affinity", 10, col, round(sum(vals) / 6, 4), formula=f"AVERAGE({col}2:{col}7)", style=sty(10))

# ---- Stages: two new rows
rows = w.rows("Stages")
H = rows[1]
by_name = {v: k for k, v in H.items()}
r03 = rows[w.find_row("Stages", "ST03")]; r07 = rows[w.find_row("Stages", "ST07")]
def build(src, over):
    out = {}
    for col, val in src.items():
        out[col] = num(val)
    for name, val in over.items():
        out[by_name[name]] = val
    return out
blank_rewards = {n: None for n in ("Win ΔJiban", "Win ΔYen", "Win ΔReputation", "Win ΔXP", "Win ΔParty support",
                                  "Loss ΔJiban", "Loss ΔYen", "Loss ΔReputation", "Loss ΔXP", "Loss ΔParty support")}
visit = build(r07, dict(blank_rewards, **{"Stage ID": "ST260", "Stage (EN)": "Member Visit", "Stage (JP)": "議員来訪",
        "Romaji": "Giin Raihō", "Mode": "Visit", "Opponent Count": 3, "Loss Ends Level": "No",
        "Show Transition": None, "Background ID": "ST07", "Time Units": 0, "Favored suit": "—"}))
fight = build(r03, dict(blank_rewards, **{"Stage ID": "ST261", "Stage (EN)": "Win Over a Member", "Stage (JP)": "説得",
        "Romaji": "Settoku", "Opponent Count": 1, "Sequence Mode": "single", "Loss Ends Level": "No",
        "Show Transition": None, "Own Party Only": None, "Background ID": "ST03", "Time Units": 0}))
for stage in (visit, fight):
    r = w.last_data_row("Stages") + 1
    for col, val in stage.items():
        w.set_cell("Stages", r, col, val, style_from=r - 1)

w.save()
# ---- Bill Level Templates: Stage 6-8 and Visit Parties
replace_sheet_data(PATH, "Bill Level Templates",
    ["Template ID", "Kind", "Level Tier", "Stage 1", "Stage 2", "Stage 3", "Stage 4", "Stage 5", "Stage 6", "Stage 7", "Stage 8", "Visit Parties", "Note"],
    [["BT01", "Favor", 1, "PATRON_MEETING", "HEARING", "VOTE", None, None, None, None, None, None,
      "Draft: a meeting with the organization, the committee hearing for the first component, the Floor Vote."],
     ["BT02", "Flagship", 2, "PATRON_MEETING", "HEARING", "MP_VISIT", "PUBLIC", "CAUCUS", "VOTE", None, None, "PT04; PT02",
      "Draft: adds an optional member visit (MP_VISIT: a visit, then a one-on-one fight, for the first party in Visit Parties that still has seats outside your side), a public room (Town Hall for a Constituency organization, Press Conference for a National one) and your own Party Caucus."]],
    )

# ---- Visit Questions / Answers
STEMS = [
 "Why should I back a bill that would {component}?",
 "Who in my district actually benefits if we {component}?",
 "My voters did not send me here to {component}. Convince me.",
 "What happens to the people left out if we {component}?",
 "Is {component} really the best use of the Assembly's time?",
 "Would you still push to {component} if it cost you votes at home?",
 "Tell me how the plan to {component} is paid for.",
 "Why not wait, instead of moving now to {component}?",
 "What do you say to those who oppose any move to {component}?",
 "Convince me this is not just a favor for one group when you {component}.",
 "How would you explain it to my party if I stood with you to {component}?",
 "What is the first thing that goes wrong if we {component}?",
 "What makes you think {component} will work here?",
 "Who asked you to {component}, and why should I trust them?",
 "If I backed you to {component}, what would you owe me?",
 "What would it take for me to stand with you on {component}?",
 "Do you really believe in {component}, or is it convenient?",
 "Is there a smaller step than {component} that we could agree on?",
 "How do I know you will not drop {component} when it gets hard?",
 "Why should a member from my party take a risk to {component}?",
 "Give me one reason my constituents would thank me for {component}.",
 "What do the experts say about {component}, and do you agree?",
 "Is {component} fair to the next generation?",
 "Do you have the votes to {component}, or are you counting on me?",
]
ANSWERS = {
 "Earnest": ["I will be straight with you: I believe this is right, and I will say so to anyone.",
   "I am not asking for a favor. I am asking you to look at it honestly with me.",
   "You deserve a plain answer, so here it is: I think it helps, and I will own it if it does not.",
   "I have nothing to hide here. Ask me anything and I will answer.",
   "I came to do what I think is right, and this is what I think is right.",
   "If I am wrong, tell me where, and I will listen."],
 "Emotional": ["Think of the families who live with this. That is who I am doing it for.",
   "I have sat in their kitchens. I cannot walk away from what I heard there.",
   "This is about people, not paper, and I think you know it.",
   "When I picture the people waiting on this, I cannot say no.",
   "Someone is hurting right now, and we can end it.",
   "I know it moves you too. I saw it on your face when we began."],
 "Appeal": ["People across the country want this, and they will remember who helped.",
   "It is popular for a reason, and it will be remembered as a win.",
   "Stand with the crowd on this one. They are on your side.",
   "Your voters will cheer when they see this come through.",
   "This is the kind of result everyone wants to be a part of.",
   "Be on the side people applaud. It will be a good day for your name."],
 "Data Driven": ["The numbers back it. Let me walk you through the figures.",
   "Here is the cost, the saving and the timeline, line by line.",
   "The evidence from elsewhere points one way.",
   "I brought the projections. Every one of them holds up.",
   "Look at the data from places that have tried it.",
   "Run the figures yourself. I am confident in what you will find."],
 "Divisive": ["Some people want this to fail. Which side are you on?",
   "The opposition will fight us on it. We should not blink.",
   "There are winners and there are those who stand in the way. Choose.",
   "Anyone who blocks this is protecting their own comfort. You are better than that.",
   "This is a fight worth having. I would rather have you in it with me.",
   "Let them complain. We know who this serves, and who it threatens."],
 "Duplicitous": ["Say yes for your own reasons, and let the credit sort itself out.",
   "Let us just say it helps your district, and leave the details out of it.",
   "No one needs to know what we agreed in this room.",
   "Let us call it something that sounds smaller, and it will pass quietly.",
   "You can tell your party whatever you like. I will not contradict you.",
   "Between us, there is room to rearrange this so everyone gets what they need."],
}
add_sheet(PATH, "Visit Questions", ["Question ID", "Text (EN)"],
          [["MV%02d" % (i + 1), s] for i, s in enumerate(STEMS)], [12, 90])
ans_rows = []
n = 1
for style, lines in ANSWERS.items():
    for line in lines:
        ans_rows.append(["MA%02d" % n, style, line]); n += 1
add_sheet(PATH, "Visit Answers", ["Answer ID", "Style", "Line (EN)"], ans_rows, [12, 14, 90])

# ---- Text rows and levers
w = WB(PATH)
TEXT = [
 ("visit.offer_title", "A visit", "Member Visit", ""),
 ("visit.offer_text", "A visit", "{name} of {party} has come to talk. Win them over, and they stand with you on this vote. Take the visit?", "name, party"),
 ("visit.take", "A visit", "Take the visit", ""),
 ("visit.skip", "A visit", "Skip it", ""),
 ("visit.caption", "A visit", "Question {number} of {total}", "number, total"),
 ("visit.continue", "A visit", "Continue", ""),
 ("visit.done_title", "A visit", "The visit is over", ""),
 ("visit.done_body", "A visit", "Rapport with {name}: {rapport}. The fight begins with {bonus} support for you.", "name, rapport, bonus"),
 ("visit.react_strong_1", "A visit", "{name} nods slowly. That is the kind of answer they respect.", "name"),
 ("visit.react_strong_2", "A visit", "{name} leans forward, interested at last.", "name"),
 ("visit.react_strong_3", "A visit", "{name} almost smiles. That landed.", "name"),
 ("visit.react_medium_1", "A visit", "{name} listens, unmoved but polite.", "name"),
 ("visit.react_medium_2", "A visit", "{name} shrugs. Not wrong, not convincing.", "name"),
 ("visit.react_medium_3", "A visit", "{name} makes a note and says nothing.", "name"),
 ("visit.react_weak_1", "A visit", "{name} frowns. That did not land.", "name"),
 ("visit.react_weak_2", "A visit", "{name} folds their arms and looks away.", "name"),
 ("visit.react_weak_3", "A visit", "{name} sighs. You have lost some ground.", "name"),
 ("visit.style.earnest", "A visit", "an honest, plain answer", ""),
 ("visit.style.emotional", "A visit", "a story that touches the heart", ""),
 ("visit.style.appeal", "A visit", "something the crowd will cheer", ""),
 ("visit.style.data_driven", "A visit", "hard numbers and evidence", ""),
 ("visit.style.divisive", "A visit", "a firm line against the other side", ""),
 ("visit.style.duplicitous", "A visit", "a quiet, clever arrangement", ""),
 ("visit.brief_1", "A visit", "{staff} leans in. \"{name} only really listens to {first}. Anything else, they tune out.\"", "staff, name, first"),
 ("visit.brief_2", "A visit", "{staff} leans in. \"{name} tends to respond to {first}, and will hear out {second}. Anything else, they tune out.\"", "staff, name, first, second"),
 ("visit.brief_3", "A visit", "{staff} leans in. \"{name} tends to respond to {first} and {second}. They will hear out {third}, and they are cold to the rest.\"", "staff, name, first, second, third"),
]
for key, where, en, ph in TEXT:
    w.append_row("Text", {"A": key, "B": where, "C": en, "D": ph or None,
                          "E": "2026-10-19 MP visit (patron Flagships)."}, style_row=w.last_data_row("Text"))
LEV = [
 ("MP Visit: Questions", 3, "First-draft. Questions a member asks in a visit."),
 ("MP Visit: Rapport Start Per Point", 5, "First-draft. Starting support the player gains in the one-on-one fight for each point of rapport (can be negative)."),
 ("MP Visit: Strong Points", 1, "First-draft. Rapport for an answer in one of the member's two favored styles."),
 ("MP Visit: Medium Points", 0, "First-draft. Rapport for an answer in the member's third style."),
 ("MP Visit: Weak Points", -1, "First-draft. Rapport for any other style."),
 ("MP Visit: Seats Won", 1, "First-draft. Seats a won-over member gives the player's pick, for that vote only."),
 ("MP Visit: Briefing Staff Rank", 2, "First-draft. The Policy Research Assistant's staff rank (tier) needed to brief the player on the member's styles; rank 2 or higher briefs, anything lower or no researcher means no briefing."),
]
for name, val, note in LEV:
    w.append_row("Balance", {"A": name, "B": val, "C": note}, style_row=w.last_data_row("Balance"))
w.save()
print("done")
