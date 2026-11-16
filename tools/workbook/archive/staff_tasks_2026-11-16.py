#!/usr/bin/env python3
"""The Staff Assignments tab and its Balance rows (Cameron, 2026-11-16;
design/proposals/STAFF_ASSIGNMENTS_2026-11-16.md). Claude's draft numbers and
sentences. Run once on a workbook that has no such tab:

    python3 tools/workbook/archive/staff_tasks_2026-11-16.py
"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

R, M, D = "Policy Research Assistant", "Media Spokesperson", "District Representative"
HEADERS = ["Task ID", "Task", "Icon", "Blocks", "Kind", "Strong Fit", "Fair Fit", "Poor Fit",
           "Strong Reward", "Poor Penalty", "Due Penalty", "Context", "Work Performed", "Weight"]
ROWS = [
    ["TK01", "Write constituent letters", "LL01", 2, "plain", D, M, R, "Constituency support:1", "Constituency support:-1", "", "Letters from the district are stacking up on the desk.", "Reads each letter, drafts a reply for your signature and files the case.", 3],
    ["TK02", "Respond to committee staff", "LL01", 1, "plain", R, D, M, "XP:2", "Reputation:-1", "Party support:-1", "A committee clerk wants answers before the next sitting.", "Answers the clerk's questions and returns the corrected papers.", 2],
    ["TK03", "Build media relationships", "LL02", 2, "plain", M, D, R, "National awareness:1", "Reputation:-1", "", "Reporters remember who returns their calls.", "Phones and lunches with reporters, offering background on your work.", 2],
    ["TK04", "Review the news", "LL02", 1, "plain", M, R, D, "Reputation:1", "Reputation:-1", "", "The morning papers and wire stories are in.", "Reads the coverage and flags what the office should answer.", 3],
    ["TK05", "Review a policy whitepaper", "LL03", 3, "plain", R, D, M, "XP:3", "Reputation:-1", "", "A think tank has circulated a long paper on a bill before the house.", "Reads the paper line by line and writes a one-page summary.", 2],
    ["TK06", "Attend a policy conference", "LL04", 4, "plain", R, M, D, "XP:3; Reputation:1", "Funds:-5000", "", "A conference on a current policy issue is open to staff.", "Sits in the sessions, takes notes and collects contacts.", 1],
    ["TK07", "Attend a meeting with {target}", "LL04", 3, "organization", D, R, M, "Standing:3", "Standing:-2", "", "{target} has invited your office to its regular meeting.", "Represents you in the room and reports back what members asked for.", 2],
    ["TK08", "Listen in on the {target}", "LL04", 3, "committee", R, D, M, "XP:2; Party support:1", "Party support:-1", "", "The {target} is sitting today.", "Follows the hearing from the gallery and notes who said what.", 2],
    ["TK09", "Attend the {target}'s press conference", "LL04", 2, "official", M, R, D, "National awareness:2", "Reputation:-1", "", "The {target} is holding a press conference today.", "Stands with the press corps, asks nothing, and takes the quotes home.", 2],
    ["TK10", "Greet constituents", "LL05", 2, "plain", D, M, R, "Constituency support:2", "Constituency support:-1", "", "Visitors are queueing at the district office door.", "Welcomes each visitor, offers tea and takes down what they came for.", 3],
    ["TK11", "Perform constituent casework", "LL05", 3, "plain", D, R, M, "Constituency support:2; District awareness:1", "Constituency support:-2", "Constituency support:-1", "Several local cases are waiting for someone to chase them.", "Phones the agencies, fills in the forms and reports back to each household.", 3],
    ["TK12", "Speak with difficult constituents", "LL05", 3, "plain", M, D, R, "Constituency support:3", "Constituency support:-3; Reputation:-1", "", "A group of angry residents has asked for a word.", "Listens, stays calm, and promises only what the office can do.", 1],
    ["TK13", "Deal with bureaucrats", "LL06", 3, "plain", R, D, M, "Funds:8000", "Funds:-8000", "", "A ministry office has a form that only a patient person can finish.", "Queues at the counter and chases signatures through three departments.", 2],
    ["TK14", "Schedule upcoming meetings", "LL06", 1, "plain", D, M, R, "Reputation:1", "Reputation:-1", "Reputation:-1", "The calendar has clashes next week.", "Rings round, moves appointments and sends the revised list.", 2],
    ["TK15", "Organize the office lunch", "LL07", 1, "plain", D, M, R, "Loyalty all:1", "Loyalty all:-1", "", "It is nearly noon and nobody has ordered.", "Collects orders, collects money, collects chopsticks.", 1],
    ["TK16", "Clean the office microwave", "LL07", 1, "plain", R, D, M, "Reputation:1", "Reputation:-1", "", "Something has exploded in it again.", "Scrubs, airs the room and leaves a note on the door.", 1],
    ["TK17", "Time off", "LL08", 4, "time_off", "", "", "", "Loyalty:1", "", "", "Your office has worked hard.", "Takes the afternoon off.", 0],
]

BALANCE = [
    ("Staff Tasks: Pool Size", 8, "Tasks offered on a workday. Time off is always one of them."),
    ("Staff Tasks: Weekend Pool Size", 5, "Tasks offered on a weekend day."),
    ("Staff Tasks: Rank Bonus Percent", 25, "Strong-fit rewards grow this percent per rank (rounded down)."),
    ("Staff Tasks: Cap Meta", 3, "Most one day's tasks can add to, or take from, Constituency support, Reputation or Party support."),
    ("Staff Tasks: Cap XP", 6, "Most XP one day's tasks can add."),
    ("Staff Tasks: Cap Funds", 10000, "Most Funds one day's tasks can add or take."),
    ("Staff Tasks: Cap Awareness", 2, "Most awareness one day's tasks can add."),
    ("Staff Tasks: Cap Standing", 6, "Most standing with one organization one day's tasks can add or take."),
    ("Staff Tasks: Fit Loyalty", 1, "Loyalty a person gains for a Strong-fit task or loses for a Poor-fit one."),
    ("Staff Tasks: Idle Loyalty", 1, "Loyalty lost on a confirmed day when a person was given no tasks."),
    ("Staff Tasks: Healthy Loyalty", 1, "Loyalty gained on a day a person's bar was mostly, but not fully, used."),
    ("Staff Tasks: Healthy Minimum Percent", 60, "Share of the bar that counts as a healthy day."),
    ("Staff Tasks: Full Streak Days", 3, "Full days in a row before overwork begins."),
    ("Staff Tasks: Full Streak Loyalty", 2, "Loyalty lost on each full day from then on."),
    ("Staff Tasks: Week Loyalty Cap", 6, "Most Loyalty the week's tasks can add or take."),
    ("Staff Tasks: Time Off Loyalty", 1, "Loyalty a person gains from time off. Cameron 2026-11-16."),
    ("Staff Tasks: Time Off Unused Loyalty", 1, "Loyalty every person loses when time off was offered and nobody took it. Cameron 2026-11-16."),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Balance")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for name, value, note in BALANCE:
        if name in by_key:
            w.set_cell("Balance", by_key[name], "B", value)
            w.set_cell("Balance", by_key[name], "C", note)
        else:
            w.append_row("Balance", {"A": name, "B": value, "C": note}, style_row=w.last_data_row("Balance"))
    w.save()
    add_sheet("design/Game_Workbook.xlsx", "Staff Assignments", HEADERS, ROWS,
              widths=[9, 34, 8, 8, 14, 26, 26, 26, 34, 34, 22, 56, 64, 8])
    print("ok")

if __name__ == "__main__":
    main()
