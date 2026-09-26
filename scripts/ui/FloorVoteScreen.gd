extends Control
## National Assembly Floor Voting (ST23): a single Yes/No/Abstain choice.
##
## Deliberately simple, the same family as VisitorScreen — no cards, no
## energy, no turns. A bill's scroll text sits in the middle, six party
## leader portraits show where each party already stands (their own baked-in
## disposition — Supportive/Opposed/Neutral — decides which face they wear
## and which line they say), and three buttons decide the player's own
## party's seat. FloorVoteEngine.gd does the actual reallocation math and
## favorability deltas; this screen only shows what it returns.
##
## Layout, top to bottom:
##   header       "National Assembly Floor Voting 本会議採決"
##   party row    six leader portraits, their own cue underneath each
##   scroll       the bill's own descriptive text
##   choices      Vote Yes / Vote No / Abstain
## then an outcome panel: three PartyVoteBars (Yes/No/Abstain) and the
## result, the same overlay pattern VisitorScreen's own outcome panel uses.

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

## Which level/stage to open when no level is in progress — running this
## scene on its own from the editor.
@export var level_id: String = "LV01"
@export var stage_id: String = "ST23"

var engine: FloorVoteEngine = null

var _stage: Dictionary = {}
var _ready_to_play := false
var _voted := false

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _party_row: HBoxContainer = %PartyRow
@onready var _bill_text: Label = %BillText
@onready var _vote_yes: Button = %VoteYes
@onready var _vote_no: Button = %VoteNo
@onready var _vote_abstain: Button = %VoteAbstain
@onready var _background: PlaceholderArt = %Background
@onready var _notice: Label = %Notice

@onready var _outcome_panel: PanelContainer = %OutcomePanel
@onready var _outcome_title: Label = %OutcomeTitle
@onready var _outcome_body: Label = %OutcomeBody
@onready var _bar_yes: PartyVoteBar = %BarYes
@onready var _bar_no: PartyVoteBar = %BarNo
@onready var _bar_abstain: PartyVoteBar = %BarAbstain
@onready var _outcome_close: Button = %OutcomeClose

var _messages: MessagePresenter = null


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.show_label = false
	_messages = MessagePresenter.new(_notice, get_tree())

	_vote_yes.pressed.connect(_on_vote.bind("Yes"))
	_vote_no.pressed.connect(_on_vote.bind("No"))
	_vote_abstain.pressed.connect(_on_vote.bind("Abstain"))
	_outcome_close.pressed.connect(_on_outcome_closed)

	_outcome_panel.hide()
	start_voting()


## Builds the room from the level in progress, or the exported level/stage
## when run on its own — the same two routes VisitorScreen.start_visiting()
## offers.
func start_voting() -> void:
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

	_stage_name.text = str(_stage.get("name_en", "National Assembly Floor Voting"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_background.art_id = str(_stage.get("stage_id", ""))

	engine = FloorVoteEngine.new()
	if not engine.setup({
		"bill": _stage.get("floor_vote", {}),
		"player_party": str(DataDB.player.get("party", "")),
	}):
		_ready_to_play = false
		_vote_yes.disabled = true
		_vote_no.disabled = true
		_vote_abstain.disabled = true
		_messages.say(", ".join(Array(engine.setup_problems)))
		return

	_ready_to_play = true
	_voted = false
	GameState.mid_stage = GameState.is_in_level()
	Audio.play_music("music_office")

	_bill_text.text = str(engine.bill().get("bill_description", ""))
	_vote_yes.text = Text.say("floor_vote.vote_yes")
	_vote_no.text = Text.say("floor_vote.vote_no")
	_vote_abstain.text = Text.say("floor_vote.vote_abstain")
	_show_parties(engine.positions())


## One card per party, in the bill's own position order: a portrait faced
## for their disposition, their name in their own colour, and their own cue
## line underneath — all six shown at once, since every party's stance is
## already decided before the player ever votes.
func _show_parties(positions: Array) -> void:
	var cards := _party_row.get_children()
	for index in cards.size():
		var card: Control = cards[index]
		card.visible = index < positions.size()
		if index >= positions.size():
			continue

		var position: Dictionary = positions[index]
		var portrait: PlaceholderArt = card.get_node("Portrait")
		var swatch: ColorRect = card.get_node("Swatch")
		var name_label: Label = card.get_node("Name")
		var cue_label: Label = card.get_node("Cue")

		var leader_id := str(DataDB.get_party_by_id(str(position.get("party_id", ""))).get("leader_opp_id", ""))
		portrait.kind = PlaceholderArt.Kind.CHARACTER
		portrait.art_id = leader_id if not leader_id.is_empty() else str(position.get("party_id", ""))
		portrait.expression = _expression_for(str(position.get("disposition", "")))

		var color := _party_color(position)
		swatch.color = color
		name_label.text = str(position.get("party_name", ""))
		name_label.add_theme_color_override("font_color", color)
		cue_label.text = str(position.get("cue_text", ""))


func _expression_for(disposition: String) -> String:
	match disposition:
		"Supportive": return ArtLoader.GAINING
		"Opposed": return ArtLoader.ATTACKING
		_: return ArtLoader.NEUTRAL


func _party_color(position: Dictionary) -> Color:
	var rgb: Array = position.get("party_color", [128, 128, 128])
	return Color(int(rgb[0]) / 255.0, int(rgb[1]) / 255.0, int(rgb[2]) / 255.0)


func _on_vote(choice: String) -> void:
	if not _ready_to_play or _voted or engine == null:
		return
	_voted = true
	_vote_yes.disabled = true
	_vote_no.disabled = true
	_vote_abstain.disabled = true

	var result := engine.choose(choice)
	GameState.apply_floor_vote_favorability(result.get("favorability_deltas", {}))
	_show_outcome(result)


func _show_outcome(result: Dictionary) -> void:
	var totals: Dictionary = result.get("totals", {})
	var passed := bool(result.get("passed", false))

	_outcome_title.text = Text.say("floor_vote.title")
	_outcome_body.text = Text.say("floor_vote.passed" if passed else "floor_vote.failed", {
		"yes": totals.get("Yes", 0), "no": totals.get("No", 0), "abstain": totals.get("Abstain", 0),
	})

	_bar_yes.show_segments(_segments_for(result.get("positions", []), "votes_yes"))
	_bar_no.show_segments(_segments_for(result.get("positions", []), "votes_no"))
	_bar_abstain.show_segments(_segments_for(result.get("positions", []), "votes_abstain"))

	_outcome_close.text = (Text.say("outcome.close") if not GameState.is_in_level()
		else (Text.say("outcome.back_to_office") if OutcomePresenter.is_last_stage_of_level()
			else Text.say("outcome.next_stage")))

	_outcome_panel.show()


func _segments_for(positions: Array, vote_field: String) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	for position: Dictionary in positions:
		segments.append({
			"color": _party_color(position),
			"votes": int(position.get(vote_field, 0)),
			"label": str(position.get("party_name", "")),
		})
	return segments


func _on_outcome_closed() -> void:
	_messages.clear()

	if not GameState.is_in_level():
		get_tree().quit()
		return

	if not _ready_to_play:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
		return

	# A Floor Vote cannot be lost — it is a decision, not a contest — worth
	# whatever the stage's own win_delta_* fields say, same as Office Hours.
	var level_over := GameState.finish_stage(LevelRunner.WON)

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		var next_scene := StageRouting.scene_for(GameState.level_runner.current_stage())
		if next_scene == StageRouting.FLOOR_VOTE_SCENE:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_scene)
