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
var _chips: HFlowContainer
var _tabs_row: HFlowContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _footer_slot: VBoxContainer
var _title_label: Label
var _subtitle_label: Label


## Builds the frame. `config`:
##   title      String, the screen's name
##   subtitle   String, its Japanese subtitle ("" for none)
##   chips      Array of String, shown on the right of the top bar
##   tabs       Array of { "id": String, "text": String, "node": String (optional node name) }; empty for none
##   active_tab String, the id of the chosen tab
##   rows       Array of Control, the cards in the scrolling column
##   footer     a Button for the fixed footer, or null
func setup(config: Dictionary) -> void:
	_look = OfficeFrameStyles.look()
	name = "OfficeScreenFrame"
	theme = OfficeFrameStyles.frame_theme()
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
		release_fixed_widths(row)

	_footer_slot = VBoxContainer.new()
	_footer_slot.name = "FrameFooter"
	column.add_child(_footer_slot)
	var footer: Variant = config.get("footer")
	if footer is Button:
		LevelBriefingStyles.dress_button(footer as Button, _look, true, not (footer as Button).disabled)
		(footer as Button).custom_minimum_size.y = maxf((footer as Button).custom_minimum_size.y, OfficeFrameStyles.touch_height())
		_footer_slot.add_child(footer as Button)


## The old panels' rows ask for a fixed 760 px line (UiKit.LINE_WIDTH), which does not fit beside an icon and a button
## inside a card and would push the whole screen wider than the phone. On the frame the column's width decides, so every
## control under `root` that asks for that fixed width gives it up (a wrapping label then takes the room it is given).
static func release_fixed_widths(root: Node) -> void:
	var nodes: Array = [root]
	nodes.append_array(root.find_children("*", "Control", true, false))
	for node: Variant in nodes:
		var control := node as Control
		if control != null and absf(control.custom_minimum_size.x - UiKit.LINE_WIDTH) < 0.5:
			control.custom_minimum_size.x = 0.0


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


## How far the column is scrolled now.
func scroll_value() -> int:
	return _scroll.scroll_vertical if _scroll != null else 0


## Scrolls the column to `value` once it has been laid out (a screen drawn again after a purchase keeps the player's place; a tester's idea,
## 2026-11-24). Waits two frames so the cards have their heights; never past the end.
func restore_scroll(value: int) -> void:
	if _scroll == null or value <= 0:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_scroll) and _scroll.is_inside_tree():
		_scroll.scroll_vertical = value


## Scrolls the column back to the top (a tab change shows its list from the start).
func scroll_to_top() -> void:
	if _scroll != null:
		_scroll.scroll_vertical = 0


func _build_top_bar(chips: Array) -> Control:
	# The chips are a flow row, right-aligned: they wrap onto a second line when they do not fit. At the Large text
	# size a long chip (Funds against the limit) no longer fits beside the back control, so the chips take their own
	# row under it; anything wider than the column would otherwise widen the whole screen past the phone.
	_back_slot = HBoxContainer.new()
	_back_slot.name = "FrameBackSlot"
	_chips = HFlowContainer.new()
	_chips.name = "FrameChips"
	_chips.alignment = FlowContainer.ALIGNMENT_END
	_chips.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(6.0)))
	_chips.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(6.0)))
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for text: Variant in chips:
		_chips.add_child(OfficeFrameStyles.chip(_look, str(text)))
	var large := TextScale.factor(Layout.text_size_setting, DataDB.balance) > 1.05
	if large:
		var stacked := VBoxContainer.new()
		stacked.name = "FrameTopBar"
		stacked.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(4.0)))
		stacked.add_child(_back_slot)
		stacked.add_child(_chips)
		return stacked
	var bar := HBoxContainer.new()
	bar.name = "FrameTopBar"
	bar.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	bar.add_child(_back_slot)
	bar.add_child(_chips)
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
	if _look.get("display_font") != null:
		_title_label.add_theme_font_override("font", _look["display_font"])   # a campaign skin's display face (P22)
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
	_fit_title.call_deferred()
	return row


## A long title ("National Assembly Library" at the large text size) steps down in size until it fits the screen's width, so it never
## pushes the whole screen wider than the phone (the text sweep, 2026-11-24). A short title is left at its size.
func _fit_title() -> void:
	if _title_label == null or not is_inside_tree():
		return
	var limit := get_viewport_rect().size.x - OfficeFrameStyles.len_px(100.0)
	var width := _title_label.get_combined_minimum_size().x
	if width <= limit or width <= 0.0:
		return
	var base := OfficeFrameStyles.px(OfficeFrameStyles.title_size(_look))
	_title_label.add_theme_font_size_override("font_size", maxi(int(float(base) * limit / width), int(base * 0.5)))


func _build_tabs(tabs: Array, active: String) -> Control:
	# A flow row: the tabs sit on one line when they fit and wrap onto a second when they do not (a large text size, or
	# six tabs), so every tab is always on the screen. The text sweep forbids text off the edge, even in a scroll box.
	_tabs_row = HFlowContainer.new()
	_tabs_row.name = "FrameTabs"
	_tabs_row.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(6.0)))
	_tabs_row.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(6.0)))
	for tab: Dictionary in tabs:
		var id := str(tab.get("id", ""))
		var button := Button.new()
		# A screen may keep its tabs' old node names (the Marketplace's PersonalTab, OfficeTab and StylesTab).
		button.name = str(tab.get("node", "FrameTab_" + id))
		button.text = str(tab.get("text", ""))
		OfficeFrameStyles.dress_tab(button, _look, id == active)
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(func() -> void: tab_chosen.emit(id))
		_tabs_row.add_child(button)
	return _tabs_row
