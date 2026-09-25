extends Node
## Entry point for the Intro (title) screen click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/intro_test.tscn
##
## Hands the work to a driver placed outside the current scene, which has to
## outlive the changes between the Intro screen and the Office; see
## intro_driver.gd.

func _ready() -> void:
	var driver := IntroDriver.new()
	driver.name = "IntroDriver"
	get_tree().root.add_child.call_deferred(driver)
