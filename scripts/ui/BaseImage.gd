class_name BaseImage
extends RefCounted
## The picture underneath a screen's room picture (Cameron, 2026-10-31). Each
## screen looks for its own `BASE_<SCREEN>.png` in the backgrounds folder,
## then the shared `BASE.png`; with neither drawn, the screen keeps its flat
## colour panel exactly as before (no labelled placeholder, on purpose).
## When a base picture is found, the screen's bottom panel turns translucent
## so the picture shows through while text over it stays readable.

## The dark tint that used to lie over every base picture is gone (Cameron,
## 2026-11-16): the picture shows exactly as drawn. Light text stays readable
## because every line of text over it gets its own dark, translucent plate
## (plate_theme()), so the picture shows between the lines and around them.
const PLATE_COLOUR := Color(0.07, 0.08, 0.11, 0.84)

static var _plate_theme: Theme
static var _faint_plate_theme: Theme
## The lighter plate for text that lies over a character picture (PortraitBehind): enough to
## read by, faint enough that the picture shows through.
const FAINT_PLATE_ALPHA := 0.5


## A theme that puts a dark translucent plate behind every Label. Set it on a
## screen or panel that sits over a base picture. Buttons already have their
## own dark boxes, and anything with its own panel keeps it.
static func plate_theme() -> Theme:
	if _plate_theme == null:
		_plate_theme = Theme.new()
		var plate := StyleBoxFlat.new()
		plate.bg_color = PLATE_COLOUR
		plate.set_corner_radius_all(8)
		plate.content_margin_left = 12.0
		plate.content_margin_right = 12.0
		plate.content_margin_top = 4.0
		plate.content_margin_bottom = 4.0
		_plate_theme.set_stylebox("normal", "Label", plate)
	return _plate_theme


## plate_theme() with a fainter plate (FAINT_PLATE_ALPHA), for a column of text laid over a
## character picture.
static func faint_plate_theme() -> Theme:
	if _faint_plate_theme == null:
		_faint_plate_theme = Theme.new()
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color(PLATE_COLOUR.r, PLATE_COLOUR.g, PLATE_COLOUR.b, FAINT_PLATE_ALPHA)
		plate.set_corner_radius_all(8)
		plate.content_margin_left = 12.0
		plate.content_margin_right = 12.0
		plate.content_margin_top = 4.0
		plate.content_margin_bottom = 4.0
		_faint_plate_theme.set_stylebox("normal", "Label", plate)
	return _faint_plate_theme


## The file a screen's base picture resolves to, or "" for none.
static func path_for(screen_id: String) -> String:
	var folder := ArtLoader.folder("background")
	for name: String in ["BASE_%s.png" % screen_id, "BASE.png"]:
		if ArtLoader.exists(folder + name):
			return folder + name
	return ""


## Puts the base picture at the very back of `screen` (behind its room
## picture) and lightens the screen's BackgroundPanel. Does nothing when no
## base picture is drawn. Returns the picture node, or null.
static func install(screen: Control, screen_id: String) -> TextureRect:
	var path := path_for(screen_id)
	if path.is_empty():
		return null
	var picture := TextureRect.new()
	picture.name = "BaseImage"
	picture.texture = load(path)
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(picture)
	screen.move_child(picture, 0)
	# No tint: the flat panel gives way completely and the picture shows as
	# drawn. (These screens keep their own panels and boxes behind their text;
	# plates are only for the scrolling panels below.)
	var panel := screen.get_node_or_null("BackgroundPanel") as ColorRect
	if panel != null:
		panel.color.a = 0.0
	return picture


## The picture behind a full-screen panel that scrolls (events, information
## screens, the shops, the battle's Details and card zoom; Cameron,
## 2026-11-13): `BASE_SCROLLING.png`, else `BASE.png`. The panel's own dark
## colour stays beneath it, so with no picture drawn nothing changes.
## The picture is the lowest child and ignores touches, so scrolling and
## taps behave exactly as before. Returns the picture node, or null.
static func install_behind_panel(panel: Control) -> TextureRect:
	if panel.get_node_or_null("BaseImage") != null:
		return null
	var path := path_for("SCROLLING")
	if path.is_empty():
		return null
	var picture := TextureRect.new()
	picture.name = "BaseImage"
	picture.texture = load(path)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(picture)
	panel.move_child(picture, 0)
	# No tint over the picture; the panel's labels get plates instead.
	panel.theme = plate_theme()
	return picture
