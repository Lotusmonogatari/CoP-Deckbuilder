extends Node
## The signature elements of each style exist and carry no extra words (P9 review, finding 2): Woodblock's
## 攻/守/得 intent seal follows the opponent's move, Broadcast has its gold diagonal between the characters,
## Living Office has the payments tray and the docket card's folder, every style's docket card says the
## hours left, and Woodblock's payment lines have dotted leaders.
##
##     xvfb-run .tools/godot --path . tests/interaction/style_elements_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _equip(style: String) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 12000
	GameState.hire_staff("SF04")
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()


func _screen(path: String) -> Control:
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2340)
	vp.disable_3d = true
	add_child(vp)
	var screen: Control = (load(path) as PackedScene).instantiate()
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	return screen


func _done(screen: Control) -> void:
	screen.get_parent().queue_free()
	await get_tree().process_frame


func _run() -> void:
	# Battle: Woodblock's seal and Broadcast's diagonal.
	for style: String in [UiStyles.WOODBLOCK, UiStyles.BROADCAST, UiStyles.LIVING_OFFICE]:
		_equip(style)
		GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
		var battle := await _screen(BATTLE)
		var seal: Variant = battle.get("_intent_seal")
		var verb := str(battle.engine.current_intent().get("verb", "none"))
		var expected: String = {"attack": "攻", "block": "守", "gain": "得"}.get(verb, "")
		if style == UiStyles.WOODBLOCK:
			if seal == null:
				_failures.append("woodblock: no intent seal")
			elif (seal as StyleMarks).visible != not expected.is_empty() or (seal as StyleMarks).glyph != expected:
				_failures.append("woodblock: the seal shows '%s' for a '%s' move" % [(seal as StyleMarks).glyph, verb])
		elif seal != null:
			_failures.append("%s: has an intent seal" % style)
		var diagonal := battle.find_child("CutIns", true, false)
		if (style == UiStyles.BROADCAST) != (diagonal != null):
			_failures.append("%s: the cut-in panels are %s" % [style, "missing" if style == UiStyles.BROADCAST else "present"])
		# Woodblock: the wave band and the framed print; no other style has them.
		var waves := battle.find_child("WaveBand", true, false)
		var print_frame := battle.find_child("PrintFrame", true, false)
		if (style == UiStyles.WOODBLOCK) != (waves != null):
			_failures.append("%s: the battle's wave band is %s" % [style, "missing" if style == UiStyles.WOODBLOCK else "present"])
		if (style == UiStyles.WOODBLOCK) != (print_frame != null):
			_failures.append("%s: the battle's framed print is %s" % [style, "missing" if style == UiStyles.WOODBLOCK else "present"])
		await _done(battle)
	# Office: the docket card says the hours in every style; Living Office has the tray and the folder.
	for style: String in UiStyles.ALL:
		_equip(style)
		var office := await _screen(OFFICE)
		var sub := office.find_child("DocketHours", true, false) as Label
		if sub == null or not sub.text.contains(str(GameState.work_hours_left())):
			_failures.append("%s: the docket card does not say the hours left" % style)
		# Living Office: the calendar is a page-a-day with a header and a curled corner, and the narration a
		# speech bubble with a tail. Woodblock: the wave band and the framed print on the portrait.
		var is_living := style == UiStyles.LIVING_OFFICE
		if is_living != (office.find_child("CalendarHeader", true, false) != null):
			_failures.append("%s: the page-a-day calendar is %s" % [style, "missing" if is_living else "present"])
		if is_living != (office.find_child("PageCurl", true, false) != null):
			_failures.append("%s: the calendar's page curl is %s" % [style, "missing" if is_living else "present"])
		if is_living != (office.find_child("BubbleTail", true, false) != null):
			_failures.append("%s: the narration bubble's tail is %s" % [style, "missing" if is_living else "present"])
		var wood := style == UiStyles.WOODBLOCK
		if wood != (office.find_child("WaveBand", true, false) != null):
			_failures.append("%s: the Office's wave band is %s" % [style, "missing" if wood else "present"])
		if wood != (office.find_child("PrintFrame", true, false) != null):
			_failures.append("%s: the Office's framed print is %s" % [style, "missing" if wood else "present"])
		var tray := office.find_child("Tray", true, false)
		if (style == UiStyles.LIVING_OFFICE) != (tray != null):
			_failures.append("%s: the payments tray is %s" % [style, "missing" if style == UiStyles.LIVING_OFFICE else "present"])
		# Woodblock's ledger: dotted leaders in the payments breakdown.
		office.call("_show_week_payments")
		await get_tree().create_timer(0.4).timeout
		var leaders := 0
		for node in office.find_children("*", "Control", true, false):
			if node is StyleMarks and (node as StyleMarks).kind == StyleMarks.Kind.LEADER:
				leaders += 1
		if (style == UiStyles.WOODBLOCK) != (leaders > 0):
			_failures.append("%s: %d dotted leaders in the payments breakdown" % [style, leaders])
		# Living Office pins carry the room object's word; the other styles have none. Each style has a preview.
		var words: Array = []
		for node in office.find_children("ObjectWord", "Label", true, false):
			words.append((node as Label).text)
		if style == UiStyles.LIVING_OFFICE:
			for want: String in ["Phone", "Bookshelf", "Front desk", "Errand list"]:
				if not words.has(want):
					_failures.append("living_office: no '%s' pin word (found %s)" % [want, str(words)])
		elif not words.is_empty():
			_failures.append("%s: has room-object words %s" % [style, str(words)])
		if UiStyle.preview(style) == null:
			_failures.append("%s: no screenshot preview for the styles shop" % style)
		# The Levels list: Living Office draws each level's hours in a ring (red and tilted when the level
		# cannot be started); the words are the same "N hours" line as in every style.
		GameState.calendar["hours"] = 37
		office.call("_show_levels")
		await get_tree().create_timer(0.4).timeout
		var rings: Array = office.find_children("HoursRing", "Control", true, false)
		var draft := office.find_child("DraftBillButton", true, false)
		if draft != null and (style == UiStyles.LIVING_OFFICE) != draft.has_node("DashedFrame"):
			_failures.append("%s: the Draft a Bill dashed frame is %s" % [style, "missing" if style == UiStyles.LIVING_OFFICE else "present"])
		if (style == UiStyles.LIVING_OFFICE) != (rings.size() > 0):
			_failures.append("%s: %d hours rings in the Levels list" % [style, rings.size()])
		if style == UiStyles.LIVING_OFFICE and rings.size() > 0:
			var tilted := 0
			var upright := 0
			for ring in rings:
				var disc := (ring as Node).get_node("Ring") as Control
				if not (disc.get_child(0) as Label).text.contains("hours"):
					_failures.append("an hours ring does not say hours")
				if absf(disc.rotation_degrees) > 1.0:
					tilted += 1
				else:
					upright += 1
			if tilted == 0 or upright == 0:
				_failures.append("late in the week some rings should be tilted (cannot start) and some upright; got %d and %d" % [tilted, upright])
		await _done(office)
	# The Living Office calendar page follows the equipped calendar style: plain, Era years, or the Ainu form.
	for package_id: String in ["", "CP05", "CP06"]:
		_equip(UiStyles.LIVING_OFFICE)
		if not package_id.is_empty():
			GameState.owned_cosmetic_packages.append(package_id)
			GameState.equip_cosmetic(CosmeticPieces.CALENDAR, package_id)
		var office2 := await _screen(OFFICE)
		var page := office2.find_child("CalendarSquare", true, false) as Control
		var date := office2.find_child("CalendarDate", true, false) as Label
		var week := office2.find_child("CalendarWeekday", true, false) as Label
		var tag := "calendar '%s': " % GameState.calendar_style()
		if date == null or date.text != GameState.calendar_date_text():
			_failures.append(tag + "the page shows '%s', the calendar says '%s'" % [date.text if date != null else "nothing", GameState.calendar_date_text()])
		if week == null or week.text != GameState.calendar_weekday_text():
			_failures.append(tag + "the page header shows '%s', the calendar says '%s'" % [week.text if week != null else "nothing", GameState.calendar_weekday_text()])
		if GameState.calendar_style() == CalendarStyles.ERA and not date.text.contains("年"):
			_failures.append(tag + "the Era page does not show an era year: '%s'" % date.text)
		if GameState.calendar_style() == CalendarStyles.AINU and date.text.contains("年"):
			_failures.append(tag + "the Ainu page shows an era year: '%s'" % date.text)
		if page != null and date != null:
			var inside := page.get_global_rect().grow(2.0)
			if not inside.encloses(date.get_global_rect()):
				_failures.append(tag + "the date runs off the page")
		await _done(office2)
	if _failures.is_empty():
		print("STYLE ELEMENTS TEST: PASS")
		get_tree().quit(0)
	else:
		print("STYLE ELEMENTS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
