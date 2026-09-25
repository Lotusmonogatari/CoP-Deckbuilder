extends Node
## The work for shot_staff.tscn, kept outside the scene it changes away from.

const SHOTS := "user://shots/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)

	GameState.awaiting_new_game = true
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().create_timer(1.0).timeout

	var office := get_tree().current_scene
	office.call("_on_protagonist_chosen", "PC01")
	await get_tree().create_timer(0.3).timeout
	GameState.meta["Funds"] = 900000

	# Two candidates for the same role (Policy Research Assistant), the same
	# pair the Ledger tests use.
	var first := DataDB.get_staff("SF02")
	var second := DataDB.get_staff("SF03")
	var role := str(first.get("role", ""))

	office.call("_show_staff")
	await get_tree().create_timer(0.5).timeout
	await _shot("40-recruitment-vacant")

	office.call("_on_hire_staff", "SF02")
	await get_tree().create_timer(0.3).timeout
	await _shot("41-recruitment-hired-with-fire-button")

	office.call("_confirm_fire_staff", role, first)
	await get_tree().create_timer(0.3).timeout
	await _shot("42-recruitment-fire-warning")

	# The real confirm button, not the connected handler directly — Overlay's
	# own _on_confirmed() closes the panel THEN emits `confirmed`, so calling
	# the handler alone (as an earlier version of this driver did) leaves the
	# warning drawn on screen even though the fire itself went through.
	(office.get_node("FireStaffPanel") as Overlay).call("_on_confirmed")
	await get_tree().create_timer(0.3).timeout
	await _shot("43-recruitment-fired-greyed-out")

	office.call("_on_hire_staff", "SF03")
	await get_tree().create_timer(0.3).timeout
	await _shot("44-recruitment-refilled")

	print("staff hired after firing: ", GameState.staff_hired.get(role, {}).get("staff_id"))
	print("staff_fired: ", GameState.staff_fired)
	print("Funds left: ", GameState.meta.get("Funds"))

	print("SHOTS DONE")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
