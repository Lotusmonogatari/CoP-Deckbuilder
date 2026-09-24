class_name InventoryPanel
extends Overlay
## The inventory, and the pop-up for one item in it.
##
## One panel, two views: the grid of everything held (tap an icon), then
## that item's details — icon, how many, stack cap, what it does, when it
## lands — with Use and Close. Built on Overlay so it keeps the three ways
## out every panel here has, and shared by the Office and the battle screen
## so the two can never drift apart; `context` is the only difference.
##
## Every sentence comes from the Text tab and every rule from Items.gd /
## GameState — this file only draws. See design/proposals/inventory.md.

## Items.OFFICE or Items.STAGE: where the Use button is being pressed.
var context := Items.OFFICE

## The battle an item is used on. Set by the battle screen; null in the
## Office.
var engine: BattleEngine = null

## Called with GameState's result after an item is used, so the screen
## behind can redraw what changed.
var on_used: Callable = Callable()

## The item whose pop-up is open, or "" while the grid is showing. The one
## confirm button means Use, and this says what it would use.
var _showing_item := ""

## What the last Use said, shown once at the top of the grid.
var _notice := ""


func _ready() -> void:
	super._ready()
	confirmed.connect(_on_use_pressed)


## The grid of everything held.
func show_inventory() -> void:
	_showing_item = ""
	var rows: Array[Control] = []
	if not _notice.is_empty():
		rows.append(_label(_notice))
		_notice = ""

	var held := _held_items()
	if held.is_empty():
		rows.append(_label(Text.say("inventory.empty")))
	else:
		var grid := GridContainer.new()
		grid.name = "Items"
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		for item_id: String in held:
			grid.add_child(_item_button(item_id))
		rows.append(grid)

	open(Text.say("inventory.title"), rows)


## One item's pop-up: what it is, how many, and Use or Close.
func show_item(item_id: String) -> void:
	_showing_item = item_id
	var item := DataDB.get_shop_item(item_id)
	var rows: Array[Control] = []

	var icon := TextureRect.new()
	icon.texture = ArtLoader.item_icon(icon_name(item))
	icon.custom_minimum_size = Vector2(220, 220)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rows.append(icon)

	rows.append(_label(Text.say("item.quantity", {"count": GameState.item_count(item_id)})))
	var cap := Items.stack_cap(item)
	if cap > 0:
		rows.append(_label(Text.say("item.stack_cap", {"count": cap}), "SmallLabel"))
	# The Description is display text, straight off the Shop tab — shown,
	# never read for what the item does (that is the Grants column's job).
	rows.append(_label(str(item.get("description", "")), "SmallLabel"))
	rows.append(_label(Items.timing_line(item, context, Text.phrase()), "SmallLabel"))

	var refusal := _refusal(item_id, item)
	if not refusal.is_empty():
		rows.append(_label(refusal))

	open(str(item.get("name", item_id)), rows,
		Text.say("item.use") if refusal.is_empty() else "",
		Text.say("item.close"))


## The icon file name for an item: its Icon cell, or its ID when blank.
static func icon_name(item: Dictionary) -> String:
	var value: Variant = item.get("icon")
	if value == null or str(value).strip_edges().is_empty():
		return str(item.get("item_id", ""))
	return str(value).strip_edges()


func _refusal(item_id: String, item: Dictionary) -> String:
	var refusal := Items.use_refusal(item, context, GameState.item_count(item_id), Text.phrase())
	if not refusal.is_empty() or context != Items.STAGE:
		return refusal
	# During a stage the battle has two more reasons of its own. Asked here
	# too, so the Use button is never offered only to be refused.
	if engine == null or engine.state == null or engine.state.is_over():
		return Text.say("item.refused.battle_over")
	if int(engine.state.items_used_this_turn.get(item_id, 0)) >= Items.uses_per_turn(item):
		return Text.say("item.refused.turn_limit")
	return ""


func _on_use_pressed() -> void:
	if _showing_item.is_empty():
		return
	var result: Dictionary
	if context == Items.STAGE:
		result = GameState.use_item_in_stage(_showing_item, engine)
	else:
		result = GameState.use_item_in_office(_showing_item)
	_notice = str(result.get("message", ""))
	if on_used.is_valid():
		on_used.call(result)
	show_inventory()


func _held_items() -> Array[String]:
	var held: Array[String] = []
	for item_id: Variant in GameState.inventory.keys():
		if GameState.item_count(str(item_id)) > 0:
			held.append(str(item_id))
	held.sort()
	return held


func _item_button(item_id: String) -> Button:
	var item := DataDB.get_shop_item(item_id)
	var button := Button.new()
	button.name = "Item_" + item_id
	button.icon = ArtLoader.item_icon(icon_name(item))
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.custom_minimum_size = Vector2(240, 280)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = Text.say("inventory.entry", {
		"name": item.get("name", item_id), "count": GameState.item_count(item_id)})
	button.pressed.connect(show_item.bind(item_id))
	return button


func _label(text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(760, 0)
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label
