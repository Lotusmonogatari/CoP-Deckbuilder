extends Node
## Entry point for the Campaign Office click test (P20 phase B).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/campaign_test.tscn

func _ready() -> void:
	var driver := CampaignDriver.new()
	driver.name = "CampaignDriver"
	get_tree().root.add_child.call_deferred(driver)
