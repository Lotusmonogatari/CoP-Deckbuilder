class_name OrgChip
extends RefCounted
## "An organization's standing moved by N", drawn as a picture instead of a
## sentence (2026-10-20): the organization's icon with a soft green (gain),
## red (loss) or grey (no change) fade over it and the signed number in the
## fade. Tapping the chip opens a small overlay with the organization's name,
## so the name is one tap away without being printed beside every number.
##
## A target can be an organization (BOxx) or an audience group (SGxx); both
## have an icon and a name in the data. A preview (what a choice WOULD do)
## wears a white outline, so it never reads as something that already
## happened. Names come from the data, never from a script.

const CHIP_SIZE := 120.0
const NAME_LAYER := 80

## Shared with the battle Outcome panel and the listening strip.
const GAIN := ListeningStrip.GAIN
const LOSS := ListeningStrip.LOSS
const NEUTRAL := ListeningStrip.NEUTRAL


## The display name of a BOxx or SGxx target, "" when the data has none.
static func name_of(target_id: String) -> String:
	var found: Dictionary = DataDB.get_booster(target_id)
	if found.is_empty():
		found = DataDB.get_segment(target_id)
	return str(found.get("name_en", ""))


## One chip. `delta` is the signed change; `preview` marks a pending one.
static func make(target_id: String, delta: int, preview: bool = false, size: float = CHIP_SIZE,
		numbered: bool = true) -> Button:
	var chip := Button.new()
	chip.name = "OrgChip_%s" % target_id
	chip.icon = ArtLoader.icon(target_id)
	chip.expand_icon = true
	chip.custom_minimum_size = Vector2(size, size)
	chip.focus_mode = Control.FOCUS_NONE
	chip.set_meta("target_id", target_id)
	chip.set_meta("delta", delta)
	chip.set_meta("preview", preview)
	chip.tooltip_text = name_of(target_id)
	_dress(chip, delta, preview, size, numbered)
	chip.pressed.connect(show_name.bind(chip, name_of(target_id)))
	return chip


## A row of side chips: no numbers, green for "with" and red for "against".
static func side_row(ids: Array, supports: bool, size: float = 90.0) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.name = "OrgSideRow"
	flow.add_theme_constant_override("h_separation", 12)
	for id: Variant in ids:
		if not name_of(str(id)).is_empty():
			flow.add_child(make(str(id), 1 if supports else -1, false, size, false))
	return flow


## A wrapping row of chips from [{ "id" or "target": String, "delta": int }],
## biggest gain first, biggest loss last (ties keep their order). Entries with
## no icon or name in the data are skipped, like every other missing-data case.
static func row(entries: Array, preview: bool = false, size: float = CHIP_SIZE) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.name = "OrgChipRow"
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	for entry: Dictionary in sorted(entries):
		var id := str(entry.get("id", entry.get("target", "")))
		if name_of(id).is_empty():
			continue
		flow.add_child(make(id, int(entry.get("delta", 0)), preview, size))
	return flow


## The same entries, highest delta first; stable for ties.
static func sorted(entries: Array) -> Array:
	var indexed: Array = []
	for i in entries.size():
		indexed.append([i, entries[i]])
	indexed.sort_custom(func(a: Array, b: Array) -> bool:
		var da := int((a[1] as Dictionary).get("delta", 0))
		var db := int((b[1] as Dictionary).get("delta", 0))
		return da > db or (da == db and int(a[0]) < int(b[0])))
	var out: Array = []
	for pair: Array in indexed:
		out.append(pair[1])
	return out


## Folds repeated targets together (two effects on one organization read as
## one chip) and drops anything that is not a BOxx/SGxx target.
static func merged(entries: Array) -> Array:
	var order: Array[String] = []
	var totals: Dictionary = {}
	for entry: Dictionary in entries:
		var id := str(entry.get("id", entry.get("target", "")))
		if name_of(id).is_empty():
			continue
		if not totals.has(id):
			order.append(id)
			totals[id] = 0
		totals[id] = int(totals[id]) + int(entry.get("delta", 0))
	var out: Array = []
	for id: String in order:
		out.append({"id": id, "delta": int(totals[id])})
	return out


## The fade and the number, over the icon.
static func _dress(chip: Button, delta: int, preview: bool, size: float, numbered: bool) -> void:
	var shade := TextureRect.new()
	shade.name = "Shade"
	shade.texture = ListeningStrip.soft_disc()
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.modulate = GAIN if delta > 0 else (LOSS if delta < 0 else NEUTRAL)
	chip.add_child(shade)
	var mark := Label.new()
	mark.name = "Mark"
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.text = "" if not numbered else ("%+d" % delta if delta != 0 else "0")
	mark.add_theme_font_size_override("font_size", int(size / 3.0))
	mark.add_theme_color_override("font_color", Color.WHITE)
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 8)
	chip.add_child(mark)
	if preview:
		var border := StyleBoxFlat.new()
		border.bg_color = Color(0, 0, 0, 0)
		border.set_border_width_all(3)
		border.border_color = Color(1, 1, 1, 0.9)
		border.set_corner_radius_all(10)
		for state in ["normal", "hover", "pressed", "focus"]:
			chip.add_theme_stylebox_override(state, border)


## Opens the name overlay above everything; any tap closes it. Only one at a
## time: opening another replaces it.
static func show_name(chip: Control, display_name: String) -> void:
	if chip == null or not chip.is_inside_tree() or display_name.is_empty():
		return
	var root := chip.get_tree().root
	var old := root.get_node_or_null("OrgNameOverlay")
	if old != null:
		old.free()
	var layer := CanvasLayer.new()
	layer.name = "OrgNameOverlay"
	layer.layer = NAME_LAYER
	var catcher := Control.new()
	catcher.name = "Catcher"
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			layer.queue_free())
	layer.add_child(catcher)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catcher.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "NamePanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.04, 0.92)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.name = "NameLabel"
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	center.add_child(panel)
	root.add_child(layer)
