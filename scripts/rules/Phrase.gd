class_name Phrase
extends RefCounted
## Looks a line up in a table of wording. Pure: no autoloads, no scene tree.
##
## The wording itself comes from the Text tab of the design workbook. This
## only knows how to find a line and fill it in.
##
## WHY THIS IS IN rules/ RATHER THAN ui/
## Because the rules engine says things too — "The gaffe meter filled.",
## "17 XP short." — and scripts/rules/ must run with no autoloads, which is
## what lets it be tested headless. So a rule that needs to explain itself is
## handed one of these through its config, the same way it is handed the
## stage, the cards and the affinity table. Nothing here reaches out for
## anything.
##
## Text.gd, the autoload the screens use, is a thin wrapper around one of
## these, so there is one implementation of the lookup rather than two.
##
## USAGE
##     var phrase := Phrase.new(DataDB.strings)
##     phrase.say("outcome.carried")                  → "Carried"
##     phrase.say("shop.xp_short", {"count": 17})     → "17 XP short."
##
## Placeholders are named — {count}, {who}, {stage} — so the sheet says what
## goes where and a row can reorder them without the code changing.
##
## PLURALS ARE TWO ROWS. A row given a `count` looks for `key.one` when the
## count is exactly 1 and `key.other` otherwise, falling back to a plain
## `key` where one wording serves both — which is right for most lines.
##
## AN EMPTY TABLE IS SAFE. Every lookup then returns the key, so a test that
## builds a config by hand without any wording still runs; it just reads in
## keys. The exporter refuses to write strings.json while the code asks for a
## key the sheet has not got, so a built game never gets there.

var _lines: Dictionary = {}

## Keys already complained about, so a missing line is mentioned once.
var _warned: Dictionary = {}


func _init(lines: Dictionary = {}) -> void:
	_lines = lines


## The line for a key, with its placeholders filled in.
func say(key: String, values: Dictionary = {}) -> String:
	var template := _template_for(key, values)
	if template.is_empty():
		return key
	return _fill(template, values, key)


## True when the table has something to say for this key. Lets a caller leave
## a line out entirely rather than printing a placeholder for it.
func has(key: String) -> bool:
	return not _template_for(key, {}).is_empty()


## True when there is no wording at all — a config built without a table.
func is_empty() -> bool:
	return _lines.is_empty()


func _template_for(key: String, values: Dictionary) -> String:
	if values.has("count"):
		var suffix := ".one" if int(values["count"]) == 1 else ".other"
		if _lines.has(key + suffix):
			return str(_lines[key + suffix])

	if _lines.has(key):
		return str(_lines[key])

	# Only worth saying when there IS a table. An empty one is a test
	# fixture, not a mistake.
	if not _lines.is_empty():
		_warn_once(key, "Phrase: no line in the workbook for '%s'." % key)
	return ""


## A placeholder with nothing to put in it is LEFT ON SCREEN rather than
## blanked, because "You start {count} ahead" is a visible bug somebody will
## report, and "You start  ahead" is one nobody notices.
func _fill(template: String, values: Dictionary, key: String) -> String:
	var filled := template
	for name: String in values.keys():
		filled = filled.replace("{%s}" % name, _shown(name, values[name]))

	if filled.contains("{"):
		_warn_once("%s:unfilled" % key,
			"Phrase: '%s' still has a placeholder with no value: %s" % [key, filled])
	return filled


## Money-sized numbers read with thousands separators ("1,000,000 Yen"). Only
## the placeholders that carry an amount are touched, and only whole numbers
## of four digits or more, so a seat count or a year is never altered.
## A placeholder named yen_something is an amount too (2026-10-23).
const AMOUNT_NAMES := ["count", "cost", "price"]


static func with_separators(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return ("-" if amount < 0 else "") + out


## A meta-variable's amount as the player reads it. Funds is money, so it is
## written with the 円 mark on the number ("+1,500円", "100,000円"); every other
## variable is a plain number with its separators. `signed` puts a + or - in
## front (the minus is always shown). Funds is a lookup key as well as a
## display word (CLAUDE.md section 6), hence the exact-name test.
static func meta_amount(variable: String, amount: int, signed: bool = false) -> String:
	var number := with_separators(absi(amount))
	var sign := ""
	if amount < 0:
		sign = "-"
	elif signed and amount > 0:
		sign = "+"
	return sign + number + ("円" if variable == "Funds" else "")


static func _shown(name: String, value: Variant) -> String:
	if (name in AMOUNT_NAMES or name.begins_with("yen_")) and (value is int or (value is float and value == floorf(value))):
		if absi(int(value)) >= 1000:
			return with_separators(int(value))
	return str(value)


func _warn_once(id: String, message: String) -> void:
	if _warned.has(id):
		return
	_warned[id] = true
	push_warning(message)
