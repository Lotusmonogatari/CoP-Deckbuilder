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

## The player's own settings, kept apart from the save so starting a new game
## never resets them.
const SETTINGS_PATH := "user://settings.json"

var text_size_setting := TextScale.NORMAL
## The theme's own font sizes as authored, so scaling is never compounded.
var _original_sizes := {}   # "Type/name" -> int
var _original_default := 0

var insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}


func _ready() -> void:
	_load_settings()
	apply_text_scale()
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


## Cycles Small -> Normal -> Large, applies it and remembers it.
func cycle_text_size() -> String:
	text_size_setting = TextScale.next(text_size_setting)
	apply_text_scale()
	_save_settings()
	return text_size_setting


## Multiplies every font size in the project theme by the chosen factor, from
## the authored sizes (so Small then Large is not Small-of-Large).
func apply_text_scale() -> void:
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		return
	if _original_sizes.is_empty():
		_original_default = theme.default_font_size
		for type_name: String in theme.get_font_size_type_list():
			for item: String in theme.get_font_size_list(type_name):
				_original_sizes["%s/%s" % [type_name, item]] = theme.get_font_size(item, type_name)
	var factor := TextScale.factor(text_size_setting, DataDB.balance)
	if _original_default > 0:
		theme.default_font_size = TextScale.scaled(_original_default, factor)
	for key: String in _original_sizes:
		var parts := key.split("/")
		theme.set_font_size(parts[1], parts[0], TextScale.scaled(int(_original_sizes[key]), factor))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and str(parsed.get("text_size", "")) in TextScale.ORDER:
		text_size_setting = str(parsed["text_size"])


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"text_size": text_size_setting}))
