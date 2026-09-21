extends Node
## Every line the game says to the player, looked up from the workbook.
##
## Cameron writes the wording in the Text tab of the design workbook. The
## exporter turns it into data/strings.json and this hands it out. Nothing
## else in the project should hold a sentence the player reads.
##
## WHY THIS EXISTS
## About a third of the game's prose used to be typed into GDScript, so
## rewording "You said nothing. One less energy this turn." meant editing
## code — which the person who writes this game does not do. Card names and
## effect text were already his to change; the lines a player reads most
## often were not.
##
## HOW A LINE IS WRITTEN
##
##     Text.say("outcome.carried")                     → "Carried"
##     Text.say("outcome.ahead", {"count": 3})         → "You start 3 ahead…"
##     Text.say("narration.gaffe", {"count": 1})       → picks the .one row
##
## Placeholders are named — {count}, {who}, {stage} — rather than Godot's
## %d and %s, so the sheet says what goes where and a row can reorder them
## without the code changing.
##
## PLURALS ARE TWO ROWS, not one clever one. A row given a `count` looks for
## `key.one` when the count is exactly 1 and `key.other` otherwise. Where
## only a plain `key` exists it is used for both, which is right for the many
## lines that read the same either way.
##
## NOTHING HERE CAN BREAK THE GAME. A key with no row returns the key itself
## and logs one line; a placeholder with no value is left visible. Both are
## meant to be impossible in a built game, because the exporter refuses to
## write strings.json while the code asks for a key the sheet does not have —
## so a mistake is caught at Cameron's desk, in the report he already reads.
##
## RULES CODE DOES NOT USE THIS. scripts/rules/ takes values in and hands
## results back with no autoloads, which is what lets it be tested headless.
## Where a rule needs to explain itself it returns a KEY and the screen looks
## it up.

## key -> the English line, as written in the workbook.
var _lines: Dictionary = {}

## Keys and placeholders already complained about, so a missing line is
## mentioned once rather than on every frame that draws it.
var _already_warned: Dictionary = {}


func _ready() -> void:
	_lines = DataDB.strings


## The line for a key, with its placeholders filled in.
func say(key: String, values: Dictionary = {}) -> String:
	var template := _template_for(key, values)
	if template.is_empty():
		return key
	return _fill(template, values, key)


## True when the sheet has something to say for this key. Lets a screen leave
## a line out entirely rather than printing a placeholder for it.
func has(key: String) -> bool:
	return not _template_for(key, {}).is_empty()


## Picks the row, taking the plural into account.
##
## `key.one` when there is exactly one of something and `key.other` when
## there is not, falling back to a plain `key` where the sheet only has one
## wording — which is the right answer for most lines.
func _template_for(key: String, values: Dictionary) -> String:
	if values.has("count"):
		var suffix := ".one" if int(values["count"]) == 1 else ".other"
		if _lines.has(key + suffix):
			return str(_lines[key + suffix])

	if _lines.has(key):
		return str(_lines[key])

	_warn_once(key, "Text: no line in the workbook for '%s'." % key)
	return ""


## Puts the values into the line.
##
## A placeholder with nothing to put in it is LEFT ON SCREEN rather than
## blanked, because "You start {count} ahead" is a visible bug somebody will
## report, and "You start  ahead" is one nobody notices.
func _fill(template: String, values: Dictionary, key: String) -> String:
	var filled := template
	for name: String in values.keys():
		filled = filled.replace("{%s}" % name, str(values[name]))

	if filled.contains("{"):
		_warn_once("%s:unfilled" % key,
			"Text: '%s' still has a placeholder with no value: %s" % [key, filled])
	return filled


func _warn_once(id: String, message: String) -> void:
	if _already_warned.has(id):
		return
	_already_warned[id] = true
	push_warning(message)
