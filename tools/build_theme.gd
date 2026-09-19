@tool
extends SceneTree
## Builds theme/cop_theme.tres — the project's default look.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_theme.gd
##
## The theme is generated rather than hand-edited because it's mostly font
## sizes, and a script makes the relationships between them obvious. Re-run
## this after changing a size below; commit the .tres it produces.
##
## WHY A SCRIPT AND NOT THE EDITOR: a .tres written by hand is easy to get
## subtly wrong (resource IDs, font variation tags). Letting Godot save it
## guarantees a file Godot can read back.

const FONT_PATH := "res://assets/fonts/NotoSansJP[wght].ttf"
const OUTPUT_PATH := "res://theme/cop_theme.tres"

## Sizes are in pixels at the base resolution of 1080 x 2340. Godot scales
## them with the screen, so these hold their proportions on any phone.
const SIZE_BODY := 34
const SIZE_HEADER := 46
const SIZE_TITLE := 58
const SIZE_SMALL := 26
const SIZE_BUTTON := 40

## The Japanese accent text that sits beside English. Smaller and dimmer:
## it's a flourish, never the thing you have to read.
const SIZE_JP_ACCENT := 24
const JP_ACCENT_ALPHA := 0.55


func _init() -> void:
	var base_font := load(FONT_PATH)
	if base_font == null:
		push_error("Could not load the font at %s. Has Godot imported it yet?" % FONT_PATH)
		quit(1)
		return

	var theme := Theme.new()

	# Noto Sans JP is a variable font, so one file covers every weight.
	# FontVariation picks a weight out of it.
	var regular := FontVariation.new()
	regular.base_font = base_font
	regular.variation_opentype = {_tag("wght"): 400}

	var bold := FontVariation.new()
	bold.base_font = base_font
	bold.variation_opentype = {_tag("wght"): 700}

	theme.default_font = regular
	theme.default_font_size = SIZE_BODY

	# --- Base controls -----------------------------------------------------
	theme.set_font("font", "Label", regular)
	theme.set_font_size("font_size", "Label", SIZE_BODY)

	theme.set_font("font", "Button", bold)
	theme.set_font_size("font_size", "Button", SIZE_BUTTON)

	theme.set_font("font", "RichTextLabel", regular)
	theme.set_font_size("normal_font_size", "RichTextLabel", SIZE_BODY)

	# --- Named variations --------------------------------------------------
	# Set a Label's "Theme Type Variation" to one of these names to get the
	# matching size, instead of overriding the font size on each label.
	_add_label_variation(theme, "TitleLabel", bold, SIZE_TITLE)
	_add_label_variation(theme, "HeaderLabel", bold, SIZE_HEADER)
	_add_label_variation(theme, "SmallLabel", regular, SIZE_SMALL)

	# The muted Japanese accent that appears next to English text.
	_add_label_variation(theme, "JapaneseAccent", regular, SIZE_JP_ACCENT)
	theme.set_color("font_color", "JapaneseAccent", Color(1, 1, 1, JP_ACCENT_ALPHA))

	# The gaffe counter. Normal until one more gaffe would end the stage,
	# then GaffeWarning turns it red — and only then.
	_add_label_variation(theme, "GaffeWarning", bold, SIZE_BODY)
	theme.set_color("font_color", "GaffeWarning", Color(0.9, 0.25, 0.2))

	var error := DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create the theme folder: %d" % error)
		quit(1)
		return

	error = ResourceSaver.save(theme, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save the theme: %d" % error)
		quit(1)
		return

	print("Wrote %s" % OUTPUT_PATH)
	quit(0)


func _add_label_variation(theme: Theme, name: String, font: Font, size: int) -> void:
	theme.set_type_variation(name, "Label")
	theme.set_font("font", name, font)
	theme.set_font_size("font_size", name, size)


## OpenType axis tags are four characters packed into an integer.
## "wght" becomes 0x77676874.
func _tag(text: String) -> int:
	var value := 0
	for index in 4:
		value = (value << 8) | text.unicode_at(index)
	return value
