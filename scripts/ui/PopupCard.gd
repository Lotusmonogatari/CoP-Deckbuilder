class_name PopupCard
extends PanelContainer
## The pop-up card (P14, 2026-11-20): one card, centred (or at the foot) over the dimmed room: a header with a kind tag and a
## meta line (day, office, hours), a title, a scrolling body and a fixed row of buttons. Every pop-up of group 1 is this one
## card with a different tag and body, not a panel of its own.
##
## It lives inside an Overlay (Overlay.open_card), so the way out is the Overlay's: its Back and Confirm buttons are lent to the
## card's foot and given back when the Overlay shows something else. It draws what it is given and reads no game state.

## The gap Overlay.open_card leaves round the card, and the least height the body keeps.
const CARD_MARGIN := 40.0
const MIN_BODY := 160.0

var _look: Dictionary
var _scroll: ScrollContainer
var _body: VBoxContainer
var _foot: Container


## `config`:
##   tag        String, the kind tag's words ("" for none)
##   tag_kind   PopupCardStyles.ACCENT (default), ALARM or GOOD
##   meta       String, the small line beside the tag (day, office, hours)
##   title      String
##   body       Array of Control, the scrolling part
##   buttons    Array of Control, the foot (choices, usually Buttons)
##   grid       true to lay the foot's buttons out two to a row (an arranged event's options)
##   primary    index in `buttons` of the one drawn filled (the way on), or -1 for none
func setup(config: Dictionary) -> void:
	_look = OfficeFrameStyles.look()
	name = "PopupCard"
	add_theme_stylebox_override("panel", LevelBriefingStyles.card_box(_look))
	theme = OfficeFrameStyles.card_theme(_look)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var column := VBoxContainer.new()
	column.name = "CardColumn"
	column.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	add_child(column)

	var header := HBoxContainer.new()
	header.name = "CardHeader"
	header.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	column.add_child(header)
	var tag_text := str(config.get("tag", ""))
	if not tag_text.is_empty():
		header.add_child(PopupCardStyles.tag(_look, tag_text, str(config.get("tag_kind", PopupCardStyles.ACCENT))))
	var meta_text := str(config.get("meta", ""))
	var meta := Label.new()
	meta.name = "CardMeta"
	meta.text = meta_text
	meta.visible = not meta_text.is_empty()
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.theme_type_variation = "SmallLabel"
	header.add_child(meta)

	var title_text := str(config.get("title", ""))
	if not title_text.is_empty():
		var title := Label.new()
		title.name = "CardTitle"
		title.text = LevelBriefingStyles.title_text(_look, title_text)
		title.theme_type_variation = "HeaderLabel"
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_TITLE - 2.0))
		column.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.name = "CardScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	column.add_child(_scroll)
	DragScroll.attach(_scroll)
	_body = VBoxContainer.new()
	_body.name = "CardBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	_scroll.add_child(_body)
	for row: Control in config.get("body", []):
		_body.add_child(row)
		UiKit.wrap_all(row)
		OfficeScreenFrame.release_fixed_widths(row)

	if bool(config.get("grid", false)):
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(8.0)))
		grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(8.0)))
		_foot = grid
	else:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
		_foot = box
	_foot.name = "CardFoot"
	column.add_child(_foot)
	var buttons: Array = config.get("buttons", [])
	for i in buttons.size():
		add_foot(buttons[i] as Control, i == int(config.get("primary", -1)))
	_fit.call_deferred()


## Adds a control to the foot. A Button is dressed as a choice (outlined in the card's ink).
func add_foot(control: Control, primary: bool = false) -> void:
	if control.get_parent() != null:
		control.get_parent().remove_child(control)
	if control is Button:
		PopupCardStyles.dress_foot_button(control as Button, _look, primary)
		(control as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_foot.add_child(control)
	UiKit.wrap_all(control)


## Takes an Overlay's Confirm or Back button into the foot as the card's own primary or secondary button.
func lend(button: Button, primary: bool) -> void:
	add_foot(button, primary)


## The body takes the height its content needs, up to most of the screen: a container does not size a scroll area to its
## content, so without this the card would collapse to its header and foot.
func _fit() -> void:
	if not is_inside_tree():
		return
	for pass_number in 2:
		await get_tree().process_frame
		if not is_inside_tree() or _scroll == null:
			return
		# What the rest of the card takes (tag, title, buttons, padding) comes off the screen first, so a tall foot at Large text
		# on a short screen still fits: the story scrolls, the choices never leave the screen (text sweep, 2026-11-20).
		_scroll.custom_minimum_size.y = 0.0
		var chrome := get_combined_minimum_size().y
		var room := get_viewport_rect().size.y - 2.0 * CARD_MARGIN - chrome
		_scroll.custom_minimum_size.y = minf(_body.get_combined_minimum_size().y, maxf(room, MIN_BODY))


## The card's body, for a screen that adds to it after setup.
func body() -> VBoxContainer:
	return _body
