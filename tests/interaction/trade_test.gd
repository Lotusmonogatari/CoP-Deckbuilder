extends Node
## Entry point for the lobbyist trade interaction test.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/trade_test.tscn

func _ready() -> void:
	var driver := TradeDriver.new()
	driver.name = "TradeDriver"
	get_tree().root.add_child.call_deferred(driver)
