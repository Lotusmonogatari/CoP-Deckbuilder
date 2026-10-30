@tool
class_name PlaceholderArt
extends Control
## Shows a piece of artwork, or an obvious stand-in labelled with its asset ID
## when the artwork hasn't been drawn yet.
##
## Use this anywhere art goes, rather than a bare TextureRect. Then a missing
## PNG shows up as a labelled coloured box instead of an empty hole, and the
## label tells you exactly which file to draw.
##
## Set `kind` and `art_id` in the inspector, or from code:
##
##     var portrait := PlaceholderArt.new()
##     portrait.kind = PlaceholderArt.Kind.CHARACTER
##     portrait.art_id = "OP03"
##     portrait.expression = "neutral"
##
## A drawn BACKGROUND can be moved (Cameron, 2026-10-30): it fills its box
## (cover: nothing bare, the overflow cropped), and the player can drag it to
## see the cropped part (Image Scroll) and it drifts as the phone tilts
## (Image Pan); both switches live in Administration (Layout keeps them).
## That covers every room, the Office, visitors, votes, transitions and event
## pictures alike. A drag counts only when the press lands on nothing in front
## of the picture that takes the mouse (a button, a list, an open panel), so
## buttons, lists and the hand behave exactly as before. Characters, cards
## and icons never move. The arithmetic is PanMath (tested).

enum Kind { CHARACTER, CARD, BACKGROUND, ICON }

@export var kind: Kind = Kind.ICON:
	set(value):
		kind = value
		_refresh()

## The asset ID: "OP03", "C11", "ST02", "BO04".
@export var art_id: String = "":
	set(value):
		art_id = value
		# A stage listing several pictures draws a fresh one when its picture is set.
		ArtLoader.forget_pick(value)
		_refresh()

## Only used for characters: neutral, attacking, guarding, gaining, damaged
## (data/art.json), plus the optional defeated and victory. A face that is
## not drawn falls back, in the end to neutral.
@export var expression: String = "neutral":
	set(value):
		expression = value
		_refresh()

## Only used for characters, and entirely optional: a stage ID tried before
## the plain expression, so a character can have a one-off outfit for one
## room (assets/.../OP03_ST04_attacking.png) without needing one everywhere
## else. Blank — the default — skips straight to the plain art.
@export var stage_id: String = "":
	set(value):
		stage_id = value
		_refresh()

## Whether to write the asset ID across a placeholder. Off for backgrounds,
## where the label would sit behind the whole battle screen.
@export var show_label: bool = true:
	set(value):
		show_label = value
		_refresh()

## Lists leave alone a press on a picture in this group (DragScroll), so a
## picture inside a scrolling panel can be dragged without scrolling it.
const DRAG_GROUP := "drag_claimers"
## How far a press must travel before it counts as dragging the picture, the
## same as a list's (DragScroll.DRAG_START), so a tap is still a tap.
const DRAG_START := 24.0
## Gravity in the units the sensors report (m/s²), so a reading becomes g.
const STANDARD_GRAVITY := 9.81
## A reading weaker than this is no sensor at all (a desktop reports zero).
const NO_SENSOR := 0.5

var _texture_rect: TextureRect
var _label: Label
var _is_placeholder := false

## True while this is a drawn background that can be dragged and tilted.
var _pans := false
var _drag := Vector2.ZERO
var _tilt := Vector2.ZERO
var _baseline := Vector2.ZERO
var _has_baseline := false
var _tracking := false
var _dragging := false
var _press_at := Vector2.ZERO


func _ready() -> void:
	_build()
	_refresh()
	resized.connect(_place)


func _build() -> void:
	if _texture_rect != null:
		return

	# Pushed to the very back (index 0, then 1) rather than left wherever
	# add_child() happens to put them. A plain PlaceholderArt has no other
	# children so this never used to matter — but a caller that adds a
	# child of its own IN THE SCENE FILE (the battle screen's own "you" chip
	# inset in the opponent portrait) has that child ready and in place
	# before this node's own _ready() runs, and add_child() always appends
	# at the end: without this, the texture just drawn would land on TOP of
	# that child and hide it completely.
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# The real mode is set per-kind in _refresh() (kind can change at runtime —
	# OpponentPresenter and PlayerPortraitPresenter swap it between CHARACTER
	# outfits). STRETCH_SCALE here is only ever seen for the one frame before
	# _refresh() runs first.
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_texture_rect)
	move_child(_texture_rect, 0)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# White on the mid-tone placeholder colour, with a dark outline so it
	# stays readable whichever hue the ID hashes to.
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	move_child(_label, 1)


func _refresh() -> void:
	if _texture_rect == null:
		return

	if art_id.is_empty():
		_texture_rect.texture = null
		_label.text = ""
		_set_panning(false)
		return

	_is_placeholder = not ArtLoader.exists(_found_path())

	match kind:
		Kind.CHARACTER: _texture_rect.texture = ArtLoader.character(art_id, expression, stage_id)
		Kind.CARD: _texture_rect.texture = ArtLoader.card(art_id)
		Kind.BACKGROUND: _texture_rect.texture = ArtLoader.background(art_id)
		Kind.ICON: _texture_rect.texture = ArtLoader.icon(art_id)

	# A character is a full-body cutout: shown whole, never cropped, so its
	# feet and head both stay on screen whatever the box's own proportions
	# are. A background instead FILLS its box with no letterboxing, cropping
	# whatever overflows — it is the room, not a figure standing in it. Cards
	# and icons keep the old fill-the-box behaviour; their own template
	# already draws to the box's exact edges.
	match kind:
		Kind.CHARACTER: _texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Kind.BACKGROUND: _texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_: _texture_rect.stretch_mode = TextureRect.STRETCH_SCALE

	_label.visible = _is_placeholder and show_label
	_label.text = _label_text() if _is_placeholder else ""
	_set_panning(kind == Kind.BACKGROUND and not _is_placeholder
		and _texture_rect.texture != null and not Engine.is_editor_hint())


## Switches between a fixed picture and one that can be dragged and tilted.
## A new picture always starts centred.
func _set_panning(on: bool) -> void:
	_drag = Vector2.ZERO
	_tilt = Vector2.ZERO
	_has_baseline = false
	_tracking = false
	_dragging = false
	_pans = on
	# The picture hangs past the box on the side it can move towards; only
	# the box itself is ever drawn.
	clip_contents = on
	set_process(on)
	set_process_input(on)
	if on:
		_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
		if not is_in_group(DRAG_GROUP):
			add_to_group(DRAG_GROUP)
		_place()
	else:
		if is_in_group(DRAG_GROUP):
			remove_from_group(DRAG_GROUP)
		_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## How far the shown window has moved from the centre of the picture, drag
## and tilt together (PanMath's offset: +x shows more of the right).
func offset() -> Vector2:
	return PanMath.clamp_offset(_drag + _tilt, _room())


func _room() -> Vector2:
	if not _pans or _texture_rect.texture == null:
		return Vector2.ZERO
	return PanMath.spare(size, _texture_rect.texture.get_size())


func _place() -> void:
	if not _pans or _texture_rect == null or _texture_rect.texture == null:
		return
	var picture := _texture_rect.texture.get_size()
	var scaled := picture * PanMath.cover_scale(size, picture)
	_drag = PanMath.clamp_offset(_drag, _room())
	_texture_rect.size = scaled
	_texture_rect.position = PanMath.picture_position(size, scaled, offset())


func _input(event: InputEvent) -> void:
	if not _pans or not Layout.image_scroll_enabled or not is_visible_in_tree():
		_tracking = false
		_dragging = false
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		# The press itself is never taken: a tap still reaches whatever it
		# landed on.
		_tracking = button.pressed and get_global_rect().has_point(button.position) \
			and not _covered_at(button.position)
		_dragging = false
		_press_at = button.position
		return
	if event is InputEventMouseMotion and _tracking:
		var motion := event as InputEventMouseMotion
		if not _dragging:
			if motion.position.distance_to(_press_at) < DRAG_START:
				return
			_dragging = true
		# The window moves the way the finger does (drag right to see more of
		# the right), the house convention for lists too.
		_drag += motion.relative
		_place()
		get_viewport().set_input_as_handled()


## True when something in front of this picture takes the mouse at `point`:
## a button, a list, a card, an open panel. Only a press on bare picture (or
## on a label or layout box, which let the mouse through) drags it.
func _covered_at(point: Vector2) -> bool:
	for node in get_tree().root.find_children("*", "Control", true, false):
		var control := node as Control
		if control == self or control.mouse_filter != Control.MOUSE_FILTER_STOP \
				or not control.is_visible_in_tree() or control.is_ancestor_of(self) \
				or not control.get_global_rect().has_point(point):
			continue
		if is_ancestor_of(control) or control.is_greater_than(self):
			return true
	return false


func _process(delta: float) -> void:
	var target := Vector2.ZERO
	if Layout.image_pan_enabled:
		var reading := Input.get_gravity()
		if reading.length() < NO_SENSOR:
			reading = Input.get_accelerometer()
		if reading.length() >= NO_SENSOR:
			if not _has_baseline:
				_baseline = Vector2(reading.x, reading.y)
				_has_baseline = true
			var tilt := (Vector2(reading.x, reading.y) - _baseline) / STANDARD_GRAVITY
			target = PanMath.tilt_offset(Vector2(tilt.x, -tilt.y),
				float(DataDB.balance.get("image_pan_tilt_strength", 2.5)), _room())
	if _tilt.is_equal_approx(target):
		return
	_tilt = PanMath.follow(_tilt, target, float(DataDB.balance.get("image_pan_follow_speed", 6)), delta)
	_place()


## The drawing actually shown, after fallbacks, or "" for none.
func _found_path() -> String:
	match kind:
		Kind.CHARACTER: return ArtLoader.character_path(art_id, expression, stage_id)
		Kind.CARD: return ArtLoader.card_path(art_id)
		Kind.BACKGROUND: return ArtLoader.background_path(art_id)
		_: return ArtLoader.folder("icon") + art_id + ".png"


## Shown on the placeholder so whoever is drawing the art knows exactly what
## to name the file.
func _label_text() -> String:
	if kind == Kind.CHARACTER:
		return ArtLoader.expected_character_path(art_id, expression).get_file()
	return art_id


## True when this is showing a stand-in rather than real artwork.
func is_placeholder() -> bool:
	return _is_placeholder
