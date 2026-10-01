extends Control
## The Stage Transition screen (2026-10-01, §7.9): a short beat between two
## stages of the same level — a character drawn from data/transition_cast.
## json speaks, the player replies, in front of a data/transition_
## backgrounds.json pick. Opt-in per stage (stages.json's own
## `show_transition`) and silent when nothing is eligible; see
## StageTransition.gd for the pure pick logic this screen is built on.
##
## StageRouting.go_to_next_stage() only checks the cheap `show_transition`
## flag before routing here — the real pool picks (which speakers, which
## background, which lines) happen once, in this screen's own _ready(), so
## there is exactly one random draw per transition, never two that could
## disagree with each other.
##
## All art is existing art, `neutral` expression, by ID — no new art-loading
## path. Every speaker swap reuses the same portrait slot (ArtBox's own
## SpeakerPortrait), sliding in fresh each time, the same "every qualifying
## speaker, one after another" shape LevelIntroScreen.gd already uses for
## multiple staff cues, extended with a slide.

const SLIDE_OFFSET := 500.0
const SLIDE_SECONDS := 0.35

@export var stage_id: String = "ST02"

@onready var _background: PlaceholderArt = %Background
@onready var _player_portrait: PlaceholderArt = %PlayerPortrait
@onready var _speaker_portrait: PlaceholderArt = %SpeakerPortrait
@onready var _speaker_name: Label = %SpeakerName
@onready var _continue_button: Button = %ContinueButton

var _banner: CueBanner = null
var _stage: Dictionary = {}
var _speakers: Array[Dictionary] = []
var _lines_accounted_for := 0
var _current_speaker_index := -1
var _speaker_rest_x := 0.0


func _ready() -> void:
	_stage = GameState.level_runner.current_stage() if GameState.is_in_level() else DataDB.get_stage(stage_id)

	_continue_button.text = Text.say("stage_transition.continue")
	_continue_button.pressed.connect(_on_continue)

	_player_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_player_portrait.art_id = str(DataDB.player.get("player_id", ""))
	_player_portrait.expression = "neutral"

	_speaker_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_speaker_portrait.expression = "neutral"
	_speaker_portrait.visible = false
	_speaker_name.visible = false

	var rng := RandomNumberGenerator.new()
	var result := StageTransition.resolve(
		_stage, DataDB.transition_cast, DataDB.transition_backgrounds, DataDB.transition_dialogue, rng)

	if result.is_empty():
		_on_continue()
		return

	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = str(result.get("background_id", "")) if not str(result.get("background_id", "")).is_empty() \
		else str(_stage.get("stage_id", ""))
	_background.show_label = false

	_speakers = result["speakers"]
	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)

	# One layout pass first, so SpeakerPortrait's own anchor-computed rest
	# position is known before anything tries to slide relative to it.
	await get_tree().process_frame
	_speaker_rest_x = _speaker_portrait.position.x

	_show_speaker(0)
	for speaker: Dictionary in _speakers:
		var name := _display_name(str(speaker["character_id"]))
		var side := _banner_side(str(speaker["character_id"]))
		_banner.say(side, name, str(speaker["character_line"]))
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), str(speaker["player_reply"]))


func _process(_delta: float) -> void:
	if _banner == null or _speakers.is_empty():
		return
	if _banner.lines_shown <= _lines_accounted_for:
		return
	_lines_accounted_for = _banner.lines_shown
	var total_lines := _speakers.size() * 2
	if _lines_accounted_for >= total_lines:
		return
	var next_index: int = _lines_accounted_for / 2
	if next_index != _current_speaker_index:
		_show_speaker(next_index)


func _show_speaker(index: int) -> void:
	_current_speaker_index = index
	var speaker: Dictionary = _speakers[index]
	var character_id := str(speaker["character_id"])

	_speaker_portrait.art_id = character_id
	_speaker_portrait.visible = true
	_speaker_name.text = _display_name(character_id)
	_speaker_name.visible = true

	_speaker_portrait.position.x = _speaker_rest_x + SLIDE_OFFSET
	var slide := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_property(_speaker_portrait, "position:x", _speaker_rest_x, SLIDE_SECONDS)


## An opponent speaks from the red/right side (the room's own voice);
## hired staff speak from the blue/left side alongside the player, since
## staff are the player's own team — the same convention LevelIntroScreen
## already uses for every staff cue.
func _banner_side(character_id: String) -> int:
	return CueBanner.OPPONENT if StageTransition.character_kind(character_id) == "opponent" else CueBanner.PLAYER


func _display_name(character_id: String) -> String:
	match StageTransition.character_kind(character_id):
		"opponent": return str(DataDB.get_opponent(character_id).get("name", character_id))
		"staff": return str(DataDB.get_staff(character_id).get("name", character_id))
	return character_id


func _on_continue() -> void:
	if not GameState.is_in_level():
		get_tree().quit()
		return
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
