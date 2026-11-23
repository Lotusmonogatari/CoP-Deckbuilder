extends Node
## Entry point for the P15 screenshots: the driver goes on the root so it survives the scene changes (see p15_shots_driver.gd).

func _ready() -> void:
	var driver := Node.new()
	driver.name = "P15ShotsDriver"
	driver.set_script(load("res://tools/p15_shots_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
