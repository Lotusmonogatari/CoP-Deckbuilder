extends Control
## The Level Intro screen (2026-09-27): a short beat between the Office and
## a level's first stage, where any hired staff with a written line for this
## level speak it over the Office background before the level begins.
##
## OfficeScreen routes here when LevelIntroCues.resolve() comes back
## non-empty OR the level names a Floor Vote bill (StageRouting.
## LEVEL_INTRO_SCENE) — a level with neither goes straight to its first
## stage instead, so this screen never has to show an empty room. The
## `level_id` export exists only for running this scene on its own from the
## editor, the same convention VisitorScreen uses.
##
## Every qualifying staff cue speaks, one after another, on the same
## CueBanner every other spoken line in the game uses, from the player's own
## (blue) side — staff are the player's own team, not an opponent. The
## portrait swaps to match whoever is currently speaking; CueBanner has no
## "line started" signal, so this watches its own `lines_shown` counter
## each frame to notice when the next cue begins.
##
## Bill lean (2026-10-01): once every staff cue has shown, a level that
## names a Floor Vote bill (DataDB.get_floor_vote()) shows the player's own
## internal thought about the level (if one is written) as one more banner
## line, then two buttons — "Lean Support"/"Lean Oppose" — each showing the
## player's own party leader's portrait. The Continue button stays disabled
## until a lean is picked, so the choice always happens; picking one applies
## a Party support delta (BillLean.gd) via the same GameState path a real
## Floor Vote's own favorability uses, then the screen proceeds normally.

@export var level_id: String = "LV31"

@onready var _background: PlaceholderArt = %Background
@onready var _portrait: PlaceholderArt = %Portrait
@onready var _name_label: Label = %StaffName
@onready var _continue_button: Button = %ContinueButton
@onready var _lean_row: Control = %LeanRow
@onready var _support_portrait: PlaceholderArt = %SupportPortrait
@onready var _support_button: Button = %SupportButton
@onready var _oppose_portrait: PlaceholderArt = %OpposePortrait
@onready var _oppose_button: Button = %OpposeButton

var _banner: CueBanner = null
var _cues: Array[Dictionary] = []
var _lines_accounted_for := 0
var _total_lines := 0

var _bill: Dictionary = {}
var _thought_text := ""
var _lean_shown := false
var _lean_resolved := false


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = "OFFICE"
	_background.show_label = false

	_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_portrait.expression = "neutral"

	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)

	_continue_button.text = "Let's go"
	_continue_button.pressed.connect(_on_continue)

	_lean_row.visible = false
	_support_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_oppose_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_support_button.text = Text.say("level_intro.lean_support")
	_oppose_button.text = Text.say("level_intro.lean_oppose")
	_support_button.pressed.connect(_on_lean_chosen.bind(BillLean.SUPPORT))
	_oppose_button.pressed.connect(_on_lean_chosen.bind(BillLean.OPPOSE))

	var lid := str(GameState.level_runner.level.get("level_id", "")) \
		if GameState.is_in_level() else level_id
	_cues = LevelIntroCues.resolve(DataDB.level_intros, lid, GameState.staff_hired, DataDB.staff)
	_bill = DataDB.get_floor_vote(lid)
	_thought_text = LevelIntroCues.player_thought(DataDB.level_intro_thoughts, lid) \
		if not _bill.is_empty() else ""
	_total_lines = _cues.size() + (1 if not _thought_text.is_empty() else 0)

	if _cues.is_empty() and _bill.is_empty():
		_portrait.visible = false
		_name_label.visible = false
		return

	if not _bill.is_empty():
		_continue_button.disabled = true

	if not _cues.is_empty():
		_show_speaker(0)
	elif not _thought_text.is_empty():
		_show_player_speaker()
	else:
		_portrait.visible = false
		_name_label.visible = false

	for cue: Dictionary in _cues:
		_banner.say(CueBanner.PLAYER, str(cue["staff_name"]), str(cue["text"]))
	if not _thought_text.is_empty():
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), _thought_text)

	if _total_lines == 0 and not _bill.is_empty():
		_show_lean_choice()


func _process(_delta: float) -> void:
	if _banner == null:
		return
	if _total_lines > 0 and _banner.lines_shown > _lines_accounted_for:
		_lines_accounted_for = _banner.lines_shown
		if _lines_accounted_for < _cues.size():
			_show_speaker(_lines_accounted_for)
		elif _lines_accounted_for == _cues.size() and not _thought_text.is_empty():
			_show_player_speaker()
	if not _bill.is_empty() and not _lean_shown and _lines_accounted_for >= _total_lines:
		_show_lean_choice()


func _show_speaker(index: int) -> void:
	var cue: Dictionary = _cues[index]
	_portrait.art_id = str(cue["staff_id"])
	_name_label.text = str(cue["staff_name"])


func _show_player_speaker() -> void:
	_portrait.visible = true
	_name_label.visible = true
	_portrait.art_id = str(DataDB.player.get("player_id", ""))
	_name_label.text = str(DataDB.player.get("name_en", ""))


func _show_lean_choice() -> void:
	_lean_shown = true
	var own_party := DataDB.get_party(str(DataDB.player.get("party", "")))
	var leader_id := str(own_party.get("leader_opp_id", ""))
	_support_portrait.art_id = leader_id
	_support_portrait.expression = "neutral"
	_oppose_portrait.art_id = leader_id
	_oppose_portrait.expression = "neutral"
	_lean_row.visible = true


func _on_lean_chosen(lean: String) -> void:
	if _lean_resolved:
		return
	_lean_resolved = true

	var own_party_name := str(DataDB.player.get("party", ""))
	var own_party := DataDB.get_party(own_party_name)
	var own_party_id := str(own_party.get("party_id", ""))
	var own_position: Dictionary = {}
	for position: Dictionary in _bill.get("positions", []):
		if str(position.get("party_id", "")) == own_party_id:
			own_position = position
			break

	var magnitude := int(DataDB.balance.get("lean_party_support_delta", 0))
	var delta := BillLean.party_support_delta(own_position, lean, magnitude)
	if delta != 0:
		GameState.apply_floor_vote_favorability({own_party_name: delta})

	_lean_row.visible = false
	_continue_button.disabled = false


func _on_continue() -> void:
	if not GameState.is_in_level():
		get_tree().quit()
		return
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
