class_name ShopItemsDriver
extends Node
## Walks the SH12/13 Supplies purchases and Rhetoric Training's three real
## card sessions (SH09-11, the XP route — the Yen route this used to also
## walk, SH27-29, was removed from the Shop tab 2026-10-04), with real
## clicks (CLAUDE.md M5, 2026-09-25 and 2026-09-25's
## card reveal popup): each one takes effect the moment it is bought rather
## than sitting in the inventory to be Used, and this proves that end to
## end — the actual Buy button, the actual report line, the card reveal
## popup's front and back views for the six random-card items, and the
## actual downstream screens (Staff, Levels) that are supposed to notice
## the change — the way the GUT unit tests (tests/test_inventory.gd) do
## not, since those call GameState.buy_*() directly and never touch a
## button, a label, or a popup.
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

	# --- Before any SH12 purchase: a Tier 1+ candidate cannot be hired -------
	if not await _check_staff_gate(office, false):
		return

	# --- Open the Marketplace (Supplies moved in here, 2026-09-28) -----------
	await _click(office.find_child("InventoryButton", true, false) as Control)
	var supplies := office.get_node("InventoryPanel") as Overlay
	if not supplies.visible:
		_failures.append("the Marketplace button did not open")
		return

	# --- SH09-11 (the random-card sessions) are not in Supplies any more ----
	# They moved to Rhetoric Training (Cameron, 2026-09-27) — walked below.
	for item_id: String in ["SH09", "SH10", "SH11"]:
		if supplies.find_child("Supply_" + item_id, true, false) != null:
			_failures.append("Supplies still lists %s, which belongs in Rhetoric Training" % item_id)
			return

	# --- A screenshot of the Supplies list with both rows visible ------------
	# Real bug class this catches: a row whose label overflows, a missing
	# icon that isn't the placeholder, or a Buy button that renders with no
	# real size (the same class of bug _walk_choice_picker() in
	# inventory_driver.gd found for the Player Choice picker).
	await _screenshot_supplies_rows(supplies, ["SH12", "SH13"])

	# --- SH12: Unlock New Staff Recruitment Tier ------------------------------
	if not await _buy(supplies, "SH12"):
		return
	if GameState.staff_recruitment_tier != 1:
		_failures.append("SH12: expected recruitment tier 1, got %d" % GameState.staff_recruitment_tier)
		return

	# --- SH13: Increase Office Funds Cap --------------------------------------
	if not await _buy(supplies, "SH13"):
		return
	if GameState.funds_cap_bonus != 100000:
		_failures.append("SH13: expected funds_cap_bonus 100000, got %d" % GameState.funds_cap_bonus)
		return

	print("  bought SH12 and SH13; each took effect on the spot")
	supplies.close()
	await _wait(0.2)

	# --- Rhetoric Training: see the card, then Pass or Learn it --------------
	if not await _walk_rhetoric_training(office):
		return

	# --- After the SH12 purchase: the same candidate is now hireable ----------
	if not await _check_staff_gate(office, true):
		return

	# --- The Levels panel already shows a seeded unlocked level as
	#     playable, not asking to be unlocked again -----------------------------
	if not await _check_levels_panel_reflects_unlock(office):
		return

	# --- Save/load: the four new fields survive a real round trip through
	#     the save file, not just an in-memory GameState.gd field -------------
	_check_save_round_trip()


## SH12's whole point, seen from the Staff screen rather than GameState:
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
	# Hiring lives on the candidate's profile now: open it from the list.
	var open_profile := staff.find_child("Profile_" + staff_id, true, false) as Button
	if open_profile == null:
		_failures.append("the Staff screen has no profile button for %s" % staff_id)
		return false
	await _click(open_profile)
	var profile := office.get_node("StaffProfilePanel") as Overlay
	var hire_button := profile.find_child("ProfileHireButton", true, false) as Button
	if hire_button == null:
		_failures.append("%s's profile has no Hire button" % staff_id)
		return false

	if expect_open:
		if hire_button.disabled:
			_failures.append(
				"%s's Hire button is still disabled ('%s') after unlocking its recruitment tier"
				% [staff_id, hire_button.text])
			return false
		print("  after SH12, a Tier 1 candidate's Hire button is enabled")
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
		print("  before any SH12 purchase, a Tier 1 candidate cannot be hired")

	profile.close()
	staff.close()
	await _wait(0.2)
	return true


## Every candidate row is its own little VBox with a name label above a
## button — found by walking up from a label containing the candidate's own
## name (StaffPanel does not tag rows with the staff_id the way Supplies
## rows are named "Supply_SHxx").
## No Supplies purchase unlocks a level any more ("Unlock Tier N Level" removed from the
## Shop tab, 2026-09-30 — level_gating_enabled's own unlock_cost_xp is 0 on
## every real level today anyway, so nothing was actually gated). This
## seeds levels_unlocked directly, the same value a purchase used to leave
## behind, to keep proving the Levels panel itself reflects it correctly.
func _check_levels_panel_reflects_unlock(office: Node) -> bool:
	if GameState.levels_unlocked.is_empty():
		for level: Dictionary in DataDB.levels:
			var level_id := str(level.get("level_id", ""))
			if not GameState.levels_unlocked.has(level_id):
				GameState.levels_unlocked.append(level_id)
				break
	if GameState.levels_unlocked.is_empty():
		_failures.append("the fixture needs at least one real level to seed levels_unlocked with")
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
							"the seeded unlocked level ('%s') still shows '%s' in the Levels panel, not Look It Over"
							% [description, button.text])
						return false
					print("  the Levels panel already treats the seeded unlocked level as playable")
					levels.close()
					await _wait(0.2)
					return true

	_failures.append("the Levels panel does not list the seeded unlocked level ('%s')" % description)
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


## Rhetoric Training end to end, with real clicks (Cameron, 2026-09-27):
## Office Management -> Rhetoric Training -> "See a card" opens the offer
## with the card's front and back BEFORE anything is paid. One draw is
## passed twice and its third card learned; then each other session is
## seen and learned, each adding exactly the card shown.
func _walk_rhetoric_training(office: Node) -> bool:
	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	await _click(_button_with_text(management, Text.say("office.rhetoric_training")))
	var training := office.get_node("%CardsPanel") as Overlay
	if not training.visible:
		_failures.append("the Rhetoric Training button did not open Rhetoric Training")
		return false

	# One full draw: 1/3, Pass, 2/3, Pass, 3/3 — no Pass and no way out on
	# the last look — then Learn it (Cameron, 2026-09-27).
	var xp_before := GameState.xp
	var owned_at_start := GameState.owned_cards.size()
	if not await _see_card(office, training, "SH09"):
		return false
	var offer := office.get_node("CardRevealPanel") as Overlay
	for look in [1, 2, 3]:
		var counter := offer.find_child("LookCounter", true, false) as Label
		if counter == null or counter.text != "%d/3" % look:
			_failures.append("look %d: the counter reads '%s', not '%d/3'"
				% [look, counter.text if counter else "(missing)", look])
			return false
		var pass_button := offer.find_child("Pass", true, false) as Button
		var back := offer.find_child("Back", true, false) as Button
		if back != null and back.visible:
			_failures.append("look %d: the card offer can be backed out of" % look)
			return false
		if look < 3:
			if pass_button == null:
				_failures.append("look %d: there is no Pass button" % look)
				return false
			var before := _offered_card(office)
			await _click(pass_button)
			if not offer.visible or _offered_card(office) == before:
				_failures.append("look %d: Pass did not show a different card" % look)
				return false
		elif pass_button != null:
			_failures.append("3/3 still has a Pass button — the last look must be learned")
			return false
	if GameState.xp != xp_before or GameState.owned_cards.size() != owned_at_start:
		_failures.append("passing twice spent XP or granted a card")
		return false
	var third := _offered_card(office)
	await _click(offer.find_child("Confirm", true, false) as Button)
	if not GameState.owned_cards.has(third) or GameState.xp >= xp_before:
		_failures.append("learning the 3/3 card (%s) did not pay for it and add it" % third)
		return false
	print("  SH09: 1/3 -> Pass -> 2/3 -> Pass -> 3/3 (no Pass, no Back) -> learned %s" % third)

	# Learn one of each session.
	for item_id: String in ["SH10", "SH11"]:
		var owned_before := GameState.owned_cards.size()
		var funds_before := int(GameState.meta.get("Funds", 0))
		var xp_start := GameState.xp
		if not await _see_card(office, training, item_id):
			return false
		var shown := _offered_card(office)
		if GameState.owned_cards.has(shown):
			_failures.append("%s offered %s, which is already owned" % [item_id, shown])
			return false
		await _click(offer.find_child("Confirm", true, false) as Button)
		if GameState.owned_cards.size() != owned_before + 1 or not GameState.owned_cards.has(shown):
			_failures.append("%s: learning did not add exactly the card shown (%s)" % [item_id, shown])
			return false
		if GameState.xp >= xp_start and int(GameState.meta.get("Funds", 0)) >= funds_before:
			_failures.append("%s: learned %s but nothing was paid" % [item_id, shown])
			return false
		print("  %s: saw %s, learned it, paid for it" % [item_id, shown])
	training.close()
	await _wait(0.2)
	return true


## Presses a session's "See a card" and checks the offer pop-up shows a real
## front (CardView) and back (CardBackView) — the back with a real width
## (the bug class CLAUDE.md notes for BattleScreen's zoom) — and a Learn
## button.
func _see_card(office: Node, training: Overlay, item_id: String) -> bool:
	var row := training.find_child("Training_" + item_id, true, false)
	if row == null:
		_failures.append("Rhetoric Training does not list %s" % item_id)
		return false
	var button := row.find_child("SeeCard", true, false) as Button
	if button == null or button.disabled:
		_failures.append("%s's See a card button is missing or disabled" % item_id)
		return false
	await _click(button)
	var offer := office.get_node_or_null("CardRevealPanel") as Overlay
	if offer == null or not offer.visible:
		_failures.append("%s: See a card did not open the card offer" % item_id)
		return false
	var back: CardBackView = null
	for node in offer.find_children("*", "", true, false):
		if node is CardBackView:
			back = node as CardBackView
	if _offered_card(office).is_empty() or back == null or back.size.x <= 0.0:
		_failures.append("%s: the card offer is missing its front or back view" % item_id)
		return false
	var confirm := offer.find_child("Confirm", true, false) as Button
	if confirm == null or not confirm.visible:
		_failures.append("%s: the card offer has no Learn button" % item_id)
		return false
	DirAccess.make_dir_recursive_absolute("user://shots")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/shop_items_card_offer.png")
	return true


func _offered_card(office: Node) -> String:
	for node in (office.get_node("CardRevealPanel") as Overlay).find_children("*", "", true, false):
		if node is CardView:
			return (node as CardView).card_id
	return ""


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
