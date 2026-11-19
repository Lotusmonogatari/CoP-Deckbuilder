class_name ResignHold
extends Node
## Resigning is confirmed by holding the Resign button (2026-11-19, Cameron): from the moment it is pressed the
## screen darkens from its outside edges inward and is fully black after Balance "Resign: Confirm Hold
## Seconds" (5). Holding all that time is the confirmation, so a stray tap or a short press does nothing;
## letting go (or sliding off the button, or a drag taking the press) cancels and the screen lightens again.
##
## One of these is a child of the Resign button (ResignScreen.button). The darkness is a full-screen veil on a
## canvas layer above every panel, with a small shader: black where the distance from the centre (taken
## across the screen's own shape, so it follows a tall phone) is past a radius that shrinks from beyond the
## corners to nothing. The veil never takes a touch, so the held press stays with the button.

signal confirmed

## Above every panel and the cue banner, below the scene-change fade and the problem report.
const VEIL_LAYER := 130
## The radius the black starts from: past the screen's corners (1.414), so nothing is dark at progress 0.
const CLEAR_START := 1.75
## How soft the inner edge of the black is, in the same units.
const SOFT := 0.3
## How fast the screen lightens after letting go.
const RELEASE_SECONDS := 0.3

const SHADER_CODE := """
shader_type canvas_item;
uniform float progress = 0.0;
void fragment() {
	float radius = length((UV - vec2(0.5)) * 2.0);
	float clear_to = mix({start}, 0.0, progress);
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(clear_to - {soft}, clear_to, radius));
}
"""

var _button: Button
var _gesture: HoldGesture
var _veil: ColorRect
var _holding := false
var _done := false
var _release_tween: Tween


## Makes `button` a hold-to-confirm button: `on_confirmed` is called once, after `seconds` of holding.
static func attach(button: Button, seconds: float, on_confirmed: Callable) -> ResignHold:
	var hold := ResignHold.new()
	hold.name = "ResignHold"
	hold._button = button
	hold._gesture = HoldGesture.new(1, seconds)
	hold.confirmed.connect(on_confirmed)
	button.add_child(hold)
	return hold


## How dark (0 clear, 1 black) a point is: `radius` is its distance from the screen's centre (0 at the centre,
## 1 at the middle of an edge, 1.414 at a corner), `progress` how far the hold has come (0 to 1). The same
## arithmetic as the shader, so it can be checked without a screen.
static func shade(radius: float, progress: float) -> float:
	var clear_to := lerpf(CLEAR_START, 0.0, progress)
	return smoothstep(clear_to - SOFT, clear_to, radius)


## "5" for 5.0, "2.5" for 2.5.
static func seconds_text(seconds: float) -> String:
	return str(int(seconds)) if is_equal_approx(seconds, round(seconds)) else str(snappedf(seconds, 0.1))


## 0 to 1: how far the hold has come.
func progress() -> float:
	return _gesture.progress() if _holding else 0.0


func is_holding() -> bool:
	return _holding


func _ready() -> void:
	set_process(false)
	_build_veil()
	_button.button_down.connect(_on_down)
	_button.button_up.connect(_on_up)


func _build_veil() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ResignVeil"
	layer.layer = VEIL_LAYER
	add_child(layer)
	_veil = ColorRect.new()
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER_CODE.format({"start": CLEAR_START, "soft": SOFT})
	var material := ShaderMaterial.new()
	material.shader = shader
	_veil.material = material
	_veil.hide()
	layer.add_child(_veil)


func _on_down() -> void:
	if _done:
		return
	if _release_tween != null:
		_release_tween.kill()
	_gesture.reset()
	_gesture.press(0)
	_holding = true
	_set_progress(0.0)
	_veil.show()
	set_process(true)


func _on_up() -> void:
	if _holding:
		_cancel()


func _process(delta: float) -> void:
	if not _holding:
		return
	# Sliding off the button, or a drag taking the press (the menu scrolls), is letting go.
	if _button.get_draw_mode() != BaseButton.DRAW_PRESSED and _button.get_draw_mode() != BaseButton.DRAW_HOVER_PRESSED:
		_cancel()
		return
	var finished := _gesture.tick(delta)
	_set_progress(_gesture.progress())
	if finished:
		_holding = false
		_done = true
		set_process(false)
		_set_progress(1.0)
		confirmed.emit()


func _cancel() -> void:
	_holding = false
	_gesture.reset()
	set_process(false)
	var start := float((_veil.material as ShaderMaterial).get_shader_parameter("progress"))
	_release_tween = create_tween()
	_release_tween.tween_method(_set_progress, start, 0.0, RELEASE_SECONDS * maxf(start, 0.05))
	_release_tween.tween_callback(_veil.hide)


func _set_progress(value: float) -> void:
	(_veil.material as ShaderMaterial).set_shader_parameter("progress", value)
