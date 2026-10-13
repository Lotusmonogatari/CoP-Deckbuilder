extends Node
## Device safe-area handling (plan step 1, design/DYNAMIC_SCREEN_PLAN.md).
##
## Every full-screen margin container in the game is named "Safe" (the
## screens) or "Margin" (the panels). When one enters the tree this keeps
## its designed margins and raises each side to the device's own inset if
## that is larger, so no scene file carries a device number and a new screen
## gets the behaviour just by using the same name. The maths is SafeArea.gd.

const NAMES := ["Safe", "Margin"]
const SIDES := ["left", "top", "right", "bottom"]
## Content never gets wider than the design width; a wider screen (tablet)
## keeps a centred column and shows the room's background down the sides.
const MAX_COLUMN := 1080.0

var insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}


func _ready() -> void:
	refresh()
	get_tree().node_added.connect(_on_node_added)
	get_tree().root.size_changed.connect(_on_resized)


## Re-reads the display. Called at start and whenever the window changes
## (rotation locks and foldables can change the safe area).
func refresh() -> void:
	var window := Vector2(DisplayServer.window_get_size())
	var viewport := get_tree().root.get_visible_rect().size
	insets = SafeArea.insets(Rect2(DisplayServer.get_display_safe_area()), window, viewport)


func _on_resized() -> void:
	refresh()
	for node in get_tree().root.find_children("*", "MarginContainer", true, false):
		_apply(node as MarginContainer)


func _on_node_added(node: Node) -> void:
	if node is MarginContainer and node.name in NAMES:
		# Its theme overrides are set by the scene/script before it enters
		# the tree, so they can be read straight away.
		_apply(node as MarginContainer)


func _apply(margin: MarginContainer) -> void:
	if margin.name not in NAMES:
		return
	var wide := 0
	if margin.is_inside_tree():
		wide = SafeArea.side_extra(margin.get_viewport().get_visible_rect().size.x, MAX_COLUMN)
	for side: String in SIDES:
		var key := "margin_" + side
		var meta := "designed_" + key
		if not margin.has_meta(meta):
			margin.set_meta(meta, margin.get_theme_constant(key))
		var sideways := side == "left" or side == "right"
		var designed := int(margin.get_meta(meta)) + (wide if sideways else 0)
		margin.add_theme_constant_override(
			key, SafeArea.margin_for(designed, float(insets[side])))
