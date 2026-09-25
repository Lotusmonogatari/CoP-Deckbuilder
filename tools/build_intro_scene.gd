@tool
extends SceneTree
## Builds scenes/menus/IntroScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_intro_scene.gd
##
## Generated for the same reason every other scene builder in tools/ is —
## see build_battle_scene.gd's own header comment. This one is the game's
## title screen: full-bleed background, the game's name, and two buttons.

const OUTPUT_PATH := "res://scenes/menus/IntroScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/IntroScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

const SIDE_MARGIN := 60

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "IntroScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()
	_add_content()
	_save()


func _add_background() -> void:
	var background := Control.new()
	background.name = "Background"
	background.set_script(load(PLACEHOLDER_SCRIPT))
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_adopt(background, _root, true)

	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.05, 0.05, 0.07, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(scrim, _root)


## Title, then the two buttons, all centred as one column lower on the
## screen — a title screen reads top-down (art first, choice last), the
## way a player's eye already goes.
func _add_content() -> void:
	var safe := MarginContainer.new()
	safe.name = "Safe"
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_right", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_bottom", 160)
	_adopt(safe, _root)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 28)
	_adopt(column, safe)

	var title := _label("Title", "Coliseum of Parliament", "TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(title, column, true)

	_adopt(_vspacer_fixed(48), column)

	var continue_button := Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(0, 110)
	_adopt(continue_button, column, true)

	var new_game_button := Button.new()
	new_game_button.name = "NewGameButton"
	new_game_button.text = "New Game"
	new_game_button.custom_minimum_size = Vector2(0, 110)
	_adopt(new_game_button, column, true)


# ---------------------------------------------------------------------------
# Helpers — identical to the other scene builders' own
# ---------------------------------------------------------------------------

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


func _vspacer_fixed(height: int) -> Control:
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(0, height)
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
