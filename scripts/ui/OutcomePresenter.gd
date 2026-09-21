class_name OutcomePresenter
extends RefCounted
## The panel at the end of a stage: what happened, and what it was worth.
##
## Owns the outcome panel's title, headline, body and button label. Takes the
## finished state in and draws it. Makes no rules decisions and changes
## nothing: the meta-variables are worked out here only so the player can be
## told, and are applied for real by GameState when the panel is closed.
##
## WHY IT IS ITS OWN FILE
## It was the largest single block in the battle screen and shares nothing
## with the rest of it — it runs once, at the end, and reads from three
## places the rest of the screen never touches (MetaRules, LevelRunner and
## the level's own sign-off text).

var _panel: PanelContainer
var _title: Label
var _headline: Label
var _body: Label
var _button: Button


func _init(panel: PanelContainer, title: Label, headline: Label,
		body: Label, button: Button) -> void:
	_panel = panel
	_title = title
	_headline = headline
	_body = body
	_button = button


func is_showing() -> bool:
	return _panel != null and _panel.visible


## Draws the panel. Does nothing if it is already up.
func show_outcome(engine: BattleEngine, stage: Dictionary) -> void:
	if is_showing():
		return
	var state := engine.state

	_title.text = _title_for(engine, stage)

	# "Carried" on its own is a word, not an ending. The last stage of a
	# level should read like the end of something.
	#
	# IN THE LEVEL'S OWN WORDS, from levels.json. It used to say "you
	# convinced Parliament and your bill was adopted" whatever the level was,
	# so a media circuit and a research circuit both ended by announcing a
	# bill that never existed. A level with nothing written yet names itself
	# instead, which is true of any of them.
	if state.outcome == "win" and is_last_stage_of_level():
		_title.text = "Carried"
		_headline.text = sign_off("win_text")
		_headline.show()
	else:
		_headline.hide()

	_body.text = _body_for(engine, stage)
	_panel.show()

	# Say what happens next, so the button is not a leap in the dark.
	_button.text = next_step_label(state)

	EventBus.battle_ended.emit(state.outcome, state.outcome_reason)


func _title_for(engine: BattleEngine, stage: Dictionary) -> String:
	var state := engine.state

	# A scored stage was never won or lost, so "Carried" would be wrong.
	#
	# Named from the stage. Three kinds of stage are scored — the caucus, the
	# town hall and the TV debate — and this said "Caucus closed" for all
	# three, so a TV debate ended by announcing it was a caucus.
	if state.win_mode == "score" and state.outcome == "win":
		var what := str(stage.get("name_en", "")).strip_edges()
		return "%s closed" % (what if not what.is_empty() else "It")

	if engine.is_press_conference() and state.outcome == "win":
		return "Conference over"

	return {
		"win": "Carried",
		"loss": "Defeated",
		"retry": "No decision",
	}.get(state.outcome, state.outcome)


## What the stage did, and what it was worth.
##
## A stage whose score carries has to say so here or the player never finds
## out: the consequence lands in a stage they have not reached yet, and a
## number that moved silently may as well not have moved.
func _body_for(engine: BattleEngine, stage: Dictionary) -> String:
	var state := engine.state
	var lines: Array[String] = [state.outcome_reason]

	if state.outcome == "loss" or not GameState.is_in_level():
		return "\n".join(lines)

	var score := state.player_score()

	# Only where a later stage actually draws on this one. Every stage has a
	# score; most of them are worth nothing to anybody, and saying otherwise
	# would be inventing a consequence.
	if GameState.level_runner.score_is_carried_from(int(stage.get("seq", -1))):
		var seats := LevelRunner.score_to_support(stage, score)
		if seats > 0:
			lines.append("You start %d ahead at the floor debate." % seats)
		elif seats < 0:
			lines.append("You start %d behind at the floor debate." % -seats)

	# Which organisations the player's answers pleased. They are about to be
	# applied and the Office shows the result, but the connection between an
	# answer and a standing is lost by the time the player gets there.
	var pleased := engine.pleased_boosters()
	if not pleased.is_empty():
		var names := BattleSetup.booster_names()
		var pleased_names: Array[String] = []
		for booster_id: String in pleased:
			pleased_names.append(str(names.get(booster_id, booster_id)))
		lines.append("")
		lines.append("Pleased: %s." % ", ".join(pleased_names))

	var changes := _what_it_was_worth(stage, score)
	if not changes.is_empty():
		lines.append("")
		lines.append(", ".join(changes) + ".")
	elif state.outcome == "win" and LevelRunner.rewards_are_unset(stage):
		# The truth, rather than silence that reads as a bug. Every playtest
		# stage is in this state until Cameron sets its numbers.
		lines.append("")
		lines.append("This stage has no rewards set yet.")

	return "\n".join(lines)


## What this stage moved, worked out here rather than read back afterwards.
##
## GameState has not been told the stage is finished yet — that happens when
## this panel is closed — so the numbers are asked for rather than observed.
## Both halves, in the order they are applied, and totalled so a variable
## moved twice reports once.
func _what_it_was_worth(stage: Dictionary, score: int) -> Array[String]:
	var moved := {}

	for half: Dictionary in [
		MetaRules.apply_win_deltas(GameState.meta, stage, DataDB.sanban)["applied"],
		MetaRules.apply_score_effects(GameState.meta, stage, score, DataDB.sanban)["applied"],
	]:
		for name: String in half.keys():
			moved[name] = int(moved.get(name, 0)) + int(half[name])

	var changes: Array[String] = []
	for name: String in moved.keys():
		if int(moved[name]) != 0:
			changes.append("%s %+d" % [name, int(moved[name])])

	var xp := int(stage.get("xp_reward", 0))
	if xp > 0:
		changes.append("%d XP" % xp)
	return changes


## How this level signs off, in its own words or in none.
static func sign_off(key: String) -> String:
	if not GameState.is_in_level():
		return ""

	var level: Dictionary = GameState.level_runner.level
	var written := str(level.get(key, "")).strip_edges()
	if not written.is_empty():
		return written

	var name_en := str(level.get("name_en", "")).strip_edges()
	if name_en.is_empty():
		return "That is the end of it."
	return "%s is behind you." % name_en


## True where the stage just played is the last one in the level.
##
## The runner has not advanced yet when this is asked, so "current" is still
## the stage that just finished.
static func is_last_stage_of_level() -> bool:
	if not GameState.is_in_level():
		return false
	var runner := GameState.level_runner
	return runner.index + 1 >= runner.stage_count()


## What pressing the button after a stage actually does.
static func next_step_label(state: BattleState) -> String:
	if not GameState.is_in_level():
		return "Close"
	if state.outcome == "loss":
		return "Back to the Office"
	return "Back to the Office" if is_last_stage_of_level() else "On to the next stage"
