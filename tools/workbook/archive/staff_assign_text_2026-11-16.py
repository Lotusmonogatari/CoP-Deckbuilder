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
    ("assign.no_staff", "Staff Assignments, no staff hired", "Hire staff to do the day's tasks for you.", ""),
    ("assign.date_line", "Staff Assignments, date and tasks left", "{date} · {count} tasks not yet given out", "date, count"),
    ("assign.hint", "Staff Assignments, how it works", "Drag a task into a person's box, or tap it to read it and choose who does it. The frame shows how well they suit it: gold strong, grey fair, red poor. Press Confirm to lock in the day.", ""),
    ("assign.tray_heading", "Staff Assignments, tasks heading", "Today's tasks", ""),
    ("assign.tray_empty", "Staff Assignments, every task has been given out", "Every task has been given out.", ""),
    ("assign.staff_heading", "Staff Assignments, staff heading", "Your staff", ""),
    ("assign.projection_heading", "Staff Assignments, projection heading", "If you confirm", ""),
    ("assign.projection_none", "Staff Assignments, projection with no changes", "Nothing changes yet.", ""),
    ("assign.confirm", "Staff Assignments, confirm button", "Confirm today's work", ""),
    ("assign.locked_note", "Staff Assignments, after confirming", "Locked in. The results arrive when the day ends.", ""),
    ("assign.blocks_short", "Staff Assignments, task card cost", "{count} hours", "count"),
    ("assign.role_line", "Staff Assignments, a person's role and rank", "{role} · Rank {tier}", "role, tier"),
    ("assign.loyalty_line", "Staff Assignments, Loyalty and today's change", "Loyalty: {word} · today {count}", "word, count"),
    ("assign.blocks_line", "Staff Assignments, workload", "{used} of {total} hours of their day used", "used, total"),
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
    ("assign.time_one", "Task popup, time cost of one block", "1 Hour", ""),
    ("assign.time_many", "Task popup, time cost", "{count} Hours", "count"),
    ("assign.popup_outcome_heading", "Task popup, heading", "Outcome", ""),
    ("assign.outcome_line", "Task popup, one fit", "{fit} ({role}): {result}", "fit, role, result"),
    ("assign.outcome_nothing", "Task popup, no effect", "nothing happens", ""),
    ("assign.outcome_time_off", "Task popup, time off", "Whoever takes it gains Loyalty {count}. If nobody takes it, everyone loses Loyalty.", "count"),
    ("assign.popup_due", "Task popup, penalty if left undone", "If nobody does it today: {penalty}", "penalty"),
    ("assign.give_heading", "Task popup, who can do it", "Assign To", ""),
    ("assign.give_to", "Task popup, button", "{name} ({fit})", "name, fit"),
    ("assign.already_theirs", "Task popup, button when they already have it", "{name} already has it", "name"),
    ("assign.refuse_locked", "Task popup, button when the day is locked", "{name}: today's work is locked in", "name"),
    ("assign.refuse_blocks", "Task popup, button when their day is full", "{name} has no room left today", "name"),
    ("assign.take_back", "Task popup, button", "Take it back", ""),
    ("assign.close", "Task popup, the way out", "Close", ""),
    ("assign.report_title", "Day report, heading", "Your staff's day", ""),
    ("assign.report_date", "Day report, date", "{date}", "date"),
    ("assign.report_line", "Day report, one task done", "{name}: {title} ({fit}): {result}", "name, title, fit, result"),
    ("assign.blocks_one", "Staff Assignments, task card cost of one hour", "1 hour", ""),
    ("assign.report_line_plain", "Day report, time off", "{name}: {title}: {result}", "name, title, result"),
    ("assign.report_unsettled", "Day report, a restless person's weaker result", "They were unsettled, so it counted one step weaker.", ""),
    ("event.delegate_label", "Event choice that sends a staff member", "{text}  ·  you choose who goes", "text"),
    ("event.delegate_title", "Event, who goes", "Who goes?", ""),
    ("event.delegate_intro", "Event, who goes", "A {role} is the best person for this. It takes {count} hours of their day.", "role, count"),
    ("event.delegate_pick", "Event, who goes, one person", "{name} ({fit}) · {left} hours free", "name, fit, left"),
    ("event.delegate_no_time", "Event, nobody has enough of today left", "Nobody on staff has enough of today left", ""),
    ("event.delegate_intro_one", "Event, who goes (one block)", "A {role} is the best person for this. It takes 1 hour of their day.", "role"),
    ("event.delegate_person_no_time", "Event, who goes, one person with no time", "{name} has no time left today", "name"),
    ("event.delegate_line", "Event result, who handled it", "{name} handled it for you ({fit}).", "name, fit"),
    ("event.delegate_fair", "Event result, a fair fit", "They were not the best person for it, so you gained less.", ""),
    ("event.delegate_poor", "Event result, a poor fit", "They were unsettled and it showed: you gained nothing.", ""),
    ("assign.name_xp", "Staff Assignments, the name of XP in a change", "XP", ""),
    ("assign.result_nothing", "Task popup, a result block with no effect", "Nothing happens", ""),
    ("assign.tile_has_it", "Task popup, a staff picture whose person already has the task", "Has this task", ""),
    ("assign.tile_locked", "Task popup, a staff picture when the day is locked in", "Locked in", ""),
    ("assign.tile_no_room", "Task popup, a staff picture when their day is full", "No room today", ""),
    ("assign.no_assignment", "Task popup, button to take the task back", "No Assignment", ""),
    ("assign.items_heading", "Staff Assignments, items for staff heading", "Items for your staff", ""),
    ("assign.items_none", "Staff Assignments, no staff items held", "You hold no coffee or tea. They are sold in the Marketplace.", ""),
    ("assign.item_caption", "Staff Assignments, a staff item card", "+{hours} hours · {free} left", "hours, free"),
    ("assign.item_caption_one", "Staff Assignments, a staff item card, one hour", "+1 hour · {free} left", "free"),
    ("assign.item_in_box", "Staff Assignments, a staff item in a person's box", "+{hours} hours", "hours"),
    ("assign.item_in_box_one", "Staff Assignments, a staff item in a person's box, one hour", "+1 hour", ""),
    ("assign.item_effect_heading", "Item popup, heading", "What it does", ""),
    ("assign.item_effect_one", "Item popup, one hour", "Adds 1 hour to one person's working day.", ""),
    ("assign.item_effect_many", "Item popup", "Adds {hours} hours to one person's working day.", "hours"),
    ("assign.item_one_each", "Item popup, the rule", "Each person can have one item a day. It is used up when you confirm the day.", ""),
    ("assign.tile_none_left", "Item popup, a staff picture when none of the item is left", "None left", ""),
    ("assign.no_staff_due", "Staff Assignments, tasks delivered but no staff hired", "You have no staff, so nobody can do these. Any marked Due that is left undone costs you when the day ends. Hire staff to take them on.", ""),
    ("assign.gift_loved", "Gift given, a liked gift", "{name} loves it. Loyalty {count}.", "name, count"),
    ("assign.gift_fine", "Gift given, a neutral gift", "{name} is glad of it. Loyalty {count}.", "name, count"),
    ("assign.gift_disliked", "Gift given, a disliked gift", "{name} did not care for it. Loyalty {count}.", "name, count"),
    ("assign.gift_title", "Gifts handed over, heading", "Gifts", ""),
    ("assign.office_heading", "Staff Assignments, Office box heading", "Office box", ""),
    ("assign.office_hint", "Staff Assignments, Office box explanation", "An item placed here changes the tasks of the next day or days. It is used up when you confirm the day.", ""),
    ("assign.office_empty", "Staff Assignments, an empty Office box", "Drop an Office item here", ""),
    ("assign.office_place", "Item popup, button to put an item in the Office box", "Place in the Office box", ""),
    ("assign.office_one_rule", "Item popup, the Office box rule", "Only one item can be in the Office box. It is used up when you confirm the day.", ""),
    ("assign.office_has_it", "Item popup, the item is already in the Office box", "Already in the Office box", ""),
    ("assign.why_line", "Staff Assignments, why today's tasks look as they do", "{note}: {family} {amount}", "note, family, amount"),
    ("assign.max_line", "Staff Assignments, the most tasks today", "Most tasks today: {count}", "count"),
    ("assign.family_max", "Staff Assignments, the name of the day's maximum in a reason", "most tasks a day", ""),
    ("assign.item_left", "Staff item card, how many are still free", "· {free} left", "free"),
    ("assign.item_cap_family", "Staff item card, strong fit for a family", "Strong at {family}", "family"),
    ("assign.item_cap_mult", "Staff item card, reward boost", "Rewards {percent}%", "percent"),
    ("assign.item_cap_quiet", "Staff item card, quiet day", "Quiet day", ""),
    ("assign.item_cap_gift", "Staff item card, gift", "Gift", ""),
    ("assign.item_cap_pool", "Staff item card, Office item that changes a family", "{family} {amount}", "family, amount"),
    ("assign.item_cap_max", "Staff item card, Office item that changes the most tasks", "Tasks {amount}", "amount"),
    ("assign.item_desc_family", "Item popup, strong fit for a family", "Today, the person you give it to counts as a strong fit for {family} tasks.", "family"),
    ("assign.item_desc_mult", "Item popup, reward boost", "Today, the rewards from that person's strong-fit tasks are {percent}% as big.", "percent"),
    ("assign.item_desc_quiet", "Item popup, quiet day", "Today, that person gains or loses no Loyalty from an idle or overworked day.", ""),
    ("assign.item_desc_gift", "Item popup, gift", "A gift. Their Loyalty changes by their taste, and you learn their taste when you hand it over.", ""),
    ("assign.item_desc_pool_one", "Item popup, an Office item for one day", "Changes the number of {family} tasks in the next day's tasks by {amount}.", "family, amount"),
    ("assign.item_desc_pool_many", "Item popup, an Office item for several days", "Changes the number of {family} tasks by {amount} on each of the next {days} days.", "family, amount, days"),
    ("assign.item_desc_max_one", "Item popup, changes the most tasks for one day", "Changes the most tasks the next day delivers by {amount}.", "amount"),
    ("assign.item_desc_max_many", "Item popup, changes the most tasks for several days", "Changes the most tasks delivered by {amount} on each of the next {days} days.", "amount, days"),
    ("staff.taste_known", "Staff profile, gift taste once known", "Gifts: likes {likes}. Dislikes {dislikes}.", "likes, dislikes"),
    ("staff.taste_unknown", "Staff profile, gift taste not yet known", "Gifts: taste unknown. Give a gift to find out.", ""),
    ("staff.taste_none", "Staff profile, no liked or disliked gift", "nothing in particular", ""),
    ("assign.item_cap_all_one", "Staff item card, +1 hour for everyone", "+1 hour, all staff", ""),
    ("assign.item_cap_all", "Staff item card, hours for everyone", "+{hours} hours, all staff", "hours"),
    ("assign.item_desc_all_one", "Item popup, +1 hour for everyone", "Adds 1 hour to every staff member's working day today.", ""),
    ("assign.item_desc_all", "Item popup, hours for everyone", "Adds {hours} hours to every staff member's working day today.", "hours"),
    ("assign.report_totals", "Day report, totals heading", "In all", ""),
]

RULES = [
    ("staff_task_official_prefixes", '["Minister", "Prime Minister", "President of the National Assembly", "Speaker"]',
     "any list of the beginnings of posts",
     "A part of an opponent's Title that begins with one of these is a post a staff task can name (\"Attend the Minister of Finance's press conference\"). Add a post here to add it to the tasks (Cameron, 2026-11-16)."),
    ("staff_task_committee_marker", "Committee on", "words that introduce a committee's name",
     "The part of an opponent's Title from this phrase onward is a committee a staff task can name (\"Listen in on the Committee on Finance\")."),
]


def main():
    w = WB("design/Game_Workbook.xlsx")
    rules = w.rows("Rules")
    by_rule = {v.get("A"): r for r, v in rules.items()}
    for key, value, options, notes in RULES:
        values = {"A": key, "B": value, "C": options, "F": notes}
        if key in by_rule:
            for col, v in values.items():
                w.set_cell("Rules", by_rule[key], col, v)
        else:
            w.append_row("Rules", values, style_row=w.last_data_row("Rules"))
    w.save()
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
