extends Node
## Entry point for the rapid-fire real-click stress test (see mash_driver.gd
## for what it actually checks and why).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/mash_test.tscn
##
## Hands the work to a driver placed outside the current scene, the same
## reason shop_items_test.gd/floor_vote_test.gd do — a change_scene_to_file()
## partway through would otherwise free this very node.

func _ready() -> void:
	var driver := MashDriver.new()
	driver.name = "MashDriver"
	get_tree().root.add_child.call_deferred(driver)
