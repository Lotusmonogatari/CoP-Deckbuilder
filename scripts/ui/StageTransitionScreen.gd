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
const SLIDE_OUT_SECONDS := 0.2

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
	_hold_continue()

	_player_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_player_portrait.art_id = str(DataDB.player.get("player_id", ""))
	_player_portrait.expression = "neutral"

	_speaker_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_speaker_portrait.expression = "neutral"
	_speaker_portrait.visible = false
	_speaker_name.visible = false

	var rng := RandomNumberGenerator.new()
	var hired_ids: Array = []
	# Primaries and extras alike may speak (Cameron, 2026-11-08).
	for staff_id: String in GameState.all_hired_staff_ids():
		hired_ids.append(staff_id)
	# A level about a bill opens with the player's thought more often than the
	# flat chance (2026-11-02, Balance "Transition: Bill Level Thought Chance").
	var bill_id := str(_stage.get("bill_id", ""))
	var thought_chance := int(DataDB.balance.get("transition_player_thought_chance", 0))
	if not bill_id.is_empty():
		thought_chance = int(DataDB.balance.get("transition_bill_level_thought_chance", thought_chance))
	var result := StageTransition.resolve(
		_stage, DataDB.transition_cast, DataDB.transition_backgrounds, DataDB.transition_dialogue, rng, hired_ids,
		thought_chance, bill_id, _lean(), DataDB.component_ids_of(bill_id),
		int(DataDB.balance.get("transition_staff_speaker_chance", -1)), GameState.transition_memory,
		_opponent_lock())

	if result.is_empty():
		_on_continue()
		return
	_remember(result)
	_lock_opponents(result)

	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = str(result.get("background_id", "")) if not str(result.get("background_id", "")).is_empty() \
		else str(_stage.get("stage_id", ""))
	_background.show_label = false

	_speakers = result["speakers"]
	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)

	# No one to speak: the player's own passing thought, blue side, no speaker.
	if _speakers.is_empty():
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), str(result.get("thought", "")))
		return

	# One layout pass first, so SpeakerPortrait's own anchor-computed rest
	# position is known before anything tries to slide relative to it.
	await get_tree().process_frame
	_speaker_rest_x = _speaker_portrait.position.x
	# The name sits under the speaker's own portrait, on the right, not centred
	# across the whole screen where it read as the player's (2026-11-02).
	_speaker_name.custom_minimum_size.x = _speaker_portrait.size.x
	_speaker_name.size_flags_horizontal = Control.SIZE_SHRINK_END

	_show_speaker(0)
	# A private thought first, when this transition drew one.
	var thought := str(result.get("thought", ""))
	_lead_lines = 0
	if not thought.is_empty():
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), thought)
		_lead_lines = 1
	for speaker: Dictionary in _speakers:
		var name := _display_name(str(speaker["character_id"]))
		var side := _banner_side(str(speaker["character_id"]))
		_banner.say(side, name, str(speaker["character_line"]))
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), str(speaker["player_reply"]))


## What ties an opponent who speaks to the stage that follows: who is already
## seated in it, who may be, and how many seats it has. Empty outside a level
## and for a stage with nobody seated (an opponent then cannot speak).
func _opponent_lock() -> Dictionary:
	if not GameState.is_in_level():
		return {}
	var drawn: Array = []
	for person: Variant in (_stage.get("opponents", []) as Array):
		drawn.append(str((person as Dictionary).get("opp_id", "")))
	var eligible: Array = []
	for person: Variant in BattleSetup.eligible_opponents(str(_stage.get("stage_id", ""))):
		eligible.append(str((person as Dictionary).get("opp_id", "")))
	# Whoever is already seated counts as eligible, even if the workbook has
	# since taken them off the stage's list (a pinned opponent, say).
	for id: String in drawn:
		if not eligible.has(id):
			eligible.append(id)
	return {"drawn": drawn, "eligible": eligible, "seats": drawn.size()}


## An opponent who spoke is the opponent in the stage that follows: seat the
## speakers first, in the order they spoke (StageTransition.lock_opponents()).
func _lock_opponents(result: Dictionary) -> void:
	var spoke := StageTransition.opponent_speakers(result.get("speakers", []))
	if spoke.is_empty() or not GameState.is_in_level():
		return
	var table := {}
	for person: Variant in DataDB.opponents:
		table[str((person as Dictionary).get("opp_id", ""))] = person
	GameState.reseat_current_stage(
		StageTransition.lock_opponents(_stage.get("opponents", []) as Array, spoke, table))


## Keeps who spoke and what was heard, so the next transition of this level
## does not repeat them (StageTransition.pick_speakers()'s `avoid`).
func _remember(result: Dictionary) -> void:
	var memory: Dictionary = GameState.transition_memory
	var heard: Dictionary = memory.get("lines", {})
	for speaker: Dictionary in result.get("speakers", []):
		heard[str(speaker.get("line_key", ""))] = true
		memory["speaker"] = str(speaker.get("character_id", ""))
	var thought := str(result.get("thought", ""))
	if not thought.is_empty():
		heard[StageTransition.line_key("PLAYER", thought)] = true
	memory["lines"] = heard
	GameState.transition_memory = memory


func _process(_delta: float) -> void:
	if _banner == null or _speakers.is_empty():
		return
	if _banner.lines_shown <= _lines_accounted_for:
		return
	_lines_accounted_for = _banner.lines_shown
	var spoken := _lines_accounted_for - _lead_lines
	if spoken < 0:
		return
	var total_lines := _speakers.size() * 2
	if spoken >= total_lines:
		return
	var next_index: int = spoken / 2
	if next_index != _current_speaker_index:
		_show_speaker(next_index)


var _slide_tween: Tween
var _lead_lines := 0


func _show_speaker(index: int) -> void:
	_current_speaker_index = index
	var first_to_speak := not _speaker_portrait.visible
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = create_tween()
	# The speaker before leaves the way the next one arrives: out to the right,
	# then the picture and name change and the new one slides in (2026-11-02).
	if not first_to_speak:
		_slide_tween.tween_property(_speaker_portrait, "position:x", _speaker_rest_x + SLIDE_OFFSET,
			SLIDE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_slide_tween.tween_callback(_seat_speaker.bind(index))
	_slide_tween.tween_property(_speaker_portrait, "position:x", _speaker_rest_x,
		SLIDE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Puts speaker `index`'s picture and name in place, just off screen, ready to slide in.
func _seat_speaker(index: int) -> void:
	var character_id := str((_speakers[index] as Dictionary)["character_id"])
	_speaker_portrait.art_id = character_id
	_speaker_portrait.visible = true
	_speaker_name.text = _label_for(character_id)
	_speaker_name.visible = true
	_speaker_portrait.position.x = _speaker_rest_x + SLIDE_OFFSET


## An opponent speaks from the red/right side (the room's own voice);
## hired staff speak from the blue/left side alongside the player, since
## staff are the player's own team — the same convention LevelIntroScreen
## already uses for every staff cue.
func _banner_side(character_id: String) -> int:
	return CueBanner.OPPONENT if StageTransition.character_kind(character_id) == "opponent" else CueBanner.PLAYER


## The name under the speaker's portrait: a party leader carries their party
## title, since the first-title rule would otherwise hide it behind a ministry
## or the Speakership (OpponentDisplay.party_leader_title()).
func _label_for(character_id: String) -> String:
	var name := _display_name(character_id)
	if StageTransition.character_kind(character_id) != "opponent":
		return name
	var leader_title := OpponentDisplay.party_leader_title(DataDB.get_opponent(character_id))
	return name if leader_title.is_empty() else Text.say("battle.name_and_title", {"name": name, "title": leader_title})


func _display_name(character_id: String) -> String:
	match StageTransition.character_kind(character_id):
		"opponent": return str(DataDB.get_opponent(character_id).get("name", character_id))
		"staff": return str(DataDB.get_staff(character_id).get("name", character_id))
	return character_id


## Keeps Continue inactive for the Balance delay when the scene first appears,
## so the opening is seen before it can be tapped past. The timer captures the
## button alone, not the screen. Tests and bots skip it (COP_NO_CONTINUE_DELAY).
func _hold_continue() -> void:
	var delay := float(DataDB.balance.get("stage_continue_delay_seconds", 0))
	if delay <= 0.0 or OS.has_environment("COP_NO_CONTINUE_DELAY"):
		return
	var button := _continue_button
	button.disabled = true
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(button):
			button.disabled = false)


func _on_continue() -> void:
	Haptics.confirm()
	if not GameState.is_in_level():
		get_tree().quit()
		return
	SceneChange.to(get_tree(), StageRouting.scene_for(GameState.level_runner.current_stage()))


## The lean taken on the level's bill ("" when this level has none).
func _lean() -> String:
	var bill_id := str(_stage.get("bill_id", ""))
	if bill_id.is_empty() or str(GameState.bill_stance.get("bill_id", "")) != bill_id:
		return ""
	return GameState.stance_lean()
