extends Node
## Entry point for the loop test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/loop_test.tscn
##
## All this does is hand the work to a driver placed outside the current
## scene. The driver has to outlive the scene changes it causes; see
## loop_driver.gd for why.

func _ready() -> void:
	var driver := LoopDriver.new()
	driver.name = "LoopDriver"
	get_tree().root.add_child.call_deferred(driver)
