extends Node
## Photographs the New Game screen, the cue banner and a long scrolling list.
##
##     xvfb-run -a --server-args="-screen 0 1080x2340x24" \
##         godot --path . tools/shot_features.tscn
##
## Writes PNGs to user://shots/. Like shot_cards, it proves nothing a build
## server could act on; it is for looking at.

const SHOTS := "user://shots/"


func _ready() -> void:
	var driver := Node.new()
	driver.set_script(load("res://tools/shot_features_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
