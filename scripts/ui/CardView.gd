class_name CardView
extends Button
## One card in the player's hand, using the front frame assigned to its suit.
##
## The frame is a single 1429x2000 PNG with the furniture already drawn on
## it: a cost disc top left, a name bar beside it, a window where the art
## will go, and a box across the lower third for the text. Nothing here
## draws any of that — it positions labels over the regions the artwork
## already has, as fractions of the card, so the layout holds at whatever
## size the hand row gives it.
##
## THE REGIONS were measured off the PNG rather than guessed, and they are
## the only numbers in this file that matter. 
##
## It is a Button so that tapping, keyboard focus and the disabled look all
## come for free. Tapping opens the card rather than playing it, so a
## mis-tap never costs a turn — the zoom carries the Play button.
##
## DRAG TO PLAY. Pulling a playable card upwards lifts it off the hand; let
## go once it has risen PLAY_LIFT pixels and it is played, with no zoom in
## between. Let go sooner and it drops back. A sideways drag is the hand
## scrolling (DragScroll), and never lifts a card.

## The player tapped this card.
signal chosen(card_id: String)

## The player dragged this card up far enough and let go: play it.
signal flung(card_id: String)

## How far up a press must move before the card lifts, and how far it must
## rise before letting go plays it.
const LIFT_START := 30.0
const PLAY_LIFT := 220.0

## The tint a lifted card takes once letting go would play it.
const READY_TINT := Color(1.0, 0.93, 0.6)

## The temporary illustration sits inside the art window, behind the frame.
const TEMPORARY_CARD_ART: Texture2D = preload("res://assets/cards/card_temporary_image.png")
const CARD_FONT: FontFile = preload("res://assets/fonts/AntakaBrushDisplay-Regular.ttf")

## Canonical suit-to-front-template mapping from data/suits.json.
const FRAME_BY_SUIT := {
	"Earnest": preload("res://assets/cards/front_sumo.png"),
	"Emotional": preload("res://assets/cards/front_sakura.png"),
	"Appeal": preload("res://assets/cards/front_ukiyoe.png"),
	"Data Driven": preload("res://assets/cards/frame_front_shoji.png"),
	"Divisive": preload("res://assets/cards/front_castle.png"),
	"Duplicitous": preload("res://assets/cards/front_ninja.png"),
}

## The frame's own proportions, so the card is never stretched.
const ASPECT := 1429.0 / 2000.0
const HEIGHT := 470.0
const WIDTH := HEIGHT * ASPECT

## Where things sit on the frame, as fractions of its width and height.
## The cost disc is a transparent HOLE in the frame, not a white circle:
## the artwork leaves it for the game to fill. Measured off the PNG.
const COST_RECT := Rect2(0.0588, 0.0330, 0.0980, 0.0705)
const COST_LABEL_LIFT := 0.008
const NAME_RECT := Rect2(0.215, 0.032, 0.655, 0.056)
const ART_RECT := Rect2(0.130, 0.210, 0.740, 0.370)
const TEXT_RECT := Rect2(0.128, 0.700, 0.744, 0.175)
const EFFECT_FONT_SIZE := 23
const EFFECT_FONT_SIZE_MIN := 12



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
var _art_image: TextureRect
var _cost_label: Label
var _name_label: Label
var _art_label: Label
var _effect_label: Label

var _press_at := Vector2.ZERO
var _pressing := false
var _lifting := false
var _rest_y := 0.0


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
	# Artwork is deliberately smaller than the card and sits behind its frame.
	# This keeps it inside the shared art window and prevents spill over the
	# template border.
	var plate := ColorRect.new()
	place(plate, ART_RECT)
	plate.color = PLATE
	add_child(plate)

	_art_image = TextureRect.new()
	_art_image.texture = TEMPORARY_CARD_ART
	place(_art_image, ART_RECT)
	_art_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_art_image)

	_frame = TextureRect.new()
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
	# Use the full circle rectangle with no added margin. Its center is the
	# measured center of the printed cost circle on the card templates.
	place(_cost_label, Rect2(
		COST_RECT.position.x,
		COST_RECT.position.y - COST_LABEL_LIFT,
		COST_RECT.size.x,
		COST_RECT.size.y))
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_cost_label.add_theme_constant_override("line_spacing", 0)
	_cost_label.add_theme_color_override("font_color", INK)
	add_child(_cost_label)
	var cost_font := FontVariation.new()
	cost_font.base_font = CARD_FONT
	cost_font.variation_embolden = 0.15
	_cost_label.add_theme_font_override("font", cost_font)
	_cost_label.add_theme_font_size_override("font_size", 31)

	_name_label = Label.new()
	place(_name_label, NAME_RECT)
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", INK)
	_name_label.add_theme_font_override("font", CARD_FONT)
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
	_art_label.add_theme_font_override("font", CARD_FONT)
	_art_label.add_theme_font_size_override("font_size", 30)
	add_child(_art_label)

	_effect_label = Label.new()
	place(_effect_label, TEXT_RECT)
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_effect_label.add_theme_color_override("font_color", INK)
	_effect_label.add_theme_font_override("font", CARD_FONT)
	_effect_label.add_theme_font_size_override("font_size", EFFECT_FONT_SIZE)
	_effect_label.add_theme_constant_override("line_spacing", 0)
	_effect_label.clip_text = true
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
	_frame.texture = FRAME_BY_SUIT.get(str(card_row.get("suit", "")), FRAME_BY_SUIT["Data Driven"])
	_fit_effect_label.call_deferred()

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
	_fit_effect_label.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _effect_label != null:
		_fit_effect_label.call_deferred()


## Shrinks the front effect text only when its wrapped lines would exceed the
## text box, and recalculates when the card is shown or its size changes.
func _fit_effect_label() -> void:
	if _effect_label == null or _effect_label.text.is_empty():
		return
	if _effect_label.size.x <= 0.0 or _effect_label.size.y <= 0.0:
		return

	var font: Font = _effect_label.get_theme_font("font")
	if font == null:
		return
	var available_width := maxf(_effect_label.size.x - 4.0, 1.0)
	var available_height := maxf(_effect_label.size.y - 4.0, 1.0)
	for font_size: int in range(EFFECT_FONT_SIZE, EFFECT_FONT_SIZE_MIN - 1, -1):
		var measured := font.get_multiline_string_size(
			_effect_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			available_width,
			font_size)
		if measured.y <= available_height:
			_effect_label.add_theme_font_size_override("font_size", font_size)
			return
	_effect_label.add_theme_font_size_override("font_size", EFFECT_FONT_SIZE_MIN)


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
	if bool(effect.get("answers_question", false)):
		parts.append(Text.say("card.answers_question"))

	if parts.is_empty():
		return str(card_row.get("effect_text", ""))
	return " ".join(parts)


# ---------------------------------------------------------------------------
# Drag to play
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			_press_at = button.global_position
			_pressing = not disabled
			_lifting = false
		else:
			if _lifting:
				_drop(_press_at.y - button.global_position.y)
			_pressing = false
		return

	if event is InputEventMouseMotion and _pressing:
		var where := (event as InputEventMouseMotion).global_position
		var up := _press_at.y - where.y
		if not _lifting and up > LIFT_START and up > absf(where.x - _press_at.x):
			_lift()
		if _lifting:
			position.y = _rest_y - maxf(up, 0.0)
			self_modulate = READY_TINT if up >= PLAY_LIFT else Color.WHITE
			accept_event()


func _lift() -> void:
	_lifting = true
	_rest_y = position.y
	z_index = 20
	# A lift is not a tap: forget the press, so letting go does not also open
	# the zoom (BaseButton.set_disabled drops a press in progress).
	disabled = true
	disabled = false
	# The hand is clipped to its own strip; a lifted card has to be seen
	# rising above it.
	var scroll := _hand_scroll()
	if scroll != null:
		scroll.clip_contents = false


func _drop(risen: float) -> void:
	_lifting = false
	z_index = 0
	self_modulate = Color.WHITE
	var scroll := _hand_scroll()
	if scroll != null:
		scroll.clip_contents = true
	var container := get_parent() as Container
	if container != null:
		container.queue_sort()   # back into its place in the hand
	else:
		position.y = _rest_y
	if risen >= PLAY_LIFT:
		flung.emit(card_id)


func _hand_scroll() -> ScrollContainer:
	var node := get_parent()
	while node != null and not (node is ScrollContainer):
		node = node.get_parent()
	return node as ScrollContainer


## Greys the card out when there isn't enough energy left to play it.
func set_affordable(affordable: bool) -> void:
	disabled = not affordable
	modulate = Color(1, 1, 1, 1.0 if affordable else 0.45)


## Dims a card whose numbers do nothing here, so that playing it is a
## decision rather than a discovery.
func set_useless_here(useless: bool) -> void:
	if useless:
		modulate = Color(1, 1, 1, 0.5)
