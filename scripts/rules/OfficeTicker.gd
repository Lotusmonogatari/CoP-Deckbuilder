class_name OfficeTicker
extends RefCounted
## Which line the Office screen's news strip shows next.
##
## data/office_ticker.json uses the exact same condition schema
## OfficeNotices.gd already reads (a staff role hired, a meta variable
## against a threshold, or "always") — see OfficeNotices.condition_met().
## The difference is there is no "slot": a ticker can show every line that
## is currently true, one after another, rather than OfficeNotices picking
## one winner per subject.
##
## Pure and UI-free (CLAUDE.md §12): TickerPresenter.gd owns the actual
## scrolling and timing; this only decides which line is next. An instance
## keeps just enough state (the last line shown) to avoid repeating it back
## to back — everything else is passed in fresh each call, so eligibility
## can change (a meta variable crossing a threshold while the Office is
## open) without this going stale.


var _last_line := ""


## Every row whose condition currently holds, in workbook order.
static func eligible_lines(rows: Array, staff_hired: Dictionary, meta: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for row: Dictionary in rows:
		if OfficeNotices.condition_met(row, staff_hired, meta):
			lines.append(str(row.get("text_en", "")))
	return lines


## A random eligible line — never the one just shown, unless it is the only
## one eligible. Empty when nothing is eligible. `rng` is injected so this
## stays deterministic under test rather than reading for real randomness.
func next_line(rows: Array, staff_hired: Dictionary, meta: Dictionary,
		rng: RandomNumberGenerator) -> String:
	var lines := eligible_lines(rows, staff_hired, meta)
	if lines.is_empty():
		return ""

	var choices := lines
	if lines.size() > 1 and lines.has(_last_line):
		choices = lines.filter(func(line: String) -> bool: return line != _last_line)

	var picked: String = choices[rng.randi_range(0, choices.size() - 1)]
	_last_line = picked
	return picked
