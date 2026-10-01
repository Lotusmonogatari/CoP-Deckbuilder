@tool
extends SceneTree
## Builds scenes/office_hours/StageTransitionScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_stage_transition_scene.gd
##
## Same unconditional wipe-and-rebuild shape as tools/build_level_intro_
## scene.gd/tools/build_visitor_scene.gd — confirmed safe to rerun (see
## CLAUDE.md §13's note on the drifted build_battle_scene.gd by contrast).
## Re-running this overwrites any editor-made changes.

const OUTPUT_PATH := "res://scenes/office_hours/StageTransitionScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/StageTransitionScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "StageTransitionScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()
	var column := _build_frame()
	_add_art_box(column)
	_add_speaker_name(column)
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


## The player's own cutout (lower-left) and the current speaker's cutout
## (lower-right) — the same two-corner shape BattleScreen's own ArtBox
## already uses for the player/opponent pair. Neither is inside a layout
## Container, the same reason CueBanner's own band can be freely tweened:
## a plain Control's anchored children keep a stable rest position between
## frames, so StageTransitionScreen.gd can slide the speaker in from it.
func _add_art_box(parent: Control) -> void:
	var art_box := Control.new()
	art_box.name = "ArtBox"
	art_box.custom_minimum_size = Vector2(0, 420)
	_adopt(art_box, parent)

	var player_portrait := Control.new()
	player_portrait.name = "PlayerPortrait"
	player_portrait.set_script(load(PLACEHOLDER_SCRIPT))
	player_portrait.anchor_left = 0.0
	player_portrait.anchor_top = 0.1
	player_portrait.anchor_right = 0.46
	player_portrait.anchor_bottom = 1.0
	_adopt(player_portrait, art_box, true)

	var speaker_portrait := Control.new()
	speaker_portrait.name = "SpeakerPortrait"
	speaker_portrait.set_script(load(PLACEHOLDER_SCRIPT))
	speaker_portrait.anchor_left = 0.54
	speaker_portrait.anchor_top = 0.1
	speaker_portrait.anchor_right = 1.0
	speaker_portrait.anchor_bottom = 1.0
	_adopt(speaker_portrait, art_box, true)


func _add_speaker_name(parent: Control) -> void:
	var name_label := Label.new()
	name_label.name = "SpeakerName"
	name_label.text = "Speaker"
	name_label.theme_type_variation = "HeaderLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_adopt(name_label, parent, true)


func _add_footer(parent: Control) -> void:
	var button := Button.new()
	button.name = "ContinueButton"
	button.text = "Continue"
	button.custom_minimum_size = Vector2(0, 110)
	_adopt(button, parent, true)


# ---------------------------------------------------------------------------
# Helpers — identical to tools/build_level_intro_scene.gd's own
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
