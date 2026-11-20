extends Node
## Entry point for the travel interaction test (see loop_driver.gd for why a driver sits outside the current scene).

func _ready() -> void:
	var driver := TravelDriver.new()
	driver.name = "TravelDriver"
	get_tree().root.add_child.call_deferred(driver)
