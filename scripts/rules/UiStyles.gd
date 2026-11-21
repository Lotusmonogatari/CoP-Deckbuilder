class_name UiStyles
extends RefCounted
## The three UI styles (P9, 2026-11-17): which one is equipped, which are
## owned, and the colour, font and size tokens each one carries.
##
## A STYLE IS LOOK AND ARRANGEMENT ONLY. Nothing in scripts/rules/ may read
## the active style to decide a rule, a number or a sentence; this file only
## answers "which style is this package" and "what is this style's token".
## Pure, like everything in scripts/rules/: no autoload, no file, no scene.
##
## Every style is a Cosmetic Package with a UI Style value (the `ui_style` slot in
## CosmeticPieces): Yezo Office (living_office), Broadcast and Woodblock. The one a
## player picks at New Game is owned free; the others are bought. The default
## (Rules tab, default_ui_style: Woodblock) is what shows until a pick exists.

const LIVING_OFFICE := "living_office"
const BROADCAST := "broadcast"
const WOODBLOCK := "woodblock"
const ALL := [LIVING_OFFICE, BROADCAST, WOODBLOCK]
## The style rows that apply to all of them.
const SHARED := "shared"


## The style a package unlocks: "" for a package with no UI Style piece.
static func style_of(package: Dictionary) -> String:
	var style := CosmeticPieces.field(package, "ui_style")
	return style if style in ALL else ""


## The style in use: the equipped package's, else `default_style`.
static func current(equipped_package: Dictionary, default_style: String = WOODBLOCK) -> String:
	var style := style_of(equipped_package)
	if style.is_empty():
		return default_style if default_style in ALL else WOODBLOCK
	return style


## Every style the player may switch to: each owned package's style (once each, in the order they were bought).
static func owned_styles(owned_package_ids: Array, packages_by_id: Callable) -> Array:
	var out: Array = []
	for package_id: Variant in owned_package_ids:
		var style := style_of(packages_by_id.call(str(package_id)))
		if not style.is_empty() and not out.has(style):
			out.append(style)
	return out


## The package that carries a style, or {}.
static func package_for(style: String, packages: Array) -> Dictionary:
	for package: Dictionary in packages:
		if style_of(package) == style:
			return package
	return {}


## The token rows from data/ui_styles.json as { style: { group: { token: value } } }.
static func index(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for row: Dictionary in rows:
		var style := str(row.get("style", ""))
		var group := str(row.get("group", ""))
		var token := str(row.get("token", ""))
		if style.is_empty() or token.is_empty():
			continue
		if not out.has(style):
			out[style] = {}
		if not (out[style] as Dictionary).has(group):
			(out[style] as Dictionary)[group] = {}
		((out[style] as Dictionary)[group] as Dictionary)[token] = str(row.get("value", ""))
	return out


## One token's text, or `fallback` when the style or token is missing.
static func token(idx: Dictionary, style: String, group: String, name: String, fallback: String = "") -> String:
	var groups: Variant = idx.get(style)
	if groups is Dictionary and (groups as Dictionary).get(group) is Dictionary:
		var value: Variant = ((groups as Dictionary)[group] as Dictionary).get(name)
		if value != null:
			return str(value)
	return fallback


## A colour token as a Color. "party colour" and anything unreadable give `fallback`.
static func colour(idx: Dictionary, style: String, name: String, fallback: Color = Color.MAGENTA) -> Color:
	var text := token(idx, style, "colour", name)
	if text.begins_with("#") and text.length() == 7:
		return Color.html(text)
	return fallback


## A size token (points, or px for radii) as a number; `fallback` when missing.
static func number(idx: Dictionary, style: String, group: String, name: String, fallback: float = 0.0) -> float:
	var text := token(idx, style, group, name)
	return text.to_float() if text.is_valid_float() else fallback


## The colour the plate behind text takes, and the ink on it, per style.
## Living Office and Broadcast are dark rooms (light ink on dark plates);
## Woodblock is a light page (dark ink on paper plaques).
static func plate_colour(idx: Dictionary, style: String) -> Color:
	if style == WOODBLOCK:
		return colour(idx, style, "plaque", Color(0.97, 0.94, 0.88))
	return colour(idx, style, "panel", Color(0.17, 0.11, 0.07))


static func plate_ink(idx: Dictionary, style: String) -> Color:
	if style == WOODBLOCK:
		return colour(idx, style, "ink", Color(0.11, 0.10, 0.09))
	return colour(idx, style, "ink_on_dark", Color(1, 0.97, 0.92))


## The colour behind a whole screen where no picture covers it.
static func ground_colour(idx: Dictionary, style: String) -> Color:
	return colour(idx, style, "ground", Color(0.08, 0.06, 0.04))
