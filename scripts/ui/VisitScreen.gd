extends Control
## The member visit (influence building, 2026-10-19). Laid out like Office
## Hours (VisitorScreen) but with its own flow: an offer the player may skip,
## a researcher's briefing when one is senior enough, a few questions answered
## in rhetorical styles, then the rapport that sets how the one-on-one fight
## opens. The next stage is that fight (ST261).
##
## Everything it shows was drawn when the patron level was built
## (PatronLevel.build_visit) and lives in stage["visit"].

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

## Text-tab keys, written out so the exporter can check each one exists.
const STYLE_KEYS := {
	"Earnest": "visit.style.earnest", "Emotional": "visit.style.emotional", "Appeal": "visit.style.appeal",
	"Data Driven": "visit.style.data_driven", "Divisive": "visit.style.divisive", "Duplicitous": "visit.style.duplicitous",
}
const BRIEF_KEYS := ["visit.brief_1", "visit.brief_2", "visit.brief_3"]
const REACT_KEYS := {
	"strong": ["visit.react_strong_1", "visit.react_strong_2", "visit.react_strong_3"],
	"medium": ["visit.react_medium_1", "visit.react_medium_2", "visit.react_medium_3"],
	"weak": ["visit.react_weak_1", "visit.react_weak_2", "visit.react_weak_3"],
}

var _stage: Dictionary = {}
var _visit: Dictionary = {}
var _member: Dictionary = {}
var _index := 0
var _answered := false
var _phase := "offer"          ## "offer", "questions" or "done"
var _ready_to_play := false

var _messages: MessagePresenter = null
var _banner: CueBanner = null

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
	_start()


func _start() -> void:
	if not GameState.is_in_level():
		_fail()
		return
	_stage = GameState.level_runner.current_stage()
	_visit = GameState.current_visit()
	if _stage.is_empty() or _visit.is_empty():
		_fail()
		return
	_member = DataDB.get_opponent(str(_visit.get("opp_id", "")))
	_stage_name.text = str(_stage.get("name_en", ""))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_background.art_id = str(_stage.get("stage_id", ""))
	_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_portrait.art_id = str(_visit.get("opp_id", ""))
	_portrait.expression = ArtLoader.NEUTRAL
	_visitor_name.text = str(_visit.get("member_name", ""))
	_visitor_title.text = str(_visit.get("party_name", ""))
	_ready_to_play = true
	GameState.mid_stage = true
	Audio.play_music("music_office")
	_show_offer()


func _fail() -> void:
	_ready_to_play = false
	var why := Text.say("battle.no_stage")
	_messages.say(why)
	StageStartFailure.show_on(self, why)


# ---------------------------------------------------------------------------
# The offer (and the researcher's briefing)
# ---------------------------------------------------------------------------

func _show_offer() -> void:
	_phase = "offer"
	_visitor_caption.text = ""
	_question_label.text = Text.say("visit.offer_text", {
		"name": str(_visit.get("member_name", "")), "party": str(_visit.get("party_name", ""))})
	_choice_a.text = Text.say("visit.take")
	_choice_b.text = Text.say("visit.skip")
	_choice_c.visible = false
	_choice_d.visible = false
	_choice_a.disabled = false
	_choice_b.disabled = false
	_continue_button.disabled = true
	_continue_button.text = Text.say("visit.continue")
	var briefing := briefing_text()
	if not briefing.is_empty():
		_banner.say(CueBanner.PLAYER, _researcher_name(), briefing)


## The Policy Research Assistant's briefing on the member's preferred styles,
## in natural speech. Empty when no researcher is hired or the one hired is
## below the staff rank the lever asks for.
func briefing_text() -> String:
	if not MpVisit.briefing_available(GameState.staff_hired, int(DataDB.balance.get("mp_visit_briefing_staff_rank", 2))):
		return ""
	var styles := MpVisit.favored_styles(_member)
	if styles.is_empty():
		return ""
	var phrases: Array[String] = []
	for style: String in styles:
		phrases.append(Text.say(STYLE_KEYS[style]))
	var args := {"staff": _researcher_name(), "name": str(_visit.get("member_name", ""))}
	for position in range(phrases.size()):
		args[["first", "second", "third"][position]] = phrases[position]
	return Text.say(BRIEF_KEYS[phrases.size() - 1], args)


func _researcher_name() -> String:
	var hired: Dictionary = GameState.staff_hired.get("Policy Research Assistant", {})
	return str(DataDB.get_staff(str(hired.get("staff_id", ""))).get("name", ""))


# ---------------------------------------------------------------------------
# The questions
# ---------------------------------------------------------------------------

func _show_question() -> void:
	_phase = "questions"
	_answered = false
	var questions: Array = _visit.get("questions", [])
	var question: Dictionary = questions[_index]
	_visitor_caption.text = Text.say("visit.caption", {"number": _index + 1, "total": questions.size()})
	_question_label.text = str(question.get("text", ""))
	var buttons: Array[Button] = [_choice_a, _choice_b, _choice_c, _choice_d]
	var choices: Array = question.get("choices", [])
	for slot in range(buttons.size()):
		buttons[slot].visible = slot < choices.size()
		buttons[slot].disabled = false
		if slot < choices.size():
			buttons[slot].text = str((choices[slot] as Dictionary).get("text", ""))
	_continue_button.disabled = true
	_portrait.expression = ArtLoader.NEUTRAL


func _on_choice(letter: String) -> void:
	if not _ready_to_play:
		return
	if _phase == "offer":
		if letter == "A":
			_visit["taken"] = true
			_index = 0
			_show_question()
		else:
			GameState.skip_member_visit()
			_leave_to_next_stage()
		return
	if _phase != "questions" or _answered:
		return
	_answered = true
	for button: Button in [_choice_a, _choice_b, _choice_c, _choice_d]:
		button.disabled = true
	_continue_button.disabled = false
	var question: Dictionary = (_visit.get("questions", []) as Array)[_index]
	var picked: Dictionary = {}
	for choice: Dictionary in question.get("choices", []):
		if str(choice.get("letter", "")) == letter:
			picked = choice
	var grade := str(picked.get("grade", MpVisit.WEAK))
	_visit["rapport"] = int(_visit.get("rapport", 0)) + MpVisit.points(grade,
		int(DataDB.balance.get("mp_visit_strong_points", 1)),
		int(DataDB.balance.get("mp_visit_medium_points", 0)),
		int(DataDB.balance.get("mp_visit_weak_points", -1)))
	_portrait.expression = ArtLoader.GAINING if grade == MpVisit.STRONG else (ArtLoader.NEUTRAL if grade == MpVisit.MEDIUM else ArtLoader.DAMAGED)
	var tone := "strong" if grade == MpVisit.STRONG else ("medium" if grade == MpVisit.MEDIUM else "weak")
	_banner.say(CueBanner.OPPONENT, str(_visit.get("member_name", "")),
		Text.say((REACT_KEYS[tone] as Array)[randi_range(0, 2)], {"name": str(_visit.get("member_name", ""))}))


func _on_continue() -> void:
	if not _ready_to_play or _phase != "questions" or not _answered:
		return
	_index += 1
	if _index >= (_visit.get("questions", []) as Array).size():
		_show_done()
	else:
		_show_question()


func _show_done() -> void:
	_phase = "done"
	var rapport := int(_visit.get("rapport", 0))
	var bonus := MpVisit.start_bonus(rapport, int(DataDB.balance.get("mp_visit_rapport_start_per_point", 5)))
	_outcome_title.text = Text.say("visit.done_title")
	_outcome_body.text = Text.say("visit.done_body", {
		"name": str(_visit.get("member_name", "")),
		"rapport": ("%+d" % rapport), "bonus": ("%+d" % bonus)})
	_outcome_close.text = Text.say("outcome.next_stage")
	_outcome_panel.show()


func _on_outcome_closed() -> void:
	_banner.clear()
	_messages.clear()
	# The visit itself cannot be lost; the fight that follows can.
	var level_over := GameState.finish_stage(LevelRunner.WON)
	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		StageRouting.go_to_next_stage(get_tree(), StageRouting.VISIT_SCENE)


func _leave_to_next_stage() -> void:
	_banner.clear()
	_messages.clear()
	StageRouting.go_to_next_stage(get_tree(), StageRouting.VISIT_SCENE)
