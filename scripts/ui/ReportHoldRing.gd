class_name ReportHoldRing
extends Control
## The ring that fills while a tester holds the problem-report gesture (2026-11-19): without it, two
## seconds of holding three fingers down would look like nothing is happening. It appears after a short
## moment, so an ordinary touch never flashes it, and it never takes a touch itself.

## Fills from 0 to 1 as the hold nears its time.
var progress := 0.0
## Where it is drawn (screen coordinates).
var centre := Vector2.ZERO
var caption := ""

const SHOW_AFTER := 0.12
const RADIUS := 96.0
const WIDTH := 16.0
const BACK := Color(0.05, 0.05, 0.08, 0.72)
const TRACK := Color(1, 1, 1, 0.25)
const FILL := Color(0.89, 0.7, 0.25, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


## Called every frame while a hold is in progress.
func show_progress(value: float, at: Vector2, words: String) -> void:
	progress = value
	centre = at
	caption = words
	visible = value > SHOW_AFTER
	queue_redraw()


func hide_ring() -> void:
	progress = 0.0
	visible = false


func _draw() -> void:
	draw_circle(centre, RADIUS + WIDTH, BACK)
	draw_arc(centre, RADIUS, 0.0, TAU, 64, TRACK, WIDTH, true)
	draw_arc(centre, RADIUS, -PI * 0.5, -PI * 0.5 + TAU * progress, 64, FILL, WIDTH, true)
	if caption.is_empty():
		return
	var font := get_theme_default_font()
	var size := 34
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var left := clampf(centre.x - width * 0.5, 24.0, maxf(size_of_view().x - width - 24.0, 24.0))
	var top := centre.y + RADIUS + WIDTH + 56.0
	draw_rect(Rect2(left - 18.0, top - size - 8.0, width + 36.0, size + 28.0), BACK)
	draw_string(font, Vector2(left, top), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


func size_of_view() -> Vector2:
	return get_viewport_rect().size
