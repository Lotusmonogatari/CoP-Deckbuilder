#!/usr/bin/env python3
"""P15 (2026-11-23): the CPTPP Decision! sequence, two whips and two votes, written into the workbook with wbx.

Run once from the repo root: python3 tools/workbook/archive/p15_cptpp_whip_build.py
Then: python3 tools/export_data.py (must say "No errors"). Every sentence here is Claude's draft for Cameron to rewrite.
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
DRAFT = "Claude's draft for Cameron to rewrite (P15, 2026-11-23)."


def last(name):
    return w.last_data_row(name)


# --- 1. People: the three whips (opponents) and the two new visitors ------------------------------------------------------------
WHIPS = [
    ("OP132", "Tomoe Sakamoto", "Assistant Party Whip", "F"),
    ("OP133", "Isamu Takaoka", "Deputy Party Whip", "M"),
    ("OP134", "Nobuko Ezaki", "Chief Party Whip", "F"),
]
for opp_id, name, title, gender in WHIPS:
    w.append_row("Opponents", {"A": opp_id, "B": name, "C": title, "D": gender, "G": "BO01", "H": "Party Whip's Office",
                               "I": "ST290", "J": "Divisive", "K": "Emotional", "L": "Earnest",
                               "M": "4-6", "N": "0", "O": "0-2"}, style_row=last("Opponents"))

w.append_row("Visitors", {"A": "VI175", "B": "Isamu Takaoka", "C": "高岡勇", "D": "Isamu Takaoka", "E": "Deputy Party Whip",
                          "F": "ST22", "G": "BO01 +1-3; BO02 +1", "H": "BO01 -3; BO02 -2", "I": "Capitol"},
             style_row=last("Visitors"))
w.append_row("Visitors", {"A": "VI176", "B": "Nobuko Ezaki", "C": "江崎信子", "D": "Nobuko Ezaki", "E": "Chief Party Whip",
                          "F": "ST22", "G": "BO01 +1-3; BO02 +1", "H": "BO01 -3; BO02 -2", "I": "Capitol"},
             style_row=last("Visitors"))

# --- 2. Parties: three whip columns, filled for all six parties with the three shared whips ------------------------------
for col, header in (("K", "Assistant Whip Opp ID"), ("L", "Deputy Whip Opp ID"), ("M", "Chief Whip Opp ID")):
    w.set_cell("Parties", 1, col, header, style_from=1)
for row in range(2, 8):
    for col, opp in (("K", "OP132"), ("L", "OP133"), ("M", "OP134")):
        w.set_cell("Parties", row, col, opp, style_from=row)

# --- 3. The whip stage ST290 and its Affinity column -----------------------------------------------------------------------------
new_row = w.copy_row("Stages", "ST06", {
    "A": "ST290", "B": "Whipped into Line", "C": "党議拘束", "D": "Tōgi Kōsoku",
    "F": "Resolve", "H": 24, "I": 1, "J": 0.0417, "K": 3, "L": 5, "M": 5, "N": 5,
    "O": 12, "P": 12, "Q": 0, "R": 1, "S": 0, "T": 0, "U": 0, "V": 0,
    "Y": -1, "Z": 0, "AA": 1, "AB": 0, "AC": -2,
    "AD": -1, "AE": 0, "AF": 0, "AG": 0, "AH": 1,
    "AJ": "pool", "AK": 6, "AO": "No", "AR": "No", "AU": 0, "AV": 0, "AX": "ST08", "AY": 1, "AZ": None, "BA": None,
})
# The brief's Win/Loss columns: Win Reputation +1, Party support -2; Loss Party support +1, Constituency support -1.
# (Win ΔJiban is Constituency support: no change on a win.)
w.set_cell("Stages", new_row, "Y", 0)
w.set_cell("Stages", new_row, "AD", -1)

# Affinity: two suits 1.5 / 1.3, two 0.5 / 0.7, two 1.0 (Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous).
affinity = {2: 1.3, 3: 1.5, 4: 1.0, 5: 0.7, 6: 1.3, 7: 0.5}
w.set_cell("Affinity", 1, "JG", "ST290", style_from=1)
for row, value in affinity.items():
    w.set_cell("Affinity", row, "JG", value, style_from=row)
w.set_cell("Affinity", 9, "JG", "Whipped into Line", style_from=9)

# --- 4. Rules and Balance ----------------------------------------------------------------------------------------------------------
w.append_row("Rules", {
    "A": "whip_bands",
    "B": '{"assistant": [0, 30], "deputy": [31, 71], "chief": [72, 89], "minister": [90, 97], "leader": [98, 100]}',
    "D": "Who whips the player, by Party support when a whip scene opens?",
    "E": '{"value": "Role -> [first, last] Party support, inclusive. The bands must cover 0 to 100 once each. A minister whips only if they are in the player\'s party; otherwise the Chief Party Whip stands in."}',
    "F": "P15 (2026-11-23, Cameron).", "G": "block"}, style_row=last("Rules"))
w.append_row("Rules", {
    "A": "whip_stage", "B": "ST290", "C": "a Stage id",
    "D": "Which Stage row is the fight a whip scene starts when the player pushes back?",
    "F": "P15 (2026-11-23, Cameron)."}, style_row=last("Rules"))
w.append_row("Balance", {
    "A": "Evening Travel XP Cap", "B": 100,
    "C": "XP the staff's after-hours trip back to a Decision! costs: all the XP the player has, up to this many (P15, 2026-11-23, Cameron)."},
    style_row=last("Balance"))

# --- 5. Floor Votes: the amendment (BI51) and the final vote (BI52) --------------------------------------------------------------
w.set_cell("Floor Vote Bills", 1, "R", "Decision Scene", style_from=1)
w.append_row("Floor Vote Bills", {
    "A": "BI51", "B": "Amendment to the CPTPP Motion",
    "C": "An amendment to the motion on joining the CPTPP, put to the house before the final vote.",
    "D": 1, "E": -1, "F": 0, "J": "PT02", "R": "DS08"}, style_row=last("Floor Vote Bills"))
w.append_row("Floor Vote Bills", {
    "A": "BI52", "B": "Joining the CPTPP",
    "C": "Approves Yezo joining the CPTPP trade pact.",
    "D": 1, "E": -1, "F": 0, "J": "PT02", "R": "DS09"}, style_row=last("Floor Vote Bills"))

# Votes from Cameron's Story Votes sheet: Absent counts as abstain. Disposition follows the party's majority; a tie is Neutral.
POSITIONS = [
    # bill, party, yes, no, abstain, disposition, cue text
    ("BI51", "PT01", 4, 14, 1, "Opposed", "A safeguard we can trust is worth a vote; this is not it."),
    ("BI51", "PT02", 7, 7, 0, "Neutral", "The party will say its piece in the chamber."),
    ("BI51", "PT03", 9, 16, 2, "Opposed", "Farms and fisheries need more than this amendment."),
    ("BI51", "PT04", 0, 4, 1, "Opposed", "Five points, one answer: no."),
    ("BI51", "PT05", 4, 17, 4, "Opposed", "Markets, not amendments, make the pact work."),
    ("BI51", "PT06", 10, 0, 1, "Supportive", "Without this amendment, we cannot let the pact through."),
    ("BI52", "PT01", 13, 5, 1, "Supportive", "Open trade is how Yezo grows."),
    ("BI52", "PT02", 9, 5, 0, "Supportive", "The government's pact is this party's pact."),
    ("BI52", "PT03", 16, 9, 2, "Supportive", "Trade built this region, and the pact keeps it open."),
    ("BI52", "PT04", 4, 0, 1, "Supportive", "Five points, one answer: join."),
    ("BI52", "PT05", 21, 0, 4, "Supportive", "Free markets are the whole point."),
    ("BI52", "PT06", 0, 10, 1, "Opposed", "Sovereignty is not for trading."),
]
PARTY_NAMES = {"PT01": "Butsutou", "PT02": "Yezo Heritage Party", "PT03": "Frontier Party", "PT04": "Five Point Independents",
               "PT05": "Keizaijiyuutou", "PT06": "Country Initiative"}
for bill, party, yes, no, abstain, disposition, cue in POSITIONS:
    w.append_row("Floor Vote Party Positions", {"A": bill, "B": party, "C": yes, "D": no, "E": abstain, "F": disposition,
                                                "G": cue, "H": PARTY_NAMES[party]}, style_row=last("Floor Vote Party Positions"))

# --- 6. Decision Scenes: new columns and the nine scenes -----------------------------------------------------------------------------
NEW_COLUMNS = [("P", "Whip Bill"), ("Q", "Whip Line"), ("R", "Minister"), ("S", "Vote Bill"), ("T", "Max Follow-Ups"), ("U", "Must End By")]
for col, header in NEW_COLUMNS:
    w.set_cell("Decision Scenes", 1, col, header, style_from=1)

# Scene, event, kind, opens, closes, speaker, follows, delay, activates, whip_bill, whip_line, minister, vote_bill, max, must_end
SCENES = [
    dict(id="DS02", ev="EV111", kind="Mandatory", opens="18.10.22", office="Capitol", speaker="OP10", face="neutral",
         max=8, must="18.10.29",
         note="P15 CPTPP chain, first scene. The Government Tables the CPTPP Motion. Chain approved at 8 follow-ups (Cameron, 2026-11-23); both votes by 18.10.29."),
    dict(id="DS03", ev="EV112", kind="Optional", closes="18.10.26", office="District", speaker="VI95", follows="DS02", delay=2,
         note="The Home Front Wants Answers. Optional, window Wed 18.10.24 to Fri 18.10.26."),
    dict(id="DS04", ev="EV113", kind="Optional", closes="18.10.26", office="Capitol", speaker="VI23", follows="DS02", delay=2,
         note="The Business Lobby Comes Calling. Optional, window Wed 18.10.24 to Fri 18.10.26."),
    dict(id="DS05", ev="EV114", kind="Mandatory", office="Capitol", speaker="OP29", face="attacking", follows="DS02", delay=3,
         activates="stage:ST290@B,C", whip="BI51", line="Aye",
         note="Imekanu Resu, Minister of Agriculture, whips every player on the AMENDMENT (asks Aye). Thu 18.10.25. Opponent whip stage if the player pushes back."),
    dict(id="DS06", ev="EV115", kind="Mandatory", office="Capitol", speaker="OP29", face="attacking", follows="DS05", delay=0,
         activates="stage:ST290@B,C", whip="BI52", line="Nay",
         note="Resu again, back to back, on the FINAL vote (asks Nay). Thu 18.10.25."),
    dict(id="DS07", ev="EV116", kind="Mandatory", office="Capitol", follows="DS02", delay=4,
         activates="stage:ST290@B,C", whip="BI52", minister="OP82",
         note="The Whip Counts Heads: the standard party whip, picked by Party support (Rules whip_bands), FINAL vote only. Fri 18.10.26."),
    dict(id="DS08", ev="EV117", kind="Mandatory", office="Capitol", speaker="OP27", follows="DS02", delay=7, vote="BI51",
         note="Floor Vote on the amendment, Mon 18.10.29. A free vote unless Resu locked it."),
    dict(id="DS09", ev="EV118", kind="Mandatory", office="Capitol", speaker="OP27", follows="DS08", delay=0, vote="BI52",
         note="Floor Vote on joining the CPTPP, the same sitting, straight after the amendment."),
    dict(id="DS10", ev="EV119", kind="Optional", closes="18.11.02", office="District", speaker="VI98", follows="DS09", delay=2,
         note="After the Vote, Back Home. Optional, window Wed 18.10.31 to Fri 18.11.02."),
]
for s in SCENES:
    cells = {"A": s["id"], "B": s["ev"], "C": s["kind"], "D": s.get("opens"), "E": s.get("closes"), "F": s["office"],
             "G": s.get("speaker"), "I": s.get("face", "neutral"), "K": s.get("follows"), "L": s.get("delay"),
             "N": s.get("activates"), "O": "Pilot (P15, 2026-11-23). " + s["note"] + " " + DRAFT,
             "P": s.get("whip"), "Q": s.get("line"), "R": s.get("minister"), "S": s.get("vote"), "T": s.get("max"), "U": s.get("must")}
    w.append_row("Decision Scenes", {k: v for k, v in cells.items() if v is not None}, style_row=last("Decision Scenes"))

# --- 7. Events and choices ----------------------------------------------------------------------------------------------------------
BO_JOIN = {"BO05": 2, "BO24": 1, "BO16": 1}       # Chamber of Commerce, Financial Industry Association, Innovation Society
BO_AGAINST = {"BO10": 2, "BO07": 1, "BO15": 1}    # Agricultural Cooperatives, Fisheries Cooperative, Our Traditional Society


def rewards(*pairs):
    return "; ".join("%s %+d" % (bo, n) for bo, n in pairs if n)


def merged(*dicts):
    out = {}
    for d in dicts:
        for k, v in d.items():
            out[k] = out.get(k, 0) + v
    return out


def pair(d, sign=1):
    return [(k, v * sign) for k, v in d.items()]


EVENTS = [
    # id, title, flavor, trigger, hours, on_date, speaker_title, location
    ("EV111", "The Government Tables the CPTPP Motion",
     "The Prime Minister tables a motion to join the CPTPP, and the chamber stirs. Every party is already counting who will break ranks.",
     "Dated", 2, "18.10.22", "Prime Minister", "Capitol"),
    ("EV112", "The Home Front Wants Answers",
     "A rice farmer waits outside your District office with a folded newspaper. He wants to know what the CPTPP means for his harvest.",
     "Followup", 2, None, None, "District"),
    ("EV113", "The Business Lobby Comes Calling",
     "A company boss asks for twenty minutes before the sitting. He has a briefing on what the CPTPP will do for exporters.",
     "Followup", 2, None, None, "Capitol"),
    ("EV114", "The Minister of Agriculture's Appeal",
     "Imekanu Resu, Minister of Agriculture, finds you in the corridor before the sitting. She wants your vote on the amendment, and she does not ask twice.",
     "Followup", 1, None, None, "Capitol"),
    ("EV115", "The Minister Asks Again",
     "Resu is not finished. She asks about the final vote now, and this time she wants a Nay.",
     "Followup", 1, None, None, "Capitol"),
    ("EV116", "The Whip Counts Heads",
     "The whip's office has a list, and your name is on it. They want to know how you will vote on the final bill.",
     "Followup", 1, None, None, "Capitol"),
    ("EV117", "Floor Vote: the Amendment",
     "The Speaker calls the house to order. The amendment to the CPTPP motion comes first, and the lobbies are full.",
     "Followup", 1, None, "Speaker of the National Assembly", "Capitol"),
    ("EV118", "Floor Vote: Joining the CPTPP",
     "The amendment is settled. The Speaker puts the motion to join the CPTPP to the house.",
     "Followup", 1, None, "Speaker of the National Assembly", "Capitol"),
    ("EV119", "After the Vote, Back Home",
     "The vote is done and the district is talking. A salmon fisher stops you outside the harbor office to say what the town thinks.",
     "Followup", 2, None, None, "District"),
]
for eid, title, flavor, trigger, hours, on_date, speaker_title, location in EVENTS:
    cells = {"A": eid, "B": title, "C": flavor, "D": trigger, "E": "Both" if trigger == "Followup" else "Weekday", "F": hours,
             "O": on_date, "P": speaker_title, "R": location}
    w.append_row("Events", {k: v for k, v in cells.items() if v is not None}, style_row=last("Events"))

# Choices: event, letter, text, result, columns (letter -> value), rewards
CHOICES = []


def choice(eid, letter, text, result, rw="", **cols):
    CHOICES.append((eid, letter, text, result, rw, cols))


# DS02: joining orgs vs farm orgs; the split orgs (Labor Federation BO09, Consumer Advocacy BO26, Taxpayers' Alliance BO23).
choice("EV111", "A", "Back it publicly",
       "You rise to say Yezo's exporters cannot wait. The farm benches go quiet.",
       rewards(*pair(BO_JOIN), *pair(BO_AGAINST, -1)), L=1)
choice("EV111", "B", "Reserve judgment and call for hearings",
       "You ask for hearings before any vote. Nobody can quite call it an answer.",
       rewards(("BO09", 1), ("BO26", 1), ("BO23", 1)))
choice("EV111", "C", "Oppose it, for the sake of farms and fisheries",
       "You say the pact asks farmers and fishers to pay for everyone else. The government benches murmur.",
       rewards(*pair(BO_AGAINST), *pair(BO_JOIN, -1)), L=1)
# DS03 (Optional, District): a promise, an explanation, a delegation; L is the lapse.
choice("EV112", "A", "Promise to fight for safeguards",
       "You promise to press for safeguards in the debate. He folds the paper into his pocket and nods.",
       rewards(("BO10", 2), ("BO07", 1)), Q="Promise Hours 2 within 96 for BO10")
choice("EV112", "B", "Explain the export upside",
       "You explain who gains if the pact opens markets. He listens, and does not agree.",
       rewards(("BO05", 1), ("BO10", -1)))
choice("EV112", "C", "Send your District Representative",
       "Your staffer takes his questions and writes every one down. He says it is something.",
       rewards(("BO10", 1)), Q="Funds 10000", U="District Representative")
choice("EV112", "L", "(lapse)", "You let the farmer wait, and the District office hears about it.",
       rewards(("BO10", -1)), H=-1)
# DS04 (Optional, Capitol): briefing, protections, decline; L is the lapse.
choice("EV113", "A", "Take the briefing",
       "You take the briefing and keep the slides. The numbers are good, and they are the lobby's own.",
       rewards(("BO05", 1), ("BO24", 1), ("BO09", -1)))
choice("EV113", "B", "Demand labor and consumer protections",
       "You say any pact needs protections for workers and shoppers. He writes it down without smiling.",
       rewards(("BO09", 1), ("BO26", 1), ("BO05", -1)))
choice("EV113", "C", "Decline the meeting",
       "You send your regrets. The company boss says he understands, which is not the same as agreeing.",
       rewards(("BO05", -1)))
choice("EV113", "L", "(lapse)", "The company boss leaves with his slides. Nobody on his side will forget it.",
       rewards(("BO05", -1)))
# DS05 / DS06: Resu. A sides with her; B and C push back and start the whip stage.
choice("EV114", "A", "I'll stand with you on the amendment.",
       "She nods once. You know where you stand, and so does she.",
       rewards(("BO17", 1)))
choice("EV114", "B", "I'd rather decide this one myself.",
       "Her smile does not reach her eyes. She says she hopes you will not regret it.",
       rewards(("BO17", -1)))
choice("EV114", "C", "I may vote against you.",
       "She says that is a mistake, and means it. The corridor empties around you.",
       rewards(("BO17", -2)))
choice("EV115", "A", "I'll vote against joining, as you ask.",
       "She nods again. The farm benches will hear of it before you reach your seat.",
       rewards(("BO17", 1), ("BO10", 1)))
choice("EV115", "B", "I want a free vote on the final bill.",
       "She says the free vote is a luxury. She does not say it kindly.",
       rewards(("BO17", -1)))
choice("EV115", "C", "I may vote for it anyway.",
       "She says you will answer for it at harvest. The words follow you down the corridor.",
       rewards(("BO17", -2), ("BO10", -1)))
# DS07: the party whip, worded relative to the party line.
choice("EV116", "A", "I'll vote with the party.",
       "You tell the whip you will vote with the party. A tick goes next to your name.",
       rewards(("BO01", 1)))
choice("EV116", "B", "I want a free vote on this one.",
       "You ask for a free vote. The whip says it will be noted, which is not a yes.",
       rewards(("BO01", -1)))
choice("EV116", "C", "I may vote against the party line.",
       "You say you may vote against the line. The whip's pen stops moving.",
       rewards(("BO01", -2), ("BO02", -1)))
# DS08 / DS09: take your seat.
choice("EV117", "A", "Take your seat",
       "You take your seat as the bell rings. The chamber settles.", "")
choice("EV118", "A", "Take your seat",
       "You take your seat for the main vote. The chamber settles.", "")
# DS10 (Optional, District): town hall, statement, silence; L is the lapse.
choice("EV119", "A", "Hold a town hall",
       "You hold a town hall at the harbor office. The room is packed, and the answers are long.",
       rewards(("BO07", 1), ("BO18", 1)), Q="Hours 2")
choice("EV119", "B", "Issue a statement",
       "You put out a statement the same afternoon. The paper prints it in full and the town reads it.",
       rewards(("BO18", 1)))
choice("EV119", "C", "Stay quiet",
       "You say nothing, and the town notices. Some call it prudence, and some do not.",
       rewards(("BO18", -1)))
choice("EV119", "L", "(lapse)", "You let the week go by without a word. The harbor town does not forget.",
       rewards(("BO18", -1)), H=-1)

COLS = {"E": "Funds Cost", "H": "Constituency support Δ", "I": "Reputation Δ", "J": "Party support Δ", "L": "National Awareness Δ"}
for eid, letter, text, result, rw, cols in CHOICES:
    cells = {"A": eid, "B": letter, "C": text, "D": result}
    if rw:
        cells["M"] = rw
    for key, val in cols.items():
        cells[{"L": "L", "H": "H", "Q": "Q", "U": "U"}.get(key, key)] = val
    w.append_row("Event Choices", {k: v for k, v in cells.items() if v is not None}, style_row=last("Event Choices"))

w.save()
print("workbook updated")
