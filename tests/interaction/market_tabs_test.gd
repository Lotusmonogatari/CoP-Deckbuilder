extends Node
## Entry point for the Marketplace tabs click test (2026-10-31):
##     xvfb-run .tools/godot --path . tests/interaction/market_tabs_test.tscn

func _ready() -> void:
	var driver := MarketTabsDriver.new()
	driver.name = "MarketTabsDriver"
	get_tree().root.add_child.call_deferred(driver)
