extends Control
## The Level Intro screen (2026-09-27): a short beat between the Office and
## a level's first stage, where any hired staff with a written line for this
## level speak it over the Office background before the level begins.
##
## OfficeScreen only ever routes here when LevelIntroCues.resolve() already
## came back non-empty (StageRouting.LEVEL_INTRO_SCENE) — a level with
## nothing to say goes straight to its first stage instead, so this screen
## never has to show an empty room. The `level_id` export exists only for
## running this scene on its own from the editor, the same convention
## VisitorScreen uses.
##
## Every qualifying cue speaks, one after another, on the same CueBanner
## every other spoken line in the game uses, from the player's own (blue)
## side — staff are the player's own team, not an opponent. The portrait
## swaps to match whoever is currently speaking; CueBanner has no
## "line started" signal, so this watches its own `lines_shown` counter
## each frame to notice when the next cue begins.

@export var level_id: String = "LV31"

@onready var _background: PlaceholderArt = %Background
@onready var _portrait: PlaceholderArt = %Portrait
@onready var _name_label: Label = %StaffName
@onready var _continue_button: Button = %ContinueButton

var _banner: CueBanner = null
var _cues: Array[Dictionary] = []
var _lines_accounted_for := 0


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

	var lid := str(GameState.level_runner.level.get("level_id", "")) \
		if GameState.is_in_level() else level_id
	_cues = LevelIntroCues.resolve(DataDB.level_intros, lid, GameState.staff_hired, DataDB.staff)

	if _cues.is_empty():
		_portrait.visible = false
		_name_label.visible = false
		return

	_show_speaker(0)
	for cue: Dictionary in _cues:
		_banner.say(CueBanner.PLAYER, str(cue["staff_name"]), str(cue["text"]))


func _process(_delta: float) -> void:
	if _cues.is_empty() or _banner == null:
		return
	if _banner.lines_shown > _lines_accounted_for:
		_lines_accounted_for = _banner.lines_shown
		if _lines_accounted_for < _cues.size():
			_show_speaker(_lines_accounted_for)


func _show_speaker(index: int) -> void:
	var cue: Dictionary = _cues[index]
	_portrait.art_id = str(cue["staff_id"])
	_name_label.text = str(cue["staff_name"])


func _on_continue() -> void:
	if not GameState.is_in_level():
		get_tree().quit()
		return
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
