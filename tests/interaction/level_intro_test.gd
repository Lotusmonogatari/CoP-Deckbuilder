extends Node
## Entry point for the Level Intro interaction test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/level_intro_test.tscn
##
## All this does is hand the work to a driver placed outside the current
## scene — see loop_driver.gd's own comment for why that has to happen.

func _ready() -> void:
	var driver := LevelIntroDriver.new()
	driver.name = "LevelIntroDriver"
	get_tree().root.add_child.call_deferred(driver)
