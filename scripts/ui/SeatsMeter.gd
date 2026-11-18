class_name SeatsMeter
extends RefCounted
## Living Office's support count (P9, 2026-11-17): the room's people as seats in a
## semicircle, or, where the count is not a head count, a continuous arc that fills
## like the regular bar.
##
## SEATS are for a room of discrete people (a floor debate, a committee). The count
## is a Balance row ("UI Style: Seat Count", 20) in two rows (outer share another
## row), filled left to right: yours, then undecided, then the opponent's, each seat
## standing for an equal share of the room's maximum and rounded to the nearest seat.
## The exact numbers are always printed beside it by SupportBar's readout.
##
## THE ARC is for a count that is not a person or a vote: the press tone, a percentage
## (the caucus). It is one band from left to right, filled in proportion, so the
## picture is true whatever the unit.
##
## Pure drawing: the caller passes the numbers. Nothing here decides anything.

const SEAT_RADIUS_OUTER := 17.0
const SEAT_RADIUS_INNER := 14.0
const ARC_WIDTH := 34.0
const OUTLINE := Color(0.0, 0.0, 0.0, 0.35)


## Seat counts for the player, undecided and opponent, always adding up to `seats`.
static func seat_split(maximum: int, player: int, opponent: int, seats: int) -> Dictionary:
	var count := maxi(seats, 1)
	var scale := float(count) / float(maxi(maximum, 1))
	var yours := clampi(roundi(float(player) * scale), 0, count)
	var theirs := clampi(roundi(float(opponent) * scale), 0, count - yours)
	return {"player": yours, "undecided": count - yours - theirs, "opponent": theirs}


## Where each seat sits: an array of { angle, ring } sorted from the far left round to
## the far right (ties: outer ring first), so "filled left to right" is array order.
static func seat_positions(seats: int, outer_percent: int) -> Array:
	var count := maxi(seats, 1)
	var outer := clampi(roundi(float(count) * float(outer_percent) / 100.0), 0, count)
	var inner := count - outer
	var out: Array = []
	for ring: Array in [[0, outer], [1, inner]]:
		var n: int = ring[1]
		for k in n:
			out.append({"angle": PI - (float(k) + 0.5) * PI / float(n), "ring": ring[0]})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["angle"]), float(b["angle"])):
			return float(a["angle"]) > float(b["angle"])
		return int(a["ring"]) < int(b["ring"]))
	return out


## The height the meter needs for a given width: a semicircle plus its rim.
static func height_for(width: float) -> float:
	return minf(width * 0.5, 300.0) + 24.0


## Draws the seats into `canvas` inside `rect`.
static func draw_seats(canvas: Control, rect: Rect2, split: Dictionary, seats: int, outer_percent: int,
		colours: Dictionary, mark: float = -1.0, look: String = UiStyles.LIVING_OFFICE, trim: Dictionary = {}) -> void:
	var radius := minf(rect.size.x * 0.5 - SEAT_RADIUS_OUTER - 6.0, rect.size.y - SEAT_RADIUS_OUTER - 6.0)
	var centre := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 8.0)
	var inner_radius := radius * 0.66
	var order := seat_positions(seats, outer_percent)
	var yours := int(split["player"])
	var undecided := int(split["undecided"])
	for i in order.size():
		var seat: Dictionary = order[i]
		var colour: Color = colours["player"] if i < yours else (colours["undecided"] if i < yours + undecided else colours["opponent"])
		var outer: bool = int(seat["ring"]) == 0
		var r := radius if outer else inner_radius
		var pos := centre + Vector2(cos(float(seat["angle"])), -sin(float(seat["angle"]))) * r
		var seat_r := SEAT_RADIUS_OUTER if outer else SEAT_RADIUS_INNER
		if look == UiStyles.BROADCAST:
			# Broadcast: an angular seat (a diamond) edged in gold.
			var reach := seat_r * 1.2
			var diamond := PackedVector2Array([pos + Vector2(0, -reach), pos + Vector2(reach, 0), pos + Vector2(0, reach), pos + Vector2(-reach, 0)])
			canvas.draw_colored_polygon(diamond, colour)
			var edge := PackedVector2Array(diamond)
			edge.append(diamond[0])
			canvas.draw_polyline(edge, trim.get("gold", Color(0.89, 0.7, 0.25)), 2.5, true)
		elif look == UiStyles.WOODBLOCK:
			# Woodblock: a printed disc with an ink edge and a vermilion offset shadow.
			canvas.draw_circle(pos + Vector2(3, 3), seat_r + 2.0, trim.get("shadow", Color(0.76, 0.23, 0.13)))
			canvas.draw_circle(pos, seat_r + 2.0, trim.get("ink", Color(0.11, 0.1, 0.09)))
			canvas.draw_circle(pos, seat_r - 1.0, colour)
		else:
			# The ring round a seat follows the seat's colour: dark round a light seat, light round a dark one
			# (IconBacking's rule), so every seat reads against what it touches.
			var ring := IconBacking.backing_for(IconBacking.luminance(colour))
			canvas.draw_circle(pos, seat_r + 4.0, Color(ring.r, ring.g, ring.b, 0.95))
			canvas.draw_circle(pos, seat_r, colour)
	# The threshold: a short line across both rows between the seat that reaches it and the next
	# (0 to 1 of the way round). Review of P9, finding 4: the seats had no mark at the line to cross.
	if mark >= 0.0 and mark <= 1.0:
		var a := PI - mark * PI
		var dir := Vector2(cos(a), -sin(a))
		canvas.draw_line(centre + dir * (inner_radius - SEAT_RADIUS_OUTER - 4.0), centre + dir * (radius + SEAT_RADIUS_OUTER + 8.0),
			Color(1, 1, 1, 0.95), 4.0)


## Draws the continuous arc: one band, filled left to right in proportion.
## `parts` is [[amount, colour], ...] and `maximum` the whole.
static func draw_arc_band(canvas: Control, rect: Rect2, parts: Array, maximum: float, colours: Dictionary,
		mark: float = -1.0, look: String = UiStyles.LIVING_OFFICE, trim: Dictionary = {}) -> void:
	var radius := minf(rect.size.x * 0.5 - ARC_WIDTH, rect.size.y - ARC_WIDTH * 0.5 - 8.0)
	var centre := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 8.0)
	var mid := radius - ARC_WIDTH * 0.5
	if look != UiStyles.LIVING_OFFICE:
		_draw_styled_band(canvas, centre, radius, parts, maximum, mark, look, trim)
		return
	# The unfilled track first.
	canvas.draw_arc(centre, mid, PI, TAU, 64, OUTLINE, ARC_WIDTH + 4.0, true)
	var cursor := 0.0
	for part: Array in parts:
		var amount := maxf(float(part[0]), 0.0)
		if amount <= 0.0 or maximum <= 0.0:
			continue
		var from := PI + (cursor / maximum) * PI
		var to := PI + (minf(cursor + amount, maximum) / maximum) * PI
		canvas.draw_arc(centre, mid, from, to, maxi(int((to - from) * 24.0), 2), part[1], ARC_WIDTH, true)
		cursor += amount
	if mark >= 0.0 and mark <= 1.0:
		var a := PI + mark * PI
		var dir := Vector2(cos(a), sin(a))
		canvas.draw_line(centre + dir * (mid - ARC_WIDTH * 0.7), centre + dir * (mid + ARC_WIDTH * 0.7), Color(1, 1, 1, 0.95), 4.0)


# ---------------------------------------------------------------- Broadcast and Woodblock arcs

## Broadcast cuts the arc into straight facets with slanted divisions and edges it in gold along the outer and
## inner rims (the bar's gold top and bottom). Woodblock prints it: a smooth band with an ink edge and a
## vermilion offset shadow. Both are the same half-ring as the Living Office arc, so every layout is shared.
const BROADCAST_FACETS := 9
const SMOOTH_FACETS := 64
## How far the inner end of a Broadcast division leans against its outer end (the bar's "/" slant), in radians.
const BROADCAST_LEAN := 0.15


static func _draw_styled_band(canvas: Control, centre: Vector2, radius: float, parts: Array, maximum: float,
		mark: float, look: String, trim: Dictionary) -> void:
	var angular := look == UiStyles.BROADCAST
	var facets := BROADCAST_FACETS if angular else SMOOTH_FACETS
	var inner := radius - ARC_WIDTH
	var lean := BROADCAST_LEAN if angular else 0.0
	var gold: Color = trim.get("gold", Color(0.89, 0.7, 0.25))
	var ink: Color = trim.get("ink", Color(0.11, 0.1, 0.09))
	var shadow: Color = trim.get("shadow", Color(0.76, 0.23, 0.13))
	# Woodblock: the whole band's offset shadow, under everything.
	if not angular:
		canvas.draw_colored_polygon(_band(centre + Vector2(6, 6), inner, radius, PI, TAU, facets, 0.0), shadow)
	# The unfilled track.
	canvas.draw_colored_polygon(_band(centre, inner, radius, PI, TAU, facets, lean), OUTLINE if angular else Color(ink.r, ink.g, ink.b, 0.25))
	var cursor := 0.0
	for part: Array in parts:
		var amount := maxf(float(part[0]), 0.0)
		if amount <= 0.0 or maximum <= 0.0:
			continue
		var from := PI + (cursor / maximum) * PI
		var to := PI + (minf(cursor + amount, maximum) / maximum) * PI
		canvas.draw_colored_polygon(_band(centre, inner, radius, from, to, facets, lean), part[1])
		cursor += amount
	if angular:
		# Gold along the outer and inner rims only, none on the ends.
		canvas.draw_polyline(_rim(centre, radius, facets), gold, 4.0, true)
		canvas.draw_polyline(_rim_between(centre, inner, PI + lean, TAU - lean, facets), gold, 4.0, true)
	else:
		# An ink edge all round, and a thin ink line where one share meets the next.
		var outline := _rim(centre, radius, facets)
		var back := _rim(centre, inner, facets)
		back.reverse()
		outline.append_array(back)
		outline.append(outline[0])
		canvas.draw_polyline(outline, ink, 3.0, true)
		var edge := 0.0
		for i in parts.size() - 1:
			edge += maxf(float(parts[i][0]), 0.0)
			if edge <= 0.0 or edge >= maximum:
				continue
			var a := PI + (edge / maximum) * PI
			canvas.draw_line(centre + Vector2(cos(a), sin(a)) * inner, centre + Vector2(cos(a), sin(a)) * radius, ink, 2.0)
	if mark >= 0.0 and mark <= 1.0:
		var a2 := PI + mark * PI
		var dir := Vector2(cos(a2), sin(a2))
		canvas.draw_line(centre + dir * (inner - 12.0), centre + dir * (radius + 12.0),
			Color(1, 1, 1, 0.95) if angular else ink, 4.0)


## The facet-grid vertices of a half-ring rim at `r`, from the far left to the far right.
static func _rim(centre: Vector2, r: float, facets: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in facets + 1:
		var a := PI + float(k) * PI / float(facets)
		points.append(centre + Vector2(cos(a), sin(a)) * r)
	return points


## The faceted rim at `r` from angle `a0` to `a1` (the ends sit exactly on the edge).
static func _rim_between(centre: Vector2, r: float, a0: float, a1: float, facets: int) -> PackedVector2Array:
	var step := PI / float(facets)
	var points := PackedVector2Array()
	points.append(_rim_point(centre, r, a0, facets))
	var k := ceili((a0 - PI) / step + 0.0001)
	while PI + float(k) * step < a1 - 0.0001:
		var a := PI + float(k) * step
		points.append(centre + Vector2(cos(a), sin(a)) * r)
		k += 1
	points.append(_rim_point(centre, r, a1, facets))
	return points


## The point on the faceted rim at angle `a`: on the straight chord between its two grid vertices, so a
## division always sits exactly on the drawn edge.
static func _rim_point(centre: Vector2, r: float, a: float, facets: int) -> Vector2:
	var step := PI / float(facets)
	var k := clampi(floori((a - PI) / step), 0, facets - 1)
	var a0 := PI + float(k) * step
	var p0 := centre + Vector2(cos(a0), sin(a0)) * r
	var p1 := centre + Vector2(cos(a0 + step), sin(a0 + step)) * r
	return p0.lerp(p1, clampf((a - a0) / step, 0.0, 1.0))


## A piece of the half-ring from angle `from` to `to`; the inner edge leans by `lean` radians.
static func _band(centre: Vector2, inner: float, outer: float, from: float, to: float, facets: int, lean: float) -> PackedVector2Array:
	var step := PI / float(facets)
	var pts := PackedVector2Array()
	pts.append(_rim_point(centre, outer, from, facets))
	var k := ceili((from - PI) / step + 0.0001)
	while PI + float(k) * step < to - 0.0001:
		var a := PI + float(k) * step
		pts.append(centre + Vector2(cos(a), sin(a)) * outer)
		k += 1
	pts.append(_rim_point(centre, outer, to, facets))
	# The inner edge back again, leaning.
	# Inner edges lean the same way inside the band; at the band's two ends they lean toward each other, so the
	# left and right feet are mirror images (the right end used to run flat against the clamp).
	var from_in := PI + lean if from <= PI + 0.0001 and lean > 0.0 else clampf(from + lean, PI, TAU)
	var to_in := TAU - lean if to >= TAU - 0.0001 and lean > 0.0 else clampf(to + lean, PI, TAU)
	pts.append(_rim_point(centre, inner, to_in, facets))
	var j := floori((to_in - PI) / step - 0.0001)
	while PI + float(j) * step > from_in + 0.0001:
		var b := PI + float(j) * step
		pts.append(centre + Vector2(cos(b), sin(b)) * inner)
		j -= 1
	pts.append(_rim_point(centre, inner, from_in, facets))
	return pts
