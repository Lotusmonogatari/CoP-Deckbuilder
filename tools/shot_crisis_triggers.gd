extends Node
## Photographs the crisis-trigger flow: a Very Hard start (party support 0),
## a stage finishing, the Town Hall/Steering Committee getting forced into
## the queue, funding frozen, and the Office alert reporting all of it.
##
##     xvfb-run -a --server-args="-screen 0 1080x2340x24" \
##         godot --path . tools/shot_crisis_triggers.tscn
##
## Writes PNGs to user://shots/. For looking at, same as every other shot_*.

const SHOTS := "user://shots/"


func _ready() -> void:
	var driver := Node.new()
	driver.set_script(load("res://tools/shot_crisis_triggers_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
