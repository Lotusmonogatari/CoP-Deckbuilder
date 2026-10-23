extends Node
## Entry point for the events interaction test (see loop_driver.gd for why a
## driver sits outside the current scene).

func _ready() -> void:
	var driver := EventDriver.new()
	driver.name = "EventDriver"
	get_tree().root.add_child.call_deferred(driver)
