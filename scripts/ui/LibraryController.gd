class_name LibraryController
extends Node
## The National Assembly Library's screen (P18, 2026-11-24): two tabs, the Reference desk and the Codex, and the reader that unrolls
## a document. VenuesController hands the Library (a venue with a research or read activity) to this; the rules are Codex and
## GameState, the drawing is CodexViews. Every sentence is a Text row or a document's own text.

const TAB_DESK := "desk"
const TAB_CODEX := "codex"
## The desk tab's three views: the desk and the Library's other activities, the list of rooms to ask about, and the reading.
const MODE_DESK := "desk"
const MODE_PICK := "pick"
const MODE_RESULT := "result"

var _venues: Node
var _venue_panel: Overlay
var _reader_panel: Overlay
var _chips: Callable
var _venue_id := ""
var _tab := TAB_DESK
var _mode := MODE_DESK
var _result: Dictionary = {}
## The reader's document: the category it moves within and the ids it can reach.
var _reader_category := ""
var _reader_ids: Array = []


## `venues` is the VenuesController (it spends hours and redraws the Step out button); `chips` is its Callable for the top bar's chips.
func setup(office: Control, venues: Node, venue_panel: Overlay, chips: Callable) -> void:
	name = "LibraryController"
	office.add_child(self)
	_venues = venues
	_venue_panel = venue_panel
	_chips = chips
	_reader_panel = Overlay.new()
	_reader_panel.name = "CodexReaderPanel"
	_reader_panel.show_back = false   # the reader has its own Roll up
	office.add_child(_reader_panel)
	_reader_panel.closed.connect(_on_reader_closed)


## True for a venue this controller draws: one with a Codex or a reference desk.
static func draws(venue_id: String) -> bool:
	for activity: Dictionary in GameState.venue_activities_of(venue_id):
		if str(activity.get("kind", "")) in ["read", "research"]:
			return true
	return false


func close_all() -> void:
	if _reader_panel != null and _reader_panel.visible:
		_reader_panel.close()


## Shows the Library. `tab` picks the tab to start on.
func open(venue_id: String, tab: String = TAB_DESK) -> void:
	_venue_id = venue_id
	_tab = tab
	_mode = MODE_DESK
	_result = {}
	_draw()


func _draw() -> void:
	var venue := GameState.venue_row(_venue_id)
	var look := OfficeFrameStyles.look()
	var unread := GameState.codex_unread_count()
	var rows: Array[Control] = []
	var footer: Button = null
	if _tab == TAB_CODEX:
		rows = _codex_rows(look)
	else:
		match _mode:
			MODE_PICK:
				rows = _pick_rows(look)
			MODE_RESULT:
				rows = _result_rows(look)
				footer = Button.new()
				footer.name = "DeskDone"
				footer.text = Text.say("desk.done_today")
				footer.disabled = true
			_:
				rows = _desk_rows(look)
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": str(venue.get("name", _venue_id)), "subtitle": str(venue.get("name_jp", "")), "chips": _chips.call(),
		"tabs": [{"id": TAB_DESK, "node": "DeskTab", "text": Text.say("codex.tab_desk")},
			{"id": TAB_CODEX, "node": "CodexTab", "text": Text.say("codex.tab_codex_new", {"count": unread}) if unread > 0 else Text.say("codex.tab_codex")}],
		"active_tab": _tab, "rows": rows, "footer": footer,
	})
	frame.tab_chosen.connect(_on_tab)
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))


func _on_tab(tab_id: String) -> void:
	_tab = tab_id
	_mode = MODE_DESK
	_result = {}
	_draw()


# --- The Reference desk tab ---------------------------------------------------------------------------------------------------------

func _desk_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [UiKit.line(Text.say("desk.intro"), "SmallLabel")]
	var activities := GameState.venue_activities_of(_venue_id)
	# The desk first, then Browse the Shelves, then the rest (Nap, Read about management practices) as they were.
	var ordered: Array = []
	for kind: String in ["research", "read"]:
		for activity: Dictionary in activities:
			if str(activity.get("kind", "")) == kind:
				ordered.append(activity)
	for activity: Dictionary in activities:
		if not ordered.has(activity):
			ordered.append(activity)
	for activity: Dictionary in ordered:
		rows.append(VenueActivityViews.card(look, activity, _on_card_do))
	return rows


## What a card's button does: the desk opens the room list, Browse the Shelves opens the Codex tab, an act is done as before.
func _on_card_do(activity_id: String) -> void:
	match str(GameState.venue_activity(activity_id).get("kind", "")):
		"research":
			_mode = MODE_PICK
			_draw()
		"read":
			_on_tab(TAB_CODEX)
		_:
			_venues.call("do_activity", activity_id)


func _pick_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [UiKit.heading(Text.say("desk.pick_heading"))]
	var rooms := GameState.desk_rooms()
	if rooms.is_empty():
		rows.append(UiKit.line(Text.say("desk.pick_none")))
	for room: Dictionary in rooms:
		var button := Button.new()
		button.name = "Room_%s_%s" % [str(room["stage_id"]), str(room["level_id"])]
		button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
		button.text = Text.say("desk.pick_row", {"stage": str(room["stage"]), "level": str(room["level"])})
		OfficeFrameStyles.dress_card_button(button, look, true)
		button.pressed.connect(_on_pick.bind(str(room["stage_id"]), str(room["level_id"])))
		rows.append(button)
	var back := Button.new()
	back.name = "DeskBack"
	back.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	back.text = Text.say("desk.back")
	OfficeFrameStyles.dress_card_button(back, look, true)
	back.pressed.connect(_on_pick_back)
	rows.append(back)
	return rows


func _on_pick_back() -> void:
	_mode = MODE_DESK
	_draw()


func _on_pick(stage_id: String, level_id: String) -> void:
	var done := GameState.do_research(stage_id, level_id)
	if not bool(done["ok"]):
		_mode = MODE_DESK
		_draw()
		return
	_venues.call("hours_spent")
	_result = done
	_mode = MODE_RESULT
	_draw()


## The reading: one card with the tag, what it cost, the room and the six rows, then the tip box.
func _result_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	var card := OfficeFrameStyles.card(look)
	card.name = "DeskResult"
	var column := card.get_node("Column") as VBoxContainer
	var top := HBoxContainer.new()
	var tag := PanelContainer.new()
	var plate := StyleBoxFlat.new()
	plate.bg_color = look["accent"]
	plate.content_margin_left = ScrollStyle.len_px(9.0)
	plate.content_margin_right = ScrollStyle.len_px(9.0)
	plate.content_margin_top = ScrollStyle.len_px(3.0)
	plate.content_margin_bottom = ScrollStyle.len_px(3.0)
	tag.add_theme_stylebox_override("panel", plate)
	var tag_label := CodexViews.ink_label(Text.say("desk.tag").to_upper(), 11.0, look["on_accent"], true, "", true)
	tag.add_child(tag_label)
	top.add_child(tag)
	var spent := CodexViews.ink_label(Text.say("desk.spent", {"hours": _desk_hours(), "limit": _desk_limit()}), 12.0, look["muted"])
	spent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(spent)
	column.add_child(top)
	column.add_child(CodexViews.ink_label(str(_result.get("stage", "")), 19.0, look["ink"], true, "DeskStage"))
	column.add_child(CodexViews.ink_label(Text.say("desk.room_line", {"level": str(_result.get("level", "")),
		"number": int(_result.get("number", 1)), "total": int(_result.get("total", 1))}), 12.0, look["muted"], false, "DeskRoomLine"))
	column.add_child(CodexViews.reading_rows(_result.get("reading", []), look["ink"], look["muted"]))
	rows.append(card)
	rows.append(CodexViews.desk_tip_box(str(_result.get("stage", "")), str(_result.get("suit", "")), int(_result.get("days", 14)), look))
	return rows


func _desk_hours() -> int:
	return int(VenueRules.visit_cost(GameState.desk_activity())["hours"])


func _desk_limit() -> int:
	return int(GameState.desk_activity().get("per_day", 1))


# --- The Codex tab -------------------------------------------------------------------------------------------------------------------

func _codex_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [UiKit.line(Text.say("codex.intro"), "SmallLabel")]
	var room_ids := GameState.room_file_ids()
	var categories := Codex.categories(DataDB.library_documents, not room_ids.is_empty())
	if categories.is_empty():
		rows.append(UiKit.line(Text.say("codex.empty")))
		return rows
	for category: String in categories:
		if category == Codex.ROOM_FILES:
			rows.append(CodexViews.category_heading(_category_name(category), Text.say("codex.count_room_files", {"count": room_ids.size()})))
			for stage_id: String in room_ids:
				rows.append(CodexViews.closed_scroll(_room_file_row(stage_id), _on_open_room_file))
			continue
		var docs := Codex.in_category(DataDB.library_documents, category)
		var found := 0
		for doc: Dictionary in docs:
			if GameState.codex_state(str(doc["doc_id"])) != "sealed":
				found += 1
		rows.append(CodexViews.category_heading(_category_name(category), Text.say("codex.count_found", {"found": found, "total": docs.size()})))
		for doc: Dictionary in docs:
			rows.append(CodexViews.closed_scroll(_doc_row(doc), _on_open_doc))
	return rows


func _category_name(category: String) -> String:
	match category:
		"room_file": return Text.say("codex.category_room_file")
		"party_platform": return Text.say("codex.category_party_platform")
		"ne3": return Text.say("codex.category_ne3")
		"history": return Text.say("codex.category_history")
	return category


func _room_file_row(stage_id: String) -> Dictionary:
	var days := GameState.room_file_days_left(stage_id)
	var file := GameState.room_file(stage_id)
	return {"id": stage_id, "node": "RoomFile_" + stage_id, "title": str(DataDB.get_stage(stage_id).get("name_en", stage_id)),
		"line": Text.say("codex.from_desk_last") if days <= 1 else Text.say("codex.from_desk", {"days": days}),
		"state": "read" if bool(file.get("read", false)) else "new"}


func _doc_row(doc: Dictionary) -> Dictionary:
	var id := str(doc["doc_id"])
	var state := GameState.codex_state(id)
	if state == "sealed":
		return {"id": id, "node": "Doc_" + id, "title": Text.say("codex.not_found"), "line": str(doc.get("hint", "")), "state": "sealed"}
	var line := ""
	match str(doc.get("unlock", "")):
		"start": line = Text.say("codex.from_start")
		"own_party": line = Text.say("codex.from_party")
		"line": line = Text.say("codex.from_line")
		"law": line = Text.say("codex.from_law")
	return {"id": id, "node": "Doc_" + id, "title": str(doc.get("title", "")), "line": line, "state": state}


# --- The reader ----------------------------------------------------------------------------------------------------------------------

func _on_open_doc(doc_id: String) -> void:
	var doc := GameState.codex_find_row(doc_id)
	_reader_category = str(doc.get("category", ""))
	_reader_ids = Codex.in_category(DataDB.library_documents, _reader_category).filter(
		func(row: Dictionary) -> bool: return GameState.codex_state(str(row["doc_id"])) != "sealed").map(
		func(row: Dictionary) -> String: return str(row["doc_id"]))
	_show_reader(doc_id)


func _on_open_room_file(stage_id: String) -> void:
	_reader_category = Codex.ROOM_FILES
	_reader_ids = GameState.room_file_ids()
	_show_reader(stage_id)


## Unrolls one document (reading it the first time pays the XP once) with Previous, Roll up and Next.
func _show_reader(id: String) -> void:
	var is_room := _reader_category == Codex.ROOM_FILES
	if is_room:
		GameState.room_file_read(id)
	elif GameState.codex_read(id) > 0:
		_venues.call("hours_spent")   # the XP shows in the chips
	var look := OfficeFrameStyles.look()
	# The scroll hangs on a dimmed copy of the style's ground; the line above it is light on a dark ground and dark on a light one.
	var ground: Color = (look["ground"] as Color).lerp(Color.BLACK, 0.5)
	var on_ground := Color(0.94, 0.94, 0.92, 0.85) if ground.get_luminance() < 0.5 else Color(0.1, 0.1, 0.1, 0.85)
	var doc := _room_file_doc(id, look) if is_room else _document_doc(id)
	var at := _reader_ids.find(id)
	var neighbours := Codex.neighbours(_reader_ids, id)
	var rows: Array[Control] = []
	var header := CodexViews.ink_label(Text.say("codex.reader_header", {"category": _category_name(_reader_category).to_upper(), "number": at + 1,
		"total": _reader_ids.size()}), 12.0, on_ground, false, "ReaderHeader")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.append(header)
	rows.append(CodexViews.reader(doc))
	var buttons := HBoxContainer.new()
	buttons.name = "ReaderButtons"
	buttons.add_theme_constant_override("separation", int(ScrollStyle.len_px(8.0)))
	buttons.add_child(_reader_button("ReaderPrevious", Text.say("codex.previous"), false, not str(neighbours["previous"]).is_empty(),
		_show_reader.bind(str(neighbours["previous"]))))
	buttons.add_child(_reader_button("ReaderRollUp", Text.say("codex.roll_up"), true, true, _reader_panel.close))
	buttons.add_child(_reader_button("ReaderNext", Text.say("codex.next"), false, not str(neighbours["next"]).is_empty(),
		_show_reader.bind(str(neighbours["next"]))))
	rows.append(buttons)
	_reader_panel.open("", rows, "", "")
	_reader_panel.set_ground(ground)


func _reader_button(node_name: String, text: String, primary: bool, enabled: bool, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	button.disabled = not enabled
	LevelBriefingStyles.dress_button(button, OfficeFrameStyles.look(), primary, enabled)
	if enabled:
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(action)
	return button


func _document_doc(doc_id: String) -> Dictionary:
	var doc := GameState.codex_find_row(doc_id)
	var paragraphs: Array = []
	for paragraph: String in str(doc.get("body", "")).split("\n\n"):
		if not paragraph.strip_edges().is_empty():
			paragraphs.append(paragraph.strip_edges())
	return {"kicker": str(doc.get("kicker", "")), "title": str(doc.get("title", "")), "title_jp": str(doc.get("title_jp", "")),
		"paragraphs": paragraphs, "footer": ""}


func _room_file_doc(stage_id: String, look: Dictionary) -> Dictionary:
	var file := GameState.room_file(stage_id)
	var stage := DataDB.get_stage(stage_id)
	var jp := str(stage.get("name_jp", ""))
	var days := GameState.room_file_days_left(stage_id)
	var date := GameState.day_date_text(int(file.get("day", 0)))
	var level := str(DataDB.get_level(str(file.get("level_id", ""))).get("description", ""))
	return {"kicker": Text.say("codex.room_kicker", {"jp": jp}) if not jp.is_empty() else Text.say("codex.room_kicker_plain"),
		"title": str(stage.get("name_en", stage_id)), "title_jp": "",
		"subtitle": Text.say("desk.room_line", {"level": level, "number": int(file.get("number", 1)), "total": int(file.get("total", 1))}),
		"paragraphs": [Text.say("codex.room_intro")],
		"extra": CodexViews.reading_rows(file.get("reading", []), ScrollStyle.colour("ink"), ScrollStyle.colour("muted")),
		"footer": Text.say("codex.room_footer_last", {"date": date}) if days <= 1 else Text.say("codex.room_footer", {"date": date, "days": days})}


## Rolling up redraws the Codex under it, so NEW marks and the unread count are today's.
func _on_reader_closed() -> void:
	if _venue_panel.visible and _tab == TAB_CODEX:
		_draw()
