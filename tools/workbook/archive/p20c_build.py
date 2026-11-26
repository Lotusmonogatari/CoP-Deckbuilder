#!/usr/bin/env python3
"""P20 phase C (2026-11-26, Cameron): the Campaign Moment! content (DS11 to DS24, EV120 to EV133 and their choices) and the Text rows the scenes'
effects need. Draft content by Claude from design/proposals/P20_CONTENT.md, reworded so no unnamed person has a gender (the genderless rule,
tests/test_events_genderless.gd) and with the challenge counting CM01 (this project's Fundraising calls ID). Run once from the repo root, then
python3 tools/export_data.py --accept-wording. DS25 / EV134 (Stepping Aside) is phase D."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P20 phase C (2026-11-26); a draft for Cameron to edit."
w = WB("design/Game_Workbook.xlsx")

# ---- Text rows -------------------------------------------------------------------------------------------------------------------
texts = {
    "campaign.effect.venue_opened": "{name} is open.",
    "campaign.effect.staff_found": "{name} can now be hired at the Campaign Office.",
    "campaign.effect.fund": "Campaign fund {change}",
    "campaign.effect.donated": "{yen}円 moved into the campaign fund.",
    "campaign.effect.lent": "{name} is lent to a colleague until {date}. The wage is still paid.",
    "campaign.effect.favor": "{name} will remember this.",
    "campaign.colleague_unknown": "A colleague",
    "campaign.staffer_unknown": "your staffer",
    "campaign.moment_note": "A moment on the campaign trail. It came by itself, and you can answer it now.",
    "campaign.reason.no_staff_free": "No campaign staff are free.",
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

# ---- Events ----------------------------------------------------------------------------------------------------------------------
# (id, title, flavor, trigger, available, hours, on_date, location)
events = [
    ("EV120", "A Storefront With Your Name on It", "The party has leased an empty storefront two doors down from your District office. Inside are a folding table, a telephone and a box of blank banners. The next election is three years away, the party liaison says, and that is about how long a campaign takes to build.", "Dated", "Weekday", 2, "18.11.01", "District"),
    ("EV121", "Boxes in the Doorway", "A person in a rain jacket is carrying boxes out of the storefront next door. Their candidate has quit the race, they say, and there is a van full of posters and nowhere to take them.", "Campaign", "Both", 1, None, "District"),
    ("EV122", "The Farewell Party", "Dan is throwing a farewell party for the volunteers of an old campaign. Nobody from your party is coming, Dan says, and someone should say a few words.", "Followup", "Both", 2, None, "District"),
    ("EV123", "An Organizer Without a Candidate", "Dan sits across your desk with a notebook full of phone numbers. Dan has run four campaigns and lost one, and would like a fifth.", "Followup", "Both", 1, None, "District"),
    ("EV124", "A Small-Donor Dinner", "Umina Kota stops you on the Capitol steps with a leather folio under one arm. Umina raises money for candidates who are bad at asking for it, and is hosting a dinner in Susukino on Friday.", "Campaign", "Both", 1, None, "Capitol"),
    ("EV125", "A Test From Umina", "Umina telephones with an offer: make three fundraising calls in the next two weeks, and Umina will decide whether you are worth the time.", "Followup", "Both", 1, None, "District"),
    ("EV126", "Worth the Time", "Umina reads your call sheet line by line, circles two names and says you should call them again.", "Followup", "Both", 1, None, "District"),
    ("EV127", "A Short Note", "A note arrives from Umina in neat handwriting. Three calls was not much to ask, it says.", "Followup", "Both", 0, None, "District"),
    ("EV128", "Heard on Otaru Radio 今日", "A host on Otaru Radio 今日 spends five minutes on your van speech. The words were fine, the host tells listeners, and the delivery was a parking ticket.", "Campaign", "Both", 1, None, "District"),
    ("EV129", "On the Air", "Yuina Chanami invites you on a program for half an hour. The phone lines will be open, Yuina warns.", "Followup", "Both", 4, None, "District"),
    ("EV130", "Ride Along", "Yuina turns up at the Campaign Office with a thermos and a microphone. Yuina has heard the van, and can fix it.", "Followup", "Both", 1, None, "District"),
    ("EV131", "A Colleague Comes Asking", "{colleague} catches you in a Capitol corridor. Their district is close this cycle, and their campaign fund is closer to empty.", "Campaign", "Both", 1, None, "Capitol"),
    ("EV132", "Stand Beside Me", "{colleague} asks you to stand beside them at a station rally in their district this weekend. A familiar face, they say, draws a bigger crowd.", "Campaign", "Both", 4, None, "District"),
    ("EV133", "Short-Handed", "{colleague}'s campaign is short-handed, and they ask to borrow {campaign_staffer} for a while.", "Campaign", "Both", 1, None, "District"),
]
last = w.last_data_row("Events")
for eid, title, flavor, trigger, available, hours, on_date, location in events:
    last += 1
    row = {"A": eid, "B": title, "C": flavor, "D": trigger, "E": available, "F": hours, "R": location}
    if on_date:
        row["O"] = on_date
    w.append_row("Events", row, style_row=last - 1)

# ---- Event choices ---------------------------------------------------------------------------------------------------------------
# (event, letter, text, result, {column: value})  Columns: J Party support, K District, L National, M Rewards, AA Campaign Fund Delta,
# AB Donate Funds, AC Lend weeks, AD Favor Owed, AE Needs
choices = [
    ("EV120", "A", "Open the doors and get to work", "You tape your name to the window and sit at the folding table. By evening the telephone has rung twice.", {}),
    ("EV120", "B", "Open it, and put in 50,000円 of your own", "You make the first donation to your own campaign yourself. The liaison says that is a good sign, and a rare one.", {"AB": 50000}),
    ("EV121", "A", "Help carry the boxes", "You carry boxes until dark. The person writes a number on the back of a poster and hands it to you.", {}),
    ("EV121", "B", "Offer a corner of your office", "You clear a corner of the Campaign Office. The boxes are stacked neatly and every one is labeled.", {}),
    ("EV121", "C", "Wish them luck", "The person nods and keeps carrying. The van pulls away an hour later.", {}),
    ("EV122", "A", "Give the toast (50,000円)", "You thank people you have never met for work you never saw. They cheer anyway.", {"AA": -50000, "M": "BO31 +2"}),
    ("EV122", "B", "Send a card and a gift (20,000円)", "The card goes round the room. Dan tells you later that it was read out twice.", {"AA": -20000}),
    ("EV122", "C", "Stay away", "Dan does not call again.", {}),
    ("EV123", "A", "Offer Dan a place on your campaign", "Dan shakes your hand and asks where the good pens are kept.", {}),
    ("EV123", "B", "Tell Dan you can't take them on", "Dan tears the first page from the notebook, leaves it on your desk and takes the rest away.", {}),
    ("EV124", "A", "Buy a seat at the table (30,000円)", "Twelve people sit at one long table. Umina knows every name and every amount.", {"AA": -30000}),
    ("EV124", "B", "Send a donation instead (10,000円)", "A thank-you note arrives with your name spelled right, which Umina says is the first rule.", {"AA": -10000}),
    ("EV124", "C", "Decline", "Umina closes the folio and wishes you a good evening.", {}),
    ("EV125", "A", "Accept", "Umina hangs up before you can ask what happens if you don't.", {}),
    ("EV125", "B", "Tell Umina you don't take tests", "Umina laughs, once, and says that is also an answer.", {}),
    ("EV126", "A", "Ask Umina to join the campaign", "Umina says yes, and asks for a telephone of Umina's own.", {}),
    ("EV126", "B", "Thank Umina for the advice", "Umina tucks the call sheet into the folio and is gone by morning.", {}),
    ("EV127", "A", "Put the note away", "You put the note in a drawer you don't open often.", {}),
    ("EV128", "A", "Call in to the program", "The host lets you talk for a full minute, then tells you to breathe.", {}),
    ("EV128", "B", "Write the host a polite letter", "The host reads the letter on air, kindly, and keeps the envelope.", {}),
    ("EV128", "C", "Let it go", "The program moves on to the weather.", {}),
    ("EV129", "A", "Go on the program", "The callers are rough and fair. Yuina laughs at one of your answers, which counts.", {"K": 2}),
    ("EV129", "B", "Send a recorded message", "Yuina plays it twice and says the second time was better.", {"K": 1}),
    ("EV129", "C", "Decline", "Yuina fills the half hour with listener mail.", {}),
    ("EV130", "A", "Hand Yuina the microphone", "Yuina tests it, frowns, and adjusts something you didn't know could be adjusted.", {}),
    ("EV130", "B", "Thank Yuina and say no", "Yuina finishes the thermos and leaves a spare battery behind.", {}),
    ("EV131", "A", "Give 100,000円", "{colleague} thanks you twice and says they won't forget it.", {"AA": -100000, "J": 2, "M": "BO17 +3", "AD": "Y"}),
    ("EV131", "B", "Give 300,000円", "{colleague} goes quiet, then shakes your hand for a long time.", {"AA": -300000, "J": 5, "M": "BO17 +3", "AD": "Y"}),
    ("EV131", "C", "Wish them well", "{colleague} says they understand, in the voice people use when they don't.", {"J": -1}),
    ("EV132", "A", "Go (30,000円 for travel)", "You stand on a crate beside {colleague} and wave at commuters. A few wave back.", {"AA": -30000, "J": 3, "L": 2, "M": "BO31 +2", "AD": "Y"}),
    ("EV132", "B", "Send a campaign staffer", "Your staffer goes in your place and comes back hoarse.", {"AE": "campaign_staff_free", "J": 2, "L": 1, "M": "BO31 +1", "AC": 1, "AD": "Y"}),
    ("EV132", "C", "Decline", "{colleague} finds someone else. You hear the crowd was small.", {}),
    ("EV133", "A", "Lend them for a week", "{campaign_staffer} packs a bag and promises to call.", {"AC": 1, "J": 2, "AD": "Y"}),
    ("EV133", "B", "Lend them for two weeks", "{campaign_staffer} is gone two weeks and comes back with stories.", {"AC": 2, "J": 4, "M": "BO32 +3", "AD": "Y"}),
    ("EV133", "C", "Say you need everyone", "{colleague} nods and says they would do the same.", {"H": ""}),
]
last = w.last_data_row("Event Choices")
for event, letter, text, result, extra in choices:
    last += 1
    row = {"A": event, "B": letter, "C": text, "D": result, "Z": [e for e in events if e[0] == event][0][7]}
    for column, value in extra.items():
        if value != "":
            row[column] = value
    w.append_row("Event Choices", row, style_row=last - 1)

# ---- Decision Scenes -------------------------------------------------------------------------------------------------------------
# A scene: id, event, kind, opens, office, speaker, follows, delay, follow_if, activates, weight, weight_late, repeat, cooldown, phase, needs
scenes = [
    ("DS11", "EV120", "Mandatory", "18.11.01", "District", None, None, None, None, "venue:VN10", None, None, None, None, None, None),
    ("DS12", "EV121", "Random", None, "District", "CS02", None, None, None, None, 3, None, None, None, "building", "office_open"),
    ("DS13", "EV122", "Mandatory", None, "District", "CS02", "DS12", 7, "A;B", None, None, None, None, None, None, None),
    ("DS14", "EV123", "Mandatory", None, "District", "CS02", "DS13", 14, "A;B", "campaign_staff:CS02@A", None, None, None, None, None, None),
    ("DS15", "EV124", "Random", None, "Capitol", "CS04", None, None, None, None, 3, 3, None, None, "building;mustering", "office_open"),
    ("DS16", "EV125", "Mandatory", None, "District", "CS04", "DS15", 7, "A;B", "challenge:CM01x3in14@A", None, None, None, None, None, None),
    ("DS17", "EV126", "Mandatory", None, "District", "CS04", "DS16", 14, "challenge_met", "campaign_staff:CS04@A", None, None, None, None, None, None),
    ("DS18", "EV127", "Mandatory", None, "District", None, "DS16", 14, "challenge_failed", None, None, None, None, None, None, None),
    ("DS19", "EV128", "Random", None, "District", "CS06", None, None, None, None, 3, 3, None, None, "any", "van_speech_done"),
    ("DS20", "EV129", "Mandatory", None, "District", "CS06", "DS19", 7, "A;B", None, None, None, None, None, None, None),
    ("DS21", "EV130", "Mandatory", None, "District", "CS06", "DS20", 14, "A;B", "campaign_staff:CS06@A", None, None, None, None, None, None),
    ("DS22", "EV131", "Random", None, "Capitol", "colleague", None, None, None, None, 4, 4, "Y", 4, "any", "office_open"),
    ("DS23", "EV132", "Random", None, "District", "colleague", None, None, None, None, 2, 5, "Y", 3, "any", "office_open"),
    ("DS24", "EV133", "Random", None, "District", "colleague", None, None, None, None, 3, 3, "Y", 4, "any", "campaign_staff_free"),
]
last = w.last_data_row("Decision Scenes")
for (sid, eid, kind, opens, office, speaker, follows, delay, follow_if, activates, weight, weight_late, repeat, cooldown, phase, needs) in scenes:
    last += 1
    row = {"A": sid, "B": eid, "C": kind, "F": office, "I": "neutral", "O": "P20 phase C (2026-11-26). Campaign Moment! draft by Claude for Cameron to rewrite.", "V": "Campaign"}
    for column, value in (("D", opens), ("G", speaker), ("K", follows), ("L", delay), ("M", follow_if), ("N", activates), ("W", weight), ("X", weight_late),
                          ("Y", repeat), ("Z", cooldown), ("AA", phase), ("AB", needs)):
        if value is not None:
            row[column] = value
    w.append_row("Decision Scenes", row, style_row=last - 1)

w.save()
print("Text rows", added, "; events", len(events), "; choices", len(choices), "; scenes", len(scenes))
