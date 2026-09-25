extends Node
## Entry point for the SH13-19 Supplies click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/shop_items_test.tscn
##
## Hands the work to a driver placed outside the current scene, the same
## reason inventory_driver.gd does.

func _ready() -> void:
	var driver := ShopItemsDriver.new()
	driver.name = "ShopItemsDriver"
	get_tree().root.add_child.call_deferred(driver)
