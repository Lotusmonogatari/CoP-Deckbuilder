extends Control
## The battle screen.
##
## This owns the engine and routes the player's input to it. It makes no
## rules decisions of its own: every question of "can I play this" or "did
## that win" goes to BattleEngine, and this only shows the answer.
##
## WHAT IT KEEPS, AND WHAT IT HANDS OVER
## It keeps the things that are about the screen as a whole — starting a
## battle, the refresh that fans out to everything else, the status row,
## the reference panel, input, and what happens when a stage ends. Four
## presenters own the rest, each with its own file:
##
##   OpponentPresenter  the speaker row, and which face they are wearing
##   HandPresenter      the cards, kept between refreshes so they can move
##   MessagePresenter   the passing sentences, queued so none is cut short
##   OutcomePresenter   the end-of-stage panel
##
## The split is not tidiness for its own sake. Everything still to come —
## a card animating as it is played, a portrait reacting, a sound cued off
## what just happened — lands in one of those four, and would otherwise all
## have landed here.
##
## Layout, top to bottom, following the UI spec:
##   header        stage name with a small Japanese accent, and the turn count
##   opponent row  portrait, name, and what they are about to do, in words
##   support bar   with the threshold marked and a caption
##   status row    energy pips and the gaffe count
##   hand          three to five cards
##   footer        End turn

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## Which battle to open when no level is in progress — running this scene on
## its own from the editor. During a level the stage comes from the level.
@export var module_id: String = "MOD01"
@export var step: int = 4

var engine: BattleEngine = null

var _stage: Dictionary = {}
var _selected_card_id: String = ""

## False when the battle could not be set up. Everything that would touch
## the engine checks this first, so a stage that failed to start shows its
## reason instead of crashing on the next click.
var _ready_to_play := false

## The gaffe count and warning state last announced on the noticeboard, so a
## refresh that changed nothing says nothing. Reset when a stage opens.
var _announced_gaffe := 0
var _announced_critical := false

# --- The presenters --------------------------------------------------------
var _speaker: OpponentPresenter = null
var _hand: HandPresenter = null
var _messages: MessagePresenter = null
var _outcome: OutcomePresenter = null

## The opened card, built once and refilled. Created on first use rather
## than in the scene, so the frame stays a thing the script owns.
var _card_back: CardBackView = null

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _turn_label: Label = %TurnLabel
@onready var _support_bar: SupportBar = %SupportBar
@onready var _energy_row: HBoxContainer = %EnergyRow
@onready var _gaffe_label: Label = %GaffeLabel
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _details_button: Button = %DetailsButton
@onready var _details_panel: PanelContainer = %DetailsPanel
@onready var _details_text: Label = %DetailsText
@onready var _card_zoom: PanelContainer = %CardZoom


func _ready() -> void:
	_speaker = OpponentPresenter.new(
		%Portrait, %OpponentName, %IntentLabel, %GuardLabel, %OpponentGuardLabel)
	_hand = HandPresenter.new(%HandRow)
	_hand.card_chosen.connect(_on_card_chosen)
	_messages = MessagePresenter.new(%Notice, get_tree())
	_outcome = OutcomePresenter.new(
		%OutcomePanel, %OutcomeTitle, %OutcomeHeadline, %OutcomeReason, %OutcomeClose)

	_end_turn_button.pressed.connect(_on_end_turn)
	_details_button.pressed.connect(_toggle_details)
	%DetailsClose.pressed.connect(func() -> void: _details_panel.hide())
	%ZoomClose.pressed.connect(func() -> void: _card_zoom.hide())
	%ZoomPlay.pressed.connect(_play_selected)
	%OutcomeClose.pressed.connect(_on_outcome_closed)

	_details_panel.hide()
	_card_zoom.hide()
	%OutcomePanel.hide()

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
		_messages.say("There is no stage to play here.")
		return

	_stage = config.get("stage", {})

	engine = BattleEngine.new()
	if not engine.setup(config):
		# A battle that cannot start says why, in words, rather than
		# presenting an empty screen. Nothing is left playable either: a
		# half-built battle that accepts input crashes instead of failing.
		_ready_to_play = false
		_end_turn_button.disabled = true
		_messages.say("This battle could not start:\n• %s"
			% "\n• ".join(Array(engine.setup_problems)))
		return

	_ready_to_play = true

	# English first, with the Japanese beside it as a small muted accent.
	_stage_name.text = str(_stage.get("name_en", "Battle"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_support_bar.unit = str(_stage.get("bar_unit", "Support"))

	# A fresh stage announces its own opening gaffe count rather than
	# inheriting whatever the last one finished on.
	_announced_gaffe = 0
	_announced_critical = false

	Audio.play_music("music_battle")

	EventBus.turn_started.emit(engine.state.turn)
	# And what the opponent opens with. This used to be left out, so the very
	# first intent of every stage — the one the player reads before playing
	# anything — never reached the noticeboard at all.
	EventBus.intent_revealed.emit(engine.current_intent())
	_refresh()


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if engine == null or not _ready_to_play:
		return

	var state := engine.state

	# The reporters' questions are the opposition in a press conference, so
	# they take the place of the turn count as well as the intent line.
	_turn_label.text = (engine.question_caption() if engine.is_press_conference()
		else engine.turn_caption())

	_speaker.show_state(engine)

	if state.bar != null:
		# A scored stage has no threshold, so the bar must not draw a line or
		# claim a number is needed to win. Neither has a press conference:
		# it runs until the reporters are finished, whatever the tone.
		var has_threshold := state.win_mode != "score" and not engine.is_press_conference()
		# Reaching the threshold ends the STAGE only when nobody else is
		# waiting to rise. On the floor it ends one debater of five.
		var wins_stage := not engine.has_more_opponents()
		_support_bar.show_bar(state.bar, has_threshold,
			OpponentPresenter.display_name(engine),
			BattleNarration.is_percent(_stage), wins_stage)

	_refresh_energy(state)
	_refresh_gaffe(state)
	_hand.show_state(engine)
	_refresh_details(state)

	_end_turn_button.disabled = state.is_over()

	if state.is_over():
		_outcome.show_outcome(engine, _stage)


## Energy as pips rather than a number: three small marks are quicker to
## count than "3 / 3" is to read.
func _refresh_energy(state: BattleState) -> void:
	# One pip per point available, which is a turn's worth normally and the
	# whole pool in a caucus. Reading energy_per_turn here would draw three
	# pips for a five-point pool and quietly lie about what is left.
	var wanted := maxi(state.energy_max, 1)

	# Pips are kept rather than rebuilt: they are cheap, but a pip that
	# survives a refresh is a pip that can be animated when it is spent.
	while _energy_row.get_child_count() > wanted:
		_energy_row.get_child(_energy_row.get_child_count() - 1).queue_free()
		_energy_row.remove_child(_energy_row.get_child(_energy_row.get_child_count() - 1))
	while _energy_row.get_child_count() < wanted:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(26, 26)
		_energy_row.add_child(pip)

	for index in _energy_row.get_child_count():
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(13)
		box.bg_color = (Color(0.95, 0.85, 0.45) if index < state.energy
			else Color(0.30, 0.30, 0.34))
		(_energy_row.get_child(index) as Panel).add_theme_stylebox_override("panel", box)


## The gaffe counter turns red ONLY when one more gaffe would end the stage.
## Colouring it earlier would cry wolf and make the real warning meaningless.
func _refresh_gaffe(state: BattleState) -> void:
	var critical := engine.gaffe_is_critical()
	_gaffe_label.text = "Gaffes %d / %d" % [state.gaffe, state.gaffe_limit]
	_gaffe_label.theme_type_variation = "GaffeWarning" if critical else ""

	# Announced only when it MOVED. This used to fire on every refresh — every
	# card, every turn, every stage opened — so a gaffe sound would have gone
	# off several times a turn, including on turns where nothing happened. The
	# label is redrawn regardless; redrawing a label is cheap and announcing a
	# thing that did not happen is not.
	if state.gaffe == _announced_gaffe and critical == _announced_critical:
		return
	var delta := state.gaffe - _announced_gaffe
	_announced_gaffe = state.gaffe
	_announced_critical = critical
	EventBus.gaffe_changed.emit(state.gaffe, delta, state.gaffe_limit, critical)


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
	# The room's own rules come first, defaults included. Nine kinds of stage
	# now differ in how they hand out energy, how many questions they ask and
	# what winning means, and this panel used to explain only the two cases
	# that were unusual — so a policy study looked like it had finite energy.
	var lines: Array[String] = StageBrief.how_this_room_works(_stage, state)

	lines.append("")
	lines.append_array([
		"Deck %d · Hand %d · Discard %d" % [
			state.deck.size(), state.hand.size(), state.discard.size()],
		"Stage: %s (%s)" % [_stage.get("name_en", ""), _stage.get("stage_id", "")],
	])

	var player := DataDB.player
	if not str(player.get("name_en", "")).is_empty():
		lines.append("You: %s, %s" % [player.get("name_en", ""), player.get("party", "")])

	# No line at all where there is nobody, rather than "Opponent: ,".
	var opponent := engine.current_opponent()
	if not opponent.is_empty():
		lines.append("Opponent: %s, %s" % [opponent.get("name", ""), opponent.get("party", "")])

	if engine.questions_remaining() > 0 or not engine.pleased_boosters().is_empty():
		lines.append("")
		var question_now := engine.current_question()
		if not question_now.is_empty():
			lines.append("This question invites a %s answer."
				% question_now.get("prefers_suit", "any"))
		var pleased := engine.pleased_boosters()
		if pleased.is_empty():
			lines.append("Nobody pleased yet.")
		else:
			# Organisations by name, not by the ID the data files use: the
			# player has no way of knowing what BO08 is.
			var named: Array[String] = []
			for booster_id: String in pleased:
				named.append(str(DataDB.get_booster(booster_id).get("name_en", booster_id)))
			lines.append("Pleased so far: %s." % ", ".join(named))

	lines.append("")
	lines.append_array(_room_lines(state))

	# How many there are to get through. How they follow one another is a row
	# in the table above, so only the count belongs here.
	if state.opponent_count > 1:
		lines.append("")
		lines.append("%d of them, one at a time. You are on %d."
			% [state.opponent_count, state.opponent_index + 1])

	if GameState.is_in_level():
		var carried := GameState.level_runner.describe_carried_buffs(
			BattleSetup.booster_names())
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

	if _card_back == null:
		_card_back = CardBackView.new()
		# Big enough to read at arm's length: at 1250 tall the card is about
		# 890 wide, which is most of a 1080 screen. The back exists to be
		# read, so it is worth the room.
		#
		# BOTH numbers, not just the height. Leaving the width at zero meant
		# the card was laid out once at no width at all and only corrected
		# itself on the resize that followed — a frame of stretched artwork
		# every time a card was opened.
		_card_back.custom_minimum_size = Vector2(
			1250.0 * CardBackView.ASPECT, 1250.0)
		_card_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		%ZoomColumn.add_child(_card_back)
		%ZoomColumn.move_child(_card_back, 0)

	_card_back.show_card(card, CardView.describe_effect(engine.preview(card), card),
		describe_room_for(engine.affinity_for(card)))

	%ZoomPlay.disabled = engine.card_cost(card) > engine.state.energy
	_card_zoom.show()


func _play_selected() -> void:
	_card_zoom.hide()
	if not _ready_to_play or _selected_card_id.is_empty():
		return

	var card_id := _selected_card_id

	# Asked BEFORE the card is played, while it is still in hand. The engine
	# works out whether a card does anything in this room in preview() and
	# nowhere else, so playing first and asking after would be too late.
	# The hand already uses the same call to dim a card that is useless here.
	var useless := bool(engine.preview(DataDB.get_card(card_id))
		.get("does_nothing", false))

	var result := engine.play_card(card_id)
	if not result.get("ok", false):
		_messages.say(str(result.get("reason", "That card cannot be played.")))
		return

	_selected_card_id = ""
	# Announced before the redraw, so anything listening can reach the card
	# view that played it while it is still on screen.
	#
	# The engine's own result says what the card did; whether it was worth
	# anything in this room is added here, because that is a question the
	# screen asks and the rules do not answer in play_card().
	result["does_nothing"] = useless
	EventBus.card_played.emit(card_id, result)
	_refresh()
	_messages.say(BattleNarration.player_move(
		result, _stage, engine.state, OpponentPresenter.display_name(engine)))


func _on_end_turn() -> void:
	if not _ready_to_play:
		return
	var result := engine.end_turn()
	if not result.get("ok", false):
		return

	EventBus.turn_ended.emit(engine.state.turn)

	# Read the opponent's move BEFORE refreshing, because a finished bout
	# swaps in the next opponent and the sentence is about the one who just
	# acted. The name comes from the same snapshot for the same reason.
	var speaker := OpponentPresenter.display_name(engine)
	_refresh()

	var lines: Array[String] = []

	# The pass penalty has always worked; nothing ever said so, which is why
	# a playtest read it as having stopped after the first time. It never
	# compounds — every quiet turn costs the same one energy.
	if bool(result.get("passed", false)) and not engine.state.is_over():
		if engine.is_press_conference():
			lines.append("You let that one go. The room cools.")
		else:
			lines.append("You said nothing. One less energy this turn.")

	# What the opponent did. The engine has always returned this and no
	# screen has ever read it, so the whole of their turn happened in
	# silence: guard built, seats taken, a panel member leaned on.
	var said := BattleNarration.opponent_move(
		result.get("opponent", {}), _stage, engine.state, speaker)
	if not said.is_empty():
		lines.append(said)

	# A debater finished by the clock or by their own attack, rather than by
	# a card — the same news, from the other end of the turn.
	var bout: Dictionary = result.get("bout_won", {})
	if not bout.is_empty():
		lines.append(BattleNarration.player_move(
			{"bout_won": bout}, _stage, engine.state, speaker))

	# One notice, not three. The queue below would show them in turn, at two
	# and a half seconds each, and a turn's worth of news should arrive as a
	# turn's worth of news.
	if not lines.is_empty():
		_messages.say("\n".join(lines))

	if not engine.state.is_over():
		EventBus.turn_started.emit(engine.state.turn)
		EventBus.intent_revealed.emit(engine.current_intent())


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
			# The two panels name their content column differently, so ask
			# for either rather than assuming one shape.
			var content := (overlay.get_node_or_null("Margin/Scroll/Centre/Column")
				if overlay.has_node("Margin/Scroll/Centre/Column")
				else overlay.get_node_or_null("Margin/Scroll/Centre/ZoomColumn")) as Control
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
# Leaving
# ---------------------------------------------------------------------------

func _on_outcome_closed() -> void:
	_messages.clear()

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
	var level_over := GameState.finish_stage(
		state.outcome, state.player_score(), engine.pleased_boosters())

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		# Same scene, next stage. Reloading keeps the setup in one place.
		get_tree().reload_current_scene()
