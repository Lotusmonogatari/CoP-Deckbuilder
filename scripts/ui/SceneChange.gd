class_name SceneChange
extends RefCounted
## The one way the game changes screen (audit U-06, 2026-11-10): a short fade
## to black, the change, and a fade back in, so a slow phone shows a deliberate
## cut instead of a frozen picture. How long each half takes is a Balance
## number ("Scene Change: Fade Seconds"; 0 turns the fade off).
##
## The tests and click drivers change scene without the fade, so their timing
## stays what it always was (`fade_enabled` is false in a test run).

## False in test runs; a test of the fade itself may set it.
static var fade_enabled := not SaveManager._is_test_run()

const LAYER_NAME := "SceneFade"


## Changes to the scene at `path`. A second call while a fade is already
## running is ignored, so two quick taps cannot change scene twice.
static func to(tree: SceneTree, path: String) -> void:
	if tree == null:
		return
	var seconds := float(DataDB.balance.get("scene_change_fade_seconds", 0.0))
	if not fade_enabled or seconds <= 0.0:
		tree.change_scene_to_file(path)
		return
	if tree.root.has_node(LAYER_NAME):
		return
	var layer := CanvasLayer.new()
	layer.name = LAYER_NAME
	layer.layer = 100
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Taps are swallowed while the screen is changing.
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(cover)
	tree.root.add_child(layer)
	var tween := layer.create_tween()
	tween.tween_property(cover, "color:a", 1.0, seconds)
	tween.tween_callback(func() -> void: tree.change_scene_to_file(path))
	tween.tween_property(cover, "color:a", 0.0, seconds)
	tween.tween_callback(layer.queue_free)
