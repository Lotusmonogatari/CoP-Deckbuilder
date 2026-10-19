extends Node
## Entry point for the member visit interaction test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/visit_test.tscn
##
## Hands the work to a driver placed outside the current scene (see
## loop_driver.gd for why).

func _ready() -> void:
	var driver := VisitDriver.new()
	driver.name = "VisitDriver"
	get_tree().root.add_child.call_deferred(driver)
