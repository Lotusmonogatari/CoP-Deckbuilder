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

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _how_to_play_button: Button = %HowToPlayButton

## The "this throws your run away" warning — built in code, like Office's
## own equivalent (_confirm_new_game()), and asking the exact same
## question in the exact same words (office.new_game*): a save on disk
## nobody has loaded yet is still a run New Game would bury the moment the
## next autosave fires, same as one already open in the Office.
var _overwrite_warning: Overlay

## The How to Play guide (HowToPlayPanel.gd), opened from its own button.
var _how_to_play_panel: Overlay
var _save_problem: Overlay

## The title painting, shown in its frame at the size the layout gives it.
var _painting: Texture2D = null


func _ready() -> void:
	# The pop-ups' button outlines are the cue-banner gold, not a party
	# colour left over from a saved run (2026-10-16, Cameron).
	Layout.set_outline_override(CueBanner.EDGE_COLOUR, true)

	_dress()

	_continue_button.text = Text.say("intro.continue")
	_continue_button.disabled = not SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)

	_new_game_button.text = Text.say("intro.new_game")
	_new_game_button.pressed.connect(_on_new_game_pressed)

	# How to Play, beneath the two doors in.
	_how_to_play_panel = HowToPlayPanel.attach(self)
	_how_to_play_button.text = Text.say("intro.how_to_play")
	_how_to_play_button.pressed.connect(HowToPlayPanel.open.bind(_how_to_play_panel))

	_overwrite_warning = Overlay.new()
	_overwrite_warning.name = "OverwriteWarning"
	add_child(_overwrite_warning)
	_overwrite_warning.confirmed.connect(_start_new_game)

	# Shown when Continue cannot read the save (2026-10-14): before this the
	# game silently began a new run, and the next autosave overwrote the file.
	_save_problem = Overlay.new()
	_save_problem.name = "SaveProblem"
	add_child(_save_problem)
	_save_problem.confirmed.connect(_start_new_game)

	resized.connect(_layout)
	_layout.call_deferred()
	Audio.play_music("music_title")


## Brand B (P10, 2026-11-18): the words, the fonts and the borders. It does not follow the UI style, because
## the style is saved with the run and there is no run before Continue.
func _dress() -> void:
	%Title.text = Text.say("intro.title_top")
	%TitleBottom.text = Text.say("intro.title_bottom")
	%Tagline.text = Text.say("intro.tagline")
	BrandTheme.style_label(%Title, 105, BrandTheme.SUMI, true)
	BrandTheme.style_label(%TitleBottom, 55, BrandTheme.INDIGO, true)
	BrandTheme.style_label(%Tagline, 30, BrandTheme.QUIET_INK, false, 0.04)

	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	%FooterVersion.text = Text.say("intro.version", {"version": version}) if not version.is_empty() else ""
	%FooterMark.text = Text.say("intro.footer_mark")
	BrandTheme.style_label(%FooterVersion, 33, BrandTheme.QUIET_INK, false)
	BrandTheme.style_label(%FooterMark, 33, BrandTheme.QUIET_INK, false)

	BrandTheme.style_button(_continue_button, BrandTheme.Kind.PRIMARY, 53)
	BrandTheme.style_button(_new_game_button, BrandTheme.Kind.SECONDARY, 50)
	BrandTheme.style_button(_how_to_play_button, BrandTheme.Kind.TERTIARY, 47)

	var frame := StyleBoxFlat.new()
	frame.bg_color = BrandTheme.PAPER
	frame.border_color = BrandTheme.INDIGO
	frame.set_border_width_all(17)
	frame.set_content_margin_all(22)
	%PrintFrame.add_theme_stylebox_override("panel", frame)

	# The plate: paper, an 8 px vermilion border with a 17 px offset shadow, and a 3 px vermilion line inset 25 px
	# (the card backs' double border).
	var plate := StyleBoxFlat.new()
	plate.bg_color = BrandTheme.PAPER
	plate.border_color = BrandTheme.VERMILION
	plate.set_border_width_all(8)
	plate.shadow_color = Color(BrandTheme.SUMI.r, BrandTheme.SUMI.g, BrandTheme.SUMI.b, 0.14)
	plate.shadow_offset = Vector2(17, 17)
	plate.shadow_size = 1
	%Plate.get_node("PlateBack").add_theme_stylebox_override("panel", plate)
	var line := StyleBoxFlat.new()
	line.bg_color = Color(0, 0, 0, 0)
	line.border_color = BrandTheme.VERMILION
	line.set_border_width_all(3)
	%Plate.get_node("PlateInset").add_theme_stylebox_override("panel", line)

	_painting = ArtLoader.background("TITLE")


## Puts every piece where IntroLayout says. Only the framed print flexes: it fills the room above the plate, so a
## shorter screen or a bigger text size shrinks the picture and nothing else.
func _layout() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	var insets: Dictionary = Layout.insets if get_viewport() == get_tree().root else {}
	# The plate's width first, so its text wraps to it; its height then follows the text.
	var plate_w := screen.x - 2.0 * maxf(IntroLayout.PLATE_MARGIN, float(insets.get("left", 0.0)))
	%Plate.size.x = plate_w
	%PlateColumn.size.x = plate_w - 100.0
	# Its height follows its text, measured here from the fonts (a wrapped Label only knows its own height a
	# frame after it is sized), plus the padding.
	var text_w := plate_w - 100.0 - 6.0   # a hair narrower than the label, so the measure never says one line fewer
	var plate_h := 55.0 + 50.0 + 2.0 * 6.0
	for label: Label in [%Title, %TitleBottom, %Tagline]:
		plate_h += _text_height(label, text_w)
	# Once the labels have a width, the column knows its real height: never less than that.
	plate_h = maxf(plate_h, (%PlateColumn as Control).get_combined_minimum_size().y + 55.0 + 50.0)
	var r := IntroLayout.rects(screen, insets, plate_h)

	_place(%Bands, r["bands"])
	var bands := r["bands"] as Rect2
	%Bands.get_node("BandTop").position = Vector2.ZERO
	%Bands.get_node("BandTop").size = Vector2(bands.size.x, 83)
	%Bands.get_node("BandMid").position = Vector2(0, 83)
	%Bands.get_node("BandMid").size = Vector2(bands.size.x, 50)
	%Bands.get_node("BandPale").position = Vector2(0, 133)
	%Bands.get_node("BandPale").size = Vector2(bands.size.x, 33)
	_place(%PrintFrame, r["print"])
	_place(%Plate, r["plate"])
	_place(%Seal, r["seal"])
	_place(_continue_button, r["continue"])
	_place(_new_game_button, r["new_game"])
	_place(_how_to_play_button, r["how_to_play"])
	_place(%Waves, r["waves"])
	var footer := r["footer"] as Rect2
	_place(%FooterVersion, Rect2(footer.position, Vector2(footer.size.x * 0.3, footer.size.y)))
	_place(%FooterMark, Rect2(footer.position + Vector2(footer.size.x * 0.3, 0), Vector2(footer.size.x * 0.7, footer.size.y)))

	# The painting fills the frame (cover), looking at 50% across and 42% down.
	if _painting != null:
		var inner := (r["print"] as Rect2).size - Vector2(2 * (17 + 22), 2 * (17 + 22))
		var atlas := AtlasTexture.new()
		atlas.atlas = _painting
		atlas.region = IntroLayout.cover_region(_painting.get_size(), inner, 0.42)
		%Painting.texture = atlas
		%Painting.stretch_mode = TextureRect.STRETCH_SCALE
	# A second pass once the wrapped text has settled (a Label's height follows its width).
	if _passes < 3:
		_passes += 1
		_layout.call_deferred()


var _passes := 0


## How tall `label`'s text is when wrapped to `width` (its own font and size).
func _text_height(label: Label, width: float) -> float:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var wrapped := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, width, size, -1,
		TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_MANDATORY)
	return wrapped.y


func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size


func _on_continue_pressed() -> void:
	Haptics.confirm()
	if not SaveManager.load_game():
		# The save vanished or could not be read. Say so and let the player
		# choose, rather than quietly starting a new run over the top.
		var newer: bool = SaveManager.last_problem == "newer"
		if SaveManager.last_problem.is_empty():
			_start_new_game()
			return
		_save_problem.open(Text.say("save.problem_title"),
			[UiKit.line(Text.say("save.newer_body") if newer else Text.say("save.unreadable_body"))],
			Text.say("save.start_new"))
		return
	SceneChange.to(get_tree(), OFFICE_SCENE)


func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		_overwrite_warning.open(Text.say("office.new_game"),
			[UiKit.line(Text.say("office.new_game_warning"))],
			Text.say("office.new_game_confirm"))
	else:
		_start_new_game()


func _start_new_game() -> void:
	GameState.awaiting_new_game = true
	SceneChange.to(get_tree(), OFFICE_SCENE)


func _exit_tree() -> void:
	Layout.set_outline_override(Color(0, 0, 0, 0), false)
