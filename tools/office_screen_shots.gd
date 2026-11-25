extends Node
## Screenshots of the Office screens on the shared frame (P13, 2026-11-20), for the review folder
## design/review/p13_office_screens_<date>/. Run under a real display:
##
##   xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 \
##       res://tools/office_screen_shots.tscn -- <screen> <style> <out.png> [text_size] [pressure] [bottom]
##
## screen: office (the Office with a paid ticket held, so the travel-mode row shows) | administration | events[:here|coming][:funds] | management[:staff|deck|rhetoric][:hire] | marketplace[:personal|office|styles] | reputation[:overview|stakeholders|backers|parties|election|laws][:resign][:factors] ·
## style: woodblock | living_office | broadcast · text_size: small | normal | large ·
## pressure: standard | harder (Political Pressure in force) · bottom: scroll the screen to its foot.
## Events are drawn at the Capitol; ":funds" empties Funds so priced events show their reason and a greyed button.
## Office Management is drawn with two places per role and a few people hired; ":hire" opens an open place's candidates.
## The Marketplace is drawn with some items held, one at its carrying limit and one sold out for the level.
## Reputation is drawn with demo changes and one law so the Overview has something to show; ":resign" lowers the three
## standings so the Resign box is available; ":factors" opens the reasons pop-up of the biggest move. Draws the real screen from a fresh run; changes no saved game.

func _ready() -> void:
	_run.call_deferred()


## The Capitol venues screens (P16): each is drawn from a state set up here, with the day's set arranged to match the mockups.
func _venue(office: Node, which: String) -> Overlay:
	var today := GameState.venue_today()
	var stage_tip := {"kind": "stage_suit", "target": "ST16", "suit": "Data Driven", "where": "cafeteria", "day": today - 1}
	var tips := [stage_tip, {"kind": "opponent_suit", "target": "OP29", "suit": "Emotional", "where": "gardens", "day": today - 5},
		{"kind": "stage_suit", "target": "ST08", "suit": "Divisive", "where": "cafeteria", "day": today - 10},
		{"kind": "stage_suit", "target": "ST28", "suit": "Data Driven", "where": "gardens", "day": today - 13}]
	match which:
		"map":
			office._venues.show_map()
			return office.get_node("VenueMapPanel")
		"cafeteria":
			office._venues.show_venue("VN01")
			return office.get_node("VenuePanel")
		"gardens":
			office._venues.show_venue("VN03")
			return office.get_node("VenuePanel")
		"desk", "codex", "scroll":
			# The Library's reference desk reading, the Codex list and an unrolled document (P18, 2026-11-24). The shipped Library
			# Documents rows are hidden placeholders, so the tool draws these three from fixture documents it makes up here
			# (never saved, never in the data).
			GameState.office_location = Offices.CAPITOL
			office._apply_office_look()
			GameState.meta["Funds"] = 50000
			DataDB.library_documents = _fixture_documents()
			GameState.codex_found = {"LD01": {"day": today, "read": false}}
			GameState.codex_find("LD01")
			if which == "desk" or which == "scroll":
				var rooms := GameState.desk_rooms()
				var done := GameState.do_research(str(rooms[0]["stage_id"]), str(rooms[0]["level_id"]))
				office._venues.show_venue("VN02")
				if which == "desk":
					var library: Node = office._venues._library
					library._result = done
					library._mode = "result"
					library._draw()
					return office.get_node("VenuePanel")
				office._venues._library._tab = "codex"
				office._venues._library._on_open_room_file(str(rooms[0]["stage_id"]))
				return office.get_node("CodexReaderPanel")
			GameState.codex_found["LD01"] = {"day": today, "read": true}
			office._venues.show_venue("VN02")
			office._venues._library._on_tab("codex")
			return office.get_node("VenuePanel")
		"shrine", "shotengai", "library", "shrinedone", "coachvenue":
			# Costed activities (2026-11-24): the shrine's, the shotengai's and the Library's screens, and a result card.
			GameState.office_location = Offices.CAPITOL if which in ["library", "coachvenue"] else Offices.DISTRICT
			office._apply_office_look()
			GameState.meta["Funds"] = 50000
			if which == "shrinedone":
				GameState.venue_activity_totals["VA11"] = 4
				office._venues.show_venue("VN08")
				office._venues._on_do_activity("VA11")
				return office.get_node("VenueResultPanel")
			office._venues.show_venue({"shrine": "VN08", "shotengai": "VN09", "library": "VN02", "coachvenue": "VN04"}[which])
			return office.get_node("VenuePanel")
		"station", "tracks", "districtmap", "districtstation":
			# Travel at the stations (2026-11-24): the Capitol's concourse and tracks, the District office's map and station.
			GameState.add_item("SH42", 2)
			GameState.add_item("SH44", 2)
			if which.begins_with("district"):
				GameState.office_location = Offices.DISTRICT
				office._apply_office_look()
			if which == "districtmap":
				office._venues.show_map()
				return office.get_node("VenueMapPanel")
			if which == "tracks":
				office._venues.show_venue("VN06")
				office._venues._show_tracks("VN06")
				return office.get_node("StationTracksPanel")
			office._venues.show_venue("VN07" if which == "districtstation" else "VN06")
			return office.get_node("VenuePanel")
		"scene_cb", "scene_ca", "scene_di", "scene_coach", "scene_opponent":
			# An overheard line spoken by an area person stands over the venue's background (2026-11-25). The sample people and lines are the
			# fixtures from Cameron's test list; none is in the data. scene_opponent is the plain card (an opponent speaks).
			DataDB.area_characters = [
				{"character_id": "CB01", "name": "Passerby", "name_jp": null, "title": "Capitol staff", "site": null},
				{"character_id": "CA01", "name": "Passerby", "name_jp": null, "title": "Capital Area resident", "site": null},
				{"character_id": "DI01", "name": "Passerby", "name_jp": null, "title": "District resident", "site": null},
				{"character_id": "VEN01", "name": "Masayuki Katō", "name_jp": "加藤正幸", "title": "Speech Coach", "site": "VN04"}]
			var cases := {
				"scene_cb": ["VN01", "CB01", "Too many new staff getting lost all day.", "cafeteria"],
				"scene_ca": ["VN06", "CA01", "Heading to the office again only to join remote calls.", ""],
				"scene_di": ["VN09", "DI01", "The wind is nice today.", ""],
				"scene_coach": ["VN04", "VEN01", "Breathe from the belly, not the throat.", ""],
				"scene_opponent": ["VN01", "OP47", "Budget tables are like choreography.", "cafeteria"]}
			var case: Array = cases[which]
			GameState.office_location = Offices.DISTRICT if case[0] == "VN09" else Offices.CAPITOL
			office._apply_office_look()
			office._venues._show_heard(case[0], {"ok": true, "number": 1, "limit": 8, "kind": "gossip", "speaker": case[1], "text": case[2],
				"hint": {}, "unlocked": "", "last": false, "where": case[3]})
			return office.get_node("VenueLinePanel")
		"stage", "listen", "perform":
			# The Sapporo Stage (2026-11-25): its screen on a Wednesday in October (VEN04 about), a Sit and Listen result and a Watch the Performance result.
			GameState.office_location = Offices.CAPITOL
			office._apply_office_look()
			_wednesday_in_october()
			office._venues.show_venue("VN05")
			if which == "listen":
				office._venues._on_do_activity("VA05")
				return office.get_node("VenueLinePanel")
			if which == "perform":
				office._venues._on_do_activity("VA20")
				return office.get_node("VenueLinePanel")
			return office.get_node("VenuePanel")
		"seats", "meals", "lunch", "paperwork":
			# The Cafeteria's seat and meal screens, the lunch result card and the paperwork confirm card (2026-11-25).
			GameState.office_location = Offices.CAPITOL
			office._apply_office_look()
			if which == "paperwork":
				office._venues._do_paperwork()
				return office.get_node("PaperworkPanel")
			office._venues._on_activity("VN01")
			var seat_id := str(GameState.seat_options("VN01")[0]["choice_id"])
			if which == "meals":
				office._venues._on_seat(seat_id, "VN01")
			elif which == "lunch":
				for row: Dictionary in DataDB.venue_choices:
					if str(row["name"]) == "Sito dumplings":
						row["chance"] = 1
				office._venues._on_meal("VC22", "VN01", seat_id)
				return office.get_node("VenueResultPanel")
			return office.get_node("VenuePanel")
		"scene_go":
			# Going to a place on the move that brings an overheard line: the line first (Continue, no Back), then the place.
			DataDB.area_characters = [{"character_id": "CB01", "name": "Passerby", "name_jp": null, "title": "Capitol staff", "site": null}]
			DataDB.balance["overheard_every"] = 1
			DataDB.balance["overheard_wobble"] = 0
			GameState.office_location = Offices.CAPITOL
			office._venues._go_to("VN01", "")
			return office.get_node("VenueLinePanel")
		"gossip", "tip", "dry":
			var entry := GameState.venue_day("VN01")
			var dealt: Array = entry["dealt"]
			dealt[0] = {"line_id": "VL001", "hint": {}}
			if which == "tip":
				dealt[0] = {"line_id": "VL081", "hint": {"kind": "stage_suit", "target": "ST16", "suit": "Data Driven", "text_key": "hint.stage_suit.data_driven_1"}}
			if which == "dry":
				entry["heard"] = dealt.size()
			GameState.venue_visit("VN01")
			office._venues._current_venue = "VN01"
			office._venues._hear("VN01")
			return office.get_node("VenueLinePanel")
		"overheard":
			var entry := GameState.venue_day("VN03")
			(entry["dealt"] as Array)[0] = {"line_id": "VL088", "hint": {"kind": "opponent_suit", "target": "OP29", "suit": "Emotional",
				"text_key": "hint.opponent_suit.emotional_1"}}
			GameState.venue_visit("VN03")
			office._venues._current_venue = "VN03"
			office._venues._hear("VN03")
			return office.get_node("VenueLinePanel")
		"tips":
			GameState.held_tips = tips
			office._venues.show_tips()
			return office.get_node("TipsPanel")
		"levels":
			GameState.held_tips = tips
			office._show_levels()
			return office.get_node("LevelsPanel")
		"briefing":
			GameState.held_tips = tips
			for level: Dictionary in DataDB.levels:
				if str(level.get("description", "")) == "Backing the Local Artisans":
					office._on_level_chosen(level)
			await get_tree().create_timer(0.6).timeout
			for scroller in office.get_node("BriefingPanel").find_children("*", "ScrollContainer", true, false):
				(scroller as ScrollContainer).scroll_vertical = 100000
			return office.get_node("BriefingPanel")
		"coach":
			office._show_speech_coach_page()
			return office.get_node("ManagementPanel")
	return null


## Made-up Library Documents rows for the P18 screenshots: one found and read, one sealed in each of two other categories.
func _fixture_documents() -> Array:
	var base := {"title_jp": "", "party": null, "unlock_value": null, "note": null, "order": 1}
	var docs: Array = []
	for row: Dictionary in [
		{"doc_id": "LD01", "category": "party_platform", "title": "Frontier Party", "kicker": "PARTY PLATFORM", "unlock": "start", "hint": ""},
		{"doc_id": "LD02", "category": "party_platform", "title": "Heritage Party", "kicker": "PARTY PLATFORM", "unlock": "line", "hint": "Five more parties"},
		{"doc_id": "LD03", "category": "ne3", "title": "ね3 (fixture)", "kicker": "ね3", "unlock": "line", "hint": "A word in the Cafeteria may lead here"},
		{"doc_id": "LD04", "category": "history", "title": "History (fixture)", "kicker": "HISTORY", "unlock": "line", "hint": "Visits around the Capital Area may lead here"}]:
		var merged := base.duplicate()
		merged.merge(row)
		merged["body"] = "A fixture paragraph for the screenshot.\n\nA second paragraph."
		docs.append(merged)
	return docs


## Moves the calendar to a Wednesday in October (VEN04 is about), for the Sapporo Stage screens.
func _wednesday_in_october() -> void:
	for week in range(0, 45):
		for day in range(0, 7):
			GameState.calendar = {"week": week, "phase": "work", "hours": day * 8}
			if GameState.weekday_today() == 3 and GameState.current_month() == 10:
				return


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
			# Both save files written (as after two saves), so the two Load rows show; removed again below.
			SaveManager.save_game()
			SaveManager.save_game(SaveManager.second_path())
			office._show_administration_menu()
			SaveManager.delete_save()
			SaveManager.delete_save(SaveManager.second_path())
			menu = office.get_node("AdministrationMenuPanel")
		"district":
			# district:PC02 — the District office's picture for that protagonist
			GameState.protagonist_id = parts[1] if parts.size() > 1 else "PC01"
			GameState.office_location = Offices.DISTRICT
			office._apply_office_look()
			menu = null
		"office":
			GameState.add_item("SH42", 2)
			menu = null
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
		"venue":
			# venue:map | cafeteria | gardens | station | tracks | districtmap | districtstation | gossip | tip | overheard | dry | tips | levels | briefing | coach (P16, 2026-11-23)
			menu = await _venue(office, parts[1] if parts.size() > 1 else "map")
		"popup":
			# The group-1 pop-ups (P14): popup:decision | scenario | moved | week | promises | broken | alert | resume | forced | hosted | result
			menu = _popup(office, parts[1] if parts.size() > 1 else "decision")
		_:
			push_error("unknown screen '%s'" % screen)
			get_tree().quit(1)
			return
	await get_tree().create_timer(0.5).timeout
	if bottom and menu != null:
		var scroll := menu.find_child("FrameScroll", true, false) as ScrollContainer
		scroll.scroll_vertical = 100000
		await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


## Opens one of the group-1 pop-up cards over the Office and returns its Overlay.
func _popup(office: Node, kind: String) -> Overlay:
	GameState.meta["Funds"] = 400000
	if kind.begins_with("event_"):
		# popup:event_EV58 (the id after the underscore): any event card
		office._present_event(kind.trim_prefix("event_"), true)
		return office.get_node("EventPanel")
	match kind:
		"lead":
			office._present_event("EV02", true)
			return office.get_node("EventPanel")
		"decision", "moved":
			var id := ""
			for event: Dictionary in DataDB.events:
				if str(event.get("trigger", "")) == "Dated" and not EventEngine.choices_for(DataDB.event_choices, str(event.get("event_id", ""))).is_empty():
					id = str(event.get("event_id", ""))
					break
			if kind == "moved":
				GameState.hire_staff(str(DataDB.staff[0].get("staff_id", "")))
				GameState.office_location = Offices.CAPITOL
				office._show_moved_card(id)
				return office._moved_panel
			office._present_event(id, false)
			return office.get_node("EventPanel")
		"scenario":
			for event: Dictionary in DataDB.events:
				if str(event.get("trigger", "")) == "Random" and not EventEngine.choices_for(DataDB.event_choices, str(event.get("event_id", ""))).is_empty():
					office._present_event(str(event.get("event_id", "")), true)
					break
			return office.get_node("EventPanel")
		"gift":
			# popup:gift: a gift handed to a staff member after Confirm (2026-11-25): the person beside the gift, the answer as narration
			var member: Dictionary = DataDB.staff[0]
			GameState.staff_hired = {str(member["role"]): {"staff_id": str(member["staff_id"]), "tier": 0}}
			GameState.staff_gift_notes = []
			GameState.staff_gift_scenes = []
			GameState._give_gift(str(member["staff_id"]), "SH04")
			office._staff_report_panel.open_card({"tag": Text.say("assign.gift_title"), "body": [StaffAssignmentsView.gift_scene(GameState.staff_gift_scenes[0])]}, "", Text.say("assign.close"))
			return office._staff_report_panel
		"assignments":
			var worker: Dictionary = DataDB.staff[0]
			GameState.staff_hired = {str(worker["role"]): {"staff_id": str(worker["staff_id"]), "tier": 0}}
			GameState.inventory["SH04"] = 1
			GameState.calendar["week"] = 9
			office._show_staff_assignments()
			return office._assignments_panel
		"week":
			GameState.calendar = {"week": 3, "phase": "work", "hours": 40}
			office._show_week_over_if_due()
			return office.get_node("WeekOverPanel")
		"promises":
			GameState.promises = [{"id": "PR1", "who": "Visitor A", "what": "", "due": GameState.time_units + 12}]
			office._show_promises()
			return office.get_node("PromisesPanel")
		"broken":
			GameState.promises_broken_unseen = [{"id": "PR1", "who": "Visitor A"}]
			office._show_broken_promises_if_any()
			return office.get_node("PromisesPanel")
		"alert":
			GameState.pending_trigger_alerts = [{"kind": "funding_freeze", "edge": "entered", "count": 2, "amount": 1000, "name": ""}]
			office._show_trigger_alerts_if_any()
			return office.get_node("TriggerAlertPanel")
		"resume":
			GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.levels[0])))
			office._show_resume_choice_if_in_level()
			return office.get_node("ResumeChoicePanel")
		"cosmetics":
			GameState.owned_cosmetic_packages.append(str(DataDB.cosmetic_packages[0].get("package_id", "")))
			office._show_cosmetics()
			return office._cosmetics_panel
		"characters":
			office._characters.open()
			return office._characters_panel
		"statistics":
			# popup:statistics: Your Statistics with a few counts, and the Export report card (2026-11-25)
			RunStats.bump(GameState.run_stats, "suits", "Earnest", 14)
			RunStats.bump(GameState.run_stats, "suits", "Appeal", 9)
			RunStats.bump(GameState.run_stats, "items", "SH20", 2)
			RunStats.bump(GameState.run_stats, "met", "OP01", 3)
			RunStats.bump(GameState.run_stats, "venues", "VN01", 5)
			RunStats.note_promise(GameState.run_stats, true)
			RunStats.note_win(GameState.run_stats, RunStats.KIND_THRESHOLD)
			RunStats.note_win(GameState.run_stats, RunStats.KIND_ZERO)
			GameState.venue_activity_totals["VA01"] = 5
			office._statistics.open()
			return office._statistics_panel
		"characterdetail":
			# popup:characterdetail: one met visitor's page (name on top, big picture, facts low; 2026-11-24)
			office._characters._show({"met": true, "id": "VI19", "name": "Dog Man", "name_jp": "犬男", "title": "Constituent",
				"party": "", "organizations": ["Party Headquarters", "Party Faction"]})
			return office._character_detail_panel
		"howto":
			HowToPlayPanel.open(office._how_to_play_panel)
			return office._how_to_play_panel
		"newgame":
			office._show_new_game(false)
			return office._new_game_panel
		"travelpage":
			GameState.add_item("SH42", 2)
			office._show_travel_page()
			return office._travel_page_panel
		"travelsheet":
			GameState.add_item("SH42", 2)
			office._show_travel_page()
			office._show_travel()
			return office._travel_panel
		"party":
			office._show_party_detail("PT03")
			return office._party_detail_panel
		"draft":
			var ids: Array = []
			for component: Dictionary in DataDB.bill_components:
				if ids.size() < 2:
					ids.append(str(component.get("component_id", "")))
			office._draft_ids = ids
			office._open_draft()
			return office._draft_panel
		"law":
			office._show_law({"bill_id": "BI01", "passed": true, "yes": 58, "no": 40, "abstain": 3, "player_vote": "Yes",
				"requirement": "Majority", "yes_needed": 51})
			return office._law_panel
		"promises2":
			GameState.promises = [{"id": "PR1", "who": "Visitor A", "what": "", "due": GameState.time_units + 6, "location": "District"},
				{"id": "PR2", "who": "Visitor B", "what": "", "due": GameState.time_units + 40}]
			office._show_promises()
			return office._promises_panel
		"offer":
			for item: Dictionary in DataDB.shop:
				if item.get("card_tier") != null:
					GameState.meta["Funds"] = 1000000
					GameState.xp = 100000
					GameState.offer_random_card(str(item.get("item_id", "")))
					break
			office._show_card_offer()
			return office._card_reveal_panel
		"hosted":
			GameState.hosted_session = {"hosted_id": str(DataDB.hosted_events[0].get("hosted_id", ""))}
			office._hosted_panel.begin()
			return office._hosted_panel
	push_error("unknown popup '%s'" % kind)
	return null


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
