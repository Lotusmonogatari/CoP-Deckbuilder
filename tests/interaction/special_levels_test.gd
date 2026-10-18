extends Node
## Entry point for the Special Levels click test.
##
##     xvfb-run .tools/godot --path . tests/interaction/special_levels_test.tscn

func _ready() -> void:
	var driver := SpecialLevelsDriver.new()
	driver.name = "SpecialLevelsDriver"
	get_tree().root.add_child.call_deferred(driver)
