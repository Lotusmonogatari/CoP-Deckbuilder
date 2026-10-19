class_name PatronVisit
extends RefCounted
## The opening stage of a sponsored-bill level (2026-10-19, Cameron): a
## representative of the sponsoring organization asks the player two dilemma
## questions about the bill, in the Office Hours format (`OfficeHoursEngine`).
## Built once when the level is created, from the bill's own components, and
## kept with the level. Pure: no UI, and every sentence is a Text-tab row.

const STAGE := "ST263"
const CHOICES := ["a", "b", "c", "d"]

## Standing moved by each choice for the patron, and for the component's
## first friend and first rival. A friend-pleaser, a hedge, a snub, a refusal.
const PATRON_DELTAS := {"a": 4, "b": 2, "c": -2, "d": -4}
const FRIEND_DELTAS := {"a": 1, "b": 0, "c": 0, "d": 0}
const RIVAL_DELTAS := {"a": -2, "b": 1, "c": 2, "d": 0}


## {"visitor": {...}, "visitors": [two entries, one question each]} for the
## patron organization `org_id` and the bill's `component_ids`. {} when the
## organization or its components cannot be found.
static func build(org_id: String, component_ids: Array) -> Dictionary:
	var org := DataDB.get_booster(org_id)
	if org.is_empty() or component_ids.is_empty():
		return {}
	var by_id := ComposedBill.index(DataDB.bill_components)
	var visitor := {
		"visitor_id": "PV_%s" % org_id,
		"name_en": Text.say("patron_visit.name", {"org": str(org.get("name_en", org_id))}),
		"name_jp": str(org.get("name_jp", "")) if org.get("name_jp") != null else "",
		"title": Text.say("patron_visit.name", {"org": str(org.get("name_en", org_id))}),
		"stages": [STAGE],
	}
	var visitors: Array = []
	for index in 2:
		# A one-component bill asks about the same part twice, the second time
		# in the "and what about" form.
		var component: Dictionary = by_id.get(str(component_ids[mini(index, component_ids.size() - 1)]), {})
		if component.is_empty():
			return {}
		var entry := visitor.duplicate(true)
		entry["question"] = _question(org_id, component, index)
		visitors.append(entry)
	return {"visitor": visitor, "visitors": visitors}


static func _question(org_id: String, component: Dictionary, index: int) -> Dictionary:
	var friend := _first_other(component.get("gains", []), org_id, 1)
	var rival := _first_other(component.get("loses", []), org_id, -1)
	var question := {
		"question_id": "PVQ_%s_%d" % [str(component.get("component_id", "")), index],
		"question_text": Text.say("patron_visit.question_first" if index == 0 else "patron_visit.question_second",
			{"phrase": str(component.get("phrase", ""))}),
		"correct_choice": "",
	}
	var words := _words()
	for key: String in CHOICES:
		question["choice_%s" % key] = str(words[key]["choice"])
		question["response_%s" % key] = str(words[key]["response"])
		question["reaction_%s" % key] = str(words[key]["reaction"])
		var effects: Array = [{"target": org_id, "delta": int(PATRON_DELTAS[key])}]
		if not friend.is_empty() and int(FRIEND_DELTAS[key]) != 0:
			effects.append({"target": friend, "delta": int(FRIEND_DELTAS[key])})
		if not rival.is_empty() and int(RIVAL_DELTAS[key]) != 0:
			effects.append({"target": rival, "delta": int(RIVAL_DELTAS[key])})
		question["effects_%s" % key] = effects
	return question


## The four choices' words, each key written out so the exporter can check it.
static func _words() -> Dictionary:
	return {
		"a": {"choice": Text.say("patron_visit.choice_a"), "response": Text.say("patron_visit.response_a"),
			"reaction": Text.say("patron_visit.reaction_a")},
		"b": {"choice": Text.say("patron_visit.choice_b"), "response": Text.say("patron_visit.response_b"),
			"reaction": Text.say("patron_visit.reaction_b")},
		"c": {"choice": Text.say("patron_visit.choice_c"), "response": Text.say("patron_visit.response_c"),
			"reaction": Text.say("patron_visit.reaction_c")},
		"d": {"choice": Text.say("patron_visit.choice_d"), "response": Text.say("patron_visit.response_d"),
			"reaction": Text.say("patron_visit.reaction_d")},
	}


## The first organization in a gains/loses list, other than the patron, with
## the wanted sign; "" when there is none.
static func _first_other(entries: Variant, org_id: String, sign_wanted: int) -> String:
	if not (entries is Array):
		return ""
	for entry: Variant in (entries as Array):
		if not (entry is Dictionary):
			continue
		var target := str((entry as Dictionary).get("target", ""))
		var delta := SafeNum.to_int((entry as Dictionary).get("delta"))
		if target != org_id and delta * sign_wanted > 0 and not DataDB.get_booster(target).is_empty():
			return target
	return ""
