class_name MarketView
extends RefCounted
## Draws the Marketplace's cards (P13, 2026-11-20) from MarketModel's data: the "You have" strip and one card for each item
## on offer, always the same shape: an icon tile, the name and price, what it does, the reason in red when it cannot be
## bought, and a Buy button (greyed then). Draws only: it reads no game state.


## The "You have" card: its heading, the strip of what you hold (the inventory's own rows, tappable) and a hint.
static func held_card(look: Dictionary, held_rows: Array[Control]) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("shop.you_have"))
	card.name = "MarketHeld"
	var column := card.get_node("Column") as VBoxContainer
	for row: Control in held_rows:
		column.add_child(row)
	var hint := UiKit.line(Text.say("shop.you_have_hint"), "SmallLabel")
	hint.custom_minimum_size.x = 0.0
	column.add_child(hint)
	return card


## One item on offer. `on_buy` is called with the item's id when Buy is pressed (never when it is greyed).
static func item_card(look: Dictionary, item: Dictionary, on_buy: Callable) -> Control:
	var card := OfficeFrameStyles.card(look)
	card.name = "Supply_" + str(item["item_id"])
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(10.0)))
	card.get_node("Column").add_child(line)

	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", LevelBriefingStyles.tile_box(look, 4.0))
	tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.texture = ArtLoader.item_icon(str(item["icon"]))
	icon.custom_minimum_size = Vector2(120, 120)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tile.add_child(icon)
	line.add_child(tile)

	var box := UiKit.tight_column()
	box.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(3.0)))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(box)
	var title := UiKit.line(str(item["title"]))
	title.name = "ItemTitle"
	title.custom_minimum_size.x = 0.0
	box.add_child(title)
	var effect := UiKit.line(str(item["description"]), "SmallLabel")
	effect.name = "ItemEffect"
	effect.custom_minimum_size.x = 0.0
	box.add_child(effect)
	var refusal := str(item["refusal"])
	if not refusal.is_empty():
		var why := UiKit.line(refusal)
		why.name = "ItemRefusal"
		why.custom_minimum_size.x = 0.0
		why.add_theme_color_override("font_color", look["down"])
		box.add_child(why)

	var button := Button.new()
	button.name = "Buy"
	button.text = Text.say("shop.buy")
	button.disabled = not refusal.is_empty()
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	OfficeFrameStyles.dress_card_button(button, look, refusal.is_empty())
	if refusal.is_empty():
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(on_buy.bind(str(item["item_id"])))
	box.add_child(button)

	# Out of Stock greys the whole card, not just its button, so a sold-out item reads as unavailable at a glance.
	if bool(item["out_of_stock"]):
		card.modulate = Color(1, 1, 1, 0.45)
	return card
