class_name ListeningStrip
extends Control
## The organisations listening to this turn's question, drawn in the table
## space between the status row and the hand (2026-10-18, Cameron).
##
## Each is an icon. While a card is picked up or selected, a translucent layer
## (grey = no change, red = loses, green = gains) and a floating "+3" / "-2"
## show what that card would do to them. After a card is played the same
## marks flash for a moment with the real change. An organisation the player
## has bought the backing of also shows which styles it likes.

const GAIN := Color(0.18, 0.62, 0.28, 0.62)
const LOSS := Color(0.78, 0.18, 0.18, 0.62)
const NEUTRAL := Color(0.45, 0.45, 0.45, 0.55)
const FLASH_SECONDS := 1.6

var _flow: HFlowContainer
## booster_id -> {root, shade, mark, taste}
var _tiles: Dictionary = {}
var _icon_size := 110.0
var _flash: Timer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_flow = HFlowContainer.new()
	_flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override("h_separation", 18)
	_flow.add_theme_constant_override("v_separation", 6)
	add_child(_flow)
	_flash = Timer.new()
	_flash.one_shot = true
	_flash.wait_time = FLASH_SECONDS
	_flash.timeout.connect(clear_marks)
	add_child(_flash)
	resized.connect(_fit)


## Draws one tile per organisation in `ids`, with taste lines for `tastes`
## ({booster_id: text}). Replaces whatever was shown.
func show_listeners(ids: Array, tastes: Dictionary = {}) -> void:
	for child in _flow.get_children():
		_flow.remove_child(child)
		child.queue_free()
	_tiles = {}
	for booster_id: String in ids:
		_add_tile(booster_id, str(tastes.get(booster_id, "")))
	visible = not _tiles.is_empty()
	_fit()


func listener_ids() -> Array:
	return _tiles.keys()


## Marks for a card being held or selected: [{booster_id, delta}]. An
## organisation already listening but not moved shows grey; one the card would
## move that was not listening is added.
func preview(changes: Array) -> void:
	_flash.stop()
	_mark(changes, true)


## The real change after a card is played, shown for a moment.
func flash(changes: Array) -> void:
	_mark(changes, false)
	if not changes.is_empty():
		_flash.start()


func clear_marks() -> void:
	for booster_id: String in _tiles:
		var tile: Dictionary = _tiles[booster_id]
		(tile["shade"] as TextureRect).hide()
		(tile["mark"] as Label).hide()


func _mark(changes: Array, grey_the_rest: bool) -> void:
	var moved := {}
	for change: Dictionary in changes:
		moved[str(change["booster_id"])] = int(change["delta"])
		if not _tiles.has(change["booster_id"]):
			_add_tile(str(change["booster_id"]), "")
	_fit()
	for booster_id: String in _tiles:
		var tile: Dictionary = _tiles[booster_id]
		var shade := tile["shade"] as TextureRect
		var mark := tile["mark"] as Label
		if moved.has(booster_id):
			var delta: int = moved[booster_id]
			shade.modulate = GAIN if delta > 0 else LOSS
			mark.text = ("+%d" if delta > 0 else "%d") % delta
			shade.show()
			mark.show()
		elif grey_the_rest:
			shade.modulate = NEUTRAL
			mark.text = "0"
			shade.show()
			mark.show()
		else:
			shade.hide()
			mark.hide()


func _add_tile(booster_id: String, taste: String) -> void:
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 0)
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.custom_minimum_size = Vector2(_icon_size, _icon_size)
	root.add_child(box)
	var icon := TextureRect.new()
	icon.texture = ArtLoader.icon(booster_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var shade := TextureRect.new()
	shade.texture = _soft_disc()
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.hide()
	box.add_child(shade)
	var mark := Label.new()
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 44)
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 8)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.hide()
	box.add_child(mark)
	var taste_label := Label.new()
	taste_label.text = taste
	taste_label.visible = not taste.is_empty()
	taste_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	taste_label.add_theme_font_size_override("font_size", 20)
	taste_label.custom_minimum_size.x = _icon_size + 20.0
	taste_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	taste_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(taste_label)
	_flow.add_child(root)
	_tiles[booster_id] = {"root": root, "box": box, "shade": shade, "mark": mark, "taste": taste_label}


## Icons shrink on a short screen so the strip never pushes the hand down.
func _fit() -> void:
	if _tiles.is_empty():
		return
	var rows := 1 if _tiles.size() <= 4 else 2
	var has_taste := false
	for booster_id: String in _tiles:
		has_taste = has_taste or (_tiles[booster_id]["taste"] as Label).visible
	var spare := 30.0 if has_taste else 6.0
	_icon_size = clampf((size.y - spare * rows) / rows, 56.0, 130.0)
	for booster_id: String in _tiles:
		var tile: Dictionary = _tiles[booster_id]
		(tile["box"] as Control).custom_minimum_size = Vector2(_icon_size, _icon_size)
		(tile["taste"] as Label).custom_minimum_size.x = _icon_size + 20.0


static var _disc: GradientTexture2D = null

## A white disc whose edge fades to nothing; tinted by modulate.
static func _soft_disc() -> GradientTexture2D:
	if _disc == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
		_disc = GradientTexture2D.new()
		_disc.gradient = gradient
		_disc.fill = GradientTexture2D.FILL_RADIAL
		_disc.fill_from = Vector2(0.5, 0.5)
		_disc.fill_to = Vector2(1.0, 0.5)
		_disc.width = 128
		_disc.height = 128
	return _disc
