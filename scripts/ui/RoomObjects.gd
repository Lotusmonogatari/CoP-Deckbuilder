class_name RoomObjects
extends RefCounted
## Living Office's room objects (P9, 2026-11-17): the Office's menu is the room. Five of its
## buttons (Events, Reputation and Results, Promises, Office Management, Marketplace) are moved
## onto the picture as lamp pins, each at a place the hand-written `office_hotspots` key of
## data/art.json gives for the Office picture in use (OFFICE or OFFICE_UPGRADED), as fractions of
## the screen.
##
## THE BUTTONS ARE THE SAME BUTTONS. They keep their names, their text and their handlers; only their
## parent, position and look change, so every destination, count and refusal reads the same in
## every style and the click tests still find them. Each pin is at least 122 px (44 pt) tall and
## carries its label all the time: the room is never a hunt.

const PIN_SIZE := Vector2(380, 122)
const LAMP := 38.0
const LAYER_NAME := "RoomObjects"


## The hotspot set for the Office picture in use.
static func hotspots() -> Dictionary:
	var all: Variant = DataDB.art.get("office_hotspots", {})
	if not all is Dictionary:
		return {}
	var key := "OFFICE_UPGRADED" if _upgraded() else "OFFICE"
	var set: Variant = (all as Dictionary).get(key, {})
	return set if set is Dictionary else {}


static func _upgraded() -> bool:
	var package_id := str(GameState.active_cosmetics.get(CosmeticPieces.BACKGROUND, ""))
	if package_id.is_empty():
		return false
	return CosmeticPieces.field(DataDB.get_cosmetic_package(package_id), "background_variant") == "UPGRADED"


## Moves `pins` ({ key: Button }) onto a layer over the Office. Safe to call again: it does nothing
## once the layer exists. Returns the layer, or null when this is not the Living Office style.
static func install(office: Control, pins: Dictionary) -> Control:
	if UiStyle.current() != UiStyles.LIVING_OFFICE:
		return null
	if office.has_node(LAYER_NAME):
		return office.get_node(LAYER_NAME)
	var places := hotspots()
	var layer := Control.new()
	layer.name = LAYER_NAME
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office.add_child(layer)
	# Over the screen's own column, under every panel that opens later.
	var safe := office.get_node_or_null("Safe")
	if safe != null:
		office.move_child(layer, safe.get_index() + 1)
	for key: String in pins:
		var button: Button = pins[key]
		var place: Variant = places.get(key)
		if button == null or not place is Array or (place as Array).size() < 2:
			continue
		var was_unique := button.unique_name_in_owner
		if button.get_parent() != null:
			button.get_parent().remove_child(button)
		layer.add_child(button)
		# Removing a node clears its owner; the screen finds some of these buttons as %Name.
		if was_unique:
			button.owner = office
			button.unique_name_in_owner = true
		_place(button, float((place as Array)[0]), float((place as Array)[1]))
	return layer


static func _place(button: Button, x: float, y: float) -> void:
	button.custom_minimum_size = PIN_SIZE
	button.size_flags_horizontal = 0
	button.anchor_left = x
	button.anchor_right = x
	button.anchor_top = y
	button.anchor_bottom = y
	button.offset_left = -PIN_SIZE.x * 0.5
	button.offset_right = PIN_SIZE.x * 0.5
	button.offset_top = -PIN_SIZE.y * 0.5
	button.offset_bottom = PIN_SIZE.y * 0.5
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var plate := UiStyle.plate_colour()
	var accent := UiStyle.colour("accent", Color(1.0, 0.84, 0.54))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(plate.r, plate.g, plate.b, 0.9)
	box.border_color = accent
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(PIN_SIZE.y * 0.5))
	box.content_margin_left = LAMP + 44.0
	box.content_margin_right = 24.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, box)
	if button.get_node_or_null("Lamp") == null:
		var lamp := Panel.new()
		lamp.name = "Lamp"
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glow := StyleBoxFlat.new()
		glow.bg_color = accent
		glow.set_corner_radius_all(int(LAMP * 0.5))
		glow.shadow_color = Color(accent.r, accent.g, accent.b, 0.55)
		glow.shadow_size = 10
		lamp.add_theme_stylebox_override("panel", glow)
		lamp.anchor_top = 0.5
		lamp.anchor_bottom = 0.5
		lamp.offset_left = 26.0
		lamp.offset_right = 26.0 + LAMP
		lamp.offset_top = -LAMP * 0.5
		lamp.offset_bottom = LAMP * 0.5
		button.add_child(lamp)
