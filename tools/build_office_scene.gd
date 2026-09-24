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
##
## DO NOT RUN THIS TODAY. It has drifted badly from the real scene: Office
## Management, Resources, Supplies, Cards, Deck, Backing, Staff and Levels
## were all added straight to scenes/office_hours/OfficeScreen.tscn as the
## Office grew, without ever being folded back in here (2026-09-27 found the
## gap — running this would have silently deleted all of them). Bring this
## script up to date with the real scene FIRST, verify with a structural
## diff against the committed .tscn (no removed or unexpectedly changed
## nodes), and only then run it. Until that happens, add a node to the real
## scene by hand in the editor, or edit .tscn text directly.

const OUTPUT_PATH := "res://scenes/office_hours/OfficeScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/OfficeScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"
const OVERLAY_SCRIPT := "res://scripts/ui/Overlay.gd"

## Same fraction as the battle screen's own BAND_HEIGHT — see its comment.
const BAND_HEIGHT := 0.75

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "OfficeScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	# The Office's own picture, data/art.json's "OFFICE" background.
	# OfficeScreen._ready() sets its kind, art_id and show_label at runtime —
	# the same convention every other PlaceholderArt here follows, so the
	# custom exported properties are never touched from this @tool script.
	#
	# 2026-09-27, Cameron: shrunk to the top BAND_HEIGHT of the screen (was
	# full-bleed), with BackgroundPanel — a plain opaque colour — filling
	# the rest, so the buttons read against a calm panel rather than
	# competing with art. Same change as the battle screen's.
	var background := Control.new()
	background.name = "Background"
	background.set_script(load(PLACEHOLDER_SCRIPT))
	background.anchor_right = 1.0
	background.anchor_bottom = BAND_HEIGHT
	_adopt(background, _root, true)

	var scrim := ColorRect.new()
	scrim.name = "BackgroundScrim"
	scrim.anchor_right = 1.0
	scrim.anchor_bottom = BAND_HEIGHT
	scrim.color = Color(0.09, 0.07, 0.06, 0.55)   # a warmer scrim than the battle's
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(scrim, _root)

	var panel := ColorRect.new()
	panel.name = "BackgroundPanel"
	panel.anchor_top = BAND_HEIGHT
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.color = Color(0.09, 0.07, 0.06, 1.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(panel, _root)

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
	# 700 * 0.75 = 525 — Cameron, 2026-09-27: a quarter shorter, given
	# straight to VSpacer below (the only other expanding child in this
	# column, so the shrink lands there with no ratio math needed).
	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.set_script(load(PLACEHOLDER_SCRIPT))
	portrait.custom_minimum_size = Vector2(0, 525)
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

	# Who is behind you, and how far. Secondary information, so it lives
	# behind a button rather than on the desk.
	var organisations := Button.new()
	organisations.name = "OrganisationsButton"
	organisations.text = "The organisations"
	organisations.custom_minimum_size = Vector2(0, 100)
	_adopt(organisations, column, true)

	# Covers everything, and knows its own three ways out.
	var panel := PanelContainer.new()
	panel.name = "OrganisationsPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.set_script(load(OVERLAY_SCRIPT))
	_adopt(panel, _root, true)

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
