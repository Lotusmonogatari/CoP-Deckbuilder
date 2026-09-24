@tool
extends SceneTree
## Builds scenes/battle/BattleScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_battle_scene.gd
##
## The scene is generated rather than hand-written because a .tscn typed by
## hand is easy to get subtly wrong — node paths, unique names, anchors — and
## letting Godot save it guarantees a file Godot can read back. The result is
## an ordinary scene: open it in the editor and drag things about freely.
##
## Re-run this only if you want to regenerate the layout from scratch; it
## overwrites any edits made in the editor.
##
## The order of the sections below is the order they appear on screen, and
## follows the layout in the build brief at section 10.

const OUTPUT_PATH := "res://scenes/battle/BattleScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/BattleScreen.gd"
const SUPPORT_BAR_SCRIPT := "res://scripts/ui/SupportBar.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

# Phones put cameras and gesture bars at the edges, so nothing important is
# allowed near them.
const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "BattleScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()

	var column := _build_frame()
	_add_header(column)
	_add_opponent_row(column)
	_add_support_bar(column)
	_add_status_row(column)

	# Whatever is left over sits between the opponent and the hand, so the
	# cards stay within reach of a thumb at the bottom of the screen.
	_adopt(_vspacer(), column)

	_add_hand(column)
	_add_footer(column)

	# Everything that sits on top of the battle rather than in it.
	_add_details_panel()
	_add_card_zoom()
	_add_outcome_panel()
	_add_notice()

	_save()


# ---------------------------------------------------------------------------
# The main column
# ---------------------------------------------------------------------------

## The stage's own picture (data/art.json, `background` folder). BattleScreen
## sets its kind, art_id and show_label at runtime (start_battle()), the same
## way every other PlaceholderArt here is left blank at build time and filled
## in by the presenter that owns it. Blank shows as an ID-coloured
## placeholder — same bargain as every other missing art. A dark scrim sits
## over it so text stays readable whatever the art turns out to look like,
## the way the flat colour it replaces always was.
##
## 2026-09-27, Cameron: the art band shrunk to the top BAND_HEIGHT of the
## screen (was full-bleed) — behind the header and the opponent, where a
## scene picture is worth having. Below that is BackgroundPanel, a plain
## opaque colour: the hand and the buttons read better against a calm panel
## than against art competing for attention under them.
const BAND_HEIGHT := 0.75

func _add_background() -> void:
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
	scrim.color = Color(0.05, 0.05, 0.07, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(scrim, _root)

	var panel := ColorRect.new()
	panel.name = "BackgroundPanel"
	panel.anchor_top = BAND_HEIGHT
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.color = Color(0.05, 0.05, 0.07, 1.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(panel, _root)


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
	column.add_theme_constant_override("separation", 24)
	_adopt(column, safe)
	return column


## "Floor Debate 本会議" on the left, "Turn 3 of 8" on the right.
func _add_header(parent: Control) -> void:
	var header := HBoxContainer.new()
	header.name = "Header"
	_adopt(header, parent)

	var title := HBoxContainer.new()
	title.name = "Title"
	title.add_theme_constant_override("separation", 12)
	_adopt(title, header)

	var stage_name := _label("StageName", "Floor Debate", "HeaderLabel")
	_adopt(stage_name, title, true)

	# The Japanese accent: always beside the English, never instead of it.
	var stage_name_jp := _label("StageNameJP", "本会議", "JapaneseAccent")
	stage_name_jp.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_adopt(stage_name_jp, title, true)

	_adopt(_spacer(), header)

	var turn := _label("TurnLabel", "Turn 1 of 8")
	turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_adopt(turn, header, true)


## Portrait, name, and what they are about to do in plain words.
func _add_opponent_row(parent: Control) -> void:
	var row := VBoxContainer.new()
	row.name = "OpponentRow"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Shares the column's leftover height with VSpacer at 3:1 rather than
	# having it all to itself — Cameron, 2026-09-27: shrink the portrait by
	# about a quarter and give that back to the hand and the buttons below.
	row.size_flags_stretch_ratio = 3.0
	row.add_theme_constant_override("separation", 16)
	_adopt(row, parent)

	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.set_script(load(PLACEHOLDER_SCRIPT))
	portrait.custom_minimum_size = Vector2(0, 620)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(portrait, row, true)

	# Your own face, as a small inset in the opponent portrait's corner — the
	# room is big enough for one full portrait, not two, so this is a "you"
	# chip rather than a second scene the way an opponent's is. It reacts to
	# what you just did (PlayerPortraitPresenter) rather than to an intent,
	# since only the opponent's next move is known ahead of time.
	var player_frame := PanelContainer.new()
	player_frame.name = "PlayerPortraitFrame"
	player_frame.anchor_left = 0.0
	# 0.685, not 0.58: a quarter shorter (2026-09-27, Cameron) — was 0.42 of
	# the portrait's own height, now 0.315.
	player_frame.anchor_top = 0.685
	player_frame.anchor_right = 0.34
	player_frame.anchor_bottom = 1.0
	player_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_box := StyleBoxFlat.new()
	frame_box.bg_color = Color(0.07, 0.08, 0.11, 0.85)
	frame_box.border_color = Color(0.95, 0.82, 0.38, 0.9)
	frame_box.set_border_width_all(4)
	frame_box.set_corner_radius_all(10)
	frame_box.content_margin_left = 4
	frame_box.content_margin_right = 4
	frame_box.content_margin_top = 4
	frame_box.content_margin_bottom = 4
	player_frame.add_theme_stylebox_override("panel", frame_box)
	_adopt(player_frame, portrait)

	var player_portrait := Control.new()
	player_portrait.name = "PlayerPortrait"
	player_portrait.set_script(load(PLACEHOLDER_SCRIPT))
	_adopt(player_portrait, player_frame, true)

	var details := VBoxContainer.new()
	details.name = "Details"
	_adopt(details, row)

	_adopt(_label("OpponentName", "Opponent", "HeaderLabel"), details, true)
	_adopt(_label("IntentLabel", "Waiting"), details, true)

	# Hidden until OpponentPresenter._show_guards() has something to say —
	# most stages never build any guard against the player at all.
	var opponent_guard := _label("OpponentGuardLabel", "They guard 0")
	opponent_guard.visible = false
	_adopt(opponent_guard, details, true)


func _add_support_bar(parent: Control) -> void:
	var bar := Control.new()
	bar.name = "SupportBar"
	bar.set_script(load(SUPPORT_BAR_SCRIPT))
	bar.custom_minimum_size = Vector2(0, 140)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(bar, parent, true)

	# SupportBar.gd draws the bar itself and expects these two by name.
	var caption := _label("Caption", "51 seats to win")
	caption.position = Vector2(0, 0)
	_adopt(caption, bar)

	var readout := _label("Readout", "", "SmallLabel")
	readout.position = Vector2(0, 108)
	_adopt(readout, bar)


## Energy pips on the left, the gaffe count and the details button right.
func _add_status_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "StatusRow"
	row.add_theme_constant_override("separation", 16)
	_adopt(row, parent)

	var energy := HBoxContainer.new()
	energy.name = "EnergyRow"
	energy.add_theme_constant_override("separation", 10)
	energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_adopt(energy, row, true)

	_adopt(_spacer(), row)

	# What the player is holding against the next attack. Hidden at zero
	# rather than sitting there as a permanent "Guarding 0".
	var guard := _label("GuardLabel", "Guarding 5", "SmallLabel")
	guard.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_adopt(guard, row, true)

	var gaffe := _label("GaffeLabel", "Gaffes 0 / 6")
	gaffe.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_adopt(gaffe, row, true)

	# Secondary information lives behind this, not on the main screen.
	var details := Button.new()
	details.name = "DetailsButton"
	details.text = "Details"
	_adopt(details, row, true)


## Three to five cards. Scrolls sideways rather than shrinking the cards,
## because an unreadable card is worse than a scroll.
func _add_hand(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "HandScroll"
	scroll.custom_minimum_size = Vector2(0, CardView.HEIGHT + 30.0)
	scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_adopt(scroll, parent)

	var hand := HBoxContainer.new()
	hand.name = "HandRow"
	hand.add_theme_constant_override("separation", 16)
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(hand, scroll, true)


func _add_footer(parent: Control) -> void:
	var button := Button.new()
	button.name = "EndTurnButton"
	button.text = "End turn"
	button.custom_minimum_size = Vector2(0, 110)
	_adopt(button, parent, true)


# ---------------------------------------------------------------------------
# Overlays
# ---------------------------------------------------------------------------

func _add_details_panel() -> void:
	var panel := _overlay_panel("DetailsPanel", 0.55)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 16)
	column.custom_minimum_size = Vector2(900, 0)
	_adopt(column, panel)

	_adopt(_label("Heading", "Details", "HeaderLabel"), column)

	var text := _label("DetailsText", "", "SmallLabel")
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(text, column, true)

	# Without this the panel covers the Details button that opened it, and
	# there is no way back to the battle. Every overlay needs its own exit.
	var close := Button.new()
	close.name = "DetailsClose"
	close.text = "Back"
	_adopt(close, column, true)


func _add_card_zoom() -> void:
	var panel := _overlay_panel("CardZoom", 0.8)

	# Named "ZoomColumn" rather than the "Column" every other overlay uses —
	# BattleScreen._on_card_chosen() reaches it directly by %ZoomColumn to
	# insert the card back view, and _overlay_content() tells this panel
	# apart from an ordinary one by that same name.
	var column := VBoxContainer.new()
	column.name = "ZoomColumn"
	column.add_theme_constant_override("separation", 16)
	column.custom_minimum_size = Vector2(900, 0)
	_adopt(column, panel)

	_adopt(_label("ZoomTitle", "", "TitleLabel"), column, true)
	_adopt(_label("ZoomSubtitle", "", "JapaneseAccent"), column, true)

	var art := Control.new()
	art.name = "ZoomArt"
	art.set_script(load(PLACEHOLDER_SCRIPT))
	art.custom_minimum_size = Vector2(0, 260)
	_adopt(art, column, true)

	var body := RichTextLabel.new()
	body.name = "ZoomText"
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(0, 260)
	_adopt(body, column, true)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 16)
	_adopt(buttons, column)

	var close := Button.new()
	close.name = "ZoomClose"
	close.text = "Back"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(close, buttons, true)

	var play := Button.new()
	play.name = "ZoomPlay"
	play.text = "Play this"
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(play, buttons, true)


func _add_outcome_panel() -> void:
	var panel := _overlay_panel("OutcomePanel", 0.5)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 20)
	column.custom_minimum_size = Vector2(900, 0)
	_adopt(column, panel)

	_adopt(_label("OutcomeTitle", "", "TitleLabel"), column, true)

	# Hidden until OutcomePresenter has a headline worth showing — most
	# outcomes are said in OutcomeReason alone.
	var headline := _label("OutcomeHeadline", "", "HeaderLabel")
	headline.visible = false
	_adopt(headline, column, true)

	var reason := _label("OutcomeReason", "")
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(reason, column, true)

	var close := Button.new()
	close.name = "OutcomeClose"
	close.text = "Close"
	_adopt(close, column, true)


## A short-lived message for things like "not enough time left this turn".
func _add_notice() -> void:
	var notice := _label("Notice", "")
	notice.name = "Notice"
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.anchor_left = 0.5
	notice.anchor_right = 0.5
	notice.offset_left = -400
	notice.offset_right = 400
	notice.offset_top = 220
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	notice.add_theme_constant_override("outline_size", 8)
	notice.hide()
	_adopt(notice, _root, true)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Adds `node` under `parent` and makes the scene root its owner, which is
## what lets it be saved. `unique` also gives it a %Name shortcut.
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


func _vspacer() -> Control:
	var spacer := Control.new()
	spacer.name = "VSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## A dimmed panel covering the screen, used for the overlays. Returns the
## container that overlay content should be added to.
func _overlay_panel(node_name: String, dim: float) -> Control:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.08, 0.11, dim + 0.35)
	panel.add_theme_stylebox_override("panel", box)
	_adopt(panel, _root, true)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 120)
	_adopt(margin, panel)

	# An overlay's content must never be able to push its own buttons off the
	# bottom of the screen. A card with unusually long text could otherwise
	# leave the player looking at a panel with no way out of it.
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_adopt(scroll, margin)

	var centre := CenterContainer.new()
	centre.name = "Centre"
	# Fills the scroll area when the content is short, so it stays centred;
	# grows past it when the content is long, so it scrolls instead.
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_adopt(centre, scroll)
	return centre


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
