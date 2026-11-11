class_name ResignScreen
extends Control
## The end of a run by resignation (2026-11-11, Cameron), in two parts.
##
## Part one: RESIGN.png and the closing words, with one crimson "Goodbye"
## button. Goodbye swipes part one off to the left and part two in from the
## right. Part two: RESIGN_2.png, the same words and button flipped left to
## right as if seen from behind the glass. After a hold it fades to black,
## stays black for a moment, then the title screen appears. Every timing is a
## Balance row ("Resign: ..."). The run and its save are already gone
## (GameState.resign_run()). Pictures that do not exist yet show a labelled
## placeholder.

## Crimson outline and fill with black text, for the Resign and Goodbye buttons.
const CRIMSON := Color(0.78, 0.07, 0.17)
const TITLE_SCENE := "res://scenes/menus/IntroScreen.tscn"

@onready var _phase_one: Control = %PhaseOne
@onready var _phase_two: Control = %PhaseTwo
@onready var _art_one: PlaceholderArt = %BackgroundOne
@onready var _art_two: PlaceholderArt = %BackgroundTwo
@onready var _words_one: Label = %WordsOne
@onready var _words_two: Label = %WordsTwo
@onready var _goodbye_one: Button = %GoodbyeOne
@onready var _goodbye_two: Button = %GoodbyeTwo
@onready var _safe_two: Control = %SafeTwo
@onready var _black: ColorRect = %Black

var _leaving := false


func _ready() -> void:
	_art_one.kind = PlaceholderArt.Kind.BACKGROUND
	_art_one.art_id = "RESIGN"
	_art_two.kind = PlaceholderArt.Kind.BACKGROUND
	_art_two.art_id = "RESIGN_2"
	for words: Label in [_words_one, _words_two]:
		words.text = Text.say("resign.body")
	for goodbye: Button in [_goodbye_one, _goodbye_two]:
		goodbye.text = Text.say("resign.to_title")
		style_crimson(goodbye)
	_goodbye_one.pressed.connect(_on_goodbye)

	# Part two is seen from behind: the whole text block (words and button) is
	# flipped about its own centre, and the centre follows the layout. It is
	# the margin box that is flipped, not the column inside it: a container
	# resets the scale of its children. The button is only for show; nothing
	# in part two can be pressed.
	_safe_two.resized.connect(_centre_flip)
	_safe_two.scale = Vector2(-1.0, 1.0)
	_goodbye_two.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goodbye_two.focus_mode = Control.FOCUS_NONE


func _centre_flip() -> void:
	_safe_two.pivot_offset = _safe_two.size / 2.0


func _on_goodbye() -> void:
	if _leaving:
		return
	_leaving = true
	Haptics.confirm()
	var width := size.x
	var swipe_seconds := float(DataDB.balance.get("resign_swipe_seconds", 0.6))
	_phase_two.position.x = width
	_phase_two.show()
	var swipe := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	swipe.tween_property(_phase_one, "position:x", -width, swipe_seconds)
	swipe.tween_property(_phase_two, "position:x", 0.0, swipe_seconds)
	swipe.finished.connect(_after_swipe)


## Hold on part two, fade to black, stay black, then the title screen.
func _after_swipe() -> void:
	_phase_one.hide()
	var ending := create_tween()
	ending.tween_interval(float(DataDB.balance.get("resign_hold_seconds", 2.0)))
	ending.tween_property(_black, "color:a", 1.0, float(DataDB.balance.get("resign_fade_seconds", 1.0)))
	ending.tween_interval(float(DataDB.balance.get("resign_black_seconds", 2.0)))
	ending.tween_callback(_to_title)


func _to_title() -> void:
	SceneChange.to(get_tree(), TITLE_SCENE)


## The Resign button for the Reputation and Results menu: crimson outline and
## fill, black text, on every state.
static func button(on_press: Callable) -> Button:
	var resign := Button.new()
	resign.name = "ResignButton"
	resign.text = Text.say("office.resign")
	resign.custom_minimum_size = Vector2(0, 110)
	style_crimson(resign)
	resign.pressed.connect(on_press)
	return resign


## Crimson outline and fill with black text, on every state: the Resign
## button and the Goodbye button share it.
static func style_crimson(target: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = CRIMSON
		box.border_color = CRIMSON
		box.set_border_width_all(4)
		box.set_corner_radius_all(10)
		target.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		target.add_theme_color_override(colour, Color.BLACK)
