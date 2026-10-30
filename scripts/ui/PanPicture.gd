class_name PanPicture
extends Control
## An event's picture that the player can drag to see the rest of
## (Image Scroll) and that drifts as the phone tilts (Image Pan) -- Cameron,
## 2026-10-30. Both switches live in Administration (Layout keeps them).
##
## The picture fills its box the way every background does (cover: nothing
## bare, the overflow cropped), so a square drawing in a wide box has some
## picture above and below to bring into view, and a panorama has some to
## either side. Dragging moves the window over the picture in the finger's
## own direction (drag right to see more of the right), the same way the
## lists here scroll. A tilt adds to that, measured from how the phone was
## held when the picture appeared, and settles back when Image Pan is off.
## A desktop has no tilt sensor and simply never drifts. The arithmetic is
## PanMath (tested); the numbers are Balance levers.
##
## A drag that starts on the picture belongs to the picture, not to the
## panel's own scrolling: DragScroll leaves alone any press that lands on a
## node in DRAG_GROUP.

const DRAG_GROUP := "drag_claimers"
## Gravity, in the units the sensors report (m/s²), so a reading becomes g.
const STANDARD_GRAVITY := 9.81
## A reading weaker than this is no sensor at all (a desktop reports zero).
const NO_SENSOR := 0.5

var art_id := ""

var _texture: Texture2D
var _picture: TextureRect
var _drag := Vector2.ZERO
var _tilt := Vector2.ZERO
var _baseline := Vector2.ZERO
var _has_baseline := false
var _pressed := false


## The picture for `id` in a box `height` tall: a PanPicture when it is drawn,
## otherwise the usual labelled placeholder (nothing to move on a placeholder).
static func make(id: String, height: float) -> Control:
	var box: Control
	if ArtLoader.background_path(id).is_empty():
		var art := PlaceholderArt.new()
		art.kind = PlaceholderArt.Kind.BACKGROUND
		art.art_id = id
		box = art
	else:
		var picture := PanPicture.new()
		picture.art_id = id
		box = picture
	box.name = "Picture_" + id
	box.custom_minimum_size = Vector2(0, height)
	return box


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texture = ArtLoader.background(art_id)
	_picture = TextureRect.new()
	_picture.name = "Image"
	_picture.texture = _texture
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	if Layout.image_scroll_enabled:
		add_to_group(DRAG_GROUP)
	resized.connect(_place)
	_place()


## How far the window has moved from the centre, drag and tilt together.
func offset() -> Vector2:
	return PanMath.clamp_offset(_drag + _tilt, _room())


func _room() -> Vector2:
	if _texture == null:
		return Vector2.ZERO
	return PanMath.spare(size, _texture.get_size())


func _place() -> void:
	if _texture == null or _picture == null:
		return
	var scaled := _texture.get_size() * PanMath.cover_scale(size, _texture.get_size())
	_drag = PanMath.clamp_offset(_drag, _room())
	_picture.size = scaled
	_picture.position = PanMath.picture_position(size, scaled, offset())


func _gui_input(event: InputEvent) -> void:
	if not Layout.image_scroll_enabled:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_pressed = (event as InputEventMouseButton).pressed
		accept_event()
	elif event is InputEventMouseMotion and _pressed:
		_drag += (event as InputEventMouseMotion).relative
		_place()
		accept_event()


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
