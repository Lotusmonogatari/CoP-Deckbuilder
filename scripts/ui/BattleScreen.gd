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

## Which battle to open. Set these before the scene loads, or leave them and
## it opens Module 01's floor debate.
@export var module_id: String = "MOD01"
@export var step: int = 4

var engine: BattleEngine = null
var _stage: Dictionary = {}
var _opponent: Dictionary = {}
var _selected_card_id: String = ""

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _turn_label: Label = %TurnLabel
@onready var _portrait: Control = %Portrait
@onready var _opponent_name: Label = %OpponentName
@onready var _intent_label: Label = %IntentLabel
@onready var _support_bar: SupportBar = %SupportBar
@onready var _energy_row: HBoxContainer = %EnergyRow
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
	%ZoomClose.pressed.connect(func() -> void: _card_zoom.hide())
	%ZoomPlay.pressed.connect(_play_selected)
	%OutcomeClose.pressed.connect(func() -> void: get_tree().quit())

	_details_panel.hide()
	_card_zoom.hide()
	_outcome_panel.hide()

	start_battle()


## Opens the battle named by module_id and step.
func start_battle() -> void:
	var config := BattleSetup.for_module_step(module_id, step)
	if config.is_empty():
		_show_notice("There is no step %d in %s." % [step, module_id])
		return

	_stage = config.get("stage", {})
	_opponent = config.get("opponent", {})

	engine = BattleEngine.new()
	if not engine.setup(config):
		# A battle that cannot start says why, in words, rather than
		# presenting an empty screen.
		_show_notice("This battle could not start:\n• %s"
			% "\n• ".join(Array(engine.setup_problems)))
		return

	_build_static_parts()
	_refresh()


func _build_static_parts() -> void:
	# English first, with the Japanese beside it as a small muted accent.
	_stage_name.text = str(_stage.get("name_en", "Battle"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))

	_opponent_name.text = str(_opponent.get("name", "Visitor A"))
	if _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CHARACTER
		art.art_id = str(_opponent.get("opp_id", ""))
		art.expression = "neutral"

	_support_bar.unit = str(_stage.get("bar_unit", "Support"))


# ---------------------------------------------------------------------------
# Drawing the current state
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if engine == null:
		return

	var state := engine.state

	_turn_label.text = engine.turn_caption()
	_intent_label.text = IntentRunner.describe(engine.current_intent())

	if state.bar != null:
		_support_bar.show_bar(state.bar)

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

	for index in state.energy_per_turn:
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


func _refresh_details(state: BattleState) -> void:
	var lines: Array[String] = [
		"Deck %d · Hand %d · Discard %d" % [state.deck.size(), state.hand.size(), state.discard.size()],
		"Stage: %s (%s)" % [_stage.get("name_en", ""), _stage.get("stage_id", "")],
		"Opponent: %s, %s" % [_opponent.get("name", ""), _opponent.get("party", "")],
	]

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

## Tapping a card opens the zoom view. Nothing is played until the player
## confirms there, so a mis-tap never costs a turn.
func _on_card_chosen(card_id: String) -> void:
	_selected_card_id = card_id
	var card := DataDB.get_card(card_id)

	if _zoom_art is PlaceholderArt:
		var art := _zoom_art as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CARD
		art.art_id = card_id

	var affinity := engine.affinity_for(card)
	var in_this_room := ""
	if not is_equal_approx(affinity, 1.0):
		in_this_room = "\n[i]%s lands %s here (×%.2f).[/i]" % [
			card.get("suit", ""),
			"harder" if affinity > 1.0 else "softer",
			affinity,
		]

	%ZoomTitle.text = str(card.get("name_en", ""))
	%ZoomSubtitle.text = "%s  %s · %s" % [
		card.get("name_jp", ""), card.get("romaji", ""), card.get("suit", "")]
	_zoom_text.text = "[b]Costs %d[/b]\n\n%s\n\nUpgraded: %s%s" % [
		int(card.get("cost", 0)), card.get("effect_text", ""),
		card.get("upgrade_text", "—"), in_this_room]

	%ZoomPlay.disabled = int(card.get("cost", 0)) > engine.state.energy
	_card_zoom.show()


func _play_selected() -> void:
	_card_zoom.hide()
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
	var result := engine.end_turn()
	if not result.get("ok", false):
		return

	EventBus.turn_ended.emit(engine.state.turn)
	_refresh()


func _toggle_details() -> void:
	_details_panel.visible = not _details_panel.visible


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

	_outcome_title.text = {
		"win": "Carried",
		"loss": "Defeated",
		"retry": "No decision",
	}.get(state.outcome, state.outcome)

	_outcome_reason.text = state.outcome_reason
	_outcome_panel.show()
	EventBus.battle_ended.emit(state.outcome, state.outcome_reason)
