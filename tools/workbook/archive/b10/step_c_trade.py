"""Influence building step C: the lobbyist trade (2026-10-19). Adds stage ST262
(with its Affinity column), the LOBBYIST_TRADE template token, the Trade
Questions tab, `trade.*` Text rows and the `Trade:` Balance levers. Raw XML.
Run once from the repo root."""
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
aff = w.rows("Affinity"); hdr = aff[1]
last = max(hdr, key=lambda c: col2n(c))
bc = {hdr[c]: c for c in hdr}["ST07"]
col = n2col(col2n(last) + 1)
sty = lambda r: w.sty("Affinity", f"{last}{r}")
w.set_cell("Affinity", 1, col, "ST262", style=sty(1))
vals = []
for r in range(2, 8):
    v = num(aff[r][bc]); vals.append(v); w.set_cell("Affinity", r, col, v, style=sty(r))
w.set_cell("Affinity", 9, col, "Lobbyist Trade", style=sty(9))
w.set_cell("Affinity", 10, col, round(sum(vals) / 6, 4), formula=f"AVERAGE({col}2:{col}7)", style=sty(10))

rows = w.rows("Stages"); H = rows[1]; by_name = {v: k for k, v in H.items()}
src = rows[w.find_row("Stages", "ST07")]
stage = {c: num(v) for c, v in src.items()}
for name, val in {"Win ΔJiban": None, "Win ΔYen": None, "Win ΔReputation": None, "Win ΔXP": None, "Win ΔParty support": None,
                  "Loss ΔJiban": None, "Loss ΔYen": None, "Loss ΔReputation": None, "Loss ΔXP": None, "Loss ΔParty support": None,
                  "Stage ID": "ST262", "Stage (EN)": "Lobbyist Trade", "Stage (JP)": "陳情団との取引", "Romaji": "Chinjōdan to no Torihiki",
                  "Mode": "Trade", "Opponent Count": 1, "Loss Ends Level": "No", "Show Transition": None,
                  "Background ID": "ST20", "Time Units": 0, "Favored suit": "—"}.items():
    stage[by_name[name]] = val
r = w.last_data_row("Stages") + 1
for c, v in stage.items():
    w.set_cell("Stages", r, c, v, style_from=r - 1)
w.save()

replace_sheet_data(PATH, "Bill Level Templates",
    ["Template ID", "Kind", "Level Tier", "Stage 1", "Stage 2", "Stage 3", "Stage 4", "Stage 5", "Stage 6", "Stage 7", "Stage 8", "Visit Parties", "Note"],
    [["BT01", "Favor", 1, "PATRON_MEETING", "HEARING", "LOBBYIST_TRADE", "VOTE", None, None, None, None, None,
      "Draft: a meeting with the organization, the committee hearing for the first component, an optional lobbyist trade (LOBBYIST_TRADE, offered when a lobbyist speaks for an organization the bill hurts), the Floor Vote."],
     ["BT02", "Flagship", 2, "PATRON_MEETING", "HEARING", "MP_VISIT", "PUBLIC", "CAUCUS", "LOBBYIST_TRADE", "VOTE", None, "PT04; PT02",
      "Draft: adds an optional member visit (MP_VISIT), a public room (Town Hall for a Constituency organization, Press Conference for a National one), your own Party Caucus and an optional lobbyist trade."]])

STEMS = [
 "My members cannot accept the plan to {component}. What will you give us?",
 "Why should we accept the plan to {component} when it costs us so much?",
 "Everyone says the plan to {component} is fair. Is it fair to us?",
 "What would you say to our people about the plan to {component}?",
 "We would rather you took out the plan to {component}. What is in it for you if you do?",
 "How do I explain the plan to {component} to the people I speak for?",
 "If the plan to {component} stays, who protects our interests?",
 "Can you show me that the plan to {component} will not hurt us?",
 "Tell me why the plan to {component} is worth the damage.",
 "What would it take for us to live with the plan to {component}?",
 "You are asking a lot with the plan to {component}. What are you offering?",
 "Will you stand by us if the plan to {component} goes badly?",
]
add_sheet(PATH, "Trade Questions", ["Question ID", "Text (EN)"], [["TQ%02d" % (i + 1), s] for i, s in enumerate(STEMS)], [12, 90])

w = WB(PATH)
TEXT = [
 ("custom_bill.name_1", "Patron bills", "A bill to {a}", "a"),
 ("trade.offer_title", "Lobbyist trade", "A lobbyist calls", ""),
 ("trade.offer_text", "Lobbyist trade", "{name}, speaking for {org}, has come to bargain over your bill. Hear them out?", "name, org"),
 ("trade.hear", "Lobbyist trade", "Hear them out", ""),
 ("trade.refuse", "Lobbyist trade", "Refuse to meet", ""),
 ("trade.pick_text", "Lobbyist trade", "Which part of the bill will you trade away? {hint}", "hint"),
 ("trade.asked_hint", "Lobbyist trade", "They want the plan to {component} gone.", "component"),
 ("trade.keep_all", "Lobbyist trade", "Keep the whole bill (end the meeting)", ""),
 ("trade.caption", "Lobbyist trade", "Round {number} of {total}", "number, total"),
 ("trade.leverage", "Lobbyist trade", "Leverage: {leverage} of 100", "leverage"),
 ("trade.package_text", "Lobbyist trade", "Leverage {leverage}. Choose what you want in return; the cost so far is {cost}.", "leverage, cost"),
 ("trade.reward_donation", "Lobbyist trade", "An office donation (cost {cost})", "cost"),
 ("trade.reward_sentiment", "Lobbyist trade", "Their goodwill (cost {cost})", "cost"),
 ("trade.reward_party_favor", "Lobbyist trade", "A party's favor (cost {cost})", "cost"),
 ("trade.reward_help", "Lobbyist trade", "Help working the bill (cost {cost})", "cost"),
 ("trade.chosen", "Lobbyist trade", "{label} - chosen", "label"),
 ("trade.make_deal", "Lobbyist trade", "Make the deal", ""),
 ("trade.walk_away", "Lobbyist trade", "Walk away", ""),
 ("trade.done_deal_title", "Lobbyist trade", "A deal is made", ""),
 ("trade.done_deal_body", "Lobbyist trade", "You give up the plan to {component}. {name} agrees to: {gains}.", "component, name, gains"),
 ("trade.done_nodeal_title", "Lobbyist trade", "No agreement", ""),
 ("trade.done_nodeal_body", "Lobbyist trade", "You and {name} could not agree. {cost}", "name, cost"),
 ("trade.done_refused_title", "Lobbyist trade", "You refused to meet", ""),
 ("trade.done_refused_body", "Lobbyist trade", "{name} leaves unhappy. {cost}", "name, cost"),
 ("trade.cost_seats", "Lobbyist trade", "Their lobbying will cost the bill {count} on the floor.", "count"),
 ("trade.cost_none", "Lobbyist trade", "It costs you nothing this time.", ""),
 ("trade.gain_donation", "Lobbyist trade", "a donation of {funds} and {xp} XP", "funds, xp"),
 ("trade.gain_sentiment", "Lobbyist trade", "better standing with {org}", "org"),
 ("trade.gain_party_favor", "Lobbyist trade", "the favor of {party}", "party"),
 ("trade.gain_help", "Lobbyist trade", "{count} on the floor", "count"),
 ("trade.react_strong_1", "Lobbyist trade", "{name} nods. That is a fair point.", "name"),
 ("trade.react_strong_2", "Lobbyist trade", "{name} sits back, impressed.", "name"),
 ("trade.react_strong_3", "Lobbyist trade", "{name} concedes the point with a thin smile.", "name"),
 ("trade.react_medium_1", "Lobbyist trade", "{name} considers it and gives nothing away.", "name"),
 ("trade.react_medium_2", "Lobbyist trade", "{name} taps the table. Not bad, not enough.", "name"),
 ("trade.react_medium_3", "Lobbyist trade", "{name} shrugs. They have heard it before.", "name"),
 ("trade.react_weak_1", "Lobbyist trade", "{name} scowls. That did not help.", "name"),
 ("trade.react_weak_2", "Lobbyist trade", "{name} pushes the paper back across the table.", "name"),
 ("trade.react_weak_3", "Lobbyist trade", "{name} looks at the clock. You have lost ground.", "name"),
]
for key, where, en, ph in TEXT:
    w.append_row("Text", {"A": key, "B": where, "C": en, "D": ph or None, "E": "2026-10-19 lobbyist trade (patron bills)."},
                 style_row=w.last_data_row("Text"))
LEV = [
 ("Trade: Rounds", 3, "First-draft. Questions the lobbyist asks in a negotiation."),
 ("Trade: Leverage Standing Percent", 25, "First-draft. Percent of your standing with the lobbyist's organization that becomes your starting leverage."),
 ("Trade: Leverage Asked Bonus", 20, "First-draft. Starting leverage bonus when the component you drop is the one the lobbyist asked for."),
 ("Trade: Leverage Other Bonus", 5, "First-draft. Starting leverage bonus when you drop any other component."),
 ("Trade: Strong Points", 15, "First-draft. Leverage for an answer in one of the lobbyist's two favored styles."),
 ("Trade: Medium Points", 5, "First-draft. Leverage for an answer in their third style."),
 ("Trade: Weak Points", -10, "First-draft. Leverage for any other style."),
 ("Trade: Cost Donation", 20, "First-draft. Leverage an office donation costs."),
 ("Trade: Cost Sentiment", 30, "First-draft. Leverage the organization's goodwill costs."),
 ("Trade: Cost Party Favor", 40, "First-draft. Leverage a party's favor costs."),
 ("Trade: Cost Help", 50, "First-draft. Leverage help working the bill (a seat) costs."),
 ("Trade: Donation Funds", 10000, "First-draft. Funds an office donation gives."),
 ("Trade: Donation XP", 20, "First-draft. XP an office donation gives."),
 ("Trade: Sentiment Standing", 5, "First-draft. Standing the organization's goodwill gives."),
 ("Trade: Party Favor", 3, "First-draft. Favor the party's favor gives."),
 ("Trade: Help Seats", 1, "First-draft. Seats help working the bill adds for your pick."),
 ("Trade: Favor Refuse Seats", 0, "First-draft. Seats lost when you refuse to meet on a Favor bill (Cameron: free)."),
 ("Trade: Favor No Deal Seats", 0, "First-draft. Seats lost when you meet and reach no agreement on a Favor bill (Cameron: free)."),
 ("Trade: Flagship Refuse Seats", 2, "Cameron, 2026-10-19. Seats lost when you refuse to meet on a Flagship."),
 ("Trade: Flagship No Deal Seats", 1, "Cameron, 2026-10-19. Seats lost when you meet and reach no agreement on a Flagship."),
 ("Trade: Patron Cost", 3, "First-draft. Standing the patron loses when you trade away one of their components."),
 ("Trade: Ally Cost", 1, "First-draft. Standing the ally loses when you trade away their component."),
]
for name, val, note in LEV:
    w.append_row("Balance", {"A": name, "B": val, "C": note}, style_row=w.last_data_row("Balance"))
w.save()
print("done")
