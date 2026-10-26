class_name HostedEventPanel
extends Overlay
## The walking tour and the dinner (2026-10-23, Cameron): three screens of
## choices, each followed by how the guests took it, then the result. Drives
## GameState.hosted_session; every number lives in HostedEvent.gd and the
## workbook's Hosted Events, Event Options, Organization Tastes and Reaction
## Lines tabs.
##
## Screen order: what to do (a walking route, or a three-part menu: one pick
## per slot), the guests' reactions; a policy topic, reactions; a modest
## promise, reactions; then the evening in total.

var _hosted: Dictionary = {}
var _step := 1
var _slots: Array[String] = []
var _slot_index := 0
var _picked: Array = []


func _init() -> void:
	# Once the evening has begun the only way on is through its choices.
	dismissable = false
	show_back = false


## Begins the evening already set up in GameState.hosted_session.
func begin() -> void:
	_hosted = GameState.get_hosted_event(str(GameState.hosted_session.get("hosted_id", "")))
	if _hosted.is_empty():
		return
	_step = 1
	_begin_step()


func _begin_step() -> void:
	_slots = HostedEvent.slots_for(DataDB.event_options, str(_hosted["hosted_id"]), _step)
	_slot_index = 0
	_picked = []
	_show_pick()


func _picture() -> Control:
	var art := PlaceholderArt.new()
	art.name = "Picture"
	art.kind = PlaceholderArt.Kind.BACKGROUND
	art.art_id = str(_hosted.get("image", ""))
	art.custom_minimum_size = Vector2(0, 360)
	return art


func _show_pick() -> void:
	var rows: Array[Control] = [_picture()]
	if _step == 1 and _slot_index == 0:
		rows.append(UiKit.line(str(_hosted.get("intro", ""))))
		rows.append(UiKit.heading(Text.say("hosted.guests_heading")))
		for guest: Dictionary in GameState.hosted_session.get("roster", []):
			var guest_name := str(guest.get("name", ""))
			var guest_title := str(guest.get("title", ""))
			# A representative whose name is only their title is listed once.
			rows.append(UiKit.line(guest_name if guest_title.is_empty() or guest_title == guest_name
				else Text.say("hosted.guest_line", {"name": guest_name, "title": guest_title}), "SmallLabel"))
		if (GameState.hosted_session.get("roster", []) as Array).is_empty():
			rows.append(UiKit.line(Text.say("hosted.no_guests"), "SmallLabel"))
	var slot := _slots[_slot_index] if _slot_index < _slots.size() else ""
	if slot.is_empty():
		rows.append(UiKit.heading(str(_hosted.get("prompt_%d" % _step, ""))))
	else:
		rows.append(UiKit.heading(Text.say("hosted.pick_slot", {"slot": slot.to_lower()})))
	for option: Dictionary in GameState.hosted_options(_step, slot):
		var button := Button.new()
		button.name = "HostedOption_" + str(option.get("option_id", ""))
		button.custom_minimum_size = Vector2(0, 100)
		button.text = str(option.get("choice_text", ""))
		button.pressed.connect(_on_pick.bind(str(option.get("option_id", ""))))
		rows.append(button)
	open(str(_hosted.get("title", "")), rows)


func _on_pick(option_id: String) -> void:
	_picked.append(option_id)
	_slot_index += 1
	if _slot_index < _slots.size():
		_show_pick()
	else:
		_show_reactions()


func _show_reactions() -> void:
	var rows: Array[Control] = [_picture()]
	for option: Dictionary in DataDB.event_options:
		if str(option.get("hosted_id", "")) == str(_hosted["hosted_id"]) and _picked.has(str(option.get("option_id", ""))):
			var flavor := str(option.get("flavor", "")) if option.get("flavor") != null else ""
			if not flavor.is_empty():
				rows.append(UiKit.line(flavor, "SmallLabel"))
	rows.append(UiKit.heading(Text.say("hosted.reactions_heading")))
	for entry: Dictionary in GameState.hosted_record_step(_step, _picked):
		rows.append(UiKit.line(str(entry["line"])))
	var next := Button.new()
	next.name = "HostedNextButton"
	next.custom_minimum_size = Vector2(0, 100)
	next.text = Text.say("hosted.next" if _step < 3 else "hosted.finish")
	next.pressed.connect(_on_next)
	rows.append(next)
	open(str(_hosted.get("title", "")), rows)


func _on_next() -> void:
	if _step < 3:
		_step += 1
		_begin_step()
	else:
		_show_result()


func _show_result() -> void:
	var result := GameState.finish_hosted_event()
	var rows: Array[Control] = [_picture()]
	var net := int(result.get("net", 0))
	var settings := HostedEvent.settings(DataDB.balance)
	var mood := "hosted.net_even"
	if net >= int(settings["good_net"]):
		mood = "hosted.net_good"
	elif net <= int(settings["bad_net"]):
		mood = "hosted.net_bad"
	rows.append(UiKit.line(Text.say(mood)))
	var entries: Array = []
	for org: Variant in (result.get("deltas", {}) as Dictionary).keys():
		if int((result["deltas"] as Dictionary)[org]) != 0:
			entries.append({"id": str(org), "delta": int((result["deltas"] as Dictionary)[org])})
	var chips := OrgChip.merged(entries)
	if not chips.is_empty():
		rows.append(OrgChip.row(chips))
	var meter_text := Text.say("awareness.district" if str(result.get("meter", "")) == "district" else "awareness.national")
	if int(result.get("awareness", 0)) != 0:
		rows.append(UiKit.line(Text.say("hosted.awareness_line",
			{"name": meter_text, "change": "%+d" % int(result["awareness"])}), "SmallLabel"))
	if int(result.get("reputation", 0)) != 0:
		rows.append(UiKit.line(Text.say("hosted.reputation_line",
			{"change": "%+d" % int(result["reputation"])}), "SmallLabel"))
	var revealed := str(result.get("revealed", ""))
	if not revealed.is_empty():
		rows.append(UiKit.line(Text.say("item.hosted_reveal", {"name": revealed}), "SmallLabel"))
	if int(result.get("hours", 0)) > 0:
		rows.append(UiKit.line(Text.say("hosted.hours_line", {"hours": int(result["hours"]), "count": int(result["hours"])}), "SmallLabel"))
	var done := Button.new()
	done.name = "HostedDoneButton"
	done.custom_minimum_size = Vector2(0, 100)
	done.text = Text.say("event.continue")
	done.pressed.connect(close)
	rows.append(done)
	open(Text.say("hosted.result_title"), rows)
