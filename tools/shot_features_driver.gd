extends Node
## The work for shot_features.tscn, kept outside the scene it changes away from.

const SHOTS := "user://shots/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)

	GameState.awaiting_new_game = true
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().create_timer(1.0).timeout
	await _shot("20-new-game")

	var office := get_tree().current_scene
	office.call("_on_protagonist_chosen", "PC01")
	await get_tree().create_timer(0.3).timeout
	await _shot("20a-office-background")
	GameState.meta["Funds"] = 900000
	office.call("_show_supplies")
	await get_tree().create_timer(0.5).timeout
	await _shot("21-supplies-scrollbar")
	(office.get_node("SuppliesPanel") as Overlay).close()

	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.levels[1])))
	get_tree().change_scene_to_file("res://scenes/battle/BattleScreen.tscn")
	await get_tree().create_timer(1.2).timeout
	var battle := get_tree().current_scene
	await _shot("22a-battle-open")

	for card: Node in battle.get_node("%HandRow").get_children():
		if card is CardView and not (card as CardView).disabled:
			battle.call("_on_card_flung", (card as CardView).card_id)
			break
	await get_tree().create_timer(0.35).timeout
	await _shot("22-banner-player")
	(battle.get_node("CueBanner") as CueBanner).clear()
	battle.call("_on_end_turn")
	await get_tree().create_timer(0.35).timeout
	await _shot("23-banner-opponent")

	print("SHOTS DONE")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
