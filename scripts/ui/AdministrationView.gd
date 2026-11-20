class_name AdministrationView
extends RefCounted
## Draws the Administration screen (P13, 2026-11-20) from AdministrationModel's data: one card per group, each row a
## label on the left and its current value as a chip on the right, then the Political Pressure box with its one button.
## Draws only. It reads no game state and says nothing the model did not hand it.


## The cards, in order: the four groups, then the Political Pressure box.
static func cards(model: Dictionary) -> Array[Control]:
	var look := OfficeFrameStyles.look()
	var out: Array[Control] = []
	for group: Dictionary in model["groups"]:
		var card := OfficeFrameStyles.card(look, str(group["title"]))
		card.name = "AdminGroup_" + str(group["id"])
		var column := card.get_node("Column") as VBoxContainer
		column.add_theme_constant_override("separation", 0)
		var first := true
		for row: Dictionary in group["rows"]:
			if not first:
				column.add_child(_hairline(look))
			first = false
			column.add_child(_row(look, row))
		out.append(card)
	out.append(_pressure_card(look, model["pressure"]))
	return out


## One row: a tappable Button (the old menu's own node name) holding the label and the value chip, or, for a row with
## `hints` and nothing to press (reporting a problem), a label with its lines under it.
static func _row(look: Dictionary, row: Dictionary) -> Control:
	var press: Callable = row["press"]
	var label := Label.new()
	label.name = "RowLabel"
	label.text = str(row["label"])
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BODY + 1.0))
	if not press.is_valid():
		var box := VBoxContainer.new()
		box.name = str(row["node"])
		box.add_theme_constant_override("separation", 2)
		box.custom_minimum_size.y = OfficeFrameStyles.touch_height()
		box.add_child(label)
		for hint: Variant in row.get("hints", []):
			var line := UiKit.line(str(hint), "SmallLabel")
			line.custom_minimum_size.x = 0.0
			box.add_child(line)
		return box
	var button := Button.new()
	button.name = str(row["node"])
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quiet := StyleBoxEmpty.new()
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(look["tile"].r, look["tile"].g, look["tile"].b, 0.6)
	for state: String in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, quiet)
	for state: String in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, pressed)
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect(press)
	var line := HBoxContainer.new()
	line.name = "RowLine"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(label)
	# The chip sits in a holder that is not a row: UiKit.wrap_all gives every label directly in a row the row's spare
	# width, which would stretch the chip across half the card.
	var holder := MarginContainer.new()
	holder.name = "RowValueHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_END
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(_value_chip(look, str(row["value"])))
	line.add_child(holder)
	button.add_child(line)
	return button


## The current value as a small tile on the right of the row.
static func _value_chip(look: Dictionary, value: String) -> Control:
	var chip := Label.new()
	chip.name = "RowValue"
	chip.text = value
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.set_meta(UiKit.ONE_LINE_META, true)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BODY))
	chip.add_theme_color_override("font_color", look["ink"])
	chip.add_theme_stylebox_override("normal", LevelBriefingStyles.chip_box(look))
	return chip


static func _hairline(look: Dictionary) -> Control:
	var rule := ColorRect.new()
	rule.name = "RowRule"
	rule.color = Color(look["muted"].r, look["muted"].g, look["muted"].b, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


## The Political Pressure box: its title, the tier in force, what the next tier does, and the one button.
static func _pressure_card(look: Dictionary, pressure: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, str(pressure["title"]))
	card.name = "AdminPressure"
	var column := card.get_node("Column") as VBoxContainer
	var now := Label.new()
	now.name = "PressureNow"
	now.text = str(pressure["now"])
	column.add_child(now)
	var blurb := UiKit.line(str(pressure["blurb"]), "SmallLabel")
	blurb.custom_minimum_size.x = 0.0
	column.add_child(blurb)
	var button: Button = pressure["button"]
	OfficeFrameStyles.dress_card_button(button, look, not button.disabled)
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	button.custom_minimum_size.x = 0.0
	column.add_child(button)
	return card
