class_name HandScrollBar
extends HScrollBar
## The hand's scroll bar, above the cards in the game's gold (2026-11-05,
## Cameron). A ScrollContainer draws its own bar underneath its content, so the
## hand's own is switched off and this one, placed just above the container,
## mirrors it both ways: dragging it scrolls the hand, and a finger drag on the
## cards (DragScroll) moves it. The bar keeps its space when the hand fits on
## screen but fades out, so the cards do not jump up and down as the hand grows.

const GOLD := CueBanner.EDGE_COLOUR
const HEIGHT := 34.0

var _scroll: ScrollContainer
var _inner: HScrollBar


## Puts a gold bar directly above `scroll` and returns it.
static func attach(scroll: ScrollContainer) -> HandScrollBar:
	var parent := scroll.get_parent()
	if parent == null:
		return null
	var bar := HandScrollBar.new()
	bar.name = "HandScrollBar"
	bar._scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	parent.add_child(bar)
	parent.move_child(bar, scroll.get_index())
	bar._connect()
	return bar


func _connect() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style()
	_inner = _scroll.get_h_scroll_bar()
	_inner.changed.connect(_copy_range)
	_inner.value_changed.connect(_copy_value)
	value_changed.connect(_on_dragged)
	_copy_range.call_deferred()


## The bar's look: a faint gold track and a gold grabber, brighter when held.
func _style() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.16)
	track.set_corner_radius_all(int(HEIGHT / 2))
	track.content_margin_top = HEIGHT / 2.0
	track.content_margin_bottom = HEIGHT / 2.0
	add_theme_stylebox_override("scroll", track)
	add_theme_stylebox_override("scroll_focus", track)
	for state: Array in [["grabber", 0.85], ["grabber_highlight", 1.0], ["grabber_pressed", 1.0]]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, float(state[1]))
		grabber.set_corner_radius_all(int(HEIGHT / 2))
		# Never shorter than a fingertip, however long the hand.
		grabber.content_margin_left = HEIGHT
		grabber.content_margin_right = HEIGHT
		add_theme_stylebox_override(str(state[0]), grabber)


## Takes the container's own range (how far it can scroll, how much shows).
func _copy_range() -> void:
	if _inner == null:
		return
	min_value = _inner.min_value
	max_value = _inner.max_value
	page = _inner.page
	step = _inner.step
	set_value_no_signal(_inner.value)
	# Fades out when everything is on screen at once.
	modulate.a = 1.0 if _inner.max_value - _inner.page > 1.0 else 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP if modulate.a > 0.0 else Control.MOUSE_FILTER_IGNORE


func _copy_value(new_value: float) -> void:
	set_value_no_signal(new_value)


func _on_dragged(new_value: float) -> void:
	_scroll.scroll_horizontal = int(new_value)
