@tool
class_name SlantBar
extends RefCounted
## The look the cue band gives a line, for the score bars (2026-11-05,
## Cameron): slanted sides at the band's own angle and a thin gold border along
## the top and bottom (none on the sides). SupportBar, VoteMeter and
## PartyVoteBar all draw through here so they match each other and the band.
##
## The slant is CueBanner's: its band shifts the top edge by 0.18 of its height
## against the bottom, leaning forward ("/") on the player's side. The bars lean
## that way too. A bar's rect is the box it fits inside: its top edge runs from
## x + offset to the right end, its bottom edge from x to (right end - offset),
## and every division inside it is a line at that same slant.

## The band's slant: horizontal shift per unit of height, top against bottom.
const SLANT := 0.18
const BORDER_COLOUR := CueBanner.EDGE_COLOUR


## How far the top edge sits to the right of the bottom edge.
static func offset(height: float) -> float:
	return SLANT * height


## Where the bottom edge of a division at `fraction` (0 to 1) across the bar
## sits; its top is `offset(height)` further right.
static func bottom_x(rect: Rect2, fraction: float) -> float:
	var slant := offset(rect.size.y)
	return rect.position.x + clampf(fraction, 0.0, 1.0) * (rect.size.x - slant)


## Draws the bar: coloured parts left to right, each [weight, colour] (a weight
## of 0 draws nothing), sized by weight out of `total` (the sum of the weights
## when 0), then the gold border strips over the top and bottom.
static func draw_parts(canvas: CanvasItem, rect: Rect2, parts: Array,
		border: float = 4.0, total: float = 0.0) -> void:
	for shape: Dictionary in shapes(rect, parts, border, total):
		canvas.draw_colored_polygon(shape["points"], shape["colour"])


## What draw_parts() paints, in order: [{ "points": PackedVector2Array,
## "colour": Color }], the coloured parts first and the two gold strips last.
## Separate so the geometry can be tested without a screen.
static func shapes(rect: Rect2, parts: Array, border: float = 4.0, total: float = 0.0) -> Array:
	var out: Array = []
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return out
	if total <= 0.0:
		for part: Array in parts:
			total += maxf(float(part[0]), 0.0)
	var slant := offset(rect.size.y)
	var y_top := rect.position.y
	var y_bottom := rect.end.y
	var used := 0.0
	for part: Array in parts:
		var weight := maxf(float(part[0]), 0.0)
		if weight <= 0.0 or total <= 0.0:
			continue
		var from_x := bottom_x(rect, used / total)
		used += weight
		# A hair of overlap on the right, so neighbours never show a seam.
		var to_x := bottom_x(rect, used / total) + (0.0 if used >= total else 0.6)
		out.append({"colour": part[1], "points": PackedVector2Array([
			Vector2(from_x + slant, y_top), Vector2(to_x + slant, y_top),
			Vector2(to_x, y_bottom), Vector2(from_x, y_bottom)])})
	out.append_array(_border_shapes(rect, border))
	return out


## A line at the bar's slant, `fraction` of the way across, reaching `extend`
## past the top and bottom: the threshold, or the mark where a win begins.
static func draw_mark(canvas: CanvasItem, rect: Rect2, fraction: float,
		colour: Color, width: float, extend: float = 8.0) -> void:
	var bx := bottom_x(rect, fraction)
	var slant := offset(rect.size.y)
	var run := slant * extend / rect.size.y   # the slope carries on past the ends
	canvas.draw_line(Vector2(bx + slant + run, rect.position.y - extend),
		Vector2(bx - run, rect.end.y + extend), colour, width)


static func _border_shapes(rect: Rect2, border: float) -> Array:
	var height := rect.size.y
	var slant := offset(height)
	var inset := slant * border / height   # how far a slanted side moves across the border's thickness
	var x := rect.position.x
	var right := rect.end.x
	return [
		{"colour": BORDER_COLOUR, "points": PackedVector2Array([
			Vector2(x + slant, rect.position.y), Vector2(right, rect.position.y),
			Vector2(right - inset, rect.position.y + border), Vector2(x + slant - inset, rect.position.y + border)])},
		{"colour": BORDER_COLOUR, "points": PackedVector2Array([
			Vector2(x + inset, rect.end.y - border), Vector2(right - slant + inset, rect.end.y - border),
			Vector2(right - slant, rect.end.y), Vector2(x, rect.end.y)])},
	]
