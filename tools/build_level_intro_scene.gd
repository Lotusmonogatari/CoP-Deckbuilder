@tool
extends SceneTree
## Builds scenes/office_hours/LevelIntroScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_level_intro_scene.gd
##
## Generated for the same reason tools/build_visitor_scene.gd is (see its own
## header comment): a .tscn Godot itself writes is guaranteed readable, and
## the result opens and edits normally. Re-running this overwrites any
## editor-made changes.

const OUTPUT_PATH := "res://scenes/office_hours/LevelIntroScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/LevelIntroScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "LevelIntroScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()
	var column := _build_frame()
	_add_portrait_row(column)
	_adopt(_vspacer(), column)
	_add_footer(column)

	_save()


func _add_background() -> void:
	var background := Control.new()
	background.name = "Background"
	background.set_script(load(PLACEHOLDER_SCRIPT))
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_adopt(background, _root, true)

	var scrim := ColorRect.new()
	scrim.name = "BackgroundScrim"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.05, 0.05, 0.07, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(scrim, _root)


func _build_frame() -> VBoxContainer:
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
	column.add_theme_constant_override("separation", 20)
	_adopt(column, safe)
	return column


func _add_portrait_row(parent: Control) -> void:
	var spacer_top := _vspacer()
	spacer_top.name = "TopSpacer"
	_adopt(spacer_top, parent)

	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.set_script(load(PLACEHOLDER_SCRIPT))
	portrait.custom_minimum_size = Vector2(260, 380)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_adopt(portrait, parent, true)

	var name_label := Label.new()
	name_label.name = "StaffName"
	name_label.text = "Staff"
	name_label.theme_type_variation = "HeaderLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_adopt(name_label, parent, true)


func _add_footer(parent: Control) -> void:
	var button := Button.new()
	button.name = "ContinueButton"
	button.text = "Let's go"
	button.custom_minimum_size = Vector2(0, 110)
	_adopt(button, parent, true)


# ---------------------------------------------------------------------------
# Helpers — identical to tools/build_visitor_scene.gd's own
# ---------------------------------------------------------------------------

func _adopt(node: Node, parent: Node, unique: bool = false) -> void:
	parent.add_child(node)
	node.owner = _root
	if unique:
		node.unique_name_in_owner = true


func _vspacer() -> Control:
	var spacer := Control.new()
	spacer.name = "VSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _save() -> void:
	var error := DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create %s: %s" % [OUTPUT_PATH.get_base_dir(), error])
		quit(1)
		return

	var packed := PackedScene.new()
	var pack_result := packed.pack(_root)
	if pack_result != OK:
		push_error("Could not pack the scene: %s" % pack_result)
		quit(1)
		return

	var save_result := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_result != OK:
		push_error("Could not save %s: %s" % [OUTPUT_PATH, save_result])
		quit(1)
		return

	print("Wrote ", OUTPUT_PATH)
	quit()
