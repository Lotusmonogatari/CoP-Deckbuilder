extends Control
## The milestone 0 test screen.
##
## It proves three things at a glance, in the editor and on a phone alike:
##   1. Every data file loads and every cross-reference in it resolves.
##   2. Japanese renders properly next to English, in the bundled font.
##   3. Missing artwork falls back to a labelled placeholder instead of
##      breaking the screen.
##
## This is the project's main scene for now. It gets replaced by the real
## title screen later; until then it's the fastest way to see whether the
## foundations are sound.
##
## Run headless with:
##     .tools/godot --headless --path . --quit-after 3

## Sample text proving the font handles both scripts. Deliberately uses the
## English-first, Japanese-as-accent pattern the whole game follows.
const SAMPLE_PAIRS := [
	["Floor debate", "本会議"],
	["Committee", "委員会"],
	["Press conference", "記者会見"],
	["Gaffe", "失言"],
]

@onready var _content: VBoxContainer = %Content


func _ready() -> void:
	_build_data_section()
	_build_font_section()
	_build_art_section()
	_print_headless_summary()


# ---------------------------------------------------------------------------
# Section 1: the data report
# ---------------------------------------------------------------------------

func _build_data_section() -> void:
	_heading("Game data")

	var status := _line(DataDB.summary_line())
	status.add_theme_color_override(
		"font_color",
		Color(0.9, 0.3, 0.25) if not DataDB.errors.is_empty() else Color(0.45, 0.8, 0.5)
	)

	_line("%d cards · %d stages · %d opponents · %d modifiers · %d boosters"
		% [DataDB.cards.size(), DataDB.stages.size(), DataDB.opponents.size(),
		   DataDB.modifiers.size(), DataDB.boosters.size()], "SmallLabel")

	for message: String in DataDB.errors:
		var label := _line("✕  " + message, "SmallLabel")
		label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25))

	if not DataDB.warnings.is_empty():
		_line("%d known gap(s) in the design data — see the console for the list."
			% DataDB.warnings.size(), "SmallLabel")

	# Prove the switches loaded, since they change how a battle plays.
	_line("Turn limit: %s · Discard hand: %s · Opponents: %s" % [
		DataDB.get_rule("turn_limit_outcome"),
		DataDB.get_rule("discard_hand_end_of_turn"),
		DataDB.get_rule("opponent_engine"),
	], "SmallLabel")


# ---------------------------------------------------------------------------
# Section 2: the font
# ---------------------------------------------------------------------------

func _build_font_section() -> void:
	_heading("Text")

	for pair: Array in SAMPLE_PAIRS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var english := Label.new()
		english.text = pair[0]
		row.add_child(english)

		# The Japanese accent: smaller and dimmer, always beside the English,
		# never on its own.
		var japanese := Label.new()
		japanese.text = pair[1]
		japanese.theme_type_variation = "JapaneseAccent"
		japanese.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(japanese)

		_content.add_child(row)

	# A stage name straight from the data, to show the pairing works with
	# real content rather than only with hardcoded samples.
	var stage := DataDB.get_stage("ST02")
	if not stage.is_empty():
		_line("From the workbook: %s %s" % [stage.get("name_en"), stage.get("name_jp")], "SmallLabel")


# ---------------------------------------------------------------------------
# Section 3: placeholder art
# ---------------------------------------------------------------------------

func _build_art_section() -> void:
	_heading("Artwork")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	# One tile per kind, so every fallback path gets exercised.
	_add_tile(row, PlaceholderArt.Kind.CHARACTER, "OP03")
	_add_tile(row, PlaceholderArt.Kind.CHARACTER, "PROTAGONIST")
	_add_tile(row, PlaceholderArt.Kind.CARD, "C11")
	_add_tile(row, PlaceholderArt.Kind.BACKGROUND, "ST02")
	_add_tile(row, PlaceholderArt.Kind.ICON, "BO04")

	_content.add_child(row)

	var missing := _count_missing_art()
	_line("%d of %d sample assets are still placeholders."
		% [missing, row.get_child_count()], "SmallLabel")


func _add_tile(parent: Control, kind: PlaceholderArt.Kind, id: String) -> void:
	var tile := PlaceholderArt.new()
	tile.custom_minimum_size = Vector2(150, 150)
	tile.kind = kind
	tile.art_id = id
	parent.add_child(tile)


func _count_missing_art() -> int:
	var missing := 0
	for path: String in [
		ArtLoader.CHARACTERS + "OP03_neutral.png",
		ArtLoader.CHARACTERS + "PROTAGONIST_neutral.png",
		ArtLoader.CARDS + "C11.png",
		ArtLoader.BACKGROUNDS + "ST02.png",
		ArtLoader.ICONS + "BO04.png",
	]:
		if not ArtLoader.exists(path):
			missing += 1
	return missing


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _heading(text: String) -> Label:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	_content.add_child(spacer)

	var label := Label.new()
	label.text = text
	label.theme_type_variation = "HeaderLabel"
	_content.add_child(label)
	return label


func _line(text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not variation.is_empty():
		label.theme_type_variation = variation
	_content.add_child(label)
	return label


## When there's no window — a build server, or a quick check from a terminal —
## the console output is the whole result, so make it a clear pass or fail.
func _print_headless_summary() -> void:
	if DisplayServer.get_name() != "headless":
		return

	print("BOOT CHECK")
	print("  data:  %s" % DataDB.summary_line())
	print("  font:  %s" % ("loaded" if _font_loaded() else "MISSING — falling back to Godot's default"))
	print("  art:   %d of 5 sample assets are placeholders" % _count_missing_art())
	print("  result: %s" % ("PASS" if DataDB.errors.is_empty() and _font_loaded() else "FAIL"))

	if not DataDB.errors.is_empty() or not _font_loaded():
		# A non-zero exit code is what makes this usable in tools/verify.sh.
		get_tree().quit(1)


func _font_loaded() -> bool:
	var theme_font := ThemeDB.get_project_theme()
	if theme_font == null or theme_font.default_font == null:
		return false
	# Godot silently substitutes its built-in font when a theme font fails to
	# load, so check the glyph coverage rather than trusting the reference.
	return theme_font.default_font.has_char("本".unicode_at(0))
