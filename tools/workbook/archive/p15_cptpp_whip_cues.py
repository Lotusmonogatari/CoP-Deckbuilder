#!/usr/bin/env python3
"""P15 (2026-11-23): the whip's lines, Resu's lines and the player's replies, as Opponent Cues and Player Cues rows.

The party whip's three sets (backs joining / opposes joining / questioning) are Cameron's appendix, Side For / Against / blank, said
by the three Party Whip's Office opponents, the ministers and the party leaders on the CPTPP bill (BI52) in the whip stage. Resu's
lines are Claude's draft, neutral so they fit her ask whichever way her party votes. Run once after p15_cptpp_whip_build.py.
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")
oc = 3864
pl = 3697

WHIP_IDS = "OP132; OP133; OP134; OP82; OP10; OP27; OP67; OP80; OP83; OP91"
BACKS = ["The party signed on to this pact. So did you, when you took the nomination.",
         "Exporters have waited years for this. Don't be the reason they wait longer.",
         "Every abstention reads as doubt in the leader.",
         "Farmers will adjust. The party won't forget.",
         "Name one trading nation that regrets joining."]
OPPOSES = ["We stand with the farms and fisheries. Where do you stand?",
           "Open the market and the cheapest rice in the Pacific comes in.",
           "Sovereignty doesn't come back once it's traded away.",
           "Vote with the government on this and you vote against us.",
           "Your district's harbor won't survive a tariff cut."]
QUESTIONING = ["Have you even read the dispute-settlement chapter?",
               "A free vote is a luxury for members with safe seats.",
               "Who briefed you on this, the lobby or the party?",
               "Doubts are fine. Votes are counted.",
               "You can question the bill after you've voted for it."]


def opponent_row(opp_ids, suit, verb, lines, bill, side):
    global oc
    cells = {"A": "OC%d" % oc, "B": suit, "C": verb, "D": opp_ids, "J": "ST290", "K": bill}
    for i, text in enumerate(lines):
        cells["EFGHI"[i]] = text
        if side:
            cells["MNOPQ"[i]] = side
    w.append_row("Opponent Cues", cells, style_row=w.last_data_row("Opponent Cues"))
    oc += 1


for verb in ("attack", "block"):
    opponent_row(WHIP_IDS, "Divisive", verb, BACKS, "BI52", "For")
    opponent_row(WHIP_IDS, "Divisive", verb, OPPOSES, "BI52", "Against")
    opponent_row(WHIP_IDS, "Divisive", verb, QUESTIONING, "BI52", "")

RESU = {
    ("BI51", "attack"): ["The amendment is the least the farms can ask.", "Every farmer in the north is counting your vote.",
                         "I am not asking for a favor. I am asking for a vote.",
                         "Safeguards on paper are worth nothing without a vote behind them.", "Stand with the farms and fisheries."],
    ("BI51", "block"): ["Say what you like. My answer is the same.", "The ministry has done the sums. The amendment holds.",
                        "You will not talk me out of this.", "I have heard every excuse before breakfast.",
                        "Hold your ground, or give it up."],
    ("BI52", "attack"): ["Vote for this pact and see who stands with you at harvest.", "Cheaper rice abroad does not feed a village at home.",
                         "You were not elected to sell the north.", "Tell the fishing towns it was for the best.",
                         "I will remember who voted for it."],
    ("BI52", "block"): ["I have made my case and it stands.", "The farms are not asking twice.",
                        "Nothing in that chapter protects them.", "I am not moved by export figures.", "Think of your district."],
}
for (bill, verb), lines in RESU.items():
    opponent_row("OP29", "Emotional", verb, lines, bill, "")

# The player's replies on the CPTPP bill in the whip stage: for joining, against joining, questioning (blank stance).
PLAYER = {
    "Support": ["Our exporters need markets bigger than Yezo.", "The pact rewards the nations that join early.",
                "Safeguards are in the text; I've read them.", "Lower tariffs mean cheaper goods for every family.",
                "Standing outside a trade bloc isn't independence. It's isolation."],
    "Oppose": ["My district's farmers didn't vote for this.", "Who negotiated the rice and dairy chapters, and for whom?",
               "We'd trade away rules we can't take back.", "Cheaper imports today, empty fishing towns tomorrow.",
               "A pact this large deserves more than one session's debate."],
    "": ["I'll vote when someone shows me the transition fund.", "Where's the impact study for the northern districts?",
         "The party line isn't an argument.", "My constituents elected me, not the whip's office.",
         "Ask me again after the committee hearing."],
}
for suit in ("Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"):
    for stance, lines in PLAYER.items():
        cells = {"A": "PL%d" % pl, "B": suit, "D": "ST290", "J": "BI52"}
        if stance:
            cells["K"] = stance
        for i, text in enumerate(lines):
            cells["EFGHI"[i]] = text
        w.append_row("Player Cues", cells, style_row=w.last_data_row("Player Cues"))
        pl += 1

w.save()
print("cues added: opponent rows to OC%d, player rows to PL%d" % (oc - 1, pl - 1))
