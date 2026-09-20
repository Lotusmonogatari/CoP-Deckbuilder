extends Control
## The battle screen.
##
## This draws a battle and takes the player's input. It makes no rules
## decisions of its own: every question of "can I play this" or "did that win"
## goes to BattleEngine, and this only shows the answer.
##
## Layout, top to bottom, following the UI spec:
##   header        stage name with a small Japanese accent, and the turn count
##   opponent row  portrait, name, and what they are about to do, in words
##   support bar   with the threshold marked and a caption
##   status row    energy pips and the gaffe count
##   hand          three to five cards
##   footer        End turn
##
## Anything secondary — deck and discard counts, the active modifiers — lives
## behind the details button rather than cluttering the main screen.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## Which battle to open when no level is in progress — running this scene on
## its own from the editor. During a level the stage comes from the level.
@export var module_id: String = "MOD01"
@export var step: int = 4

var engine: BattleEngine = null
var _stage: Dictionary = {}
var _opponent: Dictionary = {}
var _selected_card_id: String = ""

## False when the battle could not be set up. Everything that would touch
## the engine checks this first, so a stage that failed to start shows its
## reason instead of crashing on the next click.
var _ready_to_play := false

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _turn_label: Label = %TurnLabel
@onready var _portrait: Control = %Portrait
@onready var _opponent_name: Label = %OpponentName
@onready var _intent_label: Label = %IntentLabel
@onready var _support_bar: SupportBar = %SupportBar
@onready var _energy_row: HBoxContainer = %EnergyRow
@onready var _guard_label: Label = %GuardLabel
@onready var _gaffe_label: Label = %GaffeLabel
@onready var _hand_row: HBoxContainer = %HandRow
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _details_button: Button = %DetailsButton
@onready var _details_panel: PanelContainer = %DetailsPanel
@onready var _details_text: Label = %DetailsText
@onready var _card_zoom: PanelContainer = %CardZoom
@onready var _zoom_text: RichTextLabel = %ZoomText
@onready var _zoom_art: Control = %ZoomArt
@onready var _outcome_panel: PanelContainer = %OutcomePanel
@onready var _outcome_title: Label = %OutcomeTitle
@onready var _outcome_reason: Label = %OutcomeReason
@onready var _notice: Label = %Notice


func _ready() -> void:
	_end_turn_button.pressed.connect(_on_end_turn)
	_details_button.pressed.connect(_toggle_details)
	%DetailsClose.pressed.connect(func() -> void: _details_panel.hide())
	%ZoomClose.pressed.connect(func() -> void: _card_zoom.hide())
	%ZoomPlay.pressed.connect(_play_selected)
	%OutcomeClose.pressed.connect(_on_outcome_closed)

	_details_panel.hide()
	_card_zoom.hide()
	_outcome_panel.hide()

	# A reporter's question is a sentence rather than "Attacking · −6", so
	# the line it sits on has to be able to wrap.
	_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	start_battle()


## Opens the next battle.
##
## When a level is in progress, that means the level's current stage. When
## it isn't — opening this scene directly from the editor, say — it falls
## back to the module and step set in the inspector, so the scene stays
## runnable on its own.
func start_battle() -> void:
	var config: Dictionary = {}

	if GameState.is_in_level():
		var runner := GameState.level_runner
		# The run's standing, not the starting values: a press conference
		# earlier in the level has already moved reputation, and the stage
		# after it should be fought with the reputation you actually have.
		config = BattleSetup.for_playtest_stage(
			runner.current_stage(), runner.carried_buffs(), GameState.meta)
	else:
		config = BattleSetup.for_module_step(module_id, step)

	if config.is_empty():
		_show_notice("There is no stage to play here.")
		return

	_stage = config.get("stage", {})
	_opponent = config.get("opponent", {})

	engine = BattleEngine.new()
	if not engine.setup(config):
		# A battle that cannot start says why, in words, rather than
		# presenting an empty screen. Nothing is left playable either: a
		# half-built battle that accepts input crashes instead of failing.
		_ready_to_play = false
		_end_turn_button.disabled = true
		_show_notice("This battle could not start:\n• %s"
			% "\n• ".join(Array(engine.setup_problems)))
		return

	_ready_to_play = true
	_build_static_parts()
	_refresh()


func _build_static_parts() -> void:
	# English first, with the Japanese beside it as a small muted accent.
	_stage_name.text = str(_stage.get("name_en", "Battle"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))

	_support_bar.unit = str(_stage.get("bar_unit", "Support"))
	_show_opponent()


## Draws whoever is being argued with now. Called on every refresh rather
## than once at the start, because a committee changes opponent mid-stage.
func _show_opponent() -> void:
	var opponent := engine.current_opponent()

	# In a press conference nobody sits opposite: the questions are the
	# opposition. The reporter asking this one takes the row instead, so the
	# question has a face and a name rather than coming from nowhere.
	if opponent.is_empty() and engine.is_press_conference():
		_show_journalist(engine.current_question())
		return

	_portrait.show()
	_opponent_name.show()
	_opponent = opponent

	# Written out every refresh rather than only when the opponent changes.
	# It used to skip the first one — the screen's idea of who was opposite
	# was set from the same config the engine got, so they matched before the
	# name had ever been written and the player was left looking at the word
	# "Opponent". Redrawing a label is not worth guarding against.
	var caption := engine.opponent_caption()
	if caption.is_empty():
		_opponent_name.text = str(opponent.get("name", "Visitor A"))
	else:
		# "Opponent B  ·  2 of 3", so the player knows how far through a
		# committee they are without counting.
		_opponent_name.text = "%s  ·  %s" % [opponent.get("name", "Visitor A"), caption]

	if _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CHARACTER
		art.art_id = str(opponent.get("opp_id", ""))
		art.expression = "neutral"


## Puts the reporter who asked this question in the opponent's place.
##
## They are not an opponent — they never take a turn — but they are who is
## speaking, and a question with a name on it is easier to answer than one
## that arrives from an empty chair.
func _show_journalist(question: Dictionary) -> void:
	if question.is_empty():
		# Between the last answer and the outcome panel there is nobody left
		# to show.
		_portrait.hide()
		_opponent_name.hide()
		return

	var journalist := DataDB.get_journalist(str(question.get("asked_by", "")))
	if journalist.is_empty():
		_portrait.hide()
		_opponent_name.hide()
		return

	_portrait.show()
	_opponent_name.show()
	_opponent_name.text = str(journalist.get("name", "Visitor A"))

	if _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CHARACTER
		art.art_id = str(journalist.get("journalist_id", ""))
		art.expression = "neutral"


# ---------------------------------------------------------------------------
# Drawing the current state
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if engine == null or not _ready_to_play:
		return

	var state := engine.state

	if engine.is_press_conference():
		# The reporters' questions are the opposition here, so they take the
		# place of the turn count and the intent line.
		var question := engine.current_question()
		_turn_label.text = engine.question_caption()
		_intent_label.text = str(question.get("text", "That was the last question."))
	else:
		_turn_label.text = engine.turn_caption()
		_intent_label.text = IntentRunner.describe(engine.current_intent())
	_show_opponent()

	if state.bar != null:
		# A scored stage has no threshold, so the bar must not draw a line or
		# claim a number is needed to win. Neither has a press conference:
		# it runs until the reporters are finished, whatever the tone.
		var has_threshold := state.win_mode != "score" and not engine.is_press_conference()
		_support_bar.show_bar(state.bar, has_threshold)

	_refresh_energy(state)
	_refresh_gaffe(state)
	_refresh_hand(state)
	_refresh_details(state)

	_end_turn_button.disabled = state.is_over()

	if state.is_over():
		_show_outcome(state)


## Energy as pips rather than a number: three small marks are quicker to
## count than "3 / 3" is to read.
func _refresh_energy(state: BattleState) -> void:
	for child in _energy_row.get_children():
		child.queue_free()

	# One pip per point available, which is a turn's worth normally and the
	# whole pool in a caucus. Reading energy_per_turn here would draw three
	# pips for a five-point pool and quietly lie about what is left.
	for index in maxi(state.energy_max, 1):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(26, 26)
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(13)
		box.bg_color = (Color(0.95, 0.85, 0.45) if index < state.energy
			else Color(0.30, 0.30, 0.34))
		pip.add_theme_stylebox_override("panel", box)
		_energy_row.add_child(pip)


## The gaffe counter turns red ONLY when one more gaffe would end the stage.
## Colouring it earlier would cry wolf and make the real warning meaningless.
func _refresh_gaffe(state: BattleState) -> void:
	_gaffe_label.text = "Gaffes %d / %d" % [state.gaffe, state.gaffe_limit]
	_gaffe_label.theme_type_variation = "GaffeWarning" if engine.gaffe_is_critical() else ""

	# How much of the next attack the player has already covered. Shown only
	# when there is some: a permanent "Guarding 0" is noise, and the number
	# matters most in the moment it exists.
	_guard_label.text = "Guarding %d" % state.block
	_guard_label.visible = state.block > 0


func _refresh_hand(state: BattleState) -> void:
	for child in _hand_row.get_children():
		child.queue_free()

	for card_id: String in state.hand:
		var card := DataDB.get_card(card_id)
		if card.is_empty():
			continue
		var view := CardView.new()
		_hand_row.add_child(view)
		view.show_card(card)
		view.set_affordable(int(card.get("cost", 0)) <= state.energy and not state.is_over())
		view.chosen.connect(_on_card_chosen)


## Who is in the room, and what it takes to win one of them over.
##
## Both of these are rules a player would otherwise have to work out by
## losing: that the people already against you cost more to win than the
## people who have not decided, and that the audience is not the same crowd
## from one stage to the next.
func _room_lines(state: BattleState) -> Array[String]:
	var lines: Array[String] = []

	var mix: Dictionary = _stage.get("segment_mix", {})
	if not mix.is_empty():
		var parts: Array[String] = []
		for segment: Dictionary in DataDB.segments:
			var share := float(mix.get(segment.get("segment_id"), 0.0))
			if share > 0.0:
				parts.append("%d%% %s" % [roundi(share * 100.0), segment.get("name_en", "")])
		if not parts.is_empty():
			lines.append("In the room: %s." % ", ".join(parts))

	if state.bar != null and state.bar.model == BarModel.Model.SHARED_POOL:
		lines.append("Winning over somebody undecided takes one point. "
			+ "Somebody already against you takes one, two or three — "
			+ "you find out which as you go, and points you cannot spend "
			+ "are lost.")

	return lines


func _refresh_details(state: BattleState) -> void:
	var lines: Array[String] = [
		"Deck %d · Hand %d · Discard %d" % [state.deck.size(), state.hand.size(), state.discard.size()],
		"Stage: %s (%s)" % [_stage.get("name_en", ""), _stage.get("stage_id", "")],
	]

	var player := DataDB.player
	if not str(player.get("name_en", "")).is_empty():
		lines.append("You: %s, %s" % [player.get("name_en", ""), player.get("party", "")])

	# No line at all where there is nobody, rather than "Opponent: ,".
	if not _opponent.is_empty():
		lines.append("Opponent: %s, %s" % [_opponent.get("name", ""), _opponent.get("party", "")])

	if engine.questions_remaining() > 0 or not engine.pleased_boosters().is_empty():
		lines.append("")
		var question_now := engine.current_question()
		if not question_now.is_empty():
			lines.append("This question invites a %s answer."
				% question_now.get("prefers_suit", "any"))
		lines.append("One card answers one question, and you only draw if a "
			+ "card says so.")
		var pleased := engine.pleased_boosters()
		if pleased.is_empty():
			lines.append("Nobody pleased yet.")
		else:
			# Organisations by name, not by the ID the data files use: the
			# player has no way of knowing what BO08 is.
			var named: Array[String] = []
			for booster_id: String in pleased:
				var booster := DataDB.get_booster(booster_id)
				named.append(str(booster.get("name_en", booster_id)))
			lines.append("Pleased so far: %s." % ", ".join(named))

	lines.append("")
	lines.append_array(_room_lines(state))

	if state.opponent_count > 1:
		lines.append("")
		if _stage.get("sequence_mode") == "reset":
			lines.append("%d opponents, one at a time. Beat one and everything "
				% state.opponent_count
				+ "starts again against the next, including your gaffes.")
		else:
			lines.append(("%d debaters, one at a time, and %d %s ends the one "
				+ "in front of you — not the stage. Beat them and the house "
				+ "divides again from the start for the next.")
				% [state.opponent_count, state.bar.threshold,
					str(_stage.get("bar_unit", "support")).to_lower()])
			lines.append("Your record, your hand and the clock carry across "
				+ "all %d of them." % state.opponent_count)

	# Two rules a player would otherwise have to discover by losing.
	if state.energy_mode == "pool":
		lines.append("")
		lines.append("These %d are for the whole debate. They do not come back "
			% state.energy_max + "at the start of a turn.")

	if state.win_mode == "score":
		lines.append("There is nothing to reach here. However high the support "
			+ "gets is what carries into the floor debate.")

	if GameState.is_in_level():
		var carried := GameState.level_runner.describe_carried_buffs(BattleSetup.booster_names())
		if not carried.begins_with("Nothing"):
			lines.append("")
			lines.append(carried)

	if engine.used_default_intent_pattern:
		lines.append("")
		lines.append("This opponent has no move pattern of their own yet, so they are "
			+ "using the shared default from rules.json and playing generically.")

	var rule := str(_stage.get("signature_rule", ""))
	if not rule.is_empty():
		lines.append("")
		lines.append(rule)

	_details_text.text = "\n".join(lines)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

## How this room is treating this suit, in words rather than a multiplier.
##
## "×0.80" is precise and means nothing at the table. What a player needs to
## know is whether the room is with them, and roughly how much.
static func describe_room_for(affinity: float) -> String:
	if affinity >= 1.51:
		return "Being greatly enhanced by supporters."
	if affinity > 1.0:
		return "Being enhanced by supporters."
	if affinity < 0.5:
		return "Being greatly suppressed by opponents."
	if affinity < 1.0:
		return "Being suppressed by detractors."
	return "Landing as written here."


## Tapping a card opens the zoom view. Nothing is played until the player
## confirms there, so a mis-tap never costs a turn.
func _on_card_chosen(card_id: String) -> void:
	if not _ready_to_play:
		return
	_selected_card_id = card_id
	var card := DataDB.get_card(card_id)

	if _zoom_art is PlaceholderArt:
		var art := _zoom_art as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CARD
		art.art_id = card_id

	%ZoomTitle.text = str(card.get("name_en", ""))
	%ZoomSubtitle.text = "%s  %s · %s" % [
		card.get("name_jp", ""), card.get("romaji", ""), card.get("suit", "")]
	_zoom_text.text = "[b]Costs %d[/b]\n\n%s\n\n[i]%s[/i]" % [
		int(card.get("cost", 0)), card.get("effect_text", ""),
		describe_room_for(engine.affinity_for(card))]

	%ZoomPlay.disabled = int(card.get("cost", 0)) > engine.state.energy
	_card_zoom.show()


func _play_selected() -> void:
	_card_zoom.hide()
	if not _ready_to_play:
		return
	if _selected_card_id.is_empty():
		return

	var result := engine.play_card(_selected_card_id)
	if not result.get("ok", false):
		_show_notice(str(result.get("reason", "That card cannot be played.")))
		return

	EventBus.card_played.emit(_selected_card_id, result)
	_selected_card_id = ""
	_refresh()


func _on_end_turn() -> void:
	if not _ready_to_play:
		return
	var result := engine.end_turn()
	if not result.get("ok", false):
		return

	EventBus.turn_ended.emit(engine.state.turn)
	_refresh()


func _toggle_details() -> void:
	_details_panel.visible = not _details_panel.visible


# ---------------------------------------------------------------------------
# Getting out of an overlay
# ---------------------------------------------------------------------------
# Three ways out of every overlay, because being stuck on a screen with no
# exit is the worst thing a UI can do: its own button, the escape key, and
# tapping the dimmed area around it.
#
# The end-of-battle panel is deliberately excluded from the last two. It is
# not something to dismiss by accident — the stage is genuinely over, and the
# only way on is its own button.

## Overlays a player is allowed to back out of, front-most first.
func _dismissable_overlays() -> Array[Control]:
	return [_card_zoom, _details_panel]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _dismiss_top_overlay():
			get_viewport().set_input_as_handled()
		return

	# A click anywhere outside the panel's content closes it. Checked against
	# the content's own rectangle rather than the panel's, since the panel
	# covers the whole screen.
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var where: Vector2 = (event as InputEventMouseButton).position
		for overlay: Control in _dismissable_overlays():
			if not overlay.visible:
				continue
			var content := overlay.get_node_or_null("Margin/Scroll/Centre/Column") as Control
			if content != null and not content.get_global_rect().has_point(where):
				overlay.hide()
				get_viewport().set_input_as_handled()
			return   # only ever the front-most one


## Closes the front-most overlay. True when there was one to close.
func _dismiss_top_overlay() -> bool:
	for overlay: Control in _dismissable_overlays():
		if overlay.visible:
			overlay.hide()
			return true
	return false


# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------

func _show_notice(message: String) -> void:
	_notice.text = message
	_notice.show()
	# Long enough to read, short enough not to sit in the way.
	await get_tree().create_timer(2.5).timeout
	_notice.hide()


func _show_outcome(state: BattleState) -> void:
	if _outcome_panel.visible:
		return

	# A scored stage was never won or lost, so "Carried" would be wrong.
	if state.win_mode == "score" and state.outcome == "win":
		_outcome_title.text = "Caucus closed"
	elif engine.is_press_conference() and state.outcome == "win":
		_outcome_title.text = "Conference over"
	else:
		_outcome_title.text = {
			"win": "Carried",
			"loss": "Defeated",
			"retry": "No decision",
		}.get(state.outcome, state.outcome)

	_outcome_reason.text = _outcome_text(state)
	_outcome_panel.show()
	EventBus.battle_ended.emit(state.outcome, state.outcome_reason)

	# Say what happens next, so the button is not a leap in the dark.
	%OutcomeClose.text = _next_step_label(state)


## What the stage did, and what it was worth.
##
## A stage whose score carries has to say so here or the player never finds
## out: the consequence lands in a stage they have not reached yet, and a
## number that moved silently may as well not have moved.
func _outcome_text(state: BattleState) -> String:
	var lines: Array[String] = [state.outcome_reason]

	if state.outcome == "loss" or not GameState.is_in_level():
		return "\n".join(lines)

	var score := state.player_score()

	# Only where a later stage actually draws on this one. Every stage has a
	# score; most of them are worth nothing to anybody, and saying otherwise
	# would be inventing a consequence.
	if GameState.level_runner.score_is_carried_from(int(_stage.get("seq", -1))):
		var seats := LevelRunner.score_to_support(_stage, score)
		if seats > 0:
			lines.append("You start %d ahead at the floor debate." % seats)
		elif seats < 0:
			lines.append("You start %d behind at the floor debate." % -seats)

	# What the score did to the player's standing. Worked out here rather
	# than read back after the fact, because GameState has not been told the
	# stage is finished yet — that happens when this panel is closed.
	var moved: Dictionary = MetaRules.apply_score_effects(
		GameState.meta, _stage, score, DataDB.sanban)["applied"]
	for name: String in moved.keys():
		var delta := int(moved[name])
		if delta != 0:
			lines.append("%s %+d." % [name, delta])

	return "\n".join(lines)


## What pressing the button after a stage actually does.
func _next_step_label(state: BattleState) -> String:
	if not GameState.is_in_level():
		return "Close"
	if state.outcome == "loss":
		return "Back to the Office"

	var runner := GameState.level_runner
	# The runner has not advanced yet, so "current" is the stage just played.
	if runner.index + 1 >= runner.stage_count():
		return "Back to the Office"
	return "On to the next stage"


func _on_outcome_closed() -> void:
	if not GameState.is_in_level():
		get_tree().quit()
		return

	if not _ready_to_play:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
		return

	var state := engine.state
	# A caucus has no threshold: how high the support got is the score, and
	# that is what later stages draw on.
	var score := state.player_score()
	var level_over := GameState.finish_stage(
		state.outcome, score, engine.pleased_boosters())

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		# Same scene, next stage. Reloading keeps the setup in one place.
		get_tree().reload_current_scene()
