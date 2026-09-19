@tool
extends SceneTree
## Builds scenes/office_hours/OfficeScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_office_scene.gd
##
## Generated rather than hand-written for the same reason as the battle
## screen: a .tscn typed by hand is easy to get subtly wrong, and letting
## Godot save it guarantees a file Godot can read back. The result is an
## ordinary scene you can open and rearrange in the editor.
##
## The Office is deliberately sparse. For now it exists to be the place a
## run begins and ends; everything else it will eventually hold comes later.

const OUTPUT_PATH := "res://scenes/office_hours/OfficeScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/OfficeScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "OfficeScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.11, 0.10, 0.09)   # warmer than a battle
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(background, _root)

	var safe := MarginContainer.new()
	safe.name = "Safe"
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_right", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_top", TOP_MARGIN)
	safe.add_theme_constant_override("margin_bottom", BOTTOM_MARGIN)
	_adopt(safe, _root)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 24)
	_adopt(column, safe)

	# English first, Japanese as a small muted accent beside it.
	var heading := HBoxContainer.new()
	heading.name = "Heading"
	heading.add_theme_constant_override("separation", 12)
	_adopt(heading, column)

	_adopt(_label("Title", "The Office", "TitleLabel"), heading, true)

	var subtitle := _label("Subtitle", "陳情", "JapaneseAccent")
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_adopt(subtitle, heading, true)

	# The protagonist's desk. A placeholder until there is art.
	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.set_script(load(PLACEHOLDER_SCRIPT))
	portrait.custom_minimum_size = Vector2(0, 700)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(portrait, column, true)

	var report := _label("Report", "")
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(report, column, true)

	var spacer := Control.new()
	spacer.name = "VSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(spacer, column)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start the level"
	start.custom_minimum_size = Vector2(0, 130)
	_adopt(start, column, true)

	_save()


func _adopt(node: Node, parent: Node, unique: bool = false) -> void:
	parent.add_child(node)
	node.owner = _root
	if unique:
		node.unique_name_in_owner = true


func _label(node_name: String, text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


func _save() -> void:
	var error := DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create the scene folder: %d" % error)
		quit(1)
		return

	var packed := PackedScene.new()
	error = packed.pack(_root)
	if error != OK:
		push_error("Could not pack the scene: %d" % error)
		quit(1)
		return

	error = ResourceSaver.save(packed, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save the scene: %d" % error)
		quit(1)
		return

	print("Wrote %s" % OUTPUT_PATH)
	quit(0)
