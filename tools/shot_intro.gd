extends Node
## Photographs the Intro (title) screen. Same convention as shot_features.gd.
##
##     xvfb-run -a --server-args="-screen 0 1080x2340x24" \
##         godot --path . tools/shot_intro.tscn
##
## Writes PNGs to user://shots/. For looking at, not for a build server.

const SHOTS := "user://shots/"


func _ready() -> void:
	var driver := Node.new()
	driver.set_script(load("res://tools/shot_intro_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
