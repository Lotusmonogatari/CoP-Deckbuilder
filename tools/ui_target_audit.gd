extends Node
## Touch-target audit (MC²T, 2026-11-06). Opens each screen and panel of the
## game, walks the scene tree and records the size of every visible tappable
## control (buttons, cards, scroll bars, sliders), in the game's base pixels
## (1080 wide). tools/ui_target_audit.py turns the JSON into dp, points and
## millimetres and a report.
##
##   xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . tools/ui_target_audit.tscn
##   (AUDIT_OUT=/some/file.json to choose where the JSON goes)
##
## The driver adds itself to the scene root so scene changes do not free it.

var _rows: Array = []


func _ready() -> void:
	var driver := Node.new()
	driver.name = "TargetAuditDriver"
	driver.set_script(load("res://tools/ui_target_audit_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
