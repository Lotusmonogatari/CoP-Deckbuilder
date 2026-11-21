extends Node
## Entry point for the Optional-Decision!-scene click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/optional_scene_test.tscn

func _ready() -> void:
	var driver := OptionalSceneDriver.new()
	driver.name = "OptionalSceneDriver"
	get_tree().root.add_child.call_deferred(driver)
