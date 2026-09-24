extends Node
## Entry point for the New Game click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/new_game_test.tscn
##
## Hands the work to a driver placed outside the current scene, which has to
## outlive the change into the Office; see new_game_driver.gd.

func _ready() -> void:
	var driver := NewGameDriver.new()
	driver.name = "NewGameDriver"
	get_tree().root.add_child.call_deferred(driver)
