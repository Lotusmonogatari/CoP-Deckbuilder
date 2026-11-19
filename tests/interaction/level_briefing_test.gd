extends Node
## Entry point for the level briefing interaction test (see loop_driver.gd for why a driver sits outside the current scene).

func _ready() -> void:
	var driver := LevelBriefingDriver.new()
	driver.name = "LevelBriefingDriver"
	get_tree().root.add_child.call_deferred(driver)
