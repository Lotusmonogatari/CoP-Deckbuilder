class_name StyleMarks
extends Control
## Small drawn marks a style puts on its screens (P9 review, 2026-11-17): the folder and chevron of the
## docket card, the red kanji seal, the gold diagonal. Drawn, not text, so they carry no words (the
## same-information rule) and need no art. Kinds: FOLDER, CHEVRON, SEAL (a vermilion square with a
## kanji), DIAGONAL (a thin gold slanted line across its rect).

enum Kind { FOLDER, CHEVRON, SEAL, DIAGONAL, LEADER, DASHED_FRAME, CURL, WAVES, TAIL, FRAME, CUTINS }

var kind := Kind.FOLDER
var colour := Color(1, 1, 1)
var back := Color(0.1, 0.1, 0.1)
var glyph := ""


static func make(kind_in: Kind, colour_in: Color, size_in: Vector2, back_in: Color = Color.TRANSPARENT, glyph_in: String = "") -> StyleMarks:
	var m := StyleMarks.new()
	m.kind = kind_in
	m.colour = colour_in
	m.back = back_in
	m.glyph = glyph_in
	m.custom_minimum_size = size_in
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func set_glyph(value: String) -> void:
	glyph = value
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match kind:
		Kind.FOLDER:
			var box := StyleBoxFlat.new()
			box.bg_color = back
			box.set_corner_radius_all(16)
			draw_style_box(box, r)
			var w := r.size.x * 0.52
			var h := r.size.y * 0.38
			var o := r.get_center() - Vector2(w, h) * 0.5 + Vector2(0, 4)
			draw_rect(Rect2(o + Vector2(0, -h * 0.28), Vector2(w * 0.42, h * 0.3)), colour)
			draw_rect(Rect2(o, Vector2(w, h)), colour)
		Kind.CHEVRON:
			var c := r.get_center()
			var s := minf(r.size.x, r.size.y) * 0.28
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.5, -s), c + Vector2(s * 0.5, 0), c + Vector2(-s * 0.5, s)]), colour, 6.0, true)
		Kind.SEAL:
			# A paper border round the vermilion, so a seal stands out even on a red tag.
			draw_rect(r, colour)
			draw_rect(r.grow(-4), back)
			var font: Font = ThemeDB.fallback_font
			var theme_font := get_theme_default_font()
			if theme_font != null:
				font = theme_font
			var fs := int(minf(r.size.x, r.size.y) * 0.62)
			var ts := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, Vector2((r.size.x - ts.x) * 0.5, (r.size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5), glyph,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
		Kind.LEADER:
			# A row of dots along the baseline: the leader of a ledger line.
			var x := 6.0
			while x < r.size.x - 4.0:
				draw_circle(Vector2(x, r.size.y - 9.0), 2.0, colour)
				x += 12.0
		Kind.DASHED_FRAME:
			# A dashed rounded frame: dashes along the four sides, a small arc at each corner.
			var rad := minf(18.0, minf(r.size.x, r.size.y) * 0.5)
			var inset := r.grow(-2.0)
			var a := inset.position + Vector2(rad, 0)
			var b := Vector2(inset.end.x - rad, inset.position.y)
			var c := Vector2(inset.end.x, inset.position.y + rad)
			var d := Vector2(inset.end.x, inset.end.y - rad)
			var e := Vector2(inset.end.x - rad, inset.end.y)
			var f := Vector2(inset.position.x + rad, inset.end.y)
			var g := Vector2(inset.position.x, inset.end.y - rad)
			var h := Vector2(inset.position.x, inset.position.y + rad)
			for edge: Array in [[a, b], [c, d], [e, f], [g, h]]:
				draw_dashed_line(edge[0], edge[1], colour, 4.0, 16.0, true)
			draw_arc(Vector2(inset.end.x - rad, inset.position.y + rad), rad, -PI * 0.5, 0.0, 8, colour, 4.0, true)
			draw_arc(Vector2(inset.end.x - rad, inset.end.y - rad), rad, 0.0, PI * 0.5, 8, colour, 4.0, true)
			draw_arc(Vector2(inset.position.x + rad, inset.end.y - rad), rad, PI * 0.5, PI, 8, colour, 4.0, true)
			draw_arc(Vector2(inset.position.x + rad, inset.position.y + rad), rad, PI, PI * 1.5, 8, colour, 4.0, true)
		Kind.CURL:
			# A page's curled bottom-right corner, drawn in the last 46 px of a control that fills the
			# page (a panel stretches its children, so the mark finds its own corner): a soft shadow, the
			# turned-up corner in `back`, and the fold line.
			var c := 46.0
			var o := Vector2(size.x - c, size.y - c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(c, 0), o + Vector2(c, c), o + Vector2(0, c)]), Color(0, 0, 0, 0.16))
			draw_colored_polygon(PackedVector2Array([o + Vector2(c * 0.15, c * 0.15), o + Vector2(c, c * 0.15), o + Vector2(c * 0.15, c)]), back)
			draw_line(o + Vector2(c, c * 0.15), o + Vector2(c * 0.15, c), colour, 2.0, true)
		Kind.FRAME:
			# A framed print: an indigo frame, a paper mat inside it and a red offset shadow, round the
			# upper part of the control. The lower edge is left short so a character drawn over it
			# breaks the frame, as figures do in a print. The inside is clear: the picture shows through.
			var frame := Rect2(24.0, 10.0, size.x - 48.0, size.y * 0.8)
			var shadow := frame.grow(2.0)
			shadow.position += Vector2(9, 9)
			draw_rect(shadow, Color(back.r, back.g, back.b, 0.8), false, 5.0)
			draw_rect(frame, colour, false, 9.0)
			draw_rect(frame.grow(-9.0), Color(0.97, 0.94, 0.88, 0.9), false, 7.0)
		Kind.CUTINS:
			# Broadcast's two cut-in shots: a slanted panel behind each character (`colour` on the left,
			# `back` on the right), divided by a thin gold diagonal, each with a gold rule top and bottom.
			var mid := r.size.x * 0.5
			var lean := SlantBar.SLANT * r.size.y
			var gold := Color(0.89, 0.7, 0.25)
			var left := PackedVector2Array([Vector2(0, 0), Vector2(mid + lean * 0.5, 0), Vector2(mid - lean * 0.5, r.size.y), Vector2(0, r.size.y)])
			var right := PackedVector2Array([Vector2(mid + lean * 0.5, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y), Vector2(mid - lean * 0.5, r.size.y)])
			draw_colored_polygon(left, Color(colour.r, colour.g, colour.b, 0.34))
			draw_colored_polygon(right, Color(back.r, back.g, back.b, 0.34))
			draw_line(Vector2(0, 2), Vector2(mid + lean * 0.5, 2), gold, 4.0)
			draw_line(Vector2(mid + lean * 0.5, 2), Vector2(r.size.x, 2), gold, 4.0)
			draw_line(Vector2(0, r.size.y - 2), Vector2(mid - lean * 0.5, r.size.y - 2), gold, 4.0)
			draw_line(Vector2(mid - lean * 0.5, r.size.y - 2), Vector2(r.size.x, r.size.y - 2), gold, 4.0)
			draw_line(Vector2(mid + lean * 0.5, 0), Vector2(mid - lean * 0.5, r.size.y), gold, 5.0, true)
		Kind.TAIL:
			# A speech bubble's tail: a small triangle just above the top edge of the control that
			# fills the bubble, pointing up toward the speaker, in the bubble's own fill.
			var tx := size.x * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(tx - 30.0, 2.0), Vector2(tx + 30.0, 2.0), Vector2(tx + 6.0, -34.0)]), back)
		Kind.WAVES:
			# Seigaiha: rows of overlapping concentric half-circles, the wave pattern of a printed Yezo.
			var radius := 30.0
			var row_h := radius * 0.5
			var y := r.size.y + radius
			var row := 0
			while y > -radius:
				var x := -radius * (1.0 if row % 2 == 0 else 0.0)
				while x < r.size.x + radius:
					for k in 3:
						draw_arc(Vector2(x, y), radius - float(k) * 8.0, PI, TAU, 18, colour, 2.0, true)
					x += radius * 2.0
				y -= row_h
				row += 1
		Kind.DIAGONAL:
			var slant := SlantBar.SLANT * r.size.y
			draw_line(Vector2(r.size.x * 0.5 + slant * 0.5, 0), Vector2(r.size.x * 0.5 - slant * 0.5, r.size.y), colour, 5.0, true)


## Woodblock's wave band (P9 review): a seigaiha pattern along the foot of a screen. A drawn control
## that fills `width` of the bottom edge, `above` pixels up from it; it takes no touches and has no words.
static func add_wave_band(screen: Control, above: float = 0.0, height: float = 64.0) -> void:
	if UiStyle.current() != UiStyles.WOODBLOCK or screen.has_node("WaveBand"):
		return
	var indigo := UiStyle.colour("indigo", Color(0.13, 0.19, 0.35))
	var band := StyleMarks.make(Kind.WAVES, Color(indigo.r, indigo.g, indigo.b, 0.5), Vector2.ZERO)
	band.name = "WaveBand"
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -(above + height)
	band.offset_bottom = -above
	screen.add_child(band)
	# Behind the screen's own content (its Safe column), so a button or a line of text is never covered.
	var safe := screen.get_node_or_null("Safe")
	screen.move_child(band, safe.get_index() if safe != null else 0)


## Woodblock's framed print round a character area (P9 review). Drawn first, so the characters lie over it.
static func add_print_frame(area: Control) -> void:
	if UiStyle.current() != UiStyles.WOODBLOCK or area.has_node("PrintFrame"):
		return
	var frame := StyleMarks.make(Kind.FRAME, UiStyle.colour("indigo", Color(0.13, 0.19, 0.35)), Vector2.ZERO,
		UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13)))
	frame.name = "PrintFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.add_child(frame)
	area.move_child(frame, 0)
