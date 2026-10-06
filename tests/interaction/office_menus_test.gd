extends Node
## Entry point for the Office menus click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/office_menus_test.tscn
##
## Hands the work to a driver outside the current scene; see
## office_menus_driver.gd.

func _ready() -> void:
	var driver := OfficeMenusDriver.new()
	driver.name = "OfficeMenusDriver"
	get_tree().root.add_child.call_deferred(driver)
