class_name ResignScreen
extends Control
## The end of a run by resignation (2026-11-11, Cameron). Shows RESIGN.png
## (a labelled placeholder until the picture exists) and the closing words,
## then one button back to the title. The run and its save are already gone
## (GameState.resign_run()).

## Crimson outline and fill with black text, for the Resign button only.
const CRIMSON := Color(0.78, 0.07, 0.17)
const TITLE_SCENE := "res://scenes/menus/IntroScreen.tscn"

@onready var _background: PlaceholderArt = %Background
@onready var _words: Label = %Words
@onready var _button: Button = %BackButton


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = "RESIGN"
	_words.text = Text.say("resign.body")
	_button.text = Text.say("resign.to_title")
	_button.pressed.connect(_on_back)


func _on_back() -> void:
	Haptics.confirm()
	SceneChange.to(get_tree(), TITLE_SCENE)


## The Resign button for the Reputation and Results menu: crimson outline and
## fill, black text, on every state.
static func button(on_press: Callable) -> Button:
	var resign := Button.new()
	resign.name = "ResignButton"
	resign.text = Text.say("office.resign")
	resign.custom_minimum_size = Vector2(0, 110)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = CRIMSON
		box.border_color = CRIMSON
		box.set_border_width_all(4)
		box.set_corner_radius_all(10)
		resign.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		resign.add_theme_color_override(colour, Color.BLACK)
	resign.pressed.connect(on_press)
	return resign
