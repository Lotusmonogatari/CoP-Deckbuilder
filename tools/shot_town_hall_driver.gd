extends Node
## The work for shot_town_hall.tscn, kept outside the scene it changes away
## from — see shot_features_driver.gd's own comment for why.

const SHOTS := "user://shots/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)

	# LV01's own stage is ST05 Town Hall — the room this change is about.
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.levels[0])))
	get_tree().change_scene_to_file("res://scenes/battle/BattleScreen.tscn")
	await get_tree().create_timer(1.0).timeout
	var battle := get_tree().current_scene

	# 1. The room's opening word: the drawn question, on the banner, by
	# default — nothing else competing for it.
	await _shot("30-question-on-open")

	# Skip past it the way a player taps through, so the room underneath —
	# %RoomNotice hidden, nothing left over from a turn that hasn't happened
	# yet — is visible on its own too.
	var banner := battle.get_node("CueBanner")
	banner.call("skip")
	await get_tree().create_timer(0.2).timeout
	await _shot("31-question-skipped-room-notice-hidden")

	# 2. Play a card — the player's own cue banner, unchanged by this work.
	for card: Node in battle.get_node("%HandRow").get_children():
		if card is CardView and not (card as CardView).disabled:
			battle.call("_on_card_flung", (card as CardView).card_id)
			break
	await get_tree().create_timer(0.35).timeout
	await _shot("32-player-card-cue")
	banner.call("clear")

	# 3. End the turn: what happened lands in %RoomNotice; the banner moves
	# straight on to the NEXT drawn question rather than narration.
	battle.call("_on_end_turn")
	await get_tree().create_timer(0.35).timeout
	await _shot("33-room-notice-and-next-question")

	print("SHOTS DONE")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
