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
		filled = filled.replace("{%s}" % name, str(values[name]))

	if filled.contains("{"):
		_warn_once("%s:unfilled" % key,
			"Phrase: '%s' still has a placeholder with no value: %s" % [key, filled])
	return filled


func _warn_once(id: String, message: String) -> void:
	if _warned.has(id):
		return
	_warned[id] = true
	push_warning(message)
