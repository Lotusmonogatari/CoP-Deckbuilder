#!/usr/bin/env python3
"""Two offices, slice 4 (2026-11-20): the three travel tickets in the Shop (Travel Mode and Offered For columns), the encounter
rate in Balance, and six starter train encounters (Events with Trigger Train, three choices each). **Prices and every line of
the encounters are Claude's drafts for Cameron to set and rewrite.** Refuses to run twice. Then:
python3 tools/export_data.py --accept-wording"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, col2n, n2col

NOTE = "2026-11-20 two offices, slice 4 (Claude's draft)"

# Shop rows: id, name, description, Funds, Grants, Travel Mode, Offered For (blank = everyone)
ITEMS = [
    ("SH42", "Paid Train Ticket",
     "A paid seat on the express, used for a trip or a mixed level's travel instead of the rail pass. The hours are the same. The Taxpayers' Alliance, the Chamber of Commerce and the Commuter Committee each notice when a member pays their own fare: +2 standing with each on every use.",
     5000, "BO23 +2; BO05 +2; BO14 +2", "ticket", ""),
    ("SH43", "Private Car Trip",
     "A hired car and driver for one trip, used instead of the rail pass. No encounters on the road.",
     15000, "", "car", "PC02; PC03; PC04"),
    ("SH44", "Plane Ticket",
     "A seat on the flight to Sapporo, used for one trip instead of the rail pass. Much faster than the train, and no encounters on the way.",
     40000, "", "plane", "PC01"),
]

# Train encounters: id, title, flavor, then choices (letter, text, result, rewards)
ENCOUNTERS = [
    ("EV105", "A Student Asks About the Fare",
     "A student across the aisle recognizes you. Her season ticket just went up again, she says, and half her class commutes the same line.",
     [("A", "Promise to look into student fares", "She writes your name on the back of her ticket stub. \"I'll tell the others.\"", "BO11 +2; BO14 +1"),
      ("B", "Explain how fares are set", "You explain who decides and why. She nods slowly, the way people do when they have understood and are not satisfied.", "BO14 +1"),
      ("C", "Wish her luck and look out the window", "She goes back to her book.", "")]),
    ("EV106", "A Fisherman Heading Home",
     "A man in rubber boots sits down heavily beside you, smelling faintly of the harbor. The catch was poor this week, he says, and the ice plant wants more for the same ice.",
     [("A", "Ask what the co-operative is doing about it", "He tells you at length. By the end of the line you have the names of three people to call.", "BO07 +2"),
      ("B", "Say you will raise the ice prices with the ministry", "\"Many have said so,\" he answers kindly, and shakes your hand anyway.", "BO07 +1"),
      ("C", "Share your snack and say little", "He takes a rice ball and thanks you.", "")]),
    ("EV107", "A Reporter Recognizes You on the Platform",
     "A reporter from the national media is on the same carriage, notebook already in hand. \"One question, if you have a minute. Everyone on this train has a minute.\"",
     [("A", "Answer the question", "You answer it. The line makes the evening bulletin, slightly shorter than you said it.", "BO08 +2; BO17 -1"),
      ("B", "Say you will send a statement later", "She smiles and writes that down too.", "BO08 +1"),
      ("C", "Say nothing and open your papers", "She tries once more, then lets you be.", "")]),
    ("EV108", "A Farmer With a Crate of Vegetables",
     "A farmer is carrying a crate of radishes to a cousin in the city, and he has opinions about the price support scheme that he has never had the chance to share with a member.",
     [("A", "Hear him out properly", "It takes the whole ride. You come away knowing more about radishes than you meant to, and about the scheme.", "BO10 +2; BO30 +1"),
      ("B", "Take his number for the policy staff", "He writes it on the crate lid, then tears off a corner of the lid for you.", "BO10 +1"),
      ("C", "Compliment the radishes", "He gives you one. It is very good.", "")]),
    ("EV109", "A Commuter Complains About the Delays",
     "The train has been held at a signal for ten minutes. The commuter standing next to you says this happens every week and nobody ever answers for it.",
     [("A", "Take down the details and promise to ask", "You note the line, the day and the signal. He seems surprised to be taken seriously.", "BO14 +2; BO26 +1"),
      ("B", "Agree that it is frustrating", "He nods. It is, you both agree, frustrating.", "BO14 +1"),
      ("C", "Keep your head down", "The train starts moving again.", "")]),
    ("EV110", "A Colleague From Your Party Is Aboard",
     "A member of your own party is two seats down, and has noticed you. They lean over with the particular smile of someone who is about to ask for something.",
     [("A", "Invite them to sit and talk it through", "They have been wanting a word about the caucus for a week. The conversation is useful to both of you.", "BO02 +2; BO01 +1"),
      ("B", "Agree to speak at the next meeting", "\"Good,\" they say. \"Bring numbers.\"", "BO02 +1"),
      ("C", "Say you are tired and close your eyes", "They take the hint, cheerfully.", "")]),
]

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")

    def add_header(sheet, title):
        rows = w.rows(sheet)
        header = rows[min(rows)]
        if title in header.values():
            raise SystemExit("already there: %s on %s" % (title, sheet))
        letter = n2col(max(col2n(c) for c in header) + 1)
        w.set_cell(sheet, min(rows), letter, title, style_from=1)
        return letter

    # Shop
    mode_col = add_header("Shop", "Travel Mode")
    offer_col = add_header("Shop", "Offered For")
    shop_style = w.last_data_row("Shop")
    for item_id, name, description, cost, grants, mode, offered in ITEMS:
        cells = {"A": item_id, "B": name, "C": description, "D": 0, "E": cost,
                 "J": "No", "K": "No", "N": 5, mode_col: mode}
        if grants:
            cells["H"] = grants
        if offered:
            cells[offer_col] = offered
        w.append_row("Shop", cells, style_row=shop_style)
    # Balance
    w.append_row("Balance", {"A": "Travel Encounter One In", "B": 8, "C": "Two offices (2026-11-20): on a trip by the rail pass or a paid ticket, one trip in this many brings an encounter on the train. Cameron: 1 in 8. A car or plane ticket skips it."},
                 style_row=w.last_data_row("Balance"))
    # Events and their choices
    ev_style = w.last_data_row("Events")
    ev_header = w.rows("Events")[1]
    loc = [l for l, t in ev_header.items() if t == "Location"][0]
    ch_style = w.last_data_row("Event Choices")
    ch_header = w.rows("Event Choices")[1]
    loc_ch = {t: l for l, t in ch_header.items()}
    for event_id, title, flavor, choices in ENCOUNTERS:
        by = {t: l for l, t in ev_header.items()}
        w.append_row("Events", {by["Event ID"]: event_id, by["Title"]: title, by["Flavor Text"]: flavor, by["Trigger"]: "Train",
                                by["Available"]: "Both", by["Hours"]: 0, by["Weight"]: 5, by["Image"]: "TRAIN_INTERIOR", loc: "Either"},
                     style_row=ev_style)
        for letter, text, result, rewards in choices:
            cells = {"A": event_id, "B": letter, "C": text, "D": result}
            if rewards:
                cells[loc_ch["Rewards"]] = rewards
            w.append_row("Event Choices", cells, style_row=ch_style)
    # Text
    text_style = w.last_data_row("Text")
    for key, where, english, placeholders in [
        ("event.heading_train", "Event heading: an encounter on the train", "On the train", ""),
        ("travel.mode_button", "Trip modes: one button, the mode and its hours", "{mode} · {count} h", "mode, count"),
        ("travel.mode_button_owned", "Trip modes: a ticket mode with how many tickets are left", "{mode} · {count} h · {owned} left", "mode, count, owned"),
        ("travel.cost_ticket", "Trip popup: what a ticket mode costs", "Uses one {mode}.", "mode"),
        ("travel.refuse_no_ticket", "Trip mode greyed: no ticket of that kind is held", "You have no {mode} left.", "mode"),
        ("briefing.travel_by", "Level briefing, the row of travel modes for a mixed level", "Travel by", ""),
        ("briefing.refuse_tickets", "Level briefing, Go in greyed: not enough tickets for this level's trips", "You need {count} {mode} for this level's trips.", "count, mode"),
    ]:
        cells = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            cells["D"] = placeholders
        w.append_row("Text", cells, style_row=text_style)
    w.save()
    print("added 3 tickets, 6 encounters, 1 Balance row, 6 Text rows")
