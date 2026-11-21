class_name HowToPlayPanel
extends RefCounted
## The How to Play guide, drawn into an Overlay.
##
## One panel, two doors: the title screen's button and the Office's button
## both build theirs here, so the guide can never read differently depending
## on where it was opened from. What it says comes entirely from the
## workbook's "How To Play" tab (HowToPlay.gd puts it in order and fills the
## live numbers); what it shows beside the words is an optional screenshot
## and an optional video per entry, looked up by file name under
## assets/howto/.
##
## Pictures and video follow the project's usual bargain for art that has not
## been made yet: a named file that is missing shows a labelled placeholder,
## never an error and never a blank hole nobody can explain.
##
## VIDEO FORMAT: Ogg Theora (.ogv) only. It is the one format Godot decodes
## itself on every platform; mp4 and webm will not play on iOS or Android.

const ASSET_FOLDER := "res://assets/howto/"
const PICTURE_EXTENSION := ".png"
const VIDEO_EXTENSION := ".ogv"

## Matches UiKit.LINE_WIDTH so media sits in the same column as the text.
const MEDIA_WIDTH := UiKit.LINE_WIDTH
const VIDEO_HEIGHT := 428.0   # 16:9 at MEDIA_WIDTH
const PLACEHOLDER_HEIGHT := 200.0
const ENTRY_HEADING_SIZE := 40
const ENTRY_HEADING_COLOUR := Color(0.95, 0.85, 0.55)


## Builds an Overlay for the guide and adds it under `host`. The caller keeps
## the returned panel and passes it to open() when its button is pressed.
static func attach(host: Node) -> Overlay:
	var panel := Overlay.new()
	panel.name = "HowToPlayPanel"
	host.add_child(panel)
	return panel


static func open(panel: Overlay) -> void:
	# On the shared frame (P14b, 2026-11-20): one numbered card for each entry, the group names between them.
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("how_to_play.title"), "subtitle": "", "chips": [], "rows": cards(OfficeFrameStyles.look())})
	panel.open_frame(frame, Text.say("ui.back"))


## The guide as cards: a muted heading for each group, then one card for each entry with its position in the guide.
static func cards(look: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var tokens := data_tokens()
	var groups := HowToPlay.grouped(DataDB.how_to_play)
	if groups.is_empty():
		out.append(UiKit.line(Text.say("how_to_play.empty")))
		return out
	var number := 0
	for group: Dictionary in groups:
		var group_name := str(group["group"])
		if not group_name.is_empty():
			var heading := UiKit.line(group_name, "HeaderLabel")
			heading.custom_minimum_size.x = 0.0
			heading.add_theme_color_override("font_color", look["on_ground"])
			out.append(heading)
		for entry: Dictionary in group["entries"]:
			number += 1
			var card := OfficeFrameStyles.card(look)
			card.name = "HowToCard_%s" % _cell(entry, "entry_id")
			var row := _entry_row(entry, tokens, look)
			var heading_row := row.get_child(0) if row.get_child_count() > 0 else null
			card.get_node("Column").add_child(row)
			# The entry's number leads its heading, so the guide reads as a numbered list.
			var first_label: Label = null
			if heading_row != null:
				for candidate: Node in heading_row.find_children("*", "Label", true, false):
					first_label = candidate as Label
					break
			if first_label != null:
				first_label.text = "%d  %s" % [number, first_label.text]
			out.append(card)
	return out


## The guide's live tokens from the real game data (one place, so the panel,
## the tests and the click driver always agree).
static func data_tokens() -> Dictionary:
	var suit_names: Array = []
	for row in DataDB.suits:
		suit_names.append(str((row as Dictionary).get("element", "")))
	return HowToPlay.live_tokens(DataDB.stages, DataDB.rules, DataDB.questions,
		suit_names, BattleSetup.booster_names(),
		Text.say("how_to_play.style_line", {"style": "{style}", "names": "{names}"}))


## The guide's content as rows for Overlay.open(). With nothing written yet,
## a single line saying so.
static func rows() -> Array[Control]:
	var out: Array[Control] = []
	var tokens := data_tokens()
	var groups := HowToPlay.grouped(DataDB.how_to_play)

	if groups.is_empty():
		out.append(UiKit.line(Text.say("how_to_play.empty")))
		return out

	for group: Dictionary in groups:
		var group_name := str(group["group"])
		if not group_name.is_empty():
			out.append(UiKit.heading(group_name))
		for entry: Dictionary in group["entries"]:
			out.append(_entry_row(entry, tokens))
	return out


static func _entry_row(entry: Dictionary, tokens: Dictionary, look: Dictionary = {}) -> Control:
	var column := VBoxContainer.new()
	column.name = "Entry_%s" % _cell(entry, "entry_id")
	column.add_theme_constant_override("separation", 10)

	var heading := _cell(entry, "heading_en")
	if not heading.is_empty():
		column.add_child(_entry_heading(heading, _cell(entry, "heading_jp"), look))

	var body := _cell(entry, "body_en")
	if not body.is_empty():
		column.add_child(UiKit.line(HowToPlay.fill_tokens(body, tokens)))

	var screenshot := _cell(entry, "screenshot")
	if not screenshot.is_empty():
		column.add_child(_screenshot(screenshot))

	var video := _cell(entry, "video")
	if not video.is_empty():
		column.add_child(_video(video))

	var caption := _cell(entry, "caption")
	if not caption.is_empty():
		var label := UiKit.line(HowToPlay.fill_tokens(caption, tokens), "SmallLabel")
		column.add_child(label)

	return column


## English heading with the Japanese beside it as a small muted accent
## (CLAUDE.md §3), when the row has one.
static func _entry_heading(english: String, japanese: String, look: Dictionary = {}) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var label := Label.new()
	label.text = english
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", ENTRY_HEADING_SIZE)
	# The gold heading is for the dark panel; on a card the heading is the card's own ink.
	label.add_theme_color_override("font_color", ENTRY_HEADING_COLOUR if look.is_empty() else look["ink"])
	row.add_child(label)

	if not japanese.is_empty():
		var accent := Label.new()
		accent.text = japanese
		accent.theme_type_variation = "SmallLabel"
		accent.modulate = Color(1, 1, 1, 0.6)
		row.add_child(accent)
	return row


static func _screenshot(file_name: String) -> Control:
	var path := ASSET_FOLDER + file_name + PICTURE_EXTENSION
	if not ResourceLoader.exists(path):
		return _placeholder(file_name + PICTURE_EXTENSION)

	var texture := load(path) as Texture2D
	if texture == null:
		return _placeholder(file_name + PICTURE_EXTENSION)

	var picture := TextureRect.new()
	picture.name = "Screenshot"
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Full column width, tall enough to keep the picture's own shape.
	var ratio := float(texture.get_height()) / maxf(float(texture.get_width()), 1.0)
	picture.custom_minimum_size = Vector2(MEDIA_WIDTH, MEDIA_WIDTH * ratio)
	return picture


## A video poster: a Watch button that starts the clip in place, which then
## becomes a Stop button. Nothing plays until it is pressed.
static func _video(file_name: String) -> Control:
	var path := ASSET_FOLDER + file_name + VIDEO_EXTENSION
	if not ResourceLoader.exists(path):
		return _placeholder(file_name + VIDEO_EXTENSION)

	var stream := load(path) as VideoStream
	if stream == null:
		return _placeholder(file_name + VIDEO_EXTENSION)

	var column := VBoxContainer.new()
	column.name = "Video"
	column.add_theme_constant_override("separation", 8)

	# A dark frame behind the player, so the clip reads as a video box even
	# before it is started (a stopped player draws nothing at all).
	var frame := PanelContainer.new()
	frame.name = "VideoFrame"
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.03, 0.03, 0.05, 1.0)
	frame.add_theme_stylebox_override("panel", frame_style)
	column.add_child(frame)

	var player := VideoStreamPlayer.new()
	player.name = "VideoPlayer"
	player.stream = stream
	player.expand = true
	player.custom_minimum_size = Vector2(MEDIA_WIDTH, VIDEO_HEIGHT)
	frame.add_child(player)

	var button := Button.new()
	button.name = "WatchButton"
	button.custom_minimum_size = Vector2(0, 90)
	button.text = Text.say("how_to_play.watch")
	column.add_child(button)

	button.pressed.connect(func() -> void:
		if player.is_playing():
			player.stop()
			button.text = Text.say("how_to_play.watch")
		else:
			player.play()
			button.text = Text.say("how_to_play.stop"))
	player.finished.connect(func() -> void:
		button.text = Text.say("how_to_play.watch"))
	return column


## A flat grey box labelled with the file it is waiting for.
static func _placeholder(label_text: String) -> Control:
	var box := PanelContainer.new()
	box.name = "MediaPlaceholder"
	box.custom_minimum_size = Vector2(MEDIA_WIDTH, PLACEHOLDER_HEIGHT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.22, 0.27, 1.0)
	box.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "howto/" + label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_type_variation = "SmallLabel"
	box.add_child(label)
	return box


## A cell, with a blank (JSON null) read as "" rather than the text "<null>".
static func _cell(entry: Dictionary, key: String) -> String:
	var value = entry.get(key)
	return "" if value == null else str(value).strip_edges()
