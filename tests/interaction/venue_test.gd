extends Node
## Entry point for the Capitol venues click test (P16).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/venue_test.tscn

func _ready() -> void:
	var driver := VenueDriver.new()
	driver.name = "VenueDriver"
	get_tree().root.add_child.call_deferred(driver)
