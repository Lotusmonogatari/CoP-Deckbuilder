class_name UiKit
extends RefCounted
## The small pieces every panel is built from, made one way.
##
## The Office's shops, the inventory and the new-game screens all build the
## same three things: a wrapped line of text, a heading, and a button that
## either does something or shows the rules' reason it cannot. Kept here so
## a change to how one looks (a bigger touch target, say) is one edit.

## Wide enough to wrap inside an Overlay's content column.
const LINE_WIDTH := 760.0


## A line that wraps rather than running off the screen.
static func line(text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


static func heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = "HeaderLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	return label


## Makes every label and button under `root` wrap its text instead of
## running off the edge of the screen (2026-10-14). A label inside a row
## (HBoxContainer) is told to take the row's spare width so it wraps there
## rather than collapsing; one in a column already has the column's width.
## Safe to call on rows built by any screen; text that already fits is not
## changed in any way.
static func wrap_all(root: Node) -> void:
	for node in root.find_children("*", "Control", true, false):
		if node is Label:
			var label := node as Label
			if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if label.get_parent() is HBoxContainer:
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif node is Button:
			var button := node as Button
			if button.autowrap_mode == TextServer.AUTOWRAP_OFF:
				button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The row itself, when it is a bare label or button.
	if root is Label and (root as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
		(root as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif root is Button and (root as Button).autowrap_mode == TextServer.AUTOWRAP_OFF:
		(root as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## A button that says `ok_text` and calls `on_press` — or, when `refusal` is
## not empty, shows that reason greyed out and does nothing. Every shop row
## has this shape, and the refusal is always the rules' own words.
static func action_button(ok_text: String, refusal: String, on_press: Callable,
		height: float = 90.0) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.text = ok_text if refusal.is_empty() else refusal
	button.disabled = not refusal.is_empty()
	if refusal.is_empty():
		button.pressed.connect(on_press)
	return button


## A column with no gap to speak of — a row's title, its details and its
## button, read as one thing.
static func tight_column() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	return box
