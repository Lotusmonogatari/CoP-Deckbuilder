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

## Button outlines (Cameron, 2026-10-15): every button gets a 5 px outline in
## the player's party colour; a button that backs out of a screen gets a white
## one. Built into the project theme at run time, because the colour depends
## on which protagonist is playing; changing the colour later just edits the
## same style boxes, so buttons already on screen follow it.
const OUTLINE_WIDTH := 5
const CANCEL_VARIATION := "CancelButton"
const BUTTON_STATES := ["normal", "hover", "pressed", "disabled", "hover_pressed"]
## Node names of buttons that get the white outline: the ones that go back or
## close rather than forward, plus the battle screen's own End Turn,
## Inventory and Details (Cameron, 2026-10-15).
const CANCEL_NAMES := ["Back", "DetailsClose", "ZoomClose", "LeaveButton",
	"EndTurnButton", "InventoryButton", "DetailsButton"]
## What an outline is before a run has a protagonist (the title screen).
const NO_PARTY_OUTLINE := Color(1, 1, 1, 0.55)

var _outline_party := "<unset>"
var _party_styles: Array[StyleBoxFlat] = []

var insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}


func _ready() -> void:
	_load_settings()
	apply_text_scale()
	_build_button_outlines()
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


func _process(_delta: float) -> void:
	# The protagonist is chosen at New Game; follow the party when it changes.
	var party := PartyDisplay.party_name(DataDB.player)
	if party != _outline_party:
		_outline_party = party
		_recolour_outlines()


func _on_node_added(node: Node) -> void:
	if node is Button and node.get_class() == "Button":
		_mark_cancel(node as Button)
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


## One set of outlined style boxes for ordinary buttons (party colour) and a
## copy for cancel buttons (white). Each starts from Godot's own button look
## for that state, so only the outline changes.
func _build_button_outlines() -> void:
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		return
	var base := ThemeDB.get_default_theme()
	theme.add_type(CANCEL_VARIATION)
	theme.set_type_variation(CANCEL_VARIATION, "Button")
	for state: String in BUTTON_STATES:
		var source := base.get_stylebox(state if state != "hover_pressed" else "pressed", "Button")
		if not source is StyleBoxFlat:
			continue
		var party_box := _outlined(source as StyleBoxFlat, NO_PARTY_OUTLINE)
		theme.set_stylebox(state, "Button", party_box)
		_party_styles.append(party_box)
		theme.set_stylebox(state, CANCEL_VARIATION, _outlined(source as StyleBoxFlat, Color.WHITE))


func _outlined(source: StyleBoxFlat, colour: Color) -> StyleBoxFlat:
	var box := source.duplicate() as StyleBoxFlat
	box.set_border_width_all(OUTLINE_WIDTH)
	box.border_color = colour
	box.set_corner_radius_all(maxi(box.corner_radius_top_left, 10))
	# Keep the label clear of the thicker edge.
	box.content_margin_left = maxf(box.content_margin_left, 12.0)
	box.content_margin_right = maxf(box.content_margin_right, 12.0)
	box.content_margin_top = maxf(box.content_margin_top, 8.0)
	box.content_margin_bottom = maxf(box.content_margin_bottom, 8.0)
	return box


func _recolour_outlines() -> void:
	var row := DataDB.get_party(PartyDisplay.party_name(DataDB.player))
	var colour := PartyDisplay.color_for(row) if not row.is_empty() else NO_PARTY_OUTLINE
	for box in _party_styles:
		box.border_color = colour


## True for a button that backs out of a screen (white outline).
static func is_cancel_button(button: Button) -> bool:
	return str(button.name) in CANCEL_NAMES or bool(button.get_meta("cancel", false))


func _mark_cancel(button: Button) -> void:
	if is_cancel_button(button):
		button.theme_type_variation = CANCEL_VARIATION
