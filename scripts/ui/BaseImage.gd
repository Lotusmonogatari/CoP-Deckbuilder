class_name BaseImage
extends RefCounted
## The picture underneath a screen's room picture (Cameron, 2026-10-31). Each
## screen looks for its own `BASE_<SCREEN>.png` in the backgrounds folder,
## then the shared `BASE.png`; with neither drawn, the screen keeps its flat
## colour panel exactly as before (no labelled placeholder, on purpose).
## When a base picture is found, the screen's bottom panel turns translucent
## so the picture shows through while text over it stays readable.

## How see-through the bottom panel becomes over a base picture (its alpha).
const PANEL_ALPHA_OVER_BASE := 0.55


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
	var panel := screen.get_node_or_null("BackgroundPanel") as ColorRect
	if panel != null:
		panel.color.a = PANEL_ALPHA_OVER_BASE
	return picture


## The picture behind a full-screen panel that scrolls (events, information
## screens, the shops, the battle's Details and card zoom; Cameron,
## 2026-11-13): `BASE_SCROLLING.png`, else `BASE.png`. The panel's own dark
## colour stays beneath it, so with no picture drawn nothing changes.
## The picture is the lowest child; over it goes a dark tint (the same
## PANEL_ALPHA_OVER_BASE the bottom panels use), because the theme's text is
## light and would vanish on cream. Both ignore touches, so scrolling and
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
	var tint := ColorRect.new()
	tint.name = "BaseTint"
	tint.color = Color(0.07, 0.08, 0.11, PANEL_ALPHA_OVER_BASE)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tint)
	panel.move_child(tint, 1)
	return picture
