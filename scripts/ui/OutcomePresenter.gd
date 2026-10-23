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
## Where the organisation icons go (optional; without it the names are
## written into the body instead).
var _boosters_box: VBoxContainer


func _init(panel: PanelContainer, title: Label, headline: Label,
		body: Label, button: Button, boosters_box: VBoxContainer = null) -> void:
	_panel = panel
	_title = title
	_headline = headline
	_body = body
	_button = button
	_boosters_box = boosters_box


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
	#
	# WIN OR LOSE. This only ever asked for win_text, so the four loss lines
	# Cameron wrote in levels.json had never once reached the screen — a level
	# ended badly in silence, and rewriting the line changed nothing.
	if is_last_stage_of_level() and state.outcome in ["win", "loss"]:
		if state.outcome == "win":
			_title.text = Text.say("outcome.carried")
		_headline.text = sign_off(
			"win_text" if state.outcome == "win" else "loss_text")
		_headline.show()
	else:
		_headline.hide()

	_body.text = _body_for(engine, stage)
	_build_booster_icons(engine, stage)
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
		if what.is_empty():
			return Text.say("outcome.closed_unnamed")
		return Text.say("outcome.closed", {"stage": what})

	if engine.is_press_conference() and state.outcome == "win":
		return Text.say("outcome.conference_over")

	return {
		"win": Text.say("outcome.carried"),
		"loss": Text.say("outcome.defeated"),
		"retry": Text.say("outcome.no_decision"),
	}.get(state.outcome, state.outcome)


## What the stage did, and what it was worth.
##
## A stage whose score carries has to say so here or the player never finds
## out: the consequence lands in a stage they have not reached yet, and a
## number that moved silently may as well not have moved.
func _body_for(engine: BattleEngine, stage: Dictionary) -> String:
	var body := _body_without_awareness(engine, stage)
	# Gaffes still on the counter cost awareness (GameState.apply_awareness_gaffes).
	if GameState.is_in_level() and str(stage.get("mode", "")) == "Combat" and engine.state.gaffe > 0:
		body += "\n\n" + Text.say("awareness.gaffe_line", {"count": engine.state.gaffe})
	return body


func _body_without_awareness(engine: BattleEngine, stage: Dictionary) -> String:
	var state := engine.state
	var lines: Array[String] = [state.outcome_reason]

	if not GameState.is_in_level():
		return "\n".join(lines)

	var score := state.player_score()

	# Which organisations the player's answers pleased or annoyed — WIN OR
	# LOSS. This used to sit only on the win path below, so a lost stage's
	# own displeased organisations (a weak answer that annoyed one, say)
	# never reached the screen even though the standing hit itself was
	# applied same as ever — the one place that told the player why went
	# silent exactly when the news was bad (2026-09-28, caught the same way
	# the loss deltas themselves were: a stage's own consequence has to
	# reach this panel or it may as well not have happened). The connection
	# between an answer and a standing is lost by the time the player
	# reaches the Office either way.
	if _boosters_box == null:
		var names := BattleSetup.booster_names()
		for entry: Array in [
			["outcome.pleased", engine.pleased_boosters()],
			["outcome.displeased", engine.displeased_boosters()],
			["outcome.opposed", engine.opposed_boosters()],
			["outcome.crushed", engine.crushed_opponent_boosters()],
		]:
			var who: Array[String] = []
			for booster_id: String in entry[1]:
				who.append(str(names.get(booster_id, booster_id)))
			if not who.is_empty():
				lines.append("")
				lines.append(Text.say(str(entry[0]), {"names": CauseLines.join(who)}))

	# A loss says what it cost, from the stage's own loss_delta_* columns —
	# the same numbers GameState charges when this panel closes (2026-09-27:
	# before this a loss said nothing, and charged nothing either).
	if state.outcome == "loss":
		var cost := _what_it_was_worth(stage, score, "loss")
		if not cost.is_empty():
			lines.append("")
			lines.append(CauseLines.join(cost) + ".")
		return "\n".join(lines)

	# Only where a later stage actually draws on this one. Every stage has a
	# score; most of them are worth nothing to anybody, and saying otherwise
	# would be inventing a consequence.
	if GameState.level_runner.score_is_carried_from(int(stage.get("seq", -1))):
		var seats := LevelRunner.score_to_support(stage, score)
		if seats > 0:
			lines.append(Text.say("outcome.ahead", {"count": seats}))
		elif seats < 0:
			lines.append(Text.say("outcome.behind", {"count": -seats}))

	var changes := _what_it_was_worth(stage, score)
	if not changes.is_empty():
		lines.append("")
		lines.append(CauseLines.join(changes) + ".")
	elif state.outcome == "win" and LevelRunner.rewards_are_unset(stage):
		# The truth, rather than silence that reads as a bug. Every playtest
		# stage is in this state until Cameron sets its numbers.
		lines.append("")
		lines.append(Text.say("outcome.no_rewards"))

	return "\n".join(lines)


## What this stage moved, worked out here rather than read back afterwards.
##
## GameState has not been told the stage is finished yet — that happens when
## this panel is closed — so the numbers are asked for rather than observed.
## Both halves, in the order they are applied, and totalled so a variable
## moved twice reports once.
func _what_it_was_worth(stage: Dictionary, score: int, side: String = "win") -> Array[String]:
	var moved := {}
	# Funds' own bonus-adjusted max (GameState.sanban_rows_with_bonuses(), not
	# DataDB.sanban raw) — this panel recomputes the same deltas GameState is
	# about to apply for real, purely to show them; reading DataDB.sanban
	# straight would clamp Funds against the flat workbook max and show a
	# smaller "+N Funds" than what actually lands once the player has paid
	# to raise the cap (SH19) — bug found 2026-09-30, Cameron.
	var sanban_rows := GameState.sanban_rows_with_bonuses()
	var flat := (MetaRules.apply_win_deltas(GameState.meta, stage, sanban_rows) if side == "win"
		else MetaRules.apply_loss_deltas(GameState.meta, stage, sanban_rows))

	for half: Dictionary in [
		flat["applied"],
		MetaRules.apply_score_effects(GameState.meta, stage, score, sanban_rows)["applied"],
	]:
		for name: String in half.keys():
			moved[name] = int(moved.get(name, 0)) + int(half[name])

	var changes: Array[String] = []
	for name: String in moved.keys():
		if int(moved[name]) != 0:
			changes.append(Text.say("reward.delta",
				{"name": name, "amount": Phrase.meta_amount(name, int(moved[name]), true)}))

	var xp := MetaRules.stage_delta(stage, side + "_delta_xp")
	if xp > 0:
		changes.append(Text.say("outcome.xp", {"count": xp}))
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
		return Text.say("outcome.sign_off_unwritten")
	return Text.say("outcome.sign_off_named", {"level": name_en})


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
		return Text.say("outcome.close")
	# A loss usually ends the level, but not every stage's threshold is a
	# stop sign — a press conference or a media ambush running out of turns
	# only decides which reward table applied (LevelRunner.loss_ends_level());
	# the level goes on to the next stage exactly like a win would.
	if state.outcome == "loss" and LevelRunner.loss_ends_level(GameState.level_runner.current_stage()):
		return Text.say("outcome.back_to_office")
	return (Text.say("outcome.back_to_office") if is_last_stage_of_level()
		else Text.say("outcome.next_stage"))


## Net standing change per organisation this stage, in the order they were
## touched: [{booster_id, name, net}]. Same numbers GameState applies on close.
static func booster_changes(engine: BattleEngine) -> Array[Dictionary]:
	var names := BattleSetup.booster_names()
	var out: Array[Dictionary] = []
	for entry: Dictionary in BoosterChange.compute(
			engine.pleased_boosters(), engine.displeased_boosters(),
			engine.crushed_opponent_boosters(), DataDB.booster_standing,
			engine.opposed_boosters(), GameState.stance_adjust_tally(engine.booster_tally()),
			GameState.booster_standing):
		var booster_id := str(entry["booster_id"])
		out.append({"booster_id": booster_id,
			"name": str(names.get(booster_id, booster_id)), "net": int(entry["net"])})
	return out


## The bill-stance drift a won Combat stage adds (organization -> delta) folded
## into the per-organization changes, so the icons show what really lands.
static func with_drift(changes: Array[Dictionary], drift: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var names := BattleSetup.booster_names()
	var seen := {}
	for change: Dictionary in changes:
		var merged := change.duplicate()
		var id := str(change["booster_id"])
		seen[id] = true
		merged["net"] = int(change["net"]) + int(drift.get(id, 0))
		out.append(merged)
	for id: Variant in drift.keys():
		if not seen.has(str(id)) and int(drift[id]) != 0:
			out.append({"booster_id": str(id), "name": str(names.get(str(id), str(id))), "net": int(drift[id])})
	return out


## One icon per organisation the stage touched. Tapping an icon shows its name
## and the net change; tapping it again hides that. An organisation can be both
## pleased and annoyed, which is why the number is the aggregate.
func _build_booster_icons(engine: BattleEngine, stage: Dictionary = {}) -> void:
	if _boosters_box == null:
		return
	for child in _boosters_box.get_children():
		child.queue_free()
	_boosters_box.hide()
	if not GameState.is_in_level():
		return
	var changes := booster_changes(engine)
	if str(stage.get("mode", "")) == "Combat":
		changes = with_drift(changes, GameState.stance_drift_preview())
	if changes.is_empty():
		return
	# Biggest gain first, biggest loss last (stable, so a tie keeps the order
	# the organizations were touched in).
	changes = _sorted_by_net(changes)
	var hint := Label.new()
	hint.text = Text.say("outcome.booster_hint")
	hint.theme_type_variation = &"SmallLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boosters_box.add_child(hint)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	_boosters_box.add_child(row)
	for change: Dictionary in changes:
		var chip := OrgChip.make(str(change["booster_id"]), int(change["net"]))
		chip.name = "BoosterIcon_%s" % change["booster_id"]
		row.add_child(chip)
	_boosters_box.show()


## Highest net change first, lowest last; ties keep their incoming order.
static func _sorted_by_net(changes: Array[Dictionary]) -> Array[Dictionary]:
	var indexed: Array = []
	for i in changes.size():
		indexed.append([i, changes[i]])
	indexed.sort_custom(func(a: Array, b: Array) -> bool:
		var net_a := int((a[1] as Dictionary)["net"])
		var net_b := int((b[1] as Dictionary)["net"])
		return net_a > net_b or (net_a == net_b and int(a[0]) < int(b[0])))
	var out: Array[Dictionary] = []
	for pair: Array in indexed:
		out.append(pair[1])
	return out
