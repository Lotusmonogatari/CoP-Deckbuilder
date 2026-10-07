extends Node
## Entry point for the Staff Profile click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/staff_profile_test.tscn

func _ready() -> void:
	var driver := StaffProfileDriver.new()
	driver.name = "StaffProfileDriver"
	get_tree().root.add_child.call_deferred(driver)
