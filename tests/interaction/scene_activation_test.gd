extends Node
## Entry point for the Decision!-scene-starts-a-vote click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/scene_activation_test.tscn

func _ready() -> void:
	var driver := SceneActivationDriver.new()
	driver.name = "SceneActivationDriver"
	get_tree().root.add_child.call_deferred(driver)
