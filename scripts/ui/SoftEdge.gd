class_name SoftEdge
extends RefCounted
## A soft, fading edge for a plain dark or grey box (2026-11-02, Cameron).
##
## PlaceholderArt already fades a picture where it ends against something else
## (assets/shaders/soft_edge.gdshader). This puts the same fade on a panel's own
## background, so a veil behind text, or the dark box of an end-of-stage panel,
## melts into the picture around it instead of ending at a hard line. Only the
## panel's own fill fades: its children (the text) are drawn separately and stay
## sharp. The width is the Balance lever "Panel edge fade"; 0 turns it off.

const SHADER := preload("res://assets/shaders/soft_edge.gdshader")

## All four sides, or pick which sides melt: (left, top, right, bottom), 1 = fade.
const ALL_SIDES := Vector4(1.0, 1.0, 1.0, 1.0)
const TOP_ONLY := Vector4(0.0, 1.0, 0.0, 0.0)


static func width_from_balance() -> float:
	return float(DataDB.balance.get("panel_edge_fade", 0))


## Fades `box`'s own background on the chosen sides, and keeps doing so as it resizes.
static func apply(box: Control, sides: Vector4 = ALL_SIDES, width: float = -1.0) -> void:
	if width < 0.0:
		width = width_from_balance()
	if width <= 0.0:
		box.material = null
		return
	var material := ShaderMaterial.new()
	material.shader = SHADER
	box.material = material
	var refit := _refit.bind(box, sides, width)
	if not box.resized.is_connected(refit):
		box.resized.connect(refit)
	_refit(box, sides, width)


static func _refit(box: Control, sides: Vector4, width: float) -> void:
	var material := box.material as ShaderMaterial
	if material == null:
		return
	var reach := minf(width, minf(box.size.x, box.size.y) * 0.5)
	material.set_shader_parameter("box_rect", Vector4(0.0, 0.0, box.size.x, box.size.y))
	material.set_shader_parameter("fade", Vector4(sides.x * reach, sides.y * reach, sides.z * reach, sides.w * reach))
