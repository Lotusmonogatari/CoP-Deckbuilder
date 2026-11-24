#!/usr/bin/env python3
"""Venue activities (2026-11-24, Cameron): the Old Shrine, the Local Shotengai and the Library get real activities, with hours, Funds,
standing, awareness and per-day limits, and the shrine's cumulative gifts. Run once from the repo root:
    python3 tools/workbook/archive/venue_activities_build.py
Then python3 tools/export_data.py (must say "No errors"). Every sentence is Claude's draft for Cameron to reword."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

PATH = "design/Game_Workbook.xlsx"
NOTE = "Venue activities (2026-11-24): Claude's draft for Cameron to reword."
w = WB(PATH)

# --- Venue Activities: six new columns -------------------------------------------------------------------------------------------
NEW_COLS = [("P", "Rewards"), ("Q", "District Awareness Δ"), ("R", "Staff Hours"), ("S", "Bonus After Uses"),
            ("T", "Bonus Staff Hours"), ("U", "Result Text")]
for col, header in NEW_COLS:
    w.set_cell("Venue Activities", 1, col, header, style_from=1)

# Rewards: "BO20 +2; BO19 +2; BO15 +2" is standing (Shrine Association, Buddhist Temples Association, Our Traditional Society);
# "ENERGY" is +1 energy for the next stage; BO18 is Constituency Voters and BO03 Local Kōenkai.
SHRINE3 = "BO20 +2; BO19 +2; BO15 +2"
ACTS = [
    # id, venue, name, icon, hours, funds, per_day, rewards, awareness, staff_hours, bonus_after, bonus_hours, result
    ("VA08", "VN08", "Clean the surroundings", "ACT_SHRINE", 2, None, 2, SHRINE3, None, None, None, None,
     "You sweep the path no one else sweeps, rinse the stone basin and clear the leaves that no one else comes to clear."),
    ("VA10", "VN08", "Place 1,000円 in the saisenbako", "ACT_SHRINE", None, 1000, 1, SHRINE3, None, None, None, None,
     "You find the saisenbako half hidden by weeds, drop 1,000円 in, bow twice, clap twice and bow once."),
    ("VA11", "VN08", "Pay your respects", "ACT_SHRINE", 1, None, 1, None, None, None, None, None,
     "You walk the long path out to the old hall and bow your head. No one else is here, and the whole forest is quiet."),
    ("VA09", "VN09", "Distribute district office flyers", "ACT_SHOTENGAI", 2, None, 1, None, 1, None, None, None,
     "You hand out flyers outside the shops. Some people stop to read them, and some stop to talk."),
    ("VA12", "VN09", "Speak through a megaphone", "ACT_SHOTENGAI", 3, None, 1, "BO18 -1; BO03 -1", 3, None, None, None,
     "You speak through a megaphone from the corner of the street. Some listen. Some wave you away, and a few shops close their doors."),
    ("VA13", "VN09", "Treat local kōenkai members to a meal", "ACT_SHOTENGAI", 1, 15000, 2, "BO03 +3", None, None, None, None,
     "You treat your kōenkai members to a meal. The talk goes on long after the dishes are cleared."),
    ("VA14", "VN02", "Nap", "ACT_NAP", 2, None, 1, "ENERGY", None, None, None, None,
     "You find a quiet corner of the Library and sleep. You wake rested."),
    ("VA15", "VN02", "Read about management practices", "ACT_READ", 2, None, 1, None, None, 1, 50, 1,
     "You read about how to run an office well. Your staff will get more done today."),
]
for act in ACTS:
    aid, venue, name, icon, hours, funds, per_day, rewards, aware, staff, after, bonus, result = act
    cells = {"A": aid, "B": venue, "C": "act", "D": name, "E": icon, "G": hours, "H": funds, "J": per_day, "P": rewards,
             "Q": aware, "R": staff, "S": after, "T": bonus, "U": result}
    cells = {k: v for k, v in cells.items() if v is not None}
    try:
        row = w.find_row("Venue Activities", aid)
    except KeyError:
        row = None
    if row:   # VA08 and VA09 were placeholder rows (Visit the Shrine, Walk the Shotengai)
        for col in ("C", "D", "E", "G", "H", "I", "J", "P", "Q", "R", "S", "T", "U"):
            w.set_cell("Venue Activities", row, col, cells.get(col, ""), style_from=row)
    else:
        w.append_row("Venue Activities", cells, style_row=w.last_data_row("Venue Activities"))
w.save()

# --- Venue Milestones: the shrine's cumulative gifts ---------------------------------------------------------------------------------
HEAD = ["Milestone ID", "Activity ID", "Count", "Result Text", "Rewards", "District Awareness Δ", "Funds Δ"]
ROWS = [
    ["VM01", "VA11", 5, "You found 5,000円.", None, None, 5000],
    ["VM02", "VA11", 30, "You found a free rhetoric training session coupon.", "SH21", None, None],
    ["VM03", "VA11", 75, "The few who visit this old, worn down shrine see your diligence to respect the kami this shrine venerates. "
     "Those visitors also tell their friends.", "BO20 +10; BO19 +10; BO15 +10", 10, None],
    ["VM04", "VA11", 150, "The locals arranged a moment of respect for your continued presence and devotion to this old shrine. "
     "They provide you a token of their appreciation.", "BO20 +25; BO19 +25; BO15 +25", 25, 100000],
]
add_sheet(PATH, "Venue Milestones", HEAD, [[("" if v is None else v) for v in r] for r in ROWS], [14, 12, 8, 70, 34, 20, 12])

# --- Text rows --------------------------------------------------------------------------------------------------------------------
w = WB(PATH)
TEXT = [
    ("venue.act_do", "Venue activity: the button that does it", "Do this", None),
    ("venue.act_costs", "Venue activity: what it costs, before it is done", "Costs {list}", "list"),
    ("venue.act_free", "Venue activity: it costs nothing", "Costs nothing", None),
    ("venue.act_gives", "Venue activity: what it gives, before it is done", "Gives: {list}", "list"),
    ("venue.act_counted", "Venue activity with gifts: what it gives, before it is done", "Each visit is counted.", None),
    ("venue.act_left", "Venue activity: how many times are left today", "{count} of {limit} left today", "count, limit"),
    ("venue.act_times", "Venue activity with gifts: how many times it has been done", "Times done: {count}", "count"),
    ("venue.cost_hours", "Venue activity cost: hours", "{count} h", "count"),
    ("venue.cost_funds", "Venue activity cost: Funds", "{count}円", "count"),
    ("venue.effect_standing", "Venue activity effect: an organization's standing", "{name} {delta}", "name, delta"),
    ("venue.effect_awareness", "Venue activity effect: District awareness", "District awareness {delta}", "delta"),
    ("venue.effect_funds", "Venue activity effect: Funds", "Funds +{delta}円", "delta"),
    ("venue.effect_staff_hours", "Venue activity effect: work hours for all staff today", "Staff work hours today {delta}", "delta"),
    ("venue.effect_energy", "Venue activity effect: energy in the next stage", "Energy in your next stage {delta}", "delta"),
    ("venue.tag_done", "Venue activity result card: the tag", "Done", None),
    ("venue.refuse_limit", "Venue activity: the limit for today is reached", "Done for today. Come back tomorrow.", None),
    ("record.cause_venue", "What moved your standing: a venue activity", "{activity}", "activity"),
]
for key, where, english, placeholders in TEXT:
    cells = {"A": key, "B": where, "C": english, "E": NOTE}
    if placeholders:
        cells["D"] = placeholders
    w.append_row("Text", cells, style_row=w.last_data_row("Text"))
w.save()
print("workbook updated")
