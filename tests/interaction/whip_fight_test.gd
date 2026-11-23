extends Node
## Entry point for the whip-fight click test (P15).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/whip_fight_test.tscn

func _ready() -> void:
	var driver := WhipFightDriver.new()
	driver.name = "WhipFightDriver"
	get_tree().root.add_child.call_deferred(driver)
