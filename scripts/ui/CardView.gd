class_name CardView
extends Button
## One card in the player's hand, on Cameron's shoji frame.
##
## The frame is a single 1429x2000 PNG with the furniture already drawn on
## it: a cost disc top left, a name bar beside it, a window where the art
## will go, and a box across the lower third for the text. Nothing here
## draws any of that — it positions labels over the regions the artwork
## already has, as fractions of the card, so the layout holds at whatever
## size the hand row gives it.
##
## THE REGIONS were measured off the PNG rather than guessed, and they are
## the only numbers in this file that matter. If Cameron redraws the frame,
## re-measure and change them here; everything else follows.
##
## It is a Button so that tapping, keyboard focus and the disabled look all
## come for free. Tapping opens the card rather than playing it, so a
## mis-tap never costs a turn — the zoom carries the Play button.

## The player tapped this card.
signal chosen(card_id: String)

## Resolved once, when the script compiles, rather than looked up again for
## every card in every hand.
const FRAME_FRONT := preload("res://assets/cards/frame_front_shoji.png")

## The frame's own proportions, so the card is never stretched.
const ASPECT := 1429.0 / 2000.0
const HEIGHT := 470.0
const WIDTH := HEIGHT * ASPECT

## Where things sit on the frame, as fractions of its width and height.
## The cost disc is a transparent HOLE in the frame, not a white circle:
## the artwork leaves it for the game to fill. Measured off the PNG.
const COST_RECT := Rect2(0.0588, 0.0330, 0.0980, 0.0705)
const NAME_RECT := Rect2(0.215, 0.042, 0.655, 0.056)
const ART_RECT := Rect2(0.120, 0.160, 0.760, 0.436)
const TEXT_RECT := Rect2(0.128, 0.676, 0.744, 0.200)

## NO SUIT COLOUR. There used to be a coloured band across the footer strip,
## so a hand could be read by suit at a glance. Cameron had it removed on
## 2026-09-21: each suit is getting its own card template, and a stripe that
## will not survive those templates is a signal the player would have to
## unlearn. Until they arrive, one frame serves all six.

## Ink on a cream box wants to be dark, not the theme's pale text.
const INK := Color(0.16, 0.13, 0.10)

## The frame's own cream, for the disc the artwork leaves hollow.
const CREAM := Color(0.965, 0.945, 0.898)

## The art window is transparent too, and Cameron said to ignore that until
## there is art to put in it. Left alone it shows the dark screen behind the
## card, so a cream card reads as having a hole punched through it. This is
## the cream again, knocked back, so an empty window reads as an unprinted
## plate. Art will cover it entirely.
const PLATE := Color(0.902, 0.874, 0.820)

var card: Dictionary = {}
var card_id: String = ""

var _frame: TextureRect
var _cost_label: Label
var _name_label: Label
var _art_label: Label
var _effect_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	clip_contents = true
	clip_text = false
	text = ""
	# The frame is the whole look, so the button draws nothing of its own.
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())


func _ready() -> void:
	# Only if nothing has built it already. show_card() builds on demand so a
	# card can be filled in before it is put on screen, and building twice
	# lays a second set of empty labels over the filled ones — a card with no
	# name and no Japanese on it, which is exactly what happened.
	if _effect_label == null:
		_build()
	pressed.connect(func() -> void: chosen.emit(card_id))


## Anchors a control to a fraction of the card, so every region scales with
## it rather than being pinned to one size.
static func place(node: Control, where: Rect2) -> void:
	node.anchor_left = where.position.x
	node.anchor_top = where.position.y
	node.anchor_right = where.position.x + where.size.x
	node.anchor_bottom = where.position.y + where.size.y
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build() -> void:
	# Behind the frame, not over it: the window is a hole in an otherwise
	# opaque PNG, so anything laid underneath shows through exactly the hole
	# and cannot spill over the border the artwork draws around it.
	var plate := ColorRect.new()
	place(plate, ART_RECT)
	plate.color = PLATE
	add_child(plate)

	_frame = TextureRect.new()
	_frame.texture = FRAME_FRONT
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	# The frame leaves the cost disc transparent, so it has to be filled or
	# the number floats on whatever is behind the card.
	var disc := Panel.new()
	place(disc, COST_RECT)
	var disc_box := StyleBoxFlat.new()
	disc_box.bg_color = CREAM
	disc_box.set_corner_radius_all(256)   # clamped to half the height: a circle
	disc.add_theme_stylebox_override("panel", disc_box)
	add_child(disc)

	_cost_label = Label.new()
	place(_cost_label, COST_RECT)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_color_override("font_color", INK)
	_cost_label.add_theme_font_size_override("font_size", 40)
	add_child(_cost_label)

	_name_label = Label.new()
	place(_name_label, NAME_RECT)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", INK)
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_name_label)

	# The art window is empty until there is art. The Japanese name sits in
	# it rather than crowding the name bar, which holds one line.
	_art_label = Label.new()
	place(_art_label, ART_RECT)
	_art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_art_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_art_label.add_theme_color_override("font_color", Color(0.45, 0.38, 0.30, 0.85))
	_art_label.add_theme_font_size_override("font_size", 30)
	add_child(_art_label)

	_effect_label = Label.new()
	place(_effect_label, TEXT_RECT)
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_effect_label.add_theme_color_override("font_color", INK)
	_effect_label.add_theme_font_size_override("font_size", 23)
	add_child(_effect_label)


## Fills the card in from a row of cards.json.
func show_card(card_row: Dictionary) -> void:
	card = card_row
	card_id = str(card_row.get("card_id", ""))

	if _effect_label == null:
		_build()

	# The printed cost. A battle overrides it with show_cost() when something
	# has made this card cheaper than the workbook says.
	show_cost(int(card_row.get("cost", 0)))
	_name_label.text = str(card_row.get("name_en", "Unnamed"))
	_art_label.text = str(card_row.get("name_jp", ""))
	_effect_label.text = str(card_row.get("effect_text", ""))

	tooltip_text = "%s — %s" % [card_row.get("name_en", ""), card_row.get("effect_text", "")]


## What this card costs RIGHT NOW, which is not always what is printed on it.
##
## C36 makes the next card of the turn cost one less, and the disc used to go
## on showing the workbook's number: the card read "2", cost 1, and lit up as
## playable on a single point of energy. The hand asks the engine for the
## real cost to decide whether a card is affordable, and now writes the same
## number here, so the two cannot disagree.
func show_cost(cost: int) -> void:
	if _cost_label != null:
		_cost_label.text = str(cost)


## Replaces the printed text with what this card will actually do here.
##
## The workbook's effect_text is what the card says on paper. The room
## decides what it does: affinity moves the support numbers, and in some
## rooms a number does nothing at all. Showing the printed value and then
## quietly doing something else is how a player stops trusting the screen.
func show_effect_here(effect: Dictionary) -> void:
	if _effect_label == null:
		return
	_effect_label.text = describe_effect(effect, card)


## The same sentence, as a static so the zoom can print it too.
static func describe_effect(effect: Dictionary, card_row: Dictionary) -> String:
	var parts: Array[String] = []
	var self_plus := int(effect.get("self_plus", 0))
	var opp_minus := int(effect.get("opp_minus", 0))
	var guard := int(effect.get("guard", 0))
	var draw := int(effect.get("draw", 0))
	var gaffe := int(effect.get("gaffe", 0))

	if self_plus != 0:
		parts.append(Text.say("card.gain", {"count": self_plus}))
	if opp_minus != 0 and bool(effect.get("opp_minus_counts", true)):
		parts.append(Text.say("card.opponent", {"count": opp_minus}))
	if guard != 0 and bool(effect.get("guard_counts", true)):
		parts.append(Text.say("card.guard", {"count": guard}))
	if draw != 0:
		parts.append(Text.say("card.draw", {"count": draw}))
	if gaffe != 0:
		parts.append(Text.say("card.gaffe", {"amount": "%+d" % gaffe}))

	if bool(effect.get("does_nothing", false)):
		parts.append(Text.say("card.does_nothing"))

	# Every card answers the question in front of you, whatever else it does.
	# Cameron spent a draw-1 card expecting it to be free and lost a question
	# to it, because the only place that rule was written down was inside the
	# details panel.
	if bool(effect.get("answers_question", false)):
		parts.append(Text.say("card.answers_question"))

	if parts.is_empty():
		return str(card_row.get("effect_text", ""))
	return " ".join(parts)


## Greys the card out when there isn't enough energy left to play it.
func set_affordable(affordable: bool) -> void:
	disabled = not affordable
	modulate = Color(1, 1, 1, 1.0 if affordable else 0.45)


## Dims a card whose numbers do nothing here, so that playing it is a
## decision rather than a discovery.
func set_useless_here(useless: bool) -> void:
	if useless:
		modulate = Color(1, 1, 1, 0.5)
