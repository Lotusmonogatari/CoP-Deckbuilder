class_name StyleMarks
extends Control
## Small drawn marks a style puts on its screens (P9 review, 2026-11-17): the folder and chevron of the
## docket card, the red kanji seal, the gold diagonal. Drawn, not text, so they carry no words (the
## same-information rule) and need no art. Kinds: FOLDER, CHEVRON, SEAL (a vermilion square with a
## kanji), DIAGONAL (a thin gold slanted line across its rect).

enum Kind { FOLDER, CHEVRON, SEAL, DIAGONAL, LEADER, DASHED_FRAME }

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
		Kind.DIAGONAL:
			var slant := SlantBar.SLANT * r.size.y
			draw_line(Vector2(r.size.x * 0.5 + slant * 0.5, 0), Vector2(r.size.x * 0.5 - slant * 0.5, r.size.y), colour, 5.0, true)
