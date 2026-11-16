#!/usr/bin/env python3
"""Text rows for the Staff Assignments screen (Cameron, 2026-11-16). Claude's
draft. Safe to run again: existing keys are overwritten."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "2026-11-16 staff assignments (Cameron). Claude's draft."
ROWS = [
    ("assign.confirmed_already", "Staff Assignments, confirm button when already locked", "Today's work is already locked in", ""),
    ("assign.no_tasks", "Staff Assignments, nothing to give out", "There are no tasks today.", ""),
    ("assign.nothing_assigned", "Staff Assignments, confirm button with nothing given out", "Give someone a task first", ""),
    ("office.staff_assignments", "Office · Management menu, button", "Staff Assignments", ""),
    ("assign.title", "Staff Assignments, heading", "Staff Assignments", ""),
    ("assign.no_staff", "Staff Assignments, no staff hired", "Hire staff first. They do the day's tasks for you.", ""),
    ("assign.date_line", "Staff Assignments, date and tasks left", "{date} · {count} tasks not yet given out", "date, count"),
    ("assign.hint", "Staff Assignments, how it works", "Drag a task into a person's box, or tap it to read it and choose who does it. The frame shows how well they suit it: gold strong, grey fair, red poor. Press Confirm to lock in the day.", ""),
    ("assign.tray_heading", "Staff Assignments, tasks heading", "Today's tasks", ""),
    ("assign.tray_empty", "Staff Assignments, every task has been given out", "Every task has been given out.", ""),
    ("assign.staff_heading", "Staff Assignments, staff heading", "Your staff", ""),
    ("assign.projection_heading", "Staff Assignments, projection heading", "If you confirm", ""),
    ("assign.projection_none", "Staff Assignments, projection with no changes", "Nothing changes yet.", ""),
    ("assign.confirm", "Staff Assignments, confirm button", "Confirm today's work", ""),
    ("assign.locked_note", "Staff Assignments, after confirming", "Locked in. The results arrive when the day ends.", ""),
    ("assign.blocks_short", "Staff Assignments, task card cost", "{count} blocks", "count"),
    ("assign.role_line", "Staff Assignments, a person's role and rank", "{role} · Rank {tier}", "role, tier"),
    ("assign.loyalty_line", "Staff Assignments, Loyalty and today's change", "Loyalty: {word} · today {count}", "word, count"),
    ("assign.blocks_line", "Staff Assignments, workload", "{used} of {total} blocks of their day used", "used, total"),
    ("assign.box_empty", "Staff Assignments, an empty task box", "Drop a task here", ""),
    ("assign.fit_strong", "Staff Assignments, fit", "Strong fit", ""),
    ("assign.fit_fair", "Staff Assignments, fit", "Fair fit", ""),
    ("assign.fit_poor", "Staff Assignments, fit", "Poor fit", ""),
    ("assign.effect_generic", "Staff Assignments, one change", "{name} {amount}", "name, amount"),
    ("assign.effect_standing", "Staff Assignments, a standing change", "Standing with {name} {amount}", "name, amount"),
    ("assign.effect_loyalty", "Staff Assignments, a Loyalty change", "Their Loyalty {amount}", "amount"),
    ("assign.effect_loyalty_all", "Staff Assignments, a Loyalty change for everyone", "Everyone's Loyalty {amount}", "amount"),
    ("assign.proj_undone", "Staff Assignments, a due task left alone", "Left undone: {title} ({penalty})", "title, penalty"),
    ("assign.proj_time_off_unused", "Staff Assignments, nobody takes time off", "Nobody takes time off, so everyone's Loyalty falls by {count}.", "count"),
    ("assign.popup_context_heading", "Task popup, heading", "Why it is on the desk", ""),
    ("assign.popup_work_heading", "Task popup, heading", "Work performed", ""),
    ("assign.popup_time_heading", "Task popup, heading", "Time cost", ""),
    ("assign.time_one", "Task popup, time cost of one block", "1 block of a person's day", ""),
    ("assign.time_many", "Task popup, time cost", "{count} blocks of a person's day", "count"),
    ("assign.popup_outcome_heading", "Task popup, heading", "Outcome", ""),
    ("assign.outcome_line", "Task popup, one fit", "{fit} ({role}): {result}", "fit, role, result"),
    ("assign.outcome_nothing", "Task popup, no effect", "nothing happens", ""),
    ("assign.outcome_time_off", "Task popup, time off", "Whoever takes it gains Loyalty {count}. If nobody takes it, everyone loses Loyalty.", "count"),
    ("assign.popup_due", "Task popup, penalty if left undone", "If nobody does it today: {penalty}", "penalty"),
    ("assign.give_heading", "Task popup, who can do it", "Give it to", ""),
    ("assign.give_to", "Task popup, button", "{name} ({fit})", "name, fit"),
    ("assign.already_theirs", "Task popup, button when they already have it", "Already theirs", ""),
    ("assign.refuse_locked", "Task popup, button when the day is locked", "Today's work is locked in", ""),
    ("assign.refuse_blocks", "Task popup, button when their day is full", "Not enough of their day is left", ""),
    ("assign.take_back", "Task popup, button", "Take it back", ""),
    ("assign.close", "Task popup, the way out", "Close", ""),
    ("assign.report_title", "Day report, heading", "Your staff's day", ""),
    ("assign.report_date", "Day report, date", "{date}", "date"),
    ("assign.report_line", "Day report, one task done", "{name}: {title} ({fit}): {result}", "name, title, fit, result"),
    ("assign.blocks_one", "Staff Assignments, task card cost of one block", "1 block", ""),
    ("assign.report_line_plain", "Day report, time off", "{name}: {title}: {result}", "name, title, result"),
    ("assign.report_unsettled", "Day report, a restless person's weaker result", "They were unsettled, so it counted one step weaker.", ""),
    ("event.delegate_label", "Event choice that sends a staff member", "{text}  ·  you choose who goes", "text"),
    ("event.delegate_title", "Event, who goes", "Who goes?", ""),
    ("event.delegate_intro", "Event, who goes", "A {role} is the best person for this. It takes {count} blocks of their day.", "role, count"),
    ("event.delegate_pick", "Event, who goes, one person", "{name} ({fit}) · {left} blocks free", "name, fit, left"),
    ("event.delegate_no_time", "Event, nobody has enough of today left", "Nobody on staff has enough of today left", ""),
    ("event.delegate_line", "Event result, who handled it", "{name} handled it for you ({fit}).", "name, fit"),
    ("event.delegate_fair", "Event result, a fair fit", "They were not the best person for it, so you gained less.", ""),
    ("event.delegate_poor", "Event result, a poor fit", "They were unsettled and it showed: you gained nothing.", ""),
    ("assign.report_totals", "Day report, totals heading", "In all", ""),
]

def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("Text")
    by_key = {v.get("A"): r for r, v in rows.items()}
    for key, where, english, placeholders in ROWS:
        values = {"A": key, "B": where, "C": english, "E": NOTE}
        if placeholders:
            values["D"] = placeholders
        if key in by_key:
            for col, value in values.items():
                w.set_cell("Text", by_key[key], col, value)
        else:
            w.append_row("Text", values, style_row=w.last_data_row("Text"))
    w.save()
    print("ok", len(ROWS))

if __name__ == "__main__":
    main()
