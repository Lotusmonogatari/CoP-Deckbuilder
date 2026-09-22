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
##
## THIS IS A THIN WRAPPER. All the work is in Phrase, which lives in
## scripts/rules/ because the rules engine says things too and must run with
## no autoloads. One implementation of the lookup, used from both sides: the
## screens come here, and a rule is handed a Phrase through its config.
##
## See scripts/rules/Phrase.gd for the placeholder and plural rules, and for
## what happens when a key has no row.

var _phrase: Phrase = null


func _ready() -> void:
	_phrase = Phrase.new(DataDB.strings)


## The line for a key, with its placeholders filled in.
func say(key: String, values: Dictionary = {}) -> String:
	return _phrase.say(key, values) if _phrase != null else key


## True when the workbook has something to say for this key.
func has(key: String) -> bool:
	return _phrase != null and _phrase.has(key)


## The whole table, for handing to a rule that needs to explain itself.
##
## BattleEngine and the Ledger take one of these through their config rather
## than reaching for this autoload, which is what keeps scripts/rules/
## testable with none of the game running.
func phrase() -> Phrase:
	return _phrase if _phrase != null else Phrase.new()
