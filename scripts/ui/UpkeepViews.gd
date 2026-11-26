class_name UpkeepViews
extends RefCounted
## The Upkeep tab of Reputation and Results (P21 phase A, 2026-11-26, Cameron): Shore up support (hold one meter's fade), Keep in touch (hold one
## organization's fade) and Dues and the Funds limit (the dues bailout and the two calls). Each button says its price and is greyed with the reason when
## it cannot be bought. They draw what GameState tells them; nothing here decides a rule. Every sentence is a Text row.


static func _small(node_name: String, text: String) -> Label:
	var label := UiKit.line(text, "SmallLabel")
	label.name = node_name
	label.custom_minimum_size.x = 0.0
	return label


static func _button(node_name: String, text: String, why: String, look: Dictionary, on_press: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	var enabled := why.is_empty()
	button.text = text if enabled else "%s · %s" % [text, why]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not enabled
	OfficeFrameStyles.dress_card_button(button, look, enabled)
	if enabled:
		button.pressed.connect(on_press)
	return button


static func _meter_name(meter: String) -> String:
	match meter:
		"District awareness": return Text.say("awareness.district")
		"National awareness": return Text.say("awareness.national")
	return meter


static func _meter_value(meter: String) -> int:
	match meter:
		"District awareness": return int(GameState.awareness.get("district", 0))
		"National awareness": return int(GameState.awareness.get("national", 0))
	return int(GameState.meta.get(meter, 0))


## The three cards. `on_hold` is called with the hold key, `on_bailout` with nothing, `on_cap` with the kind.
static func cards(look: Dictionary, on_hold: Callable, on_bailout: Callable, on_cap: Callable) -> Array[Control]:
	var out: Array[Control] = []
	var shore := OfficeFrameStyles.card(look, Text.say("upkeep.shore_title"))
	shore.name = "ShoreUpCard"
	var column := shore.get_node("Column") as VBoxContainer
	column.add_child(_small("ShoreBlurb", Text.say("upkeep.shore_blurb")))
	for meter: String in GameState.HOLD_METERS:
		var key := "meter:" + meter
		column.add_child(_small("MeterLine_" + meter.replace(" ", ""), Text.say("upkeep.meter_line",
			{"name": _meter_name(meter), "value": _meter_value(meter), "fade": GameState.meter_fade(meter)})))
		var why := GameState.hold_refusal(key)
		var label := Text.say("upkeep.held") if GameState.decay_holds.has(key) else Text.say("upkeep.hold_button", {"cost": GameState.hold_price_of(key)})
		column.add_child(_button("Hold_" + meter.replace(" ", ""), label, "" if GameState.decay_holds.has(key) else why, look, on_hold.bind(key)))
	out.append(shore)
	var touch := OfficeFrameStyles.card(look, Text.say("upkeep.touch_title"))
	touch.name = "KeepInTouchCard"
	var touch_column := touch.get_node("Column") as VBoxContainer
	touch_column.add_child(_small("TouchBlurb", Text.say("upkeep.touch_blurb")))
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		if GameState.org_fade(id) <= 0 and not GameState.decay_holds.has("org:" + id):
			continue
		var key := "org:" + id
		touch_column.add_child(_small("OrgLine_" + id, Text.say("upkeep.org_line",
			{"name": str(booster.get("name_en", id)), "value": int(GameState.booster_standing.get(id, 0)), "fade": GameState.org_fade(id)})))
		var label := Text.say("upkeep.held") if GameState.decay_holds.has(key) else Text.say("upkeep.hold_button", {"cost": GameState.hold_price_of(key)})
		touch_column.add_child(_button("HoldOrg_" + id, label, "" if GameState.decay_holds.has(key) else GameState.hold_refusal(key), look, on_hold.bind(key)))
	out.append(touch)
	var dues := OfficeFrameStyles.card(look, Text.say("upkeep.dues_title"))
	dues.name = "DuesReliefCard"
	var dues_column := dues.get_node("Column") as VBoxContainer
	dues_column.add_child(_small("BailoutBlurb", Text.say("upkeep.bailout_blurb")))
	dues_column.add_child(_button("DuesBailout", Text.say("upkeep.bailout_button", {"cost": GameState.bailout_price(), "yen": Levers.whole("dues_bailout_yen")}),
		GameState.bailout_refusal(), look, on_bailout))
	dues_column.add_child(_small("CapBlurb", Text.say("upkeep.cap_blurb", {"ceiling": Levers.whole("funds_petition_ceiling")})))
	dues_column.add_child(_button("CapCallParty", Text.say("upkeep.cap_party_button", {"support": Levers.whole("cap_call_party_support"),
		"cost": GameState.cap_call_price(GameState.CAP_PARTY), "yen": Levers.whole("cap_call_yen")}), GameState.cap_call_refusal(GameState.CAP_PARTY), look, on_cap.bind(GameState.CAP_PARTY)))
	dues_column.add_child(_button("CapCallFinance", Text.say("upkeep.cap_finance_button", {"standing": Levers.whole("cap_call_finance_standing"),
		"cost": GameState.cap_call_price(GameState.CAP_FINANCE), "yen": Levers.whole("cap_call_finance_yen")}), GameState.cap_call_refusal(GameState.CAP_FINANCE), look, on_cap.bind(GameState.CAP_FINANCE)))
	out.append(dues)
	return out
