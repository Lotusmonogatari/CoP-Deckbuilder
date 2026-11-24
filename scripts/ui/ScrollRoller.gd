class_name ScrollRoller
extends Control
## One roller of a scroll (P18): a wooden or gold bar with a lit and a shaded band and a cap at each end. Vertical rollers sit at the
## ends of a closed scroll in the Codex list; horizontal ones sit above and below an unrolled document. Draws itself from the
## style's scroll tokens (ScrollStyle) and nothing else.

var vertical := false
## True for a roller of a document not yet found: the colours are dulled.
var dim := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var cap_long := ScrollStyle.len_px(5.0)       # how far a cap reaches along the bar
	var overhang := ScrollStyle.len_px(2.0)       # how far a cap stands beyond the bar's sides
	var mid := _tone(ScrollStyle.colour("roller_mid"))
	var lit := _tone(ScrollStyle.colour("roller_top"))
	var shade := _tone(ScrollStyle.colour("roller_bottom"))
	var cap := _tone(ScrollStyle.colour("cap"))
	var radius := int(ScrollStyle.number("roller_radius_px", 0.0) * LevelBriefingStyles.S)
	var bar := Rect2(Vector2.ZERO, size)
	if vertical:
		bar = Rect2(Vector2(0.0, 0.0), Vector2(size.x, size.y)).grow_individual(-0.0, -overhang, 0.0, -overhang)
	else:
		bar = Rect2(Vector2.ZERO, size).grow_individual(-overhang, 0.0, -overhang, 0.0)
	var box := StyleBoxFlat.new()
	box.bg_color = mid
	box.set_corner_radius_all(radius)
	draw_style_box(box, bar)
	var band := StyleBoxFlat.new()
	band.set_corner_radius_all(radius)
	# A lit band along the top (or left) edge and a shaded band along the bottom (or right) edge.
	if vertical:
		band.bg_color = lit
		draw_style_box(band, Rect2(bar.position + Vector2(bar.size.x * 0.12, 0.0), Vector2(bar.size.x * 0.22, bar.size.y)))
		band.bg_color = shade
		draw_style_box(band, Rect2(bar.position + Vector2(bar.size.x * 0.66, 0.0), Vector2(bar.size.x * 0.22, bar.size.y)))
		draw_rect(Rect2(0.0, 0.0, size.x, cap_long), cap)
		draw_rect(Rect2(0.0, size.y - cap_long, size.x, cap_long), cap)
	else:
		band.bg_color = lit
		draw_style_box(band, Rect2(bar.position + Vector2(0.0, bar.size.y * 0.12), Vector2(bar.size.x, bar.size.y * 0.22)))
		band.bg_color = shade
		draw_style_box(band, Rect2(bar.position + Vector2(0.0, bar.size.y * 0.66), Vector2(bar.size.x, bar.size.y * 0.22)))
		draw_rect(Rect2(0.0, 0.0, cap_long, size.y), cap)
		draw_rect(Rect2(size.x - cap_long, 0.0, cap_long, size.y), cap)


func _tone(colour: Color) -> Color:
	return colour.lerp(Color(0.55, 0.52, 0.48), 0.6) if dim else colour
