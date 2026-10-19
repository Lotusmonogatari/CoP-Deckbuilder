extends Node
## Entry point for the Draft a Bill click test.
##
##     xvfb-run .tools/godot --path . tests/interaction/draft_test.tscn

func _ready() -> void:
	var driver := DraftDriver.new()
	driver.name = "DraftDriver"
	get_tree().root.add_child.call_deferred(driver)
