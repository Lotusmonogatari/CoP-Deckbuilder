extends Node
## Entry point for the promises click test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/promises_test.tscn

func _ready() -> void:
	var driver := PromisesDriver.new()
	driver.name = "PromisesDriver"
	get_tree().root.add_child.call_deferred(driver)
