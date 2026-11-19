extends Node
## Entry point for the level bonus interaction test (see loop_driver.gd for why a driver sits outside the
## current scene).

func _ready() -> void:
	var driver := LevelBonusDriver.new()
	driver.name = "LevelBonusDriver"
	get_tree().root.add_child.call_deferred(driver)
