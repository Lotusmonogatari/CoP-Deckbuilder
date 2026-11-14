extends Node
## Audit Phase 4, technical probe (needs a display: run under xvfb-run).
## Measures what tools/benchmark.gd does not: draw calls per frame, which nodes
## still run _process on an idle screen, memory growth across repeated stage
## loads, save size and save time, and save/load round trip (INV-24).
##
##   xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . \
##       --resolution 1080x2340 audit/tests/tech_probe.tscn
##   AUDIT_OUT=/path/out.json

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
var _out := {}


func _ready() -> void:
	var probe := AuditTechProbe.new()
	probe.name = "AuditTechProbe"
	get_tree().root.add_child.call_deferred(probe)
