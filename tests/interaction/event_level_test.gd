extends Node
## Entry point for the event-starts-a-level click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/event_level_test.tscn

func _ready() -> void:
	var driver := EventLevelDriver.new()
	driver.name = "EventLevelDriver"
	get_tree().root.add_child.call_deferred(driver)
