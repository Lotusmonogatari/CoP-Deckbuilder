extends Node
## Entry point for the hosted-event interaction test (see loop_driver.gd for why
## a driver sits outside the current scene).

func _ready() -> void:
	var driver := HostedDriver.new()
	driver.name = "HostedDriver"
	get_tree().root.add_child.call_deferred(driver)
