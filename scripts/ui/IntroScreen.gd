extends Control
## The title screen — the first thing the game shows, always.
##
## Two doors in: Continue, which loads the one save slot and opens the
## Office as it left off; New Game, which hands off to the Office's own
## protagonist picker (already built, already tested) rather than a second
## one living here — see design/proposals/intro_screen.md.
##
## SaveManager no longer loads the save eagerly at boot (it used to);
## Continue is the one place that happens now, so pressing it is a real,
## checkable action rather than something that already silently occurred
## before this screen even drew. GameState.has_save() at _ready() is only
## ever a file check — nothing is read into memory until Continue is
## actually pressed.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

@onready var _background: PlaceholderArt = %Background
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton

## The "this throws your run away" warning — built in code, like Office's
## own equivalent (_confirm_new_game()), and asking the exact same
## question in the exact same words (office.new_game*): a save on disk
## nobody has loaded yet is still a run New Game would bury the moment the
## next autosave fires, same as one already open in the Office.
var _overwrite_warning: Overlay


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = "TITLE"
	_background.show_label = false

	_continue_button.text = Text.say("intro.continue")
	_continue_button.disabled = not SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)

	_new_game_button.text = Text.say("intro.new_game")
	_new_game_button.pressed.connect(_on_new_game_pressed)

	_overwrite_warning = Overlay.new()
	_overwrite_warning.name = "OverwriteWarning"
	add_child(_overwrite_warning)
	_overwrite_warning.confirmed.connect(_start_new_game)

	%Title.text = Text.say("intro.title")

	Audio.play_music("music_title")


func _on_continue_pressed() -> void:
	if not SaveManager.load_game():
		# The save vanished or failed to read between this screen opening
		# and the tap — rare, but the same fallback SaveManager's own boot
		# check used to fall back to: a fresh run rather than a dead end.
		GameState.awaiting_new_game = true
	get_tree().change_scene_to_file(OFFICE_SCENE)


func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		_overwrite_warning.open(Text.say("office.new_game"),
			[UiKit.line(Text.say("office.new_game_warning"))],
			Text.say("office.new_game_confirm"))
	else:
		_start_new_game()


func _start_new_game() -> void:
	GameState.awaiting_new_game = true
	get_tree().change_scene_to_file(OFFICE_SCENE)
