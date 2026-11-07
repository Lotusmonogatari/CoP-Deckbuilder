"""Fills the two empty event slots EV01 and EV02 (rows 2-3 of Events, rows 2-7
of Event Choices) with draft content, 2026-11-07 (Cameron: one about the
Sapporo Grand Sumo tournament). No new event IDs or rows are created beyond
the empty ones. All text is Claude's draft for Cameron to rewrite.
Archived copy: not runnable as it stands (see ../../README.md)."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

EVENTS = {
 2: {"A": "EV01", "B": "Sapporo Grand Sumo Wants an Answer",
     "C": "The sumo association's host committee says the Grand Sumo tournament can come back to Sapporo every year, if the city and its legislators stand behind it. Hotel owners want the crowds. The ratepayers and the neighborhoods around the arena want the bill and the traffic counted first.",
     "D": "Random", "E": "Both", "F": 2, "I": 5, "M": "OUT_FESTIVAL_1", "Q": "Summer"},
 3: {"A": "EV02", "B": "The Temple Bell Needs a Ringer",
     "C": "The Buddhist Temples Association is ringing out the old year at the hillside temple and asks you to take a turn at the great bell. A neighbor mentions, quietly, that the bell tower roof leaks.",
     "D": "Random", "E": "Both", "F": 1, "I": 5, "M": "OUT_FESTIVAL_2_WINTER", "Q": "Winter"},
}

CHOICES = {
 2: {"A": "EV01", "B": "A", "C": "Pledge to fight for the tournament every year",
     "D": "You tell the committee you will argue for a yearly tournament in every room that will listen. The hotel owners applaud, and the ratepayers write down your pledge.",
     "K": "1-2", "M": "BO25 +1; BO04 +1; BO23 -1",
     "Q": "Promise Hours 2 within 72 for BO25",
     "R": "National +1; BO25 +2; BO04 +1", "S": "BO25 -4; BO04 -3; Reputation -2",
     "T": "You spend two hours with the mayors and the hotel owners, and the committee leaves with a letter of support to take back to the association."},
 3: {"A": "EV01", "B": "B", "C": "Welcome it once and ask for the public costs first",
     "D": "You tell the committee you would welcome the tournament once and study what it costs the public before promising it again. The ratepayers nod. The hotel owners do not.",
     "I": "0-1", "M": "BO23 +1; BO06 +1; BO25 -1"},
 4: {"A": "EV01", "B": "C", "C": "Send a staff member to hear both sides",
     "D": "Your staffer sits with the committee in the morning and with the ratepayers in the afternoon, and brings back both lists.",
     "K": "0-1"},
 5: {"A": "EV02", "B": "A", "C": "Take your turn at the bell and stay for tea",
     "D": "The bell hums in your chest for a full minute. Over tea the abbot thanks you, and mentions the roof.",
     "I": "0-1", "K": "1-2", "M": "BO19 +1"},
 6: {"A": "EV02", "B": "B", "C": "Send a staff member with a donation for the repairs",
     "D": "Your staffer places the envelope in the offering box and signs the book on your behalf. The abbot sends a note of thanks.",
     "M": "BO19 +1", "Q": "Funds 10000"},
 7: {"A": "EV02", "B": "C", "C": "Offer to speak for the roof at the next heritage debate",
     "D": "You tell the abbot you will raise the bell tower roof when heritage funding is next debated. He writes it down, and so does a ratepayer in the back row.",
     "M": "BO19 +1; BO23 -1",
     "Q": "Promise Hours 1 within 72 for BO19",
     "R": "BO19 +2; BO20 +1", "S": "BO19 -3; Reputation -1",
     "T": "You stand up in the heritage debate and name the bell tower roof. The abbot hears of it before you are back in your office."},
}

w = WB("design/Game_Workbook.xlsx")
for row, cells in EVENTS.items():
    for col, value in cells.items():
        w.set_cell("Events", row, col, value, style_from=4)
for row, cells in CHOICES.items():
    for col, value in cells.items():
        w.set_cell("Event Choices", row, col, value, style_from=8)
w.save()
print("filled EV01 and EV02")
