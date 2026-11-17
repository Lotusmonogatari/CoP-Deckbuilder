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
		colours: Dictionary) -> void:
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
		canvas.draw_circle(pos, seat_r + 2.0, OUTLINE)
		canvas.draw_circle(pos, seat_r, colour)


## Draws the continuous arc: one band, filled left to right in proportion.
## `parts` is [[amount, colour], ...] and `maximum` the whole.
static func draw_arc_band(canvas: Control, rect: Rect2, parts: Array, maximum: float, colours: Dictionary,
		mark: float = -1.0) -> void:
	var radius := minf(rect.size.x * 0.5 - ARC_WIDTH, rect.size.y - ARC_WIDTH * 0.5 - 8.0)
	var centre := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 8.0)
	var mid := radius - ARC_WIDTH * 0.5
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
