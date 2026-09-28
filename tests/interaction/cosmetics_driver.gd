class_name CosmeticsDriver
extends Node
## Walks the Cosmetics page with real clicks (§8, 2026-09-28): buying a
## package, then equipping and un-equipping it per slot, against the real
## seed packages (CP01 "Neon Ambition" — outfit + background + music; CP02
## "Quiet Chamber" — music only).
##
## Proves what the GUT tests (tests/test_cosmetic_pieces.gd,
## tests/test_cosmetics_game_state.gd) call GameState.buy_cosmetic_package()/
## equip_cosmetic() directly and never see: the actual Cosmetics button, the
## actual Buy button and its price/refusal text, and that the panel
## genuinely re-lists the package under "Equip" (not "for sale") the moment
## it's bought.
##
## Lives outside the current scene, the same reason inventory_driver.gd does,
## though nothing here changes scenes either.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.xp = 0
	GameState.meta["Funds"] = 100000
	GameState.owned_cosmetic_packages = []
	GameState.active_cosmetics = {}

	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await _wait(0.6)

	await _walk()

	print("")
	if _failures.is_empty():
		print("COSMETICS TEST: PASS")
		get_tree().quit(0)
	else:
		print("COSMETICS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene

	# --- Open the Cosmetics page ---------------------------------------------
	var cosmetics_button := office.find_child("CosmeticsButton", true, false) as Control
	await _click(cosmetics_button)
	var panel := office.get_node("CosmeticsPanel") as Overlay
	if not panel.visible:
		_failures.append("the Cosmetics button did not open the Cosmetics page")
		return

	# --- CP01 is offered for sale, not yet in the Equip section -------------
	var cp01_row := panel.find_child("Cosmetic_CP01", true, false)
	if cp01_row == null:
		_failures.append("CP01 is not listed for sale before it's owned")
		return
	if panel.find_child("CosmeticSlot_outfit", true, false) != null:
		_failures.append("an Equip section shows before anything is owned")
		return
	print("  CP01 listed for sale; no Equip section until something is owned")

	# --- Buy CP01 with a real click on its own Buy button --------------------
	var buy := _button_with_text(cp01_row, Text.say("shop.buy"))
	if buy == null:
		_failures.append("CP01's row has no Buy button")
		return
	var funds_before := int(GameState.meta.get("Funds", 0))
	await _click(buy)
	if not GameState.owned_cosmetic_packages.has("CP01"):
		_failures.append("pressing Buy did not add CP01 to owned_cosmetic_packages")
		return
	if int(GameState.meta.get("Funds", 0)) >= funds_before:
		_failures.append("pressing Buy did not deduct Funds")
		return
	print("  bought CP01 with a real click on its own Buy button")

	# --- The panel now shows Equip, CP01 no longer for sale -------------------
	panel = office.get_node("CosmeticsPanel") as Overlay
	if panel.find_child("Cosmetic_CP01", true, false) != null:
		_failures.append("CP01 is still listed for sale after being bought")
		return
	var outfit_row := panel.find_child("CosmeticSlot_outfit", true, false)
	if outfit_row == null:
		_failures.append("no Outfit equip row appeared once CP01 (which has an outfit piece) is owned")
		return
	print("  CP01 dropped off the shop list and the Equip section appeared")

	# --- Equip CP01's outfit with a real click on its own name ---------------
	var outfit_choice := _button_with_text(outfit_row, "Neon Ambition")
	if outfit_choice == null:
		_failures.append("the Outfit row has no button for CP01 (Neon Ambition)")
		return
	await _click(outfit_choice)
	if str(GameState.active_cosmetics.get(CosmeticPieces.OUTFIT, "")) != "CP01":
		_failures.append("clicking CP01's own name in the Outfit row did not equip it")
		return
	print("  equipped CP01's outfit with a real click")

	# --- Equipping the Background piece updates the LIVE Office picture ------
	# right away, with no scene reload needed (2026-09-28: PlaceholderArt only
	# refreshes on its own property setters, so a naive equip that only
	# touched GameState left the old OFFICE.png showing behind this very
	# panel until the player left and came back — caught by a throwaway
	# driver, fixed in _on_equip_cosmetic()).
	panel = office.get_node("CosmeticsPanel") as Overlay
	var background_row := panel.find_child("CosmeticSlot_background", true, false)
	if background_row == null:
		_failures.append("no Background equip row appeared for CP01")
		return
	var background_choice := _button_with_text(background_row, "Neon Ambition")
	if background_choice == null:
		_failures.append("the Background row has no button for CP01")
		return
	var background_art := office.find_child("Background", true, false) as PlaceholderArt
	if background_art == null:
		_failures.append("could not find the Office's own Background node")
		return
	await _click(background_choice)
	var background_texture: Texture2D = background_art._texture_rect.texture
	if background_texture == null or not background_texture.resource_path.ends_with("OFFICE_UPGRADED.png"):
		_failures.append("equipping CP01's Background did not update the live Office picture (got %s)"
			% [background_texture.resource_path if background_texture else "null"])
		return
	print("  equipped CP01's background and the live Office picture updated at once")

	# --- Un-equip it: Default, clicked for real -------------------------------
	panel = office.get_node("CosmeticsPanel") as Overlay
	outfit_row = panel.find_child("CosmeticSlot_outfit", true, false)
	var default_choice := _button_with_text(outfit_row, Text.say("office.cosmetics_default"))
	if default_choice == null:
		_failures.append("the Outfit row has no Default button")
		return
	await _click(default_choice)
	if GameState.active_cosmetics.has(CosmeticPieces.OUTFIT):
		_failures.append("clicking Default did not clear the equipped outfit")
		return
	print("  clicking Default un-equips the outfit again")

	# --- The Music slot offers CP01 too (it has a music piece as well) -------
	panel = office.get_node("CosmeticsPanel") as Overlay
	var music_row := panel.find_child("CosmeticSlot_music", true, false)
	if music_row == null:
		_failures.append("no Music equip row appeared for CP01")
		return
	var music_choice := _button_with_text(music_row, "Neon Ambition")
	if music_choice == null:
		_failures.append("the Music row has no button for CP01")
		return
	await _click(music_choice)
	if str(GameState.active_cosmetics.get(CosmeticPieces.MUSIC, "")) != "CP01":
		_failures.append("clicking CP01's own name in the Music row did not equip it")
		return
	print("  equipped CP01's music independently of the outfit slot (already un-equipped)")

	panel.close()
	await _wait(0.2)


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
	# Overlay content scrolls; bring the target into view the way a player
	# would by scrolling, or a click aimed at it lands somewhere else.
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
