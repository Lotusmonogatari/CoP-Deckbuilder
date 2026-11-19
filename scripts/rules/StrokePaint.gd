class_name StrokePaint
extends RefCounted
## Paints a tester's circle onto a screenshot (2026-11-19): the "marked" picture saved with a problem
## report. A stroke is a list of points in screen coordinates; the picture may be a different size
## (a phone renders at its own resolution), so `scale` is picture pixels per screen unit.
##
## Each stroke is drawn twice, a wide pale line under a narrower red one, so it reads on both dark and
## light screens. Square dabs along each segment: plain, and fast enough for a few hundred points.

const OUTLINE := Color(1, 1, 1, 0.9)
const INK := Color(0.93, 0.17, 0.12, 1.0)
## Half-widths in screen units.
const OUTLINE_RADIUS := 8.0
const INK_RADIUS := 4.5


## Draws `strokes` (Array of PackedVector2Array) onto `image` in place and returns it.
static func paint(image: Image, strokes: Array, scale: float) -> Image:
	if image == null or image.is_empty():
		return image
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	for pass_index in 2:
		var radius := (OUTLINE_RADIUS if pass_index == 0 else INK_RADIUS) * scale
		var colour := OUTLINE if pass_index == 0 else INK
		for stroke: Variant in strokes:
			_dab_line(image, stroke as PackedVector2Array, scale, radius, colour)
	return image


static func _dab_line(image: Image, points: PackedVector2Array, scale: float, radius: float, colour: Color) -> void:
	if points.is_empty():
		return
	var step := maxf(radius * 0.6, 1.0)
	var previous := points[0] * scale
	_dab(image, previous, radius, colour)
	for index in range(1, points.size()):
		var next := points[index] * scale
		var length := previous.distance_to(next)
		var count := maxi(int(ceil(length / step)), 1)
		for part in range(1, count + 1):
			_dab(image, previous.lerp(next, float(part) / float(count)), radius, colour)
		previous = next


static func _dab(image: Image, centre: Vector2, radius: float, colour: Color) -> void:
	var size := Vector2i(maxi(int(round(radius * 2.0)), 1), maxi(int(round(radius * 2.0)), 1))
	var corner := Vector2i(int(round(centre.x - radius)), int(round(centre.y - radius)))
	var area := Rect2i(corner, size).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if area.size.x > 0 and area.size.y > 0:
		image.fill_rect(area, colour)


## The box around everything drawn (screen units), or an empty Rect2 when nothing was.
static func bounds(strokes: Array) -> Rect2:
	var box := Rect2()
	var first := true
	for stroke: Variant in strokes:
		for point: Vector2 in (stroke as PackedVector2Array):
			if first:
				box = Rect2(point, Vector2.ZERO)
				first = false
			else:
				box = box.expand(point)
	return box
