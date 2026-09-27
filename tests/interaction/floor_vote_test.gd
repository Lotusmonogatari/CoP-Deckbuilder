extends Node
## Entry point for the Floor Vote interaction test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/floor_vote_test.tscn
##
## All this does is hand the work to a driver placed outside the current
## scene — see loop_driver.gd's own comment for why that has to happen.

func _ready() -> void:
	var driver := FloorVoteDriver.new()
	driver.name = "FloorVoteDriver"
	get_tree().root.add_child.call_deferred(driver)
