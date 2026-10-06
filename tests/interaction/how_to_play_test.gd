extends Node
## Entry point for the How to Play click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/how_to_play_test.tscn
##
## Hands the work to a driver outside the current scene, which has to outlive
## the change between the title screen and the Office; see
## how_to_play_driver.gd.

func _ready() -> void:
	var driver := HowToPlayDriver.new()
	driver.name = "HowToPlayDriver"
	get_tree().root.add_child.call_deferred(driver)
