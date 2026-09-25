extends Node
## Photographs the Recruitment shop's Fire flow — hiring, the severance
## warning, a firing going through, and re-filling the vacated role.
##
##     xvfb-run -a --server-args="-screen 0 1080x2340x24" \
##         godot --path . tools/shot_staff.tscn
##
## Writes PNGs to user://shots/. Like shot_features, it proves nothing a
## build server could act on; it is for looking at. See
## design/proposals/staff_firing.md.

const SHOTS := "user://shots/"


func _ready() -> void:
	var driver := Node.new()
	driver.set_script(load("res://tools/shot_staff_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
