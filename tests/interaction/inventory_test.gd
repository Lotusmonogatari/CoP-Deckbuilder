extends Node
## Entry point for the inventory click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/inventory_test.tscn
##
## Hands the work to a driver placed outside the current scene, which has to
## outlive the scene change into battle; see inventory_driver.gd.

func _ready() -> void:
	var driver := InventoryDriver.new()
	driver.name = "InventoryDriver"
	get_tree().root.add_child.call_deferred(driver)
