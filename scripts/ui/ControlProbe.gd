class_name ControlProbe
extends RefCounted
## Turns the screen showing into a list of boxes for LayoutWatch (2026-11-19): every visible control
## with where it is, what it says and what holds it. Reading only; nothing is changed.
##
## Left out on purpose: anything hidden (and everything inside it), anything fully see-through, and the
## insides of a SubViewport (its coordinates are its own). Kept but flagged: what sits inside a
## scrolling list ("scrolled": running past the screen's edge is normal there, but being outside the
## group that holds it is not) and cards ("skip": a hand of cards overlaps and fans on purpose).


## Boxes in drawing order (a later box is drawn over an earlier one), paths relative to `root`.
static func collect(root: Node) -> Array:
	var boxes: Array = []
	if root != null:
		_walk(root, root, false, false, boxes)
	return boxes


static func _walk(node: Node, root: Node, scrolled: bool, in_card: bool, boxes: Array) -> void:
	for child in node.get_children():
		if child is SubViewport:
			continue
		if child is CanvasLayer and not (child as CanvasLayer).visible:
			continue
		if not (child is Control):
			_walk(child, root, scrolled, in_card, boxes)
			continue
		var control := child as Control
		if not control.visible or control.modulate.a < 0.05:
			continue
		var card := in_card or _is_card(control)
		var rect := control.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			boxes.append({
				"path": str(root.get_path_to(control)),
				"kind": _kind_of(control),
				"text": _text_of(control),
				"rect": rect,
				"parent_rect": _group_rect(control),
				"interactive": control is BaseButton,
				"scrolled": scrolled,
				"skip": card,
			})
		_walk(control, root, scrolled or control is ScrollContainer, card, boxes)


## The box of the container that holds `control`, when that container lays its children out (a grid,
## a row, a margin). A scrolling list and a control that opted out of layout give none.
static func _group_rect(control: Control) -> Variant:
	var parent := control.get_parent()
	if control.top_level or not (parent is Container) or parent is ScrollContainer:
		return null
	return (parent as Control).get_global_rect()


static func _is_card(control: Control) -> bool:
	var script: Script = control.get_script()
	if script == null:
		return false
	var script_name := str(script.get_global_name())
	return script_name == "CardView" or script_name == "CardBackView"


static func _kind_of(control: Control) -> String:
	var script: Script = control.get_script()
	if script != null and not str(script.get_global_name()).is_empty():
		return str(script.get_global_name())
	return control.get_class()


static func _text_of(control: Control) -> String:
	if not ("text" in control):
		return ""
	var text := str(control.get("text")).replace("\n", " ").strip_edges()
	return text.substr(0, 40) + "..." if text.length() > 43 else text
