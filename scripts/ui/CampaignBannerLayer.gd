class_name CampaignBannerLayer
extends Control
## A phase banner on the campaign skin (P22, 2026-11-26, Cameron): a full screen in the skin's ground with its texture (fibers for Samurai, stone for
## Gladiator), the kicker, the big title in the display face, the Japanese accent, a sentence, the phase's art across the lower 520/844 of the screen and
## one button on the dark band under it. It draws what it is given and reports the press; the pages and what follows are CampaignController's.

signal confirmed

var _look: Dictionary
var _texture_step := 7.0
var _texture_horizontal := false
var _texture_colour := Color(0.47, 0.35, 0.16, 0.07)


## `page`: {kicker, title, jp, sub, cta, phase}. Called inside CampaignLook.begin() so `_look` is the skin.
func show_page(page: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_look = OfficeFrameStyles.look()
	name = "CampaignBannerPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_texture_horizontal = UiStyle.scoped_token("art", "texture_direction", "vertical") == "horizontal"
	_texture_step = maxf(2.0, UiStyle.scoped_token("art", "texture_step", "7").to_float()) * OfficeFrameStyles.len_px(1.0)
	_texture_colour = Color(0.47, 0.35, 0.16, UiStyle.scoped_token("art", "texture_alpha", "0.07").to_float())
	var ground := ColorRect.new()
	ground.name = "BannerGround"
	ground.color = _look["ground"]
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.draw.connect(_draw_texture.bind(ground))
	add_child(ground)
	var screen := get_viewport_rect().size
	var art_height := screen.y * 520.0 / 844.0
	var art := CampaignLook.banner(str(_look["skin"]), str(page.get("phase", "")), screen.x)
	if art != null:
		var picture := TextureRect.new()
		picture.name = "BannerArt"
		picture.texture = art
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		picture.offset_top = -art_height
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(picture)
	var column := VBoxContainer.new()
	column.name = "BannerText"
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	column.offset_left = OfficeFrameStyles.len_px(24.0)
	column.offset_right = -OfficeFrameStyles.len_px(24.0)
	column.offset_top = OfficeFrameStyles.len_px(36.0)
	column.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(_text(str(page.get("kicker", "")).to_upper(), LevelBriefingStyles.SIZE_SMALL, _look["muted"], null, "BannerKicker"))
	column.add_child(_text(LevelBriefingStyles.title_text(_look, str(page.get("title", ""))), 36.0, _look["ink"], _look["display_font"], "BannerTitle"))
	column.add_child(_text(str(page.get("jp", "")), 16.0, _look["skin_jp"], null, "BannerJapanese"))
	column.add_child(_text(str(page.get("sub", "")), 14.0, _look["ink"], null, "BannerSentence"))
	var band := ColorRect.new()
	band.name = "BannerBand"
	band.color = _look["skin_button"]
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -OfficeFrameStyles.len_px(120.0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var button := Button.new()
	button.name = "Confirm"
	button.text = str(page.get("cta", ""))
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	button.offset_left = OfficeFrameStyles.len_px(20.0)
	button.offset_right = -OfficeFrameStyles.len_px(20.0)
	button.offset_bottom = -OfficeFrameStyles.len_px(24.0)
	button.offset_top = -OfficeFrameStyles.len_px(24.0) - maxf(OfficeFrameStyles.touch_height(), OfficeFrameStyles.len_px(54.0))
	var box := StyleBoxFlat.new()
	box.bg_color = _look["skin_button"]
	box.set_border_width_all(int(OfficeFrameStyles.len_px(3.0)))
	box.border_color = _look["card"]
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, box)
	for colour_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(colour_name, _look["skin_button_ink"])
	button.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BUTTON))
	button.pressed.connect(func() -> void: confirmed.emit())
	add_child(button)
	show()


func _text(text: String, mockup_px: float, colour: Color, display_font: Font, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 0.0
	label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(mockup_px))
	label.add_theme_color_override("font_color", colour)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display_font != null:
		label.add_theme_font_override("font", display_font)
	return label


## The ground's texture: thin lines (fibers, vertical) or courses (stone, horizontal) at the skin's step and alpha, drawn over the ground.
func _draw_texture(canvas: Control) -> void:
	var size_now := canvas.size
	var at := _texture_step
	var line_width := maxf(1.0, OfficeFrameStyles.len_px(1.0))
	if _texture_horizontal:
		while at < size_now.y:
			canvas.draw_line(Vector2(0, at), Vector2(size_now.x, at), _texture_colour, line_width)
			at += _texture_step
	else:
		while at < size_now.x:
			canvas.draw_line(Vector2(at, 0), Vector2(at, size_now.y), _texture_colour, line_width)
			at += _texture_step
