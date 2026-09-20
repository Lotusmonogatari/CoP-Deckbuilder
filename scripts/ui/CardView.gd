class_name CardView
extends Button
## One card in the player's hand.
##
## The face is deliberately sparse, per the UI spec: the cost, the English
## name, and a one-line effect. Everything else — the full text, the suit, the
## art, the Japanese name — waits behind a tap.
##
## It is a Button so that tapping, keyboard focus and the disabled look all
## come for free rather than being rebuilt.

## The player tapped this card.
signal chosen(card_id: String)

const WIDTH := 190.0
const HEIGHT := 360.0

## A quiet colour per suit, so a hand can be read by shape at a glance
## without anyone having to learn what the colours mean.
const SUIT_COLORS := {
	"Earnest": Color(0.35, 0.50, 0.42),
	"Emotional": Color(0.60, 0.38, 0.40),
	"Appeal": Color(0.55, 0.47, 0.30),
	"Data Driven": Color(0.33, 0.45, 0.58),
	"Divisive": Color(0.52, 0.35, 0.52),
	"Duplicitous": Color(0.42, 0.40, 0.34),
}

var card: Dictionary = {}
var card_id: String = ""

var _cost_label: Label
var _name_label: Label
var _effect_label: Label
var _jp_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	# Nothing may spill outside a card's edge, however long its effect text
	# turns out to be. A clipped sentence is ugly; one lying across the card
	# next to it is unreadable.
	clip_contents = true
	clip_text = false
	# The button's own label is unused; everything is laid out as children.
	text = ""


func _ready() -> void:
	_build()
	pressed.connect(func() -> void: chosen.emit(card_id))


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	# Cost, top left, in its own row so the name can wrap beneath it.
	_cost_label = Label.new()
	_cost_label.theme_type_variation = "HeaderLabel"
	column.add_child(_cost_label)

	_name_label = Label.new()
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.max_lines_visible = 2
	_name_label.add_theme_font_size_override("font_size", 28)
	_name_label.custom_minimum_size = Vector2(0, 76)
	column.add_child(_name_label)

	# The single Japanese accent this card is allowed.
	_jp_label = Label.new()
	_jp_label.theme_type_variation = "JapaneseAccent"
	_jp_label.max_lines_visible = 1
	_jp_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_jp_label.custom_minimum_size = Vector2(0, 30)
	column.add_child(_jp_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	_effect_label = Label.new()
	_effect_label.theme_type_variation = "SmallLabel"
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.max_lines_visible = 3
	_effect_label.add_theme_font_size_override("font_size", 22)
	_effect_label.custom_minimum_size = Vector2(0, 84)
	column.add_child(_effect_label)


## Fills the card in from a row of cards.json.
func show_card(card_row: Dictionary) -> void:
	card = card_row
	card_id = str(card_row.get("card_id", ""))

	if _cost_label == null:
		_build()

	_cost_label.text = str(int(card_row.get("cost", 0)))
	_name_label.text = str(card_row.get("name_en", "Unnamed"))
	_jp_label.text = str(card_row.get("name_jp", ""))
	_effect_label.text = str(card_row.get("effect_text", ""))

	var suit := str(card_row.get("suit", ""))
	var tint: Color = SUIT_COLORS.get(suit, Color(0.35, 0.35, 0.40))
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, _panel_for(state, tint))

	tooltip_text = "%s — %s" % [card_row.get("name_en", ""), card_row.get("effect_text", "")]


## Replaces the printed text with what this card will actually do here.
##
## The workbook's effect_text is what the card says on paper. The room
## decides what it does: affinity moves the support numbers, and in some
## rooms a number does nothing at all. Showing the printed value and then
## quietly doing something else is how a player stops trusting the screen.
func show_effect_here(effect: Dictionary) -> void:
	if _effect_label == null:
		return

	var parts: Array[String] = []
	var self_plus := int(effect.get("self_plus", 0))
	var opp_minus := int(effect.get("opp_minus", 0))
	var guard := int(effect.get("guard", 0))
	var draw := int(effect.get("draw", 0))
	var gaffe := int(effect.get("gaffe", 0))

	if self_plus != 0:
		parts.append("Gain %d." % self_plus)
	if opp_minus != 0 and bool(effect.get("opp_minus_counts", true)):
		parts.append("Opponent −%d." % opp_minus)
	if guard != 0 and bool(effect.get("guard_counts", true)):
		parts.append("Guard %d." % guard)
	if draw != 0:
		parts.append("Draw %d." % draw)
	if gaffe != 0:
		parts.append("Gaffe %+d." % gaffe)

	if bool(effect.get("does_nothing", false)):
		parts.append("Nothing this card does counts in this room.")

	# Every card answers the question in front of you, whatever else it does.
	# Cameron spent a draw-1 card expecting it to be free and lost a question
	# to it, because the only place that rule was written down was inside the
	# details panel.
	if bool(effect.get("answers_question", false)):
		parts.append("Answers this question.")

	_effect_label.text = " ".join(parts) if not parts.is_empty() else str(card.get("effect_text", ""))


## Greys the card out when there isn't enough energy left to play it.
func set_affordable(affordable: bool) -> void:
	disabled = not affordable
	modulate = Color(1, 1, 1, 1.0 if affordable else 0.45)


## Dims a card whose numbers do nothing here, so that playing it is a
## decision rather than a discovery.
func set_useless_here(useless: bool) -> void:
	if useless:
		modulate = Color(1, 1, 1, 0.5)


func _panel_for(state: String, tint: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = tint
	box.set_corner_radius_all(10)
	box.set_content_margin_all(0)

	match state:
		"hover":
			box.bg_color = tint.lightened(0.12)
		"pressed":
			box.bg_color = tint.darkened(0.15)
		"disabled":
			box.bg_color = tint.darkened(0.35)
		"focus":
			box.border_color = Color(1, 1, 1, 0.9)
			box.set_border_width_all(3)

	return box
