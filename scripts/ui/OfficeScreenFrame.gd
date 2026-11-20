class_name OfficeScreenFrame
extends PanelContainer
## The one frame the Office screens share (P13, 2026-11-20): a "‹ Office" control and status chips on top, the screen's
## title with its Japanese subtitle, an optional row of tabs, a scrolling column of cards, and an optional fixed button
## at the foot. The top bar, title, tabs and footer stay put; only the column scrolls.
##
## It lives inside an Overlay (Overlay.open_frame), never instead of one: the Overlay still owns the way out (the
## "‹ Office" control IS the Overlay's own Back button, moved into the top bar; the escape key still closes it), so no
## screen drawn on this frame can trap the player.
##
## It draws what it is given. A screen hands it plain data (a title, chips as text, tabs as ids and text, rows as
## nodes) and reacts to `tab_chosen`; nothing here reads GameState or knows a rule. How it looks in each of the three
## styles is OfficeFrameStyles.

## A tab was tapped (its id).
signal tab_chosen(tab_id: String)

var _look: Dictionary
var _back_slot: HBoxContainer
var _chips: HBoxContainer
var _tabs_row: HBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _footer_slot: VBoxContainer
var _title_label: Label
var _subtitle_label: Label


## Builds the frame. `config`:
##   title      String, the screen's name
##   subtitle   String, its Japanese subtitle ("" for none)
##   chips      Array of String, shown on the right of the top bar
##   tabs       Array of { "id": String, "text": String }; empty for a screen without tabs
##   active_tab String, the id of the chosen tab
##   rows       Array of Control, the cards in the scrolling column
##   footer     a Button for the fixed footer, or null
func setup(config: Dictionary) -> void:
	_look = OfficeFrameStyles.look()
	name = "OfficeScreenFrame"
	var ground := StyleBoxFlat.new()
	ground.bg_color = _look["ground"]
	add_theme_stylebox_override("panel", ground)

	var margin := MarginContainer.new()
	margin.name = "FrameMargin"
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)

	var column := VBoxContainer.new()
	column.name = "FrameColumn"
	column.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	margin.add_child(column)

	column.add_child(_build_top_bar(config.get("chips", [])))
	column.add_child(_build_title(str(config.get("title", "")), str(config.get("subtitle", ""))))
	var tabs: Array = config.get("tabs", [])
	if not tabs.is_empty():
		column.add_child(_build_tabs(tabs, str(config.get("active_tab", ""))))

	_scroll = ScrollContainer.new()
	_scroll.name = "FrameScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Drags and wheels still scroll it; no bar is drawn beside the cards (the mockups have none).
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	column.add_child(_scroll)
	DragScroll.attach(_scroll)
	_body = VBoxContainer.new()
	_body.name = "FrameBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(10.0)))
	_scroll.add_child(_body)
	for row: Control in config.get("rows", []):
		_body.add_child(row)
		UiKit.wrap_all(row)

	_footer_slot = VBoxContainer.new()
	_footer_slot.name = "FrameFooter"
	column.add_child(_footer_slot)
	var footer: Variant = config.get("footer")
	if footer is Button:
		LevelBriefingStyles.dress_button(footer as Button, _look, true, not (footer as Button).disabled)
		(footer as Button).custom_minimum_size.y = maxf((footer as Button).custom_minimum_size.y, OfficeFrameStyles.touch_height())
		_footer_slot.add_child(footer as Button)


## Takes the Overlay's own Back button into the top bar as the "‹ Office" control. Its node, its name and its wiring
## (a tap closes the Overlay) stay as they were, so a test or a player that presses Back still does.
func attach_back(button: Button, text: String) -> void:
	if button.get_parent() != null:
		button.get_parent().remove_child(button)
	button.text = text
	OfficeFrameStyles.dress_back(button, _look)
	_back_slot.add_child(button)


## The column the cards go in, for a screen that adds to it after setup.
func body() -> VBoxContainer:
	return _body


## Scrolls the column back to the top (a tab change shows its list from the start).
func scroll_to_top() -> void:
	if _scroll != null:
		_scroll.scroll_vertical = 0


func _build_top_bar(chips: Array) -> Control:
	var bar := HBoxContainer.new()
	bar.name = "FrameTopBar"
	bar.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	_back_slot = HBoxContainer.new()
	_back_slot.name = "FrameBackSlot"
	bar.add_child(_back_slot)
	var spacer := Control.new()
	spacer.name = "FrameSpacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	_chips = HBoxContainer.new()
	_chips.name = "FrameChips"
	_chips.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(6.0)))
	bar.add_child(_chips)
	for text: Variant in chips:
		_chips.add_child(OfficeFrameStyles.chip(_look, str(text)))
	return bar


func _build_title(title: String, subtitle: String) -> Control:
	# A flow row: the Japanese subtitle sits beside the title when it fits and drops under it when it does not.
	var row := HFlowContainer.new()
	row.name = "FrameTitleRow"
	row.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(10.0)))
	row.add_theme_constant_override("v_separation", 0)
	_title_label = Label.new()
	_title_label.name = "FrameTitle"
	_title_label.text = LevelBriefingStyles.title_text(_look, title)
	_title_label.theme_type_variation = "HeaderLabel"
	# One line (a title is short); a wrapping label in a flow row would shrink to a letter wide.
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(OfficeFrameStyles.title_size(_look)))
	_title_label.add_theme_color_override("font_color", _look["on_ground"])
	_title_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	row.add_child(_title_label)
	_subtitle_label = Label.new()
	_subtitle_label.name = "FrameSubtitle"
	_subtitle_label.text = subtitle
	_subtitle_label.visible = not subtitle.is_empty()
	_subtitle_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subtitle_label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL))
	_subtitle_label.add_theme_color_override("font_color", _look["on_ground_muted"])
	_subtitle_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	row.add_child(_subtitle_label)
	return row


func _build_tabs(tabs: Array, active: String) -> Control:
	# A row that scrolls sideways when the tabs do not fit; the vertical scroll is off so it never grabs a downward drag.
	var scroll := ScrollContainer.new()
	scroll.name = "FrameTabsScroll"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Drags sideways, with no bar drawn under the tabs.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.custom_minimum_size.y = OfficeFrameStyles.touch_height() + 8.0
	DragScroll.attach(scroll, false)
	_tabs_row = HBoxContainer.new()
	_tabs_row.name = "FrameTabs"
	_tabs_row.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	scroll.add_child(_tabs_row)
	for tab: Dictionary in tabs:
		var id := str(tab.get("id", ""))
		var button := Button.new()
		button.name = "FrameTab_" + id
		button.text = str(tab.get("text", ""))
		OfficeFrameStyles.dress_tab(button, _look, id == active)
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(func() -> void: tab_chosen.emit(id))
		_tabs_row.add_child(button)
	return scroll
