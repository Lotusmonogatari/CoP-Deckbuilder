class_name CampaignSkinParts
extends RefCounted
## The parts a campaign skin draws (P22, 2026-11-26, Cameron): the phase bar, the stat tiles with their bars, tier pips and badges, the van with the
## player's name on its side, the selection stamp, and the card label's emblem. Every function is called inside CampaignLook.begin() so the look it is
## given carries the skin's colours; none decides a rule. Sizes are mockup pixels (390 wide) scaled to the 1080 base by OfficeFrameStyles.


static func _label(text: String, mockup_px: float, colour: Color, display_font: Font = null, node_name: String = "") -> Label:
	var label := Label.new()
	if not node_name.is_empty():
		label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 0.0
	label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(mockup_px))
	label.add_theme_color_override("font_color", colour)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if display_font != null:
		label.add_theme_font_override("font", display_font)
	return label


# --- The phase bar ----------------------------------------------------------------------------------------------------------------------

## The full-width bar under the tabs: the emblem, the phase's name in the display face and a note at the right, between two rules.
static func phase_bar(look: Dictionary, phase_name: String, note: String) -> Control:
	var bar := PanelContainer.new()
	bar.name = "PhaseBar"
	var box := StyleBoxFlat.new()
	box.bg_color = look["skin_phase_bar"]
	box.border_width_top = int(OfficeFrameStyles.len_px(3.0))
	box.border_width_bottom = int(OfficeFrameStyles.len_px(3.0))
	box.border_color = look["skin_phase_rule"]
	box.set_content_margin_all(OfficeFrameStyles.len_px(10.0))
	bar.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(10.0)))
	bar.add_child(row)
	var emblem := CampaignLook.emblem(str(look["skin"]), 20.0)
	if emblem != null:
		var icon := TextureRect.new()
		icon.name = "PhaseEmblem"
		icon.texture = emblem
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * OfficeFrameStyles.len_px(24.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	var name_label := _label(LevelBriefingStyles.title_text(look, phase_name), 16.0, look["skin_phase_bar_ink"], look["display_font"], "PhaseName")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	if not note.is_empty():
		var note_label := _label(note, LevelBriefingStyles.SIZE_SMALL, look["skin_phase_bar_ink"], null, "PhaseNoteText")
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(note_label)
	return bar


# --- Stat tiles -------------------------------------------------------------------------------------------------------------------------

## One tile: a small caps heading, a big value in the display face, an optional bar (0 to 1) and a caption.
static func stat_tile(look: Dictionary, heading: String, value: String, ratio: float, caption: String, node_name: String) -> Control:
	var tile := VBoxContainer.new()
	tile.name = node_name
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(3.0)))
	tile.add_child(_label(heading.to_upper(), LevelBriefingStyles.SIZE_SMALL, look["muted"], null, "TileHeading"))
	tile.add_child(_label(value, 20.0, look["ink"], look["display_font"], "TileValue"))
	if ratio >= 0.0:
		tile.add_child(bar(look, ratio))
	if not caption.is_empty():
		tile.add_child(_label(caption, LevelBriefingStyles.SIZE_SMALL, look["muted"], null, "TileCaption"))
	return tile


## A flat bar: the track and a fill in the skin's bar colour (the party colour in the accent family).
static func bar(look: Dictionary, ratio: float) -> Control:
	var track := ColorRect.new()
	track.name = "SkinBar"
	track.color = look["skin_bar_track"]
	track.custom_minimum_size = Vector2(0, OfficeFrameStyles.len_px(6.0))
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := ColorRect.new()
	fill.name = "SkinBarFill"
	fill.color = look["skin_bar_fill"]
	fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(ratio, 0.0, 1.0)
	fill.offset_right = 0.0
	track.add_child(fill)
	return track


## A grid of two columns of tiles.
static func tile_grid(tiles: Array[Control]) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "StatGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(14.0)))
	grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(12.0)))
	for tile: Control in tiles:
		grid.add_child(tile)
	return grid


## The poll's strength range on a 0 to 100 track with a mark at each selection threshold (40, 60 and 75).
static func range_bar(look: Dictionary, low: int, high: int, marks: Array[int]) -> Control:
	var track := ColorRect.new()
	track.name = "PollRange"
	track.color = look["skin_bar_track"]
	track.custom_minimum_size = Vector2(0, OfficeFrameStyles.len_px(14.0))
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var span := ColorRect.new()
	span.name = "PollRangeSpan"
	span.color = look["skin_bar_fill"]
	span.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	span.anchor_left = clampf(float(low) / 100.0, 0.0, 1.0)
	span.anchor_right = clampf(float(high) / 100.0, 0.0, 1.0)
	span.offset_left = 0.0
	span.offset_right = 0.0
	track.add_child(span)
	for mark: int in marks:
		var tick := ColorRect.new()
		tick.name = "PollMark_%d" % mark
		tick.color = look["ink"]
		tick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tick.anchor_left = float(mark) / 100.0
		tick.anchor_right = float(mark) / 100.0
		tick.offset_left = 0.0
		tick.offset_right = maxf(1.0, OfficeFrameStyles.len_px(1.5))
		track.add_child(tick)
	return track


# --- Tiers --------------------------------------------------------------------------------------------------------------------------------

## One square per tier a person can reach (0 up to `highest`), filled up to `tier` in the accent, each carrying the tier numeral.
static func tier_pips(look: Dictionary, tier: int, highest: int) -> Control:
	var row := HBoxContainer.new()
	row.name = "TierPips"
	row.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(6.0)))
	for step in range(0, highest + 1):
		row.add_child(badge(look, step, step <= tier))
	return row


## A square badge with a tier numeral (Roman in the Gladiator skin): filled when reached.
static func badge(look: Dictionary, tier: int, filled: bool) -> Control:
	var holder := PanelContainer.new()
	holder.name = "TierBadge_%d" % tier
	var box := StyleBoxFlat.new()
	box.bg_color = look["accent"] if filled else Color(0, 0, 0, 0)
	box.set_border_width_all(int(OfficeFrameStyles.len_px(2.0)))
	box.border_color = look["ink"]
	box.set_content_margin_all(OfficeFrameStyles.len_px(3.0))
	holder.add_theme_stylebox_override("panel", box)
	var text := _label(CampaignSkin.numeral(tier, str(look["numerals"])), LevelBriefingStyles.SIZE_SMALL, look["on_accent"] if filled else look["ink"])
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.set_meta(UiKit.ONE_LINE_META, true)
	holder.add_child(text)
	return holder


# --- The van ------------------------------------------------------------------------------------------------------------------------------

## The van art with the player's name written on its side panel (the red strip), in the accent's ink.
static func van_picture(look: Dictionary, player_name: String) -> Control:
	var width := OfficeFrameStyles.len_px(230.0)
	var accent_hex := "#" + (look["accent"] as Color).to_html(false)
	var own_accent := UiStyles.token(UiStyle.idx(), str(look["skin"]), "colour", "accent").to_upper()
	var texture := CampaignLook.texture("van_%s.svg" % str(look["skin"]).trim_prefix("campaign_"), width / 230.0,
		func(svg: String) -> String: return svg.replace('fill="%s"' % own_accent, 'fill="%s"' % accent_hex))
	var holder := Control.new()
	holder.name = "VanPicture"
	holder.custom_minimum_size = Vector2(width, OfficeFrameStyles.len_px(110.0))
	if texture == null:
		return holder
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(art)
	var name_label := _label(player_name, 9.0, look["on_accent"], null, "VanName")
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.anchor_left = 26.0 / 230.0
	name_label.anchor_right = 160.0 / 230.0
	name_label.anchor_top = 46.0 / 110.0
	name_label.anchor_bottom = 66.0 / 110.0
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(name_label)
	return holder


# --- The selection stamp --------------------------------------------------------------------------------------------------------------------

## The outcome stamp: a bordered box in the stamp colour, tilted by the skin's `stamp_tilt_deg`, "Selected" (or "Not Selected") in the display face and
## the outcome under it. Not Selected uses the same stamp in the same colour.
static func stamp(look: Dictionary, headline: String, outcome: String) -> Control:
	var wrapper := CenterContainer.new()
	wrapper.name = "StampHolder"
	var box := PanelContainer.new()
	box.name = "SelectionStamp"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(int(OfficeFrameStyles.len_px(3.0)))
	style.border_color = look["skin_stamp"]
	style.set_content_margin_all(OfficeFrameStyles.len_px(10.0))
	box.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(column)
	box.custom_minimum_size.x = OfficeFrameStyles.len_px(220.0)
	var title := _label(LevelBriefingStyles.title_text(look, headline), 22.0, look["skin_stamp"], look["display_font"], "StampWord")
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.set_meta(UiKit.ONE_LINE_META, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	if not outcome.is_empty():
		var detail := _label(outcome, LevelBriefingStyles.SIZE_SMALL, look["skin_stamp"], null, "StampOutcome")
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(detail)
	var tilt := UiStyle.number("shape", "stamp_tilt_deg", 0.0)
	box.resized.connect(func() -> void: box.pivot_offset = box.size / 2.0)
	box.rotation_degrees = tilt
	wrapper.add_child(box)
	wrapper.custom_minimum_size.y = OfficeFrameStyles.len_px(100.0)
	return wrapper
