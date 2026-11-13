class_name MoveFlash
extends RefCounted
## The small flash behind a character when they make a move (Cameron,
## 2026-11-13). Pure: the settings are rows of the workbook's Move Flashes tab
## (data/move_flashes.json), the colour of "the character" is handed in.
##
## A row says, for one side ("player" or "opponent") and one move (attack,
## gain, guard, hit, defeat, victory): the colour (blank = the character's own
## Characters-list colour, or "R, G, B" 0-255), how many pixels the glow
## reaches beyond the character, its strength (0-1), how long it holds at full
## strength and how long it takes to fade. More variety later is more rows.

const SIDES := ["player", "opponent"]
const MOVES := ["attack", "gain", "guard", "hit", "defeat", "victory"]

## The art expression each move goes with; "neutral" has no flash.
const MOVE_FOR_EXPRESSION := {
	"attacking": "attack", "gaining": "gain", "guarding": "guard",
	"damaged": "hit", "defeated": "defeat", "victory": "victory",
}


## The move an expression shows, or "" (a neutral face flashes nothing).
static func move_for_expression(expression: String) -> String:
	return str(MOVE_FOR_EXPRESSION.get(expression, ""))


## The row for a side and move, or {} when the tab has none.
static func row_for(rows: Array, side: String, move: String) -> Dictionary:
	for row: Variant in rows:
		if row is Dictionary and str((row as Dictionary).get("side", "")) == side \
				and str((row as Dictionary).get("move", "")) == move:
			return row as Dictionary
	return {}


## "R, G, B" (0-255) as a colour; null for a blank or unreadable cell.
static func parse_colour(text: Variant) -> Variant:
	if text == null:
		return null
	var parts := str(text).split(",", false)
	if parts.size() != 3:
		return null
	for part: String in parts:
		if not part.strip_edges().is_valid_int():
			return null
	return Color(int(parts[0]) / 255.0, int(parts[1]) / 255.0, int(parts[2]) / 255.0)


## What to play for this expression, or {} for none:
## { color, width, strength, hold, fade }.
static func plan(rows: Array, side: String, expression: String, character_colour: Color) -> Dictionary:
	var move := move_for_expression(expression)
	if move.is_empty():
		return {}
	var row := row_for(rows, side, move)
	if row.is_empty():
		return {}
	var colour: Color = character_colour
	var own: Variant = parse_colour(row.get("colour"))
	if own is Color:
		colour = own
	var width := float(row.get("width_px", 0) if row.get("width_px") != null else 0)
	var strength := clampf(float(row.get("strength", 0) if row.get("strength") != null else 0), 0.0, 1.0)
	if width <= 0.0 or strength <= 0.0:
		return {}
	return {
		"color": colour, "width": width, "strength": strength,
		"hold": maxf(float(row.get("hold_seconds", 0) if row.get("hold_seconds") != null else 0), 0.0),
		"fade": maxf(float(row.get("fade_seconds", 0) if row.get("fade_seconds") != null else 0), 0.01),
	}
