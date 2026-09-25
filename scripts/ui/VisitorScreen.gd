extends Control
## Office Hours (ST07): a multiple-choice visitor room.
##
## The screen half of design/proposals/office_hours.md — everything else it
## describes (drawing a visitor pool, drawing each one's question, the rules
## engine, resolving a Reward/Penalty into a real effect) was already built
## and tested; this is what was missing. Deliberately much simpler than
## BattleScreen: no cards, no energy, no hand, no guard, no gaffe meter — one
## visitor at a time asks one already-drawn question, the player picks one of
## its four choices, and the next visitor is next.
##
## Layout, top to bottom:
##   header     "Office Hours 陳情" and "Visitor 2 of 3"
##   portrait   who is in the room (VisitorPresenter)
##   question   what they are asking
##   choices    the four answers
##   footer     Continue, disabled until this visitor has been answered
##
## What they say back lands on the same CueBanner every other spoken line in
## the game uses, from their own (red) side.

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

## Which level/stage to open when no level is in progress — running this
## scene on its own from the editor. LV11 is the first real level whose
## queue includes an Office Hours stage.
@export var level_id: String = "LV11"
@export var stage_id: String = "ST07"

var engine: OfficeHoursEngine = null

var _stage: Dictionary = {}
var _ready_to_play := false

var _visitor_presenter: VisitorPresenter = null
var _messages: MessagePresenter = null
var _banner: CueBanner = null

## True once the current visitor has answered — the footer button reads
## "Continue" and unlocks, and the four choices lock so a second tap cannot
## re-answer someone already spoken to.
var _answered := false

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _visitor_caption: Label = %VisitorCaption
@onready var _portrait: PlaceholderArt = %Portrait
@onready var _visitor_name: Label = %VisitorName
@onready var _visitor_title: Label = %VisitorTitle
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

	_visitor_presenter = VisitorPresenter.new(_portrait, _visitor_name, _visitor_title)
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

	_outcome_panel.hide()

	start_visiting()


## Builds the room from the level in progress, or the exported level/stage
## when run on its own — the same two routes BattleScreen.start_battle()
## offers.
func start_visiting() -> void:
	if GameState.is_in_level():
		_stage = GameState.level_runner.current_stage()
	else:
		var expanded := BattleSetup.expand_level(DataDB.get_level(level_id))
		_stage = {}
		for stage: Dictionary in expanded.get("stages", []):
			if str(stage.get("stage_id", "")) == stage_id:
				_stage = stage
				break

	if _stage.is_empty():
		_ready_to_play = false
		_messages.say(Text.say("battle.no_stage"))
		return

	_stage_name.text = str(_stage.get("name_en", "Office Hours"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_background.art_id = str(_stage.get("stage_id", ""))

	engine = OfficeHoursEngine.new()
	if not engine.setup({"visitors": _stage.get("visitors", [])}):
		_ready_to_play = false
		_choice_a.disabled = true
		_choice_b.disabled = true
		_choice_c.disabled = true
		_choice_d.disabled = true
		_messages.say(Text.say("office_hours.cannot_start",
			{"problems": "\n• ".join(Array(engine.setup_problems))}))
		return

	_ready_to_play = true
	GameState.mid_stage = GameState.is_in_level()
	Audio.play_music("music_office")
	_show_visitor()


func _show_visitor() -> void:
	_answered = false
	var visitor := engine.current_visitor()
	var question := engine.current_question()

	_visitor_presenter.show_visitor(visitor)
	_visitor_caption.text = Text.say("caption.opponent",
		{"number": engine.visitor_index() + 1, "total": engine.visitor_count()})
	_question_label.text = str(question.get("question_text", ""))

	_choice_a.text = str(question.get("choice_a", ""))
	_choice_b.text = str(question.get("choice_b", ""))
	_choice_c.text = str(question.get("choice_c", ""))
	_choice_d.text = str(question.get("choice_d", ""))
	for choice: Button in [_choice_a, _choice_b, _choice_c, _choice_d]:
		choice.disabled = false

	_continue_button.disabled = true
	_continue_button.text = Text.say("office_hours.continue")


func _on_choice(letter: String) -> void:
	if not _ready_to_play or _answered or engine == null:
		return
	_answered = true
	for choice: Button in [_choice_a, _choice_b, _choice_c, _choice_d]:
		choice.disabled = true
	_continue_button.disabled = false

	var result := engine.answer(letter)
	var correct := bool(result.get("correct", false))
	_visitor_presenter.react(correct)

	var visitor := engine.current_visitor()
	_banner.say(CueBanner.OPPONENT, str(visitor.get("name_en", "")),
		str(result.get("response_text", "")), str(result.get("reaction", "")))

	# Applied the moment it is actually worth something to the player, not
	# batched up for the end of the room — the same reason a card's own
	# effect lands the instant it is played rather than at end of turn.
	var entries: Array = result.get("reward", []) if correct else result.get("penalty", [])
	if not entries.is_empty():
		GameState.apply_visitor_reward_entries(entries)


func _on_continue() -> void:
	if not _ready_to_play or not _answered or engine == null:
		return
	engine.advance()
	if engine.is_finished():
		_show_outcome()
	else:
		_show_visitor()


func _show_outcome() -> void:
	var outcome := engine.outcome()
	_outcome_title.text = Text.say("office_hours.done")
	_outcome_body.text = Text.say("office_hours.summary",
		{"correct": outcome.get("correct", 0), "visited": outcome.get("visited", 0)})

	# Same three-way label OutcomePresenter's own button uses — reused
	# directly rather than re-worked out here, since "which stage is last"
	# is its logic to own, not this screen's to duplicate.
	_outcome_close.text = (Text.say("outcome.close") if not GameState.is_in_level()
		else (Text.say("outcome.back_to_office") if OutcomePresenter.is_last_stage_of_level()
			else Text.say("outcome.next_stage")))

	_outcome_panel.show()


func _on_outcome_closed() -> void:
	_messages.clear()
	_banner.clear()

	if not GameState.is_in_level():
		get_tree().quit()
		return

	if not _ready_to_play:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
		return

	# Office Hours cannot be lost (design/proposals/office_hours.md §4 point
	# 6) — finishing it is always a win, worth whatever the stage's own
	# win_delta_* fields say, same as any other stage.
	var level_over := GameState.finish_stage(LevelRunner.WON)

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		var next_scene := StageRouting.scene_for(GameState.level_runner.current_stage())
		if next_scene == StageRouting.VISITOR_SCENE:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_scene)
