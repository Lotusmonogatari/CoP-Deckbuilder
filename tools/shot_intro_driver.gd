extends Node
## The work for shot_intro.tscn, kept outside the scene it changes away
## from — see shot_features_driver.gd's own comment for why.

const SHOTS := "user://shots/"
const INTRO_SCENE := "res://scenes/menus/IntroScreen.tscn"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)

	SaveManager.delete_save()
	get_tree().change_scene_to_file(INTRO_SCENE)
	await get_tree().create_timer(0.6).timeout
	await _shot("40-intro-no-save")

	var intro := get_tree().current_scene
	await _click(intro.get_node("%NewGameButton"))
	await get_tree().create_timer(0.4).timeout
	await _shot("41-new-game-picker")

	SaveManager.save_game()
	get_tree().change_scene_to_file(INTRO_SCENE)
	await get_tree().create_timer(0.6).timeout
	await _shot("42-intro-with-save")

	intro = get_tree().current_scene
	await _click(intro.get_node("%NewGameButton"))
	await get_tree().create_timer(0.4).timeout
	await _shot("43-overwrite-warning")

	SaveManager.delete_save()
	print("SHOTS DONE")
	get_tree().quit()


func _click(control: Control) -> void:
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
