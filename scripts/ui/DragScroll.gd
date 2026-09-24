class_name DragScroll
extends Node
## Drag a list with a finger (or the mouse) to scroll it.
##
## Put one inside any ScrollContainer: `DragScroll.attach(scroll)`. A press
## anywhere over the list — on a button included — that then moves further
## than DRAG_START along the list's own direction scrolls it, and the button
## the finger started on is NOT pressed. A press that barely moves is an
## ordinary tap. Letting go mid-swipe keeps the list gliding for a moment.
##
## WHY NOT GODOT'S OWN
## ScrollContainer only drag-scrolls when the device reports a touchscreen,
## and a drag that starts on a button (every row of every shop here) goes to
## the button instead. This works the same on a desktop, a phone, and in the
## click tests, which is where it gets proved.
##
## A drag across the list's direction is left alone — in the hand, that is
## what lets a card be pulled upwards to play while sideways drags scroll.

## How far, in pixels, a press must travel before it counts as a drag. Big
## enough that a slightly shaky tap is still a tap.
const DRAG_START := 24.0

## How quickly a flung list slows down, per second (0 stops dead, 1 never).
const GLIDE_KEEP_PER_SECOND := 0.03

## The fastest a flung list may glide, in pixels per second.
const MAX_GLIDE := 2500.0

var _scroll: ScrollContainer
var _vertical := true

var _tracking := false
var _dragging := false
var _start := Vector2.ZERO
var _start_scroll := 0.0
var _last := Vector2.ZERO
var _velocity := 0.0
var _last_time := 0


## Makes `scroll` draggable along its scrolling direction. `vertical` false
## for a list that scrolls sideways, such as the hand.
static func attach(scroll: ScrollContainer, vertical: bool = true) -> DragScroll:
	var helper := DragScroll.new()
	helper.name = "DragScroll"
	helper._scroll = scroll
	helper._vertical = vertical
	scroll.add_child(helper, false, Node.INTERNAL_MODE_BACK)
	return helper


## True from the moment a press became a drag until it is let go. Anything
## else that reacts to presses (a panel's tap-outside-to-close) checks it.
func is_dragging() -> bool:
	return _dragging


func _input(event: InputEvent) -> void:
	if _scroll == null or not _scroll.is_visible_in_tree():
		_tracking = false
		return

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			if _scroll.get_global_rect().has_point(button.position):
				_tracking = true
				_dragging = false
				_start = button.position
				_last = button.position
				_start_scroll = _position()
				_velocity = 0.0
				_last_time = Time.get_ticks_msec()
		else:
			# The release is let through on purpose: Godot must see the finger
			# lift, or it goes on sending taps to the button the drag began on.
			# That button has already forgotten its press (_cancel_press()).
			_tracking = false
			_dragging = false
		return

	if event is InputEventMouseMotion and _tracking:
		var where := (event as InputEventMouseMotion).position
		var moved := where - _start
		if not _dragging:
			var along := absf(moved.y) if _vertical else absf(moved.x)
			var across := absf(moved.x) if _vertical else absf(moved.y)
			if across > DRAG_START and across > along:
				_tracking = false   # a drag the other way; not ours
				return
			if along < DRAG_START:
				return
			_dragging = true
			_cancel_press()

		var now := Time.get_ticks_msec()
		# The scroll position moves WITH the finger's own direction of travel
		# (drag right to bring content on the right into view), not against
		# it — Cameron, 2026-09-24: the reverse ("content follows the
		# finger", the usual touchscreen pan) made you drag the opposite way
		# from wherever you meant to go.
		var step := (where.y - _last.y) if _vertical else (where.x - _last.x)
		var seconds := maxf(float(now - _last_time) / 1000.0, 0.001)
		_velocity = clampf(step / seconds, -MAX_GLIDE, MAX_GLIDE)
		_last = where
		_last_time = now
		_set_position(_start_scroll + (moved.y if _vertical else moved.x))
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _dragging or absf(_velocity) < 20.0:
		return
	_set_position(_position() + _velocity * delta)
	_velocity *= pow(GLIDE_KEEP_PER_SECOND, delta)


## The button under the finger was pressed down when the drag began, and
## would count the eventual release as a tap. Disabling a button makes it
## forget a press in progress (BaseButton.set_disabled); switching it
## straight back leaves nothing to see.
func _cancel_press() -> void:
	for button: BaseButton in _buttons_at(_start, _scroll):
		if not button.disabled:
			button.disabled = true
			button.disabled = false


static func _buttons_at(point: Vector2, root: Node) -> Array[BaseButton]:
	var found: Array[BaseButton] = []
	for child in root.get_children():
		if child is BaseButton and (child as Control).get_global_rect().has_point(point):
			found.append(child)
		found.append_array(_buttons_at(point, child))
	return found


func _position() -> float:
	return float(_scroll.scroll_vertical if _vertical else _scroll.scroll_horizontal)


func _set_position(value: float) -> void:
	if _vertical:
		_scroll.scroll_vertical = roundi(value)
	else:
		_scroll.scroll_horizontal = roundi(value)
