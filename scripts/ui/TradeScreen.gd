extends Control
## The lobbyist's trade (influence building step C, 2026-10-19). A lobbyist for
## an organization the patron bill hurts offers to bargain. The player chooses
## whether to meet, which component to give up, answers a few questions in
## rhetorical styles (each moves a LEVERAGE meter), then spends the leverage on
## rewards or walks away. Laid out like Office Hours; everything it shows was
## drawn when the patron level was built and lives in stage["trade"].

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

## Text-tab keys, written out so the exporter can check each one exists.
const REWARD_KEYS := {
	"donation": "trade.reward_donation", "sentiment": "trade.reward_sentiment",
	"party_favor": "trade.reward_party_favor", "help": "trade.reward_help",
}
const REACT_KEYS := {
	"strong": ["trade.react_strong_1", "trade.react_strong_2", "trade.react_strong_3"],
	"medium": ["trade.react_medium_1", "trade.react_medium_2", "trade.react_medium_3"],
	"weak": ["trade.react_weak_1", "trade.react_weak_2", "trade.react_weak_3"],
}

var _stage: Dictionary = {}
var _trade: Dictionary = {}
var _lobbyist: Dictionary = {}
var _phase := "offer"            ## offer, pick, rounds, package, done
var _dropped_id := ""
var _dropped_phrase := ""
var _leverage := 0
var _round := 0
var _answered := false
var _chosen: Array = []
var _drop_ids: Array = []
var _ready_to_play := false

var _messages: MessagePresenter = null
var _banner: CueBanner = null
var _bar: ProgressBar = null
var _bar_label: Label = null
var _walk_away: Button = null

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _caption: Label = %VisitorCaption
@onready var _portrait: PlaceholderArt = %Portrait
@onready var _person_name: Label = %VisitorName
@onready var _person_title: Label = %VisitorTitle
@onready var _question_label: Label = %QuestionLabel
@onready var _choice_a: Button = %ChoiceA
@onready var _choice_b: Button = %ChoiceB
@onready var _choice_c: Button = %ChoiceC
@onready var _choice_d: Button = %ChoiceD
@onready var _continue_button: Button = %ContinueButton
@onready var _background: PlaceholderArt = %Background
@onready var _outcome_panel: PanelContainer = %OutcomePanel
@onready var _outcome_title: Label = %OutcomeTitle
@onready var _outcome_body: Label = %OutcomeBody
@onready var _outcome_close: Button = %OutcomeClose


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.show_label = false
	_messages = MessagePresenter.new(%Notice, get_tree())
	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)
	_choice_a.pressed.connect(_on_choice.bind("A"))
	_choice_b.pressed.connect(_on_choice.bind("B"))
	_choice_c.pressed.connect(_on_choice.bind("C"))
	_choice_d.pressed.connect(_on_choice.bind("D"))
	_continue_button.pressed.connect(_on_continue)
	_outcome_close.pressed.connect(_on_outcome_closed)
	var outcome_scroll := _outcome_panel.get_node_or_null("Margin/Scroll") as ScrollContainer
	if outcome_scroll != null:
		DragScroll.attach(outcome_scroll)
	_outcome_panel.hide()
	_build_leverage_meter()
	_start()


## The leverage indicator (a bar and its number) and the Walk away button are
## built in code, beside the question and the choices.
func _build_leverage_meter() -> void:
	_bar_label = Label.new()
	_bar_label.name = "LeverageLabel"
	_bar_label.visible = false
	_question_label.get_parent().add_child(_bar_label)
	_question_label.get_parent().move_child(_bar_label, _question_label.get_index())
	_bar = ProgressBar.new()
	_bar.name = "LeverageBar"
	_bar.min_value = 0
	_bar.max_value = 100
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 36)
	_bar.visible = false
	_question_label.get_parent().add_child(_bar)
	_question_label.get_parent().move_child(_bar, _question_label.get_index())
	_walk_away = Button.new()
	_walk_away.name = "WalkAwayButton"
	_walk_away.text = Text.say("trade.walk_away")
	_walk_away.visible = false
	_walk_away.pressed.connect(_on_walk_away)
	_continue_button.get_parent().add_child(_walk_away)
	_continue_button.get_parent().move_child(_walk_away, _continue_button.get_index())


func _start() -> void:
	if not GameState.is_in_level():
		_fail()
		return
	_stage = GameState.level_runner.current_stage()
	_trade = GameState.current_trade()
	if _stage.is_empty() or _trade.is_empty():
		_fail()
		return
	_lobbyist = DataDB.get_opponent(str(_trade.get("opp_id", "")))
	_stage_name.text = str(_stage.get("name_en", ""))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_background.art_id = str(_stage.get("stage_id", ""))
	_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_portrait.art_id = str(_trade.get("opp_id", ""))
	_portrait.expression = ArtLoader.NEUTRAL
	_person_name.text = str(_trade.get("lobbyist_name", ""))
	_person_title.text = _org_name()
	_ready_to_play = true
	GameState.mid_stage = true
	Audio.play_music("music_office")
	_show_offer()


func _fail() -> void:
	_ready_to_play = false
	var why := Text.say("battle.no_stage")
	_messages.say(why)
	StageStartFailure.show_on(self, why)


func _org_name() -> String:
	return str(DataDB.get_booster(str(_trade.get("org", ""))).get("name_en", str(_trade.get("org", ""))))


func _components() -> Dictionary:
	return ComposedBill.index(DataDB.bill_components)


func _phrase_of(component_id: String) -> String:
	return str((_components().get(component_id, {}) as Dictionary).get("phrase", ""))


func _buttons() -> Array[Button]:
	return [_choice_a, _choice_b, _choice_c, _choice_d]


func _show_meter(on: bool) -> void:
	_bar.visible = on
	_bar_label.visible = on
	if on:
		_bar.value = _leverage
		_bar_label.text = Text.say("trade.leverage", {"leverage": _leverage})


# ---------------------------------------------------------------------------
# Offer, pick
# ---------------------------------------------------------------------------

func _show_offer() -> void:
	_phase = "offer"
	_caption.text = ""
	_show_meter(false)
	_walk_away.visible = false
	_question_label.text = Text.say("trade.offer_text", {"name": str(_trade.get("lobbyist_name", "")), "org": _org_name()})
	_choice_a.text = Text.say("trade.hear")
	_choice_b.text = Text.say("trade.refuse")
	_choice_a.visible = true
	_choice_b.visible = true
	_choice_c.visible = false
	_choice_d.visible = false
	_choice_a.disabled = false
	_choice_b.disabled = false
	_continue_button.disabled = true
	_continue_button.text = Text.say("visit.continue")


func _show_pick() -> void:
	_phase = "pick"
	_drop_ids = (_trade.get("drops", []) as Array).duplicate()
	var asked := str(_trade.get("asked", ""))
	var hint := Text.say("trade.asked_hint", {"component": _phrase_of(asked)}) if not asked.is_empty() else ""
	_question_label.text = Text.say("trade.pick_text", {"hint": hint})
	var buttons := _buttons()
	for slot in range(buttons.size()):
		buttons[slot].disabled = false
		buttons[slot].visible = slot <= _drop_ids.size()
	for slot in range(_drop_ids.size()):
		buttons[slot].text = _phrase_of(str(_drop_ids[slot]))
	buttons[_drop_ids.size()].text = Text.say("trade.keep_all")


# ---------------------------------------------------------------------------
# Rounds
# ---------------------------------------------------------------------------

func _show_round() -> void:
	_phase = "rounds"
	_answered = false
	var questions: Array = _trade.get("questions", [])
	var question: Dictionary = questions[_round]
	_caption.text = Text.say("trade.caption", {"number": _round + 1, "total": questions.size()})
	_show_meter(true)
	_question_label.text = str(question.get("text", "")).replace("{component}", _dropped_phrase)
	var choices: Array = question.get("choices", [])
	var buttons := _buttons()
	for slot in range(buttons.size()):
		buttons[slot].visible = slot < choices.size()
		buttons[slot].disabled = false
		if slot < choices.size():
			buttons[slot].text = str((choices[slot] as Dictionary).get("text", ""))
	_continue_button.disabled = true
	_portrait.expression = ArtLoader.NEUTRAL


func _answer(letter: String) -> void:
	_answered = true
	for button: Button in _buttons():
		button.disabled = true
	_continue_button.disabled = false
	var question: Dictionary = (_trade.get("questions", []) as Array)[_round]
	var grade := MpVisit.WEAK
	for choice: Dictionary in question.get("choices", []):
		if str(choice.get("letter", "")) == letter:
			grade = str(choice.get("grade", MpVisit.WEAK))
	_leverage = LobbyistTrade.after_answer(_leverage, grade, DataDB.balance)
	_show_meter(true)
	_portrait.expression = ArtLoader.GAINING if grade == MpVisit.STRONG else (ArtLoader.NEUTRAL if grade == MpVisit.MEDIUM else ArtLoader.DAMAGED)
	var tone := "strong" if grade == MpVisit.STRONG else ("medium" if grade == MpVisit.MEDIUM else "weak")
	_banner.say(CueBanner.OPPONENT, str(_trade.get("lobbyist_name", "")),
		Text.say((REACT_KEYS[tone] as Array)[randi_range(0, 2)], {"name": str(_trade.get("lobbyist_name", ""))}))


# ---------------------------------------------------------------------------
# The package
# ---------------------------------------------------------------------------

func _show_package() -> void:
	_phase = "package"
	_chosen = []
	_caption.text = ""
	_show_meter(true)
	_walk_away.visible = true
	_refresh_package()


func _refresh_package() -> void:
	_question_label.text = Text.say("trade.package_text", {
		"leverage": _leverage, "cost": LobbyistTrade.total_cost(_chosen, DataDB.balance)})
	var buttons := _buttons()
	for slot in range(LobbyistTrade.REWARDS.size()):
		var reward: String = LobbyistTrade.REWARDS[slot]
		var label := Text.say(REWARD_KEYS[reward], {"cost": LobbyistTrade.reward_cost(reward, DataDB.balance)})
		buttons[slot].text = Text.say("trade.chosen", {"label": label}) if _chosen.has(reward) else label
		buttons[slot].visible = true
		buttons[slot].disabled = false
	_continue_button.text = Text.say("trade.make_deal")
	_continue_button.disabled = not LobbyistTrade.can_close(_chosen, _leverage, DataDB.balance)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _on_choice(letter: String) -> void:
	if not _ready_to_play:
		return
	var index := "ABCD".find(letter)
	match _phase:
		"offer":
			if letter == "A":
				_show_pick()
			else:
				_finish_without_deal(true)
		"pick":
			if index >= _drop_ids.size():
				_finish_without_deal(false)
				return
			_dropped_id = str(_drop_ids[index])
			_dropped_phrase = _phrase_of(_dropped_id)
			var org_standing := int(GameState.booster_standing.get(str(_trade.get("org", "")), 0))
			_leverage = LobbyistTrade.starting_leverage(org_standing, _dropped_id == str(_trade.get("asked", "")), DataDB.balance)
			_round = 0
			_show_round()
		"rounds":
			if not _answered:
				_answer(letter)
		"package":
			var reward: String = LobbyistTrade.REWARDS[index]
			if _chosen.has(reward):
				_chosen.erase(reward)
			else:
				_chosen.append(reward)
			_refresh_package()


func _on_continue() -> void:
	if not _ready_to_play:
		return
	if _phase == "rounds" and _answered:
		_round += 1
		if _round >= (_trade.get("questions", []) as Array).size():
			_show_package()
		else:
			_show_round()
	elif _phase == "package":
		var result := GameState.conclude_trade_deal(_dropped_id, _chosen, _leverage)
		if not bool(result.get("ok", false)):
			return
		_show_deal_done(result)


func _on_walk_away() -> void:
	if _phase == "package":
		_finish_without_deal(false)


# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

func _finish_without_deal(refused: bool) -> void:
	var result := GameState.conclude_trade_without_deal(refused)
	_phase = "done"
	_walk_away.visible = false
	var cost := Text.say("trade.cost_seats", {"count": int(result["seats"])}) if int(result["seats"]) > 0 else Text.say("trade.cost_none")
	var name := str(_trade.get("lobbyist_name", ""))
	if refused:
		_outcome_title.text = Text.say("trade.done_refused_title")
		_outcome_body.text = Text.say("trade.done_refused_body", {"name": name, "cost": cost})
	else:
		_outcome_title.text = Text.say("trade.done_nodeal_title")
		_outcome_body.text = Text.say("trade.done_nodeal_body", {"name": name, "cost": cost})
	_open_outcome()


func _show_deal_done(result: Dictionary) -> void:
	_phase = "done"
	_walk_away.visible = false
	var parts: Array[String] = []
	for gain: Dictionary in result.get("gains", []):
		match str(gain.get("type", "")):
			"donation":
				parts.append(Text.say("trade.gain_donation", {"funds": Phrase.meta_amount("Funds", int(gain["funds"]), false), "xp": int(gain["xp"])}))
			"sentiment":
				parts.append(Text.say("trade.gain_sentiment", {"org": _org_name()}))
			"party_favor":
				parts.append(Text.say("trade.gain_party_favor", {"party": str(gain["party"])}))
			"help":
				parts.append(Text.say("trade.gain_help", {"count": int(gain["count"])}))
	_outcome_title.text = Text.say("trade.done_deal_title")
	_outcome_body.text = Text.say("trade.done_deal_body", {
		"component": _dropped_phrase, "name": str(_trade.get("lobbyist_name", "")), "gains": ", ".join(parts)})
	_open_outcome()


func _open_outcome() -> void:
	_banner.clear()
	_outcome_close.text = Text.say("outcome.next_stage")
	_outcome_panel.show()


func _on_outcome_closed() -> void:
	_banner.clear()
	_messages.clear()
	var level_over := GameState.finish_stage(LevelRunner.WON)
	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		StageRouting.go_to_next_stage(get_tree(), StageRouting.TRADE_SCENE)
