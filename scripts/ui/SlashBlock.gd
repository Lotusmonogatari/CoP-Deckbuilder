class_name SlashBlock
extends Control
## A slanted ("slashed") block of colour with one line of text on it: used for
## the positive, neutral and negative results of a staff task (Cameron,
## 2026-11-16). The text is the whole message; the colour says which kind.

const SLANT := 34.0
const BORDER := 4.0

var fill := Color("#8a6a12")
var edge := Color("#e8c25a")
var _label: Label


## `text` is what the block says; `fill_colour` and `edge_colour` code its kind.
func setup(text: String, fill_colour: Color, edge_colour: Color) -> void:
	fill = fill_colour
	edge = edge_colour
	custom_minimum_size = Vector2(0, 100)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.text = text
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = SLANT + 12.0
	_label.offset_right = -(SLANT + 12.0)
	# The block is its own plate: no page plate behind the words.
	_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_label)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var points := PackedVector2Array([Vector2(SLANT, 0), Vector2(w, 0), Vector2(w - SLANT, h), Vector2(0, h)])
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), edge, BORDER, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
