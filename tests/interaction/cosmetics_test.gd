extends Node
## Entry point for the Cosmetics click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/cosmetics_test.tscn
##
## Hands the work to a driver placed outside the current scene, the same
## reason inventory_driver.gd/loop_driver.gd need to; see cosmetics_driver.gd.

func _ready() -> void:
	var driver := CosmeticsDriver.new()
	driver.name = "CosmeticsDriver"
	get_tree().root.add_child.call_deferred(driver)
