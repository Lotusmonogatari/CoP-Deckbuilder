extends Node
## Entry point for the Requests click test.
##
##     xvfb-run .tools/godot --path . tests/interaction/requests_test.tscn

func _ready() -> void:
	var driver := RequestsDriver.new()
	driver.name = "RequestsDriver"
	get_tree().root.add_child.call_deferred(driver)
