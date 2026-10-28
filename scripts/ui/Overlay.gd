class_name Overlay
extends PanelContainer
## A panel that covers the screen, with three ways out of it.
##
## Being stuck on a screen with no exit is the worst thing a UI can do, and
## it has happened here once already — the battle's details panel shipped
## without a close button and a playtest found it immediately. So the way out
## is built into the thing rather than remembered at each call site:
##
##   its own Back button
##   the escape key
##   tapping the dimmed area around the content
##
## The content scrolls, because a long card or a long list must never push
## the Back button off the bottom of the screen and recreate the trap.
##
## A panel that genuinely should not be dismissed by accident — the one that
## says a stage is over — sets `dismissable` to false and keeps only its own
## button.

## `closed` fires however the panel shuts — Back, escape, a tap outside, or
## confirm. Its listener is the Office's first-run New Game screen, which
## must still leave the player as somebody if they back out of choosing.
## Same rule as EventBus: a signal exists only while something listens.
signal closed

## Emitted when the player presses the confirm button, where one was asked
## for. A panel that leads somewhere — a briefing before a level — needs a
## way to say YES as well as a way to back out, and "Back" cannot be both.
signal confirmed

## False for a panel the player must acknowledge rather than wave away.
@export var dismissable := true

## Whether the Back button shows. Off for a panel whose only ways forward are
## its own buttons — Rhetoric Training's card offer, which must end in
## Learn it (or Pass, while passes remain), never in simply backing out.
@export var show_back := true

## True for a panel whose content starts at the top of the screen instead of
## being centred up and down (the staff profile, 2026-10-28).
@export var top_aligned := false

## The screen behind has to be covered, not tinted: this sits over a portrait
## and a heading, and a half-transparent panel makes both unreadable.
##
## Fully opaque. It was 0.94, which sounds like nothing — but six per cent of
## light text on a near-black panel is still perfectly readable, and a
## screenshot showed the Office's headings ghosting through every shop.
const BACKDROP := Color(0.07, 0.08, 0.11, 1.0)

var _body: VBoxContainer
## Width of the content column: the 1080 base width less 40 px margins.
const COLUMN_WIDTH := 1000.0

var _title: Label
var _back: Button
var _confirm: Button

## Where a press outside the content began, or null. A tap outside closes
## the panel on the finger lifting, not landing, so a drag that starts in the
## margin scrolls instead of shutting it.
var _outside_press: Variant = null


func _ready() -> void:
	# Anchors AND offsets. Anchors alone keep whatever rectangle the node
	# already has, which is fine for a panel placed in a scene (it arrives
	# full-screen) but leaves one built in code at 0 x 0 — its content then
	# sits outside a zero-size scroll area, drawn but unclickable. Found by
	# the inventory click test, 2026-09-25.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()


func _build() -> void:
	if _body != null:
		return

	var box := StyleBoxFlat.new()
	box.bg_color = BACKDROP
	add_theme_stylebox_override("panel", box)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	margin.add_child(scroll)
	DragScroll.attach(scroll)
	# Text wraps; nothing in a panel should ever need a sideways scroll.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centre)

	_body = VBoxContainer.new()
	_body.name = "Column"
	_body.add_theme_constant_override("separation", 18)
	# A definite width, so wrapped text has something to wrap against. The
	# screen is never narrower than the 1080 base width, minus the 40 px
	# margins either side.
	_body.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	centre.add_child(_body)

	_title = Label.new()
	_title.name = "Heading"
	_title.theme_type_variation = "HeaderLabel"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_title)

	_back = Button.new()
	_back.name = "Back"
	_back.text = Text.say("ui.back")
	_back.custom_minimum_size = Vector2(0, 110)
	_back.pressed.connect(close)
	# Parented straight away. A panel that is built and never opened (most of
	# the Office's, most visits) used to leave these two buttons floating
	# outside the tree, and nothing ever freed them: about 6 objects and
	# 0.4 MB of text-layout memory per Office load (stress test, 2026-10-14).
	# open() takes them out and puts them back at the bottom of the column.
	_body.add_child(_back)

	# Hidden unless a caller asks for it. It sits ABOVE Back so the action
	# the player most likely wants is the one under their thumb.
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.custom_minimum_size = Vector2(0, 110)
	_confirm.hide()
	_confirm.pressed.connect(_on_confirmed)
	_body.add_child(_confirm)


## Opens it with a heading and a list of nodes to show between the heading
## and the Back button. Anything shown before is cleared.
##
## `back_text` relabels the way out for a panel where "Back" reads wrongly —
## an item pop-up closes rather than goes back. Blank keeps "Back".
func open(heading: String, rows: Array[Control], confirm_text: String = "",
		back_text: String = "") -> void:
	_build()
	_title.text = heading
	# A panel with no heading (the staff profile) shows no empty bar.
	_title.visible = not heading.is_empty()
	_back.text = back_text if not back_text.is_empty() else Text.say("ui.back")

	for child in _body.get_children():
		if child != _title:
			_body.remove_child(child)
			if child != _back and child != _confirm:
				child.queue_free()

	for row: Control in rows:
		_body.add_child(row)
		UiKit.wrap_all(row)

	_confirm.text = confirm_text
	_confirm.visible = not confirm_text.is_empty()
	_body.add_child(_confirm)
	_body.add_child(_back)
	_back.visible = show_back

	show()
	# Filling the scroll area's height is what pins the content to the top: the
	# centring container has no room left to centre it in.
	_body.custom_minimum_size.y = 0.0
	if top_aligned:
		_pin_to_top.call_deferred()


func _pin_to_top() -> void:
	var scroll := _body.get_parent().get_parent() as ScrollContainer
	if scroll != null and visible:
		_body.custom_minimum_size.y = scroll.size.y


func _on_confirmed() -> void:
	# Out of the way first, so the screen it leads to is not built underneath
	# a panel that is still covering it.
	close()
	confirmed.emit()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## The content's own rectangle, so a caller can tell a tap on the dimmed
## surround from a tap on the panel itself.
func content_rect() -> Rect2:
	return _body.get_global_rect() if _body != null else Rect2()


func _input(event: InputEvent) -> void:
	if not visible or not dismissable:
		return

	# An Overlay can open on top of another one that stays open underneath it
	# (Rhetoric Training's own card-offer popup, opened "on top of the
	# training list, which stays open underneath" — _on_see_card()'s own
	# comment). Without this check, the UNDERLYING panel's own _input() still
	# fires for a tap aimed at the one on top: Godot delivers _input() to
	# every node that overrides it, in sibling order, regardless of which one
	# is actually drawn on top, so a tap the top panel's own Confirm button
	# would have happily accepted could land outside the covered panel's own
	# (smaller, unrelated) content_rect() and silently close IT instead —
	# `get_viewport().set_input_as_handled()` then stops the event before the
	# top panel, or its Button, ever sees it. Found 2026-10-04: a real click
	# on Rhetoric Training's "Learn it" button did exactly this and silently
	# closed the training list behind it, with nothing paid or granted.
	var parent := get_parent()
	if parent != null:
		for i in range(get_index() + 1, parent.get_child_count()):
			var sibling := parent.get_child(i)
			if sibling is Overlay and (sibling as Overlay).visible:
				return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var where := (event as InputEventMouseButton).position
		if (event as InputEventMouseButton).pressed:
			_outside_press = where if not content_rect().has_point(where) else null
		elif is_tap_outside(_outside_press, where, content_rect()):
			_outside_press = null
			close()
			get_viewport().set_input_as_handled()


## True when a press at `pressed_at` (null if it began inside) and a release
## at `released_at` make one tap outside `content`, rather than a drag.
static func is_tap_outside(pressed_at: Variant, released_at: Vector2, content: Rect2) -> bool:
	return pressed_at is Vector2 and not content.has_point(released_at) \
		and (pressed_at as Vector2).distance_to(released_at) < DragScroll.DRAG_START
