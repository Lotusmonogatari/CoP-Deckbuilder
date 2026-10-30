extends Node
## Entry point for the event picture drag / tilt click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/image_pan_test.tscn

func _ready() -> void:
	var driver := ImagePanDriver.new()
	driver.name = "ImagePanDriver"
	get_tree().root.add_child.call_deferred(driver)
