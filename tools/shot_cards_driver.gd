extends Node
## Photographs the cards, so a change to the frames can be looked at.
##
##     xvfb-run -a --server-args="-screen 0 1080x2340x24" \
##         godot --path . tools/shot_cards.tscn
##
## Writes two PNGs to user://shots/ — the hand as it is dealt, and one card
## turned over. On Linux that is
## ~/.local/share/godot/app_userdata/Coliseum of Parliament/shots/.
##
## WHY THIS EXISTS
## The card frames are artwork with text positioned over measured regions of
## it, and nothing in the test suite can tell you whether the result reads
## properly. A screenshot can. It is not part of tools/verify.sh: it proves
## nothing a build server could act on, and it needs a screen.

const SHOTS := "user://shots/"

## Which level to open. 1 is Bill on the Floor, whose floor debate deals a
## full five-card hand — the case where the row has to scroll.
const LEVEL := 1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	await get_tree().process_frame

	GameState.begin_level(LevelRunner.new(DataDB.levels[LEVEL]))
	get_tree().change_scene_to_file("res://scenes/battle/BattleScreen.tscn")
	await get_tree().create_timer(1.2).timeout
	await _shot("10-hand")

	# And a card turned over, which is the whole of the back frame's job.
	var screen := get_tree().current_scene
	var hand := screen.get_node("%HandRow")
	if hand.get_child_count() > 0:
		screen.call("_on_card_chosen", (hand.get_child(0) as CardView).card_id)
		await get_tree().create_timer(0.8).timeout
		await _shot("11-card-back")

	print("SHOTS DONE")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	# After the draw, not before: grabbing the viewport mid-frame gives you
	# the previous one, which is how a screenshot ends up showing the layout
	# you just changed away from.
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
