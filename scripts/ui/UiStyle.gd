class_name UiStyle
extends RefCounted
## The active UI style (P9, 2026-11-17): which one is equipped, its tokens, and
## putting its theme over the project theme.
##
## A style changes look and arrangement only. Screens ask `current()` while they
## BUILD, so a change shows on the next screen; a battle in progress keeps the
## look it started with because its nodes are already built. Nothing in
## scripts/rules/ reads this (the rules know only UiStyles, the pure half).

static var _index: Dictionary = {}
static var _index_rows := -1
static var _applied := ""


## The id of the style in use: "living_office", "broadcast" or "woodblock".
static func current() -> String:
	var package_id := str(GameState.active_cosmetics.get(CosmeticPieces.UI_STYLE, ""))
	if package_id.is_empty():
		return UiStyles.LIVING_OFFICE
	return UiStyles.current(DataDB.get_cosmetic_package(package_id))


static func idx() -> Dictionary:
	if _index_rows != DataDB.ui_styles.size():
		_index = UiStyles.index(DataDB.ui_styles)
		_index_rows = DataDB.ui_styles.size()
	return _index


static func colour(name: String, fallback: Color = Color.MAGENTA, style: String = "") -> Color:
	return UiStyles.colour(idx(), style if not style.is_empty() else current(), name, fallback)


static func number(group: String, name: String, fallback: float = 0.0, style: String = "") -> float:
	return UiStyles.number(idx(), style if not style.is_empty() else current(), group, name, fallback)


static func plate_colour() -> Color:
	return UiStyles.plate_colour(idx(), current())


static func plate_ink() -> Color:
	return UiStyles.plate_ink(idx(), current())


static func ground_colour() -> Color:
	return UiStyles.ground_colour(idx(), current())


## Merges the active style's overlay into the project theme. Cheap when the
## style has not changed. Returns true when something was applied.
static func sync() -> bool:
	var style := current()
	if style == _applied:
		return false
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		return false
	theme.merge_with(overlay(style))
	_applied = style
	BaseImage.reset_cache()
	return true


## The style's theme overlay: the saved theme/cop_theme_<style>.tres that tools/build_theme.gd
## writes, or one built on the spot from the same tokens when the file is missing.
static func overlay(style: String) -> Theme:
	var file := "res://theme/cop_theme_%s.tres" % ("living" if style == UiStyles.LIVING_OFFICE else style)
	if ResourceLoader.exists(file):
		var saved: Variant = load(file)
		if saved is Theme:
			return saved
	return UiStyleTheme.build(style, idx())


## A screenshot of the Office in `style`, for the Office styles tab (assets/ui_styles/), or null.
static func preview(style: String) -> Texture2D:
	var path := "res://assets/ui_styles/preview_%s.png" % style
	if ResourceLoader.exists(path):
		var texture: Variant = load(path)
		if texture is Texture2D:
			return texture
	return null


## Forget what was applied (a new run, or a test that rebuilt the theme).
static func forget() -> void:
	_applied = ""
