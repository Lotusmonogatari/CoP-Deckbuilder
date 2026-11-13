class_name MoveFlashLayer
extends Control
## The flash behind a character's picture when they move (Cameron, 2026-11-13).
##
## Attached to a portrait (a PlaceholderArt) as its lowest child; it is a
## little larger than the portrait, so the glow reaches beyond the character's
## edge, and it never takes a touch. `play(expression, colour)` is called
## where the picture changes. What it looks like comes from the Move Flashes
## tab (via MoveFlash.plan); with no row for the move, nothing happens.

const SHADER_PATH := "res://assets/shaders/move_glow.gdshader"
## Extra room left around the glow so its end is never clipped, in pixels.
const ROOM := 2.0

var side := "opponent"
var _art: PlaceholderArt
var _glow: ColorRect
var _material: ShaderMaterial
var _tween: Tween
var _margin := 0.0


## Puts a layer behind `art`'s picture and returns it (null if `art` is not a
## portrait). Safe to call once per portrait.
static func attach(art: Control, for_side: String) -> MoveFlashLayer:
	if not (art is PlaceholderArt):
		return null
	var existing := art.get_node_or_null("MoveFlash") as MoveFlashLayer
	if existing != null:
		return existing
	var layer := MoveFlashLayer.new()
	layer.name = "MoveFlash"
	layer.side = for_side
	layer._art = art as PlaceholderArt
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.add_child(layer)
	art.move_child(layer, 0)
	return layer


func _ready() -> void:
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	_glow.material = _material
	_glow.hide()
	add_child(_glow)
	set_process(false)


## Flashes for the face now being worn. `character_colour` is the character's
## own Characters-list colour; the Move Flashes row may override it.
func play(expression: String, character_colour: Color) -> void:
	if _glow == null or not is_visible_in_tree():
		return
	var plan := MoveFlash.plan(DataDB.move_flashes, side, expression, character_colour)
	if plan.is_empty():
		return
	_margin = float(plan["width"]) + ROOM
	_material.set_shader_parameter("glow_color", plan["color"])
	_material.set_shader_parameter("width", plan["width"])
	_place()
	_glow.show()
	set_process(true)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_material.set_shader_parameter("amount", float(plan["strength"]))
	_tween = create_tween()
	_tween.tween_interval(float(plan["hold"]))
	_tween.tween_method(_set_amount.bind(float(plan["strength"])), 1.0, 0.0, float(plan["fade"]))
	_tween.tween_callback(_finish)


func _set_amount(progress: float, strength: float) -> void:
	_material.set_shader_parameter("amount", strength * progress)


func _finish() -> void:
	_glow.hide()
	set_process(false)


## Follows the picture while the glow is up (it may change the moment the
## face does).
func _process(_delta: float) -> void:
	_place()


## Sizes the glow rectangle beyond the portrait and tells the shader where the
## picture sits inside it, mirroring how the portrait keeps its aspect.
func _place() -> void:
	var box := _art.size
	_glow.position = Vector2(-_margin, -_margin)
	_glow.size = box + Vector2(_margin, _margin) * 2.0
	var texture := _art.shown_texture()
	var image := Rect2(Vector2.ZERO, box)
	if texture != null and texture.get_size().x > 0.0 and texture.get_size().y > 0.0:
		var scale := minf(box.x / texture.get_size().x, box.y / texture.get_size().y)
		var shown := texture.get_size() * scale
		image = Rect2((box - shown) / 2.0, shown)
	_material.set_shader_parameter("use_art", 1.0 if texture != null else 0.0)
	_material.set_shader_parameter("art", texture)
	_material.set_shader_parameter("img_rect",
		Vector4(image.position.x + _margin, image.position.y + _margin, image.size.x, image.size.y))
