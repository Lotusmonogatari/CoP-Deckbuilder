extends Node
## Entry point for the Office Hours interaction test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/office_hours_test.tscn
##
## All this does is hand the work to a driver placed outside the current
## scene — see loop_driver.gd's own comment for why that has to happen.

func _ready() -> void:
	var driver := OfficeHoursDriver.new()
	driver.name = "OfficeHoursDriver"
	get_tree().root.add_child.call_deferred(driver)
