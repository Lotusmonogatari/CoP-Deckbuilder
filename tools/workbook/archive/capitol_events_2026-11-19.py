"""B3 (2026-11-19): ten Capitol events, EV95-EV104, Claude's draft for Cameron to rewrite.
Workbook rows only (Events, Event Choices, Text). RUNNABLE: it refuses to run if EV95 already exists, so after a merge that
touched the workbook, check out the merged workbook and run it again from the repo root, then export (--accept-wording). Each event: A engage, B send staff, C a careful middle
path (some with a promise), D the Decline row, computed from the CONTENT_GUIDE rule (1.5 x the shortfall of
sending staff against accepting, half up; Constituency, Reputation, Party, District, National and
organization standing only). Run from the repo root."""
import math, re, sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-19 Capitol events (Claude's draft for Cameron to rewrite)"
VARS = {"H": "constituency", "I": "reputation", "J": "party", "K": "district", "L": "national"}
PA, MS = "Policy Research Assistant", "Media Spokesperson"


def parse(v):
    """'0-2' -> (0,2); 1 -> (1,1); '-2-0' -> (-2,0); None -> (0,0)."""
    if v is None or v == "":
        return (0, 0)
    if isinstance(v, int):
        return (v, v)
    m = re.match(r"^(-?\d+)\s*-\s*(-?\d+)$", str(v))
    if m:
        return (int(m.group(1)), int(m.group(2)))
    return (int(v), int(v))


def fmt(lo, hi):
    return lo if lo == hi else f"{lo}-{hi}"


def half_up(x):
    return int(math.floor(x + 0.5))


def orgs(s):
    out = {}
    for part in (s or "").split(";"):
        part = part.strip()
        if part:
            k, d = part.split()
            out[k] = int(d)
    return out


def decline(a, staff):
    row = {}
    for col in VARS:
        a_lo, a_hi = parse(a.get(col))
        s_lo, s_hi = parse(staff.get(col))
        sf = sorted([max(0, a_lo - s_lo), max(0, a_hi - s_hi)])
        lo, hi = -half_up(1.5 * sf[1]), -half_up(1.5 * sf[0])
        if lo or hi:
            row[col] = fmt(lo, hi)
    ao, so = orgs(a.get("M")), orgs(staff.get("M"))
    parts = []
    for k, d in ao.items():
        sf = max(0, d - so.get(k, 0))
        if sf:
            parts.append(f"{k} -{half_up(1.5 * sf)}")
    if parts:
        row["M"] = "; ".join(parts)
    return row


# id, title, flavor, hours, weight, min national awareness, [A, B, C], decline result text
EVENTS = [
 ("EV95", "A Committee Clerk Needs a Signature",
  "A committee clerk catches you in the corridor with a schedule change that moves a colleague's hearing to Thursday. It needs a member's signature by the end of the day.",
  1, 6, None,
  [dict(C="Read it through and sign", D="It is a clean change. The clerk thanks you and remembers who was quick.", I="0-1", M="BO17 +1"),
   dict(C="Send a staffer to check it against the calendar", D="Your staffer finds a clash with another hearing, and the clerk fixes it before anyone notices.", U=PA),
   dict(C="Sign it and ask for the full week's schedule", D="The clerk agrees to send it. You agree to read it.", Q="Promise Hours 1 within 24 for BO17", T="You read the week's schedule and flag two clashes for the clerk.")],
  "You wave the clerk on. Someone else signs, and the clerk remembers who did not."),
 ("EV96", "A Member From Another Party Asks You to Co-Sign",
  "A member from across the aisle asks you to co-sign a small amendment to the order of debate. It changes little, they say, but a second party's name would help.",
  1, 5, 10,
  [dict(C="Co-sign it", D="Your name goes on it. Your colleagues notice whose name sits beside yours.", J="-1-0", M="BO17 +2"),
   dict(C="Send a staffer to read the amendment first", D="Your staffer reads it in an hour and reports that it changes less than claimed.", M="BO17 +1", U=PA),
   dict(C="Ask for a day to read it yourself", D="They agree, a little stiffly.", Q="Promise Hours 1 within 24 for BO17", T="You read the amendment through and send back two questions. They answer both.")],
  "You tell them you cannot help. The amendment goes ahead without you, and they are polite about it."),
 ("EV97", "The Press Gallery Wants a Word After the Vote",
  "The vote ends early and the press gallery empties into the corridor. Two reporters wait by the stairs with the same question: what did you make of it?",
  1, 6, 15,
  [dict(C="Give them a clear answer on the stairs", D="Your answer is short enough to quote, and they quote it.", I="0-2", L="1-2", M="BO08 +1"),
   dict(C="Send your spokesperson to the stairs", D="Your spokesperson handles it. The quote is careful and nearly forgotten by evening.", L="0-1", U=MS),
   dict(C="Say you will put it in writing", D="A thin statement goes out at nine. It says what it says.", M="BO08 -1", Q="Promise Hours 1 within 24 for BO08", T="You send a one-page statement before the evening bulletins go out.")],
  "You take the back stairs. The reporters get their quote from someone else."),
 ("EV98", "A Lobbyist Leaves a Gift Basket",
  "A gift basket arrives at your office from a business group, with a card that hopes you are keeping well. The fruit is excellent. The card is very friendly.",
  1, 5, None,
  [dict(C="Return it with a polite note", D="The group takes it well, or says it does. Your staff are visibly disappointed about the fruit.", I="1-2", M="BO05 -1"),
   dict(C="Have a staffer log it and pass it to the staff room", D="It is logged, photographed and eaten by noon. Nobody can say you hid it.", I="0-1", U=PA),
   dict(C="Keep it and send a thank-you", D="The thank-you is warm. So, a little, is the note someone adds to your file.", I="-2--1", M="BO05 +2")],
  "You leave the basket on a side table and say nothing. By afternoon it is all anyone in the office talks about."),
 ("EV99", "The Session Runs Late",
  "The debate runs past the dinner hour and the chamber thins out. Whoever stays will be noted, and whoever leaves will be noted too.",
  2, 6, None,
  [dict(C="Stay to the end", D="You hear every speech. A clerk from the Candidate Selection Committee ticks a box.", J="1-2", M="BO32 +1"),
   dict(C="Send word that a staffer will take notes", D="Your staffer takes good notes. The empty seat takes better ones.", J="0-1", U=PA),
   dict(C="Leave after your own vote and catch up on reading", D="You vote, then leave quietly with a briefcase of papers. Nobody stops you.", G="5-10", J="-1-0")],
  "You go home at the dinner hour without a word. The empty seat is remembered."),
 ("EV100", "The Party Faction Invites You to Lunch",
  "Members of your party's faction have a table booked for lunch and an empty chair. Nothing is on the agenda, which usually means something is.",
  2, 5, None,
  [dict(C="Take the chair and listen", D="You hear who is counting votes for what. You are asked for nothing, today.", J="0-1", M="BO02 +2; BO01 -1"),
   dict(C="Send a staffer with your regrets and a question", D="Your staffer brings back the menu and a few names.", M="BO02 +1", U=PA),
   dict(C="Join them for coffee only", D="You stay for coffee and leave before the toasts. It is noticed, in both directions.", I="0-1", M="BO02 +1")],
  "You send your regrets without a reason. The chair stays empty, and people notice who it was meant for."),
 ("EV101", "A Budget Annex Arrives Without a Summary",
  "The Ministry of Finance has sent the annex to a spending bill, three hundred pages and no summary, with a note that members are welcome to ask questions.",
  2, 5, None,
  [dict(C="Read the tables that matter and ask questions", D="You find a line that does not add up and ask about it. The Ministry says it will check.", G="10-20", M="BO23 +1"),
   dict(C="Have a staffer summarize it overnight", D="Your staffer's summary is four pages, with the odd line circled.", G="5-10", U=PA),
   dict(C="Ask the Ministry for a briefing", D="A junior official comes to your office with a binder and a long afternoon.", M="BO23 -1", Q="Promise Hours 2 within 48 for BO23", T="You sit through the briefing and come away with three clear questions.")],
  "You send the annex back unread. A note from the Ministry politely records the fact."),
 ("EV102", "A School Group Visits the Gallery",
  "A class from a school in your district is in the visitors' gallery on a day trip. Their teacher has asked whether you might say hello before they go home.",
  1, 5, None,
  [dict(C="Come up and answer their questions", D="A girl in the front row asks why the chamber is so loud. You tell her.", H="0-1", M="BO11 +1"),
   dict(C="Send a staffer to take them through the building", D="Your staffer gives a good tour and a quiet photograph.", U=PA),
   dict(C="Wave from the gallery rail", D="They wave back. It takes thirty seconds and a lot of waving.", H="0-1")],
  "You are in a meeting when the class goes home. The teacher leaves a polite note at the front desk."),
 ("EV103", "A Rival's Aide Offers to Compare Notes",
  "An aide to a member of a rival party stops you after the hearing and offers to compare notes on who is saying what in the corridors. They would like the same from you.",
  1, 4, 20,
  [dict(C="Trade a little, nothing you would not say aloud", D="The notes are thin and mostly accurate. So, you suspect, are theirs.", J="-1-0", M="BO17 +2"),
   dict(C="Send a staffer to meet theirs", D="The two staffers swap business cards and nothing else.", M="BO17 +1", U=PA),
   dict(C="Thank them and keep your notes to yourself", D="They nod, a little amused. They will ask again next month.", I="0-1")],
  "You say you are late for a meeting. The aide shrugs and finds someone else to compare notes with."),
 ("EV104", "The Labor Federation Asks for a Seat at the Table",
  "Three delegates from the Labor Federation wait outside the committee room with a folder and the polite persistence of people who have waited before.",
  1, 5, None,
  [dict(C="Hear them out for ten minutes", D="They want a name on a letter. You give them ten minutes and a pen to borrow.", I="0-1", M="BO09 +1"),
   dict(C="Have a staffer take the folder and meet them later", D="Your staffer takes the folder and a long list of dates.", U=PA),
   dict(C="Promise to read the folder by Friday", D="The delegates leave the folder on your desk and a polite note.", M="BO09 +1", Q="Promise Hours 1 within 48 for BO09", T="You read the folder and write back with a date for a proper meeting.")],
  "You walk past with a nod. The delegates sit down on the bench and open the folder for no one."),
]

EVENT_COLS = {"id": "A", "title": "B", "flavor": "C", "trigger": "D", "avail": "E", "hours": "F", "weight": "I", "nat": "L"}
CHOICE_COLS = ("C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "Q", "T", "U")

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")
    for eid, *_ in EVENTS:
        try:
            w.find_row("Events", eid); raise SystemExit("already there: " + eid)
        except KeyError:
            pass
    ev_style = w.last_data_row("Events")
    ch_style = w.last_data_row("Event Choices")
    tx_style = w.last_data_row("Text")
    summary = []
    for eid, title, flavor, hours, weight, nat, choices, decline_text in EVENTS:
        row = {"A": eid, "B": title, "C": flavor, "D": "Random", "E": "Weekday", "F": hours, "I": weight}
        if nat:
            row["L"] = nat
        w.append_row("Events", row, style_row=ev_style)
        for letter, ch in zip("ABC", choices):
            cells = {"A": eid, "B": letter}
            cells.update({k: v for k, v in ch.items()})
            for k, v in list(cells.items()):
                if k in "EFGHIJKL" and isinstance(v, str) and re.fullmatch(r"-?\d+", v):
                    cells[k] = int(v)
            w.append_row("Event Choices", cells, style_row=ch_style)
        d = decline(choices[0], choices[1])
        cells = {"A": eid, "B": "D", "C": "@event.decline", "D": f"@event.decline.{eid}"}
        for k, v in d.items():
            cells[k] = int(v) if isinstance(v, str) and re.fullmatch(r"-?\d+", v) else v
        w.append_row("Event Choices", cells, style_row=ch_style)
        w.append_row("Text", {"A": f"event.decline.{eid}", "B": f"Event Choices: the result of declining {eid}", "C": decline_text, "E": NOTE}, style_row=tx_style)
        summary.append((eid, title, d))
    w.save()
    for eid, title, d in summary:
        print(eid, title, "| decline:", d)
