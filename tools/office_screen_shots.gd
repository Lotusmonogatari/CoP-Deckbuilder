extends Node
## Screenshots of the Office screens on the shared frame (P13, 2026-11-20), for the review folder
## design/review/p13_office_screens_<date>/. Run under a real display:
##
##   xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 \
##       res://tools/office_screen_shots.tscn -- <screen> <style> <out.png> [text_size] [pressure] [bottom]
##
## screen: administration | events[:here|coming][:funds] | management[:staff|deck|rhetoric][:hire] | marketplace[:personal|office|styles] | reputation[:overview|stakeholders|backers|parties|election|laws][:resign][:factors] ·
## style: woodblock | living_office | broadcast · text_size: small | normal | large ·
## pressure: standard | harder (Political Pressure in force) · bottom: scroll the screen to its foot.
## Events are drawn at the Capitol; ":funds" empties Funds so priced events show their reason and a greyed button.
## Office Management is drawn with two places per role and a few people hired; ":hire" opens an open place's candidates.
## The Marketplace is drawn with some items held, one at its carrying limit and one sold out for the level.
## Reputation is drawn with demo changes and one law so the Overview has something to show; ":resign" lowers the three
## standings so the Resign box is available; ":factors" opens the reasons pop-up of the biggest move. Draws the real screen from a fresh run; changes no saved game.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := args[0] if args.size() > 0 else "administration"
	var style := args[1] if args.size() > 1 else UiStyles.LIVING_OFFICE
	var out := args[2] if args.size() > 2 else "/tmp/office_screen.png"
	var size_setting := args[3] if args.size() > 3 else ""
	var pressure := args[4] if args.size() > 4 else ""
	var bottom := args.size() > 5 and args[5] == "bottom"
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = style
	UiStyle.sync()
	if not size_setting.is_empty():
		Layout.text_size_setting = size_setting
	if pressure == "harder":
		GameState.difficulty = Difficulty.HARDER
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child(office)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	var menu: Overlay = null
	var parts := screen.split(":")
	match parts[0]:
		"administration":
			office._show_administration_menu()
			menu = office.get_node("AdministrationMenuPanel")
		"events":
			if "funds" in parts:
				GameState.meta["Funds"] = 0
			office._show_events(parts[1] if parts.size() > 1 and parts[1] != "funds" else "here")
			menu = office.get_node("EventsPanel")
		"management":
			_seed_staff()
			var tab := parts[1] if parts.size() > 1 and parts[1] != "hire" else "staff"
			office._show_management_tab(tab)
			menu = office.get_node("ManagementPanel")
			if "hire" in parts:
				office._show_staff_candidates(Ledger.staff_roles(DataDB.staff)[0])
				menu = office.get_node("StaffPanel")
		"marketplace":
			GameState.add_item("SH15", 3)
			GameState.add_item("SH16", 2)
			GameState.shop_bought_this_level["SH14"] = 2
			var tabs := {"personal": Items.PERSONAL, "office": Items.OFFICE_INVENTORY, "styles": "Styles"}
			office._market_tab = tabs.get(parts[1] if parts.size() > 1 else "personal", Items.PERSONAL)
			office._show_marketplace()
			menu = office.get_node("InventoryPanel")
		"reputation":
			_seed_demo("resign" in parts)
			office._show_reputation(parts[1] if parts.size() > 1 and parts[1] != "resign" else "overview")
			menu = office.get_node("ReputationMenuPanel")
			if "factors" in parts:
				var first: Dictionary = ReputationModel.moves()[0]
				office._show_standing_factors(first["booster"])
				menu = office.get_node("StandingFactorsPanel")
		_:
			push_error("unknown screen '%s'" % screen)
			get_tree().quit(1)
			return
	await get_tree().create_timer(0.5).timeout
	if bottom:
		var scroll := menu.find_child("FrameScroll", true, false) as ScrollContainer
		scroll.scroll_vertical = 100000
		await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


## Demo numbers for the Reputation screens: three organizations that moved, the four meta changes, one law and a
## level cleared. With `resign` the three standings are lowered so the Resign box is available.
func _seed_demo(resign: bool) -> void:
	var ids: Array = []
	for booster: Dictionary in DataDB.boosters:
		ids.append(str(booster.get("booster_id", "")))
	var changes := [6, -3, 2]
	var standings := [58, 44, 51]
	for i in 3:
		GameState.booster_standing[ids[i]] = standings[i]
		GameState.last_booster_change[ids[i]] = changes[i]
		GameState.last_booster_cause[ids[i]] = [{"cause": "Won a debate", "amount": changes[i]}]
	GameState.last_meta_change = {"Constituency support": 4, "Reputation": -1, "Funds": 35000}
	GameState.last_meta_cause = {"Funds": [{"cause": "Stage pay", "amount": 35000}]}
	GameState.statute_book = [{"bill_id": "BI01", "passed": true, "yes": 58, "no": 40, "abstain": 3, "player_vote": "Yes",
		"requirement": "Majority", "yes_needed": 51}]
	GameState.levels_cleared = {"LV01": 2}
	if resign:
		GameState.meta["Reputation"] = 0
		GameState.meta["Party support"] = 0
		GameState.meta["Constituency support"] = 0


## Demo staff for Office Management: a second place in every role, two people in the first role and one in the next two.
func _seed_staff() -> void:
	GameState.meta["Funds"] = 1000000
	GameState.staff_recruitment_tier = 2
	GameState.staff_slot_buys = 1
	var roles := Ledger.staff_roles(DataDB.staff)
	for i in roles.size():
		var candidates := DataDB.get_staff_by_role(str(roles[i]))
		if i < 3 and candidates.size() > 0:
			GameState.hire_staff(str(candidates[0].get("staff_id", "")))
		if i == 0 and candidates.size() > 1:
			GameState.hire_staff(str(candidates[1].get("staff_id", "")))
