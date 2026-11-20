class_name TravelStrip
extends Control
## The strip along the bottom of the Office that takes a trip (two offices, slice 2, 2026-11-20): a train on a track.
## Its words (where, how long, by what, and what it costs) are on the strip before anything is pressed. Drag the
## train along the track past the Balance row's share (about 60%) and let go to travel; short of that it springs
## back. A tap opens the same confirm instead, so the drag is the fast path and not the only one.
##
## It is drawn here (a placeholder train) until the TRAIN_STRIP picture is drawn. `text` and `disabled` behave like a
## Button's, so a greyed strip says why it cannot be used.

signal tapped
signal committed

const HEIGHT := 120.0
const TRAIN_W := 220.0
const TRAIN_H := 84.0
const NOSE := 28.0
const MARGIN := 18.0
const TAP_SLOP := 14.0
const SPRING_TIME := 0.25

var text: String = "":
	set(value):
		text = value
		if _label != null:
			_label.text = value
## A greyed strip ignores drags and taps.
var disabled: bool = false:
	set(value):
		disabled = value
		modulate.a = 0.6 if value else 1.0
## +1: the train sits at the left and is pulled to the right (Capitol to District); -1 the reverse.
var direction: int = 1:
	set(value):
		direction = 1 if value >= 0 else -1
		_layout_label()
		queue_redraw()

var _label: Label
var _progress := 0.0
var _pressing := false
var _dragging := false
var _press_x := 0.0
var _spring: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = Label.new()
	_label.name = "Words"
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_label.add_theme_color_override("font_color", UiStyle.colour("brief_ink", Color(0.1, 0.1, 0.1)))
	add_child(_label)
	resized.connect(_layout_label)
	_layout_label()


## The words keep to the side of the track the train is not on.
func _layout_label() -> void:
	if _label == null:
		return
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var train_side := TRAIN_W + NOSE + MARGIN
	if direction > 0:
		_label.offset_left = train_side
		_label.offset_right = -MARGIN
	else:
		_label.offset_left = MARGIN
		_label.offset_right = -train_side


## The length the train can travel.
func track_length() -> float:
	return maxf(0.0, size.x - 2.0 * MARGIN - TRAIN_W - NOSE)


## How far along the track the train is now (0 to 1).
func progress() -> float:
	return _progress


func _draw() -> void:
	var ink := UiStyle.colour("brief_ink", Color(0.1, 0.1, 0.1))
	var card := UiStyle.colour("brief_card", Color(1, 1, 1))
	var accent := UiStyle.colour("brief_accent", Color(0.9, 0.7, 0.2))
	var on_accent := UiStyle.colour("brief_on_accent", Color(0.1, 0.1, 0.1))
	var track := StyleBoxFlat.new()
	track.bg_color = card
	track.set_border_width_all(2)
	track.border_color = ink
	track.set_corner_radius_all(14)
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	# The train: a body, three windows and a nose that points the way it travels.
	var along := _progress * track_length()
	var x := MARGIN + along if direction > 0 else size.x - MARGIN - TRAIN_W - along
	var y := (size.y - TRAIN_H) * 0.5
	var body := StyleBoxFlat.new()
	body.bg_color = accent
	body.set_corner_radius_all(10)
	draw_style_box(body, Rect2(x, y, TRAIN_W, TRAIN_H))
	for i in 3:
		var window := Rect2(x + 18.0 + float(i) * 66.0, y + 16.0, 48.0, 28.0)
		draw_rect(window, Color(on_accent.r, on_accent.g, on_accent.b, 0.32))
	draw_rect(Rect2(x + 12.0, y + TRAIN_H - 18.0, TRAIN_W - 24.0, 6.0), Color(on_accent.r, on_accent.g, on_accent.b, 0.5))
	var nose: PackedVector2Array
	if direction > 0:
		nose = PackedVector2Array([Vector2(x + TRAIN_W, y + 10.0), Vector2(x + TRAIN_W + NOSE, y + TRAIN_H * 0.5), Vector2(x + TRAIN_W, y + TRAIN_H - 10.0)])
	else:
		nose = PackedVector2Array([Vector2(x, y + 10.0), Vector2(x - NOSE, y + TRAIN_H * 0.5), Vector2(x, y + TRAIN_H - 10.0)])
	draw_colored_polygon(nose, accent)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		if click.pressed:
			_begin(click.position.x)
		else:
			_end()
		accept_event()
	elif event is InputEventMouseMotion and _pressing:
		_drag((event as InputEventMouseMotion).position.x)
		accept_event()


func _begin(x: float) -> void:
	if _spring != null:
		_spring.kill()
	_pressing = true
	_dragging = false
	_press_x = x


func _drag(x: float) -> void:
	var moved := x - _press_x
	if not _dragging and Swipe.is_tap(moved, TAP_SLOP):
		return
	_dragging = true
	_progress = Swipe.progress(moved, track_length(), direction)
	queue_redraw()


func _end() -> void:
	if not _pressing:
		return
	_pressing = false
	if not _dragging:
		tapped.emit()
		return
	_dragging = false
	if Swipe.commits(_progress, Levers.num("travel_swipe_commit_percent") / 100.0):
		_progress = 0.0   # the card takes over; the strip is back at rest for the next office
		queue_redraw()
		committed.emit()
		return
	_spring_back()


func _spring_back() -> void:
	_spring = create_tween()
	_spring.tween_method(_set_progress, _progress, 0.0, SPRING_TIME)


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()
