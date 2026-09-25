class_name ShopItemsDriver
extends Node
## Walks the SH13-19 Supplies purchases with real clicks (CLAUDE.md M5,
## 2026-09-25): each one takes effect the moment it is bought rather than
## sitting in the inventory to be Used, and this proves that end to end —
## the actual Buy button, the actual report line, and the actual downstream
## screens (Staff, Levels) that are supposed to notice the change — the way
## the GUT unit tests (tests/test_inventory.gd) do not, since those call
## GameState.buy_*() directly and never touch a button or a label.
##
## Lives outside the current scene, the same reason inventory_driver.gd
## does, though nothing here changes scenes.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"
const SCREENSHOT_PATH := "user://shots/shop_items_supplies.png"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.xp = 100000
	GameState.meta["Funds"] = 99999999
	GameState.owned_cards = []
	GameState.levels_unlocked = []
	GameState.staff_recruitment_tier = 0
	GameState.funds_cap_bonus = 0
	GameState.shop_bought_this_level = {}
	GameState.inventory = {}

	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await _wait(0.6)

	await _walk()

	print("")
	if _failures.is_empty():
		print("SHOP ITEMS TEST: PASS")
		get_tree().quit(0)
	else:
		print("SHOP ITEMS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene

	# --- Before any SH18 purchase: a Tier 1+ candidate cannot be hired -------
	if not await _check_staff_gate(office, false):
		return

	# --- Open Supplies --------------------------------------------------------
	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	var supplies_door := _button_with_text(management, Text.say("shop.supplies"))
	if supplies_door == null:
		_failures.append("Office Management has no Supplies button")
		return
	await _click(supplies_door)
	var supplies := office.get_node("SuppliesPanel") as Overlay
	if not supplies.visible:
		_failures.append("the Supplies button did not open the Supplies shop")
		return

	# --- SH13/14: Unlock Tier 1/2 Level ---------------------------------------
	if not await _buy(supplies, "SH13"):
		return
	if GameState.levels_unlocked.size() != 1:
		_failures.append("SH13: expected 1 unlocked level, got %d" % GameState.levels_unlocked.size())
		return
	if not await _buy(supplies, "SH14"):
		return
	if GameState.levels_unlocked.size() != 2:
		_failures.append("SH14: expected 2 unlocked levels, got %d" % GameState.levels_unlocked.size())
		return

	# --- SH15/16/17: Unlock Random Tier N Card --------------------------------
	# Each one now pops a reveal of the actual card on top of Supplies
	# (Cameron, 2026-09-25) — dismissed here the way a player would tap
	# past it, or every later click in this walk would land on the reveal
	# instead of whatever it is meant to hit.
	if not await _buy(supplies, "SH15"):
		return
	if not await _check_and_dismiss_card_reveal(office):
		return
	if GameState.owned_cards.size() != 1:
		_failures.append("SH15: expected 1 owned card, got %d" % GameState.owned_cards.size())
		return
	if not await _buy(supplies, "SH16"):
		return
	if not await _check_and_dismiss_card_reveal(office):
		return
	if GameState.owned_cards.size() != 2:
		_failures.append("SH16: expected 2 owned cards, got %d" % GameState.owned_cards.size())
		return
	if not await _buy(supplies, "SH17"):
		return
	if not await _check_and_dismiss_card_reveal(office):
		return
	if GameState.owned_cards.size() != 3:
		_failures.append("SH17: expected 3 owned cards, got %d" % GameState.owned_cards.size())
		return

	# --- A screenshot of the Supplies list with all seven rows visible -------
	# Real bug class this catches: a row whose label overflows, a missing
	# icon that isn't the placeholder, or a Buy button that renders with no
	# real size (the same class of bug _walk_choice_picker() in
	# inventory_driver.gd found for the Player Choice picker).
	await _screenshot_supplies_rows(supplies,
		["SH13", "SH14", "SH15", "SH16", "SH17", "SH18", "SH19"])

	# --- SH18: Unlock New Staff Recruitment Tier ------------------------------
	if not await _buy(supplies, "SH18"):
		return
	if GameState.staff_recruitment_tier != 1:
		_failures.append("SH18: expected recruitment tier 1, got %d" % GameState.staff_recruitment_tier)
		return

	# --- SH19: Increase Office Funds Cap --------------------------------------
	if not await _buy(supplies, "SH19"):
		return
	if GameState.funds_cap_bonus != 100000:
		_failures.append("SH19: expected funds_cap_bonus 100000, got %d" % GameState.funds_cap_bonus)
		return

	print("  bought one of each SH13-19; each took effect on the spot")
	supplies.close()
	await _wait(0.2)

	# --- After the SH18 purchase: the same candidate is now hireable ----------
	if not await _check_staff_gate(office, true):
		return

	# --- The Levels panel already shows one of the SH13-bought levels as
	#     playable, not asking to be unlocked again -----------------------------
	if not await _check_levels_panel_reflects_unlock(office):
		return

	# --- Save/load: the four new fields survive a real round trip through
	#     the save file, not just an in-memory GameState.gd field -------------
	_check_save_round_trip()


## SH18's whole point, seen from the Staff screen rather than GameState:
## before any purchase, a Tier 1+ candidate's Hire button is disabled with
## the "not open yet" refusal AS its own button text (UiKit.action_button);
## after one purchase, the same candidate's button is enabled and reads
## "Hire".
func _check_staff_gate(office: Node, expect_open: bool) -> bool:
	var tier_1_candidate: Dictionary = {}
	for candidate: Dictionary in DataDB.staff:
		if int(candidate.get("highest_tier", 0)) == 1:
			tier_1_candidate = candidate
			break
	if tier_1_candidate.is_empty():
		_failures.append("the fixture needs a real Tier 1 staff candidate")
		return false

	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	var staff_door := _button_with_text(management, Text.say("office.staff"))
	if staff_door == null:
		_failures.append("Office Management has no Staff button")
		return false
	await _click(staff_door)
	var staff := office.get_node("%StaffPanel") as Overlay
	if not staff.visible:
		_failures.append("the Staff button did not open the Staff screen")
		return false

	var staff_id := str(tier_1_candidate.get("staff_id", ""))
	var hire_button := _button_containing(staff, staff_id, tier_1_candidate)
	if hire_button == null:
		_failures.append("the Staff screen has no button near %s" % staff_id)
		return false

	if expect_open:
		if hire_button.disabled:
			_failures.append(
				"%s's Hire button is still disabled ('%s') after unlocking its recruitment tier"
				% [staff_id, hire_button.text])
			return false
		print("  after SH18, a Tier 1 candidate's Hire button is enabled")
	else:
		if not hire_button.disabled:
			_failures.append(
				"%s's Hire button is enabled before any recruitment tier was ever unlocked" % staff_id)
			return false
		if hire_button.text != Text.say("office.recruitment_tier_locked"):
			_failures.append(
				"%s's disabled button says '%s', not the recruitment-tier refusal"
				% [staff_id, hire_button.text])
			return false
		print("  before any SH18 purchase, a Tier 1 candidate cannot be hired")

	staff.close()
	await _wait(0.2)
	return true


## Every candidate row is its own little VBox with a name label above a
## button — found by walking up from a label containing the candidate's own
## name (StaffPanel does not tag rows with the staff_id the way Supplies
## rows are named "Supply_SHxx").
func _button_containing(root: Node, _staff_id: String, candidate: Dictionary) -> Button:
	var name_text := str(Text.say("office.staff_candidate", {
		"name": candidate.get("name", ""), "cost": int(candidate.get("hiring_cost_yen", 0))}))
	for label in root.find_children("", "Label", true, false):
		if (label as Label).text == name_text:
			var box := label.get_parent()
			for child in box.get_children():
				if child is Button:
					return child as Button
	return null


func _check_levels_panel_reflects_unlock(office: Node) -> bool:
	if GameState.levels_unlocked.is_empty():
		_failures.append("nothing was actually unlocked to check the Levels panel against")
		return false
	var level := DataDB.get_level(GameState.levels_unlocked[0])
	var description := str(level.get("description", ""))

	await _click(office.get_node("%StartButton"))
	var levels := office.get_node("%LevelsPanel") as Overlay
	if not levels.visible:
		_failures.append("the Start button did not open the Levels panel")
		return false

	for label in levels.find_children("", "Label", true, false):
		if (label as Label).text == description:
			var box := label.get_parent()
			for child in box.get_children():
				if child is Button:
					var button := child as Button
					if button.disabled or button.text != Text.say("office.look_it_over"):
						_failures.append(
							"the level SH13/14 unlocked ('%s') still shows '%s' in the Levels panel, not Look It Over"
							% [description, button.text])
						return false
					print("  the Levels panel already treats the SH13-unlocked level as playable")
					levels.close()
					await _wait(0.2)
					return true

	_failures.append("the Levels panel does not list the level SH13/14 unlocked ('%s')" % description)
	return false


## The four new GameState fields (staff_recruitment_tier, funds_cap_bonus,
## owned_cards, levels_unlocked) have to survive an actual save/load round
## trip, not just live correctly in memory for the rest of this run.
func _check_save_round_trip() -> void:
	var before := {
		"staff_recruitment_tier": GameState.staff_recruitment_tier,
		"funds_cap_bonus": GameState.funds_cap_bonus,
		"owned_cards": GameState.owned_cards.duplicate(),
		"levels_unlocked": GameState.levels_unlocked.duplicate(),
	}
	SaveManager.save_game()

	GameState.staff_recruitment_tier = 0
	GameState.funds_cap_bonus = 0
	GameState.owned_cards = []
	GameState.levels_unlocked = []

	if not SaveManager.load_game():
		_failures.append("the save just written could not be loaded back")
		return

	if GameState.staff_recruitment_tier != before["staff_recruitment_tier"]:
		_failures.append("staff_recruitment_tier did not survive save/load (%d -> %d)"
			% [before["staff_recruitment_tier"], GameState.staff_recruitment_tier])
	if GameState.funds_cap_bonus != before["funds_cap_bonus"]:
		_failures.append("funds_cap_bonus did not survive save/load (%d -> %d)"
			% [before["funds_cap_bonus"], GameState.funds_cap_bonus])
	if GameState.owned_cards != before["owned_cards"]:
		_failures.append("owned_cards did not survive save/load")
	if GameState.levels_unlocked != before["levels_unlocked"]:
		_failures.append("levels_unlocked did not survive save/load")
	if _failures.is_empty():
		print("  staff_recruitment_tier, funds_cap_bonus and the two unlock lists survive save/load")


func _screenshot_supplies_rows(supplies: Overlay, item_ids: Array) -> void:
	DirAccess.make_dir_recursive_absolute("user://shots")
	var scroll := supplies.get_node("Margin/Scroll") as ScrollContainer
	if scroll == null:
		return
	var first := supplies.find_child("Supply_" + str(item_ids[0]), true, false)
	if first == null:
		return
	scroll.ensure_control_visible(first)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("  wrote a screenshot of the Supplies list to %s" % SCREENSHOT_PATH)


## Presses an item's Buy button in an open Supplies panel, and checks the
## report line is non-empty and does not read "This can't be used here" (the
## exact regression this whole feature exists to fix — SH27-29's original
## bug report). The caller checks the resulting state itself, right after.
func _buy(supplies: Overlay, item_id: String) -> bool:
	var row := supplies.find_child("Supply_" + item_id, true, false)
	if row == null:
		_failures.append("the Supplies shop does not list %s" % item_id)
		return false
	var button := row.find_child("Buy", true, false) as Button
	if button == null:
		_failures.append("%s has no Buy button" % item_id)
		return false
	if button.disabled:
		_failures.append("%s's Buy button is disabled before it was ever bought: '%s'"
			% [item_id, button.text])
		return false

	await _click(button)

	var report := (get_tree().current_scene as Control).get_node("%Report") as Label
	var message := report.text
	if message.is_empty():
		_failures.append("%s: buying it left no report message" % item_id)
		return false
	if message.contains("can't be used here") or message.contains("cannot be used"):
		_failures.append("%s: still shows the old 'can't be used here' refusal — %s"
			% [item_id, message])
		return false

	print("  bought %s -> %s" % [item_id, message])
	return true


## Checks the card reveal popup a successful SH15/16/17 (or SH27-29) buy
## opens on top of Supplies — a real CardView is showing, with a real
## texture and the newly-owned card's own name on it — then dismisses it
## with its Confirm button, the way a player taps past a reveal.
func _check_and_dismiss_card_reveal(office: Node) -> bool:
	var panel := office.get_node_or_null("CardRevealPanel") as Overlay
	if panel == null or not panel.visible:
		_failures.append("buying a random card did not open the card reveal popup")
		return false

	var view: CardView = null
	for node in panel.find_children("*", "", true, false):
		if node is CardView:
			view = node as CardView
			break
	if view == null:
		_failures.append("the card reveal popup has no CardView in it")
		return false
	if view.card_id.is_empty():
		_failures.append("the card reveal popup's CardView was never filled in")
		return false
	if not GameState.owned_cards.has(view.card_id):
		_failures.append("the card reveal popup shows %s, which was not actually granted"
			% view.card_id)
		return false

	DirAccess.make_dir_recursive_absolute("user://shots")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/shop_items_card_reveal.png")

	var confirm := panel.find_child("Confirm", true, false) as Button
	if confirm == null or not confirm.visible:
		_failures.append("the card reveal popup has no Confirm button")
		return false
	await _click(confirm)
	if panel.visible:
		_failures.append("pressing Confirm did not close the card reveal popup")
		return false

	print("  the card reveal popup showed %s and dismissed cleanly" % view.card_id)
	return true


func _button_with_text(root: Node, text: String) -> Control:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).text == text:
			return node as Control
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var parent := control.get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).ensure_control_visible(control)
		await get_tree().process_frame
		await get_tree().process_frame

	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return
	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
	await _wait(0.1)
