extends Node
## Entry point for the week interaction test: hands the work to a driver placed
## outside the current scene (see loop_driver.gd for why).

func _ready() -> void:
	var driver := WeekDriver.new()
	driver.name = "WeekDriver"
	get_tree().root.add_child.call_deferred(driver)
