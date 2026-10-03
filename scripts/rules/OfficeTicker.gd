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
##
## "{player}" token (2026-10-03): a row's own text_en can include the
## literal token "{player}", filled in with the current protagonist's own
## name before the line is shown. Unlike OfficeNotices' own "{staff}"
## token (which only ever appears on a staff_role-conditioned row, so the
## staff lookup it needs always has an answer), "{player}" is safe on ANY
## row — always, meta, or staff_role alike — since the player's name is
## fixed for the whole run the moment one exists. Stays pure the same way
## every other input here does: the caller (TickerPresenter.gd) passes the
## name in; this file never reads DataDB itself.


var _last_line := ""


## Fills "{player}" in `text` with `player_name` — the one token the
## ticker supports today. A blank `player_name` (no run started, or a
## caller that doesn't care) leaves the token untouched rather than
## blanking it out, so a half-wired caller never ships a broken-looking
## line.
static func fill_tokens(text: String, player_name: String) -> String:
	if player_name.is_empty() or not text.contains("{player}"):
		return text
	return text.replace("{player}", player_name)


## Every row whose condition currently holds, in workbook order, with any
## token already filled in.
static func eligible_lines(rows: Array, staff_hired: Dictionary, meta: Dictionary,
		player_name: String = "") -> Array[String]:
	var lines: Array[String] = []
	for row: Dictionary in rows:
		if OfficeNotices.condition_met(row, staff_hired, meta):
			lines.append(fill_tokens(str(row.get("text_en", "")), player_name))
	return lines


## A random eligible line — never the one just shown, unless it is the only
## one eligible. Empty when nothing is eligible. `rng` is injected so this
## stays deterministic under test rather than reading for real randomness.
func next_line(rows: Array, staff_hired: Dictionary, meta: Dictionary,
		rng: RandomNumberGenerator, player_name: String = "") -> String:
	var lines := eligible_lines(rows, staff_hired, meta, player_name)
	if lines.is_empty():
		return ""

	var choices := lines
	if lines.size() > 1 and lines.has(_last_line):
		choices = lines.filter(func(line: String) -> bool: return line != _last_line)

	var picked: String = choices[rng.randi_range(0, choices.size() - 1)]
	_last_line = picked
	return picked
