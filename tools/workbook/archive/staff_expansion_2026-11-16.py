#!/usr/bin/env python3
"""Staff task expansion, phases 1 and 2 (Cameron, 2026-11-16;
design/proposals/STAFF_TASKS_EXPANSION_2026-11-16.md).

Phase 1: 47 new tasks on the Staff Assignments tab (64 in all, 8 per icon
family). Phase 2: the Staff Task Families tab (each family's daily range) and
the Staff Task Ramp tab (the most tasks delivered a day, by week), and the two
old fixed pool-size Balance rows are retired. All wording and numbers are
Claude's draft for Cameron to rewrite. Run once on a workbook without the tabs.
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

R, M, D = "Policy Research Assistant", "Media Spokesperson", "District Representative"
LL01, LL02, LL03, LL04, LL05, LL06, LL07, LL08 = [f"LL0{i}" for i in range(1, 9)]
FAMILY = {LL01: "Correspondence", LL02: "Press", LL03: "Analysis", LL04: "Meetings",
          LL05: "Constituents", LL06: "Administration", LL07: "Chores", LL08: "Rest"}

# id, title, icon, hours, kind, strong, fair, poor, reward, penalty, due penalty, context, work, weight
T = [
    # Correspondence
    ("TK18", "Sign thank-you cards", LL01, 1, "plain", D, M, R, "Constituency support:1", "Constituency support:-1", "", "A stack of cards for last month's visitors is waiting for a signature.", "Adds a line to each card and posts the batch.", 2),
    ("TK19", "Answer a petition", LL01, 2, "plain", D, R, M, "Constituency support:2", "Constituency support:-1; Reputation:-1", "", "A petition with hundreds of names has come in.", "Reads it, drafts an answer and sends each signer a copy.", 2),
    ("TK20", "Reply to a ministry letter", LL01, 2, "plain", R, D, M, "XP:2", "Reputation:-1", "", "A ministry has written asking for the office's position.", "Checks the facts, drafts a careful reply and sends it back.", 2),
    ("TK21", "Proofread the newsletter", LL01, 2, "plain", M, R, D, "Reputation:1", "Reputation:-1", "", "The district newsletter goes out this week.", "Reads every line for typing mistakes and awkward phrasing.", 2),
    ("TK22", "Answer the office inbox", LL01, 1, "plain", D, M, R, "Constituency support:1", "Constituency support:-1", "Constituency support:-1", "The shared inbox is filling up again.", "Sorts the messages and answers the ones that can be answered today.", 3),
    ("TK23", "Mail the district report", LL01, 1, "plain", M, D, R, "District awareness:1", "Reputation:-1", "", "The quarterly report to the district is ready to go out.", "Stuffs envelopes, checks the addresses and posts them.", 1),
    # Press
    ("TK24", "Draft a press release", LL02, 2, "plain", M, R, D, "National awareness:1", "Reputation:-1", "", "The office has news worth announcing.", "Writes a short release and sends it to the usual outlets.", 2),
    ("TK25", "Prepare a Q&A sheet", LL02, 2, "plain", M, R, D, "Reputation:1", "Reputation:-1", "", "Reporters will ask the same ten questions again.", "Writes the questions and the answers the member will stand behind.", 2),
    ("TK26", "Return a reporter's call", LL02, 1, "plain", M, D, R, "National awareness:1", "Reputation:-1", "Reputation:-1", "A reporter has called twice and is waiting.", "Calls back, gives a clear answer and keeps it short.", 3),
    ("TK27", "Fact-check a quote", LL02, 2, "plain", R, M, D, "Reputation:1; XP:1", "Reputation:-2", "", "A quote attributed to the member is going round.", "Finds the original words and writes a short correction if needed.", 1),
    ("TK28", "Monitor the social feeds", LL02, 1, "plain", M, R, D, "Reputation:1", "Reputation:-1", "", "People are talking about the office online.", "Reads the day's mentions and flags what needs an answer.", 2),
    ("TK29", "Pitch a local story", LL02, 3, "plain", M, D, R, "District awareness:2", "Reputation:-1", "", "The local paper is short of good news.", "Calls the editor with a story about something the office did.", 1),
    # Analysis
    ("TK30", "Summarize a committee report", LL03, 3, "plain", R, D, M, "XP:3", "Reputation:-1", "", "A committee has published a long report on a current bill.", "Reads it through and writes a two-page summary.", 2),
    ("TK31", "Check a bill's costing", LL03, 3, "plain", R, M, D, "XP:2; Reputation:1", "Reputation:-1", "", "The cost estimate for a bill has been questioned.", "Rebuilds the numbers and lists what does not add up.", 2),
    ("TK32", "Compare how other regions handle it", LL03, 4, "plain", R, D, M, "XP:3; Party support:1", "Reputation:-1", "", "A colleague asks how other regions solved the same problem.", "Finds three examples and sets out what worked and what failed.", 1),
    ("TK33", "Brief the member on a bill", LL03, 2, "plain", M, R, D, "Reputation:1", "Reputation:-1", "", "The member has ten minutes before a vote.", "Writes a one-page brief: what it does, who gains, who pays.", 2),
    ("TK34", "Read the public submissions", LL03, 3, "plain", R, D, M, "XP:2; Constituency support:1", "Constituency support:-1", "", "The public has sent in comments on a proposal.", "Reads each submission and sorts them by what they ask for.", 2),
    ("TK35", "Build a one-page fact sheet", LL03, 2, "plain", R, M, D, "XP:2", "Reputation:-1", "", "A visitor asked for the facts on a local issue.", "Collects the key numbers and sets them out on one page.", 2),
    ("TK36", "Review the budget line items", LL03, 3, "plain", R, D, M, "Funds:5000", "Funds:-5000", "", "A line in the office budget does not look right.", "Goes through each item and finds the savings, or the mistakes.", 1),
    # Meetings
    ("TK37", "Attend a town council session", LL04, 3, "plain", D, R, M, "Constituency support:2", "Constituency support:-1", "", "The town council is sitting on something that affects the district.", "Sits in the gallery, takes notes and speaks to members at the break.", 2),
    ("TK38", "Attend a trade fair", LL04, 3, "plain", M, D, R, "National awareness:1; Reputation:1", "Funds:-3000", "", "A trade fair has opened in the prefecture.", "Walks the stands, shakes hands and collects business cards.", 1),
    ("TK39", "Sit in on a party caucus", LL04, 2, "plain", R, M, D, "Party support:2", "Party support:-1", "", "The party caucus is meeting and the member cannot attend.", "Listens for what the party wants and reports back.", 2),
    ("TK40", "Visit the {target} office", LL04, 2, "organization", D, M, R, "Standing:2", "Standing:-1", "", "{target} has asked to meet someone from the office.", "Calls in person, listens to the concerns and takes notes.", 2),
    # Constituents
    ("TK41", "Hold an office hour", LL05, 3, "plain", D, M, R, "Constituency support:2; XP:1", "Constituency support:-1", "", "Constituents have booked the office's open hours.", "Meets each visitor in turn and records what they need.", 2),
    ("TK42", "Visit a local shop", LL05, 2, "plain", D, M, R, "Constituency support:1; District awareness:1", "Constituency support:-1", "", "A shop on the main street has invited the office to drop in.", "Chats with the owner, buys something small and listens.", 2),
    ("TK43", "Return a complaint call", LL05, 1, "plain", D, R, M, "Constituency support:1", "Constituency support:-2", "Constituency support:-1", "A resident left an angry message yesterday.", "Calls back, apologises for the wait and takes down the problem.", 3),
    ("TK44", "Visit the elders' home", LL05, 3, "plain", D, M, R, "Constituency support:2", "Constituency support:-1", "", "The residents of the elders' home have asked after the member.", "Visits with tea and a small gift and listens to what they say.", 1),
    ("TK45", "Host a school group", LL05, 2, "plain", M, D, R, "District awareness:1; Constituency support:1", "Reputation:-1", "", "A school class is visiting the legislature.", "Shows the children round and answers their questions.", 1),
    # Administration
    ("TK46", "File expense claims", LL06, 2, "plain", R, D, M, "Funds:3000", "Funds:-3000", "Funds:-2000", "The month's receipts are still in a drawer.", "Sorts the receipts and files each claim before the deadline.", 3),
    ("TK47", "Renew a permit", LL06, 2, "plain", R, D, M, "Reputation:1", "Reputation:-1", "", "A permit for the district office is about to lapse.", "Fills in the forms and walks them to the counter.", 2),
    ("TK48", "Book a hall", LL06, 1, "plain", D, M, R, "Constituency support:1", "Constituency support:-1", "", "A town meeting needs a room.", "Finds a free hall and confirms the booking.", 2),
    ("TK49", "Update the donor list", LL06, 2, "plain", M, R, D, "Funds:4000", "Reputation:-1", "", "The supporter list has not been touched in months.", "Checks each name and address and adds the new ones.", 1),
    ("TK50", "Chase a late reimbursement", LL06, 2, "plain", R, M, D, "Funds:5000", "Funds:-3000", "", "A promised payment has not arrived.", "Writes, phones and waits at the counter until it is settled.", 1),
    ("TK51", "Archive last month's papers", LL06, 1, "plain", R, D, M, "XP:1", "Reputation:-1", "", "The filing trays are full again.", "Boxes the old papers and labels each box.", 2),
    # Chores
    ("TK52", "Restock the tea", LL07, 1, "plain", D, M, R, "Loyalty all:1", "Loyalty all:-1", "", "The tea tin is empty.", "Buys tea and biscuits and puts the kettle on.", 1),
    ("TK53", "Fix the printer", LL07, 1, "plain", R, D, M, "Reputation:1", "Reputation:-1", "", "The printer is jammed again.", "Pulls out the paper, finds the cause and fixes it.", 1),
    ("TK54", "Tidy the filing cabinet", LL07, 1, "plain", R, D, M, "XP:1", "Reputation:-1", "", "Nobody can find anything in the filing cabinet.", "Sorts every folder and relabels the drawers.", 1),
    ("TK55", "Sort the mail", LL07, 1, "plain", M, D, R, "Constituency support:1", "Constituency support:-1", "", "Two days of mail are in a heap by the door.", "Opens, sorts and passes each letter to the right desk.", 1),
    ("TK56", "Water the office plants", LL07, 1, "plain", D, M, R, "Loyalty all:1", "Loyalty all:-1", "", "The plants by the window have gone dry.", "Waters them, and moves the sad one to the light.", 1),
    ("TK57", "Wipe down the meeting table", LL07, 1, "plain", R, D, M, "Reputation:1", "Reputation:-1", "", "A visitor is due and the table is sticky.", "Wipes the table and straightens the chairs.", 1),
    # Rest (time off in different lengths)
    ("TK58", "Take a short break", LL08, 2, "time_off", "", "", "", "Loyalty:1", "", "", "The office has been busy.", "Steps out for tea and a walk round the block.", 1),
    ("TK59", "Take a long lunch", LL08, 3, "time_off", "", "", "", "Loyalty:1", "", "", "Nobody has sat down for lunch all week.", "Takes lunch somewhere with a view.", 1),
    ("TK60", "Take a half day", LL08, 4, "time_off", "", "", "", "Loyalty:1", "", "", "The work will keep until the afternoon.", "Goes home at noon.", 1),
    ("TK61", "Walk by the lake", LL08, 2, "time_off", "", "", "", "Loyalty:1", "", "", "The weather is fine and the lake is close.", "Takes a slow walk along the shore.", 1),
    ("TK62", "Take a quiet afternoon", LL08, 3, "time_off", "", "", "", "Loyalty:1", "", "", "It is a slow afternoon.", "Reads, drinks tea and answers nothing.", 1),
    ("TK63", "Leave early", LL08, 4, "time_off", "", "", "", "Loyalty:1", "", "", "Everything on the desk can wait until tomorrow.", "Locks up and heads home early.", 1),
    ("TK64", "Go on a staff outing", LL08, 4, "time_off", "", "", "", "Loyalty:1", "", "", "The whole office has been invited out.", "Spends the afternoon with the team away from the desk.", 1),
]

FAMILIES_HEADERS = ["Family", "Min", "Max", "Cap", "Weekend Factor", "Note"]
FAMILIES = [
    ["Correspondence", 1, 2, 4, 50, "Letters and replies: something nearly every day."],
    ["Press", 0, 2, 4, 50, "Some days there is no press work at all."],
    ["Analysis", 0, 2, 4, 50, "Reading and checking; heavier when a bill is in progress (drivers, phase 3)."],
    ["Meetings", 0, 2, 4, 50, "Going somewhere and representing the member."],
    ["Constituents", 1, 3, 5, 50, "The district always has someone at the door."],
    ["Administration", 0, 2, 4, 50, "Forms and filings; heavier when dues are owed (drivers, phase 3)."],
    ["Chores", 0, 1, 3, 50, "Small jobs around the office."],
    ["Rest", 1, 1, 1, 100, "One chance a day to give someone time off."],
]
RAMP_HEADERS = ["Week", "Max Tasks", "Weekend Factor", "Note"]
RAMP = [
    [1, 0, 50, "The first week is free: no tasks are delivered."],
    [2, 1, 50, "One task a day."],
    [3, 2, 50, "Two tasks a day."],
    [4, 3, 50, "Three tasks a day."],
    [5, 15, 50, "From this week on, the default maximum; the last row applies to every later week."],
]


def main():
    w = WB("design/Game_Workbook.xlsx")
    sheet = "Staff Assignments"
    for row in T:
        values = {"A": row[0], "B": row[1], "C": row[2], "D": row[3], "E": row[4], "F": row[5], "G": row[6],
                  "H": row[7], "I": row[8], "J": row[9], "K": row[10], "L": row[11], "M": row[12],
                  "N": row[13], "O": FAMILY[row[2]]}
        values = {k: v for k, v in values.items() if v != ""}
        try:
            existing = w.find_row(sheet, row[0])
        except KeyError:
            existing = None
        if existing:
            for col, v in values.items():
                w.set_cell(sheet, existing, col, v)
        else:
            w.append_row(sheet, values, style_row=w.last_data_row(sheet))
    # The two fixed pool-size rows are replaced by the ramp tab.
    for key in ("Staff Tasks: Pool Size", "Staff Tasks: Weekend Pool Size"):
        try:
            w.delete_row("Balance", w.find_row("Balance", key))
        except KeyError:
            pass
    w.save()
    names = [s for s in WB("design/Game_Workbook.xlsx").sheet]
    if "Staff Task Families" not in names:
        add_sheet("design/Game_Workbook.xlsx", "Staff Task Families", FAMILIES_HEADERS, FAMILIES, widths=[18, 8, 8, 8, 16, 70])
    if "Staff Task Ramp" not in names:
        add_sheet("design/Game_Workbook.xlsx", "Staff Task Ramp", RAMP_HEADERS, RAMP, widths=[8, 12, 16, 80])
    print("ok", len(T))


if __name__ == "__main__":
    main()
