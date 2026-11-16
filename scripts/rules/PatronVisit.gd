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
## The numbers are Balance-tab levers ("Patron visit: Patron A" and so on).
static func delta(who: String, key: String) -> int:
	return Levers.whole("patron_visit_%s_%s" % [who, key])


## {"visitor": {...}, "visitors": [two entries, one question each]} for the
## patron organization `org_id` and the bill's `component_ids`. {} when the
## organization or its components cannot be found.
##
## Everything it needs is handed in (audit F-16, 2026-11-16: this file used to
## reach for the DataDB and Text autoloads, which the rules layer must not):
## `boosters` and `components` are the data tables, `words` the Text phrase book.
static func build(org_id: String, component_ids: Array, boosters: Array, components: Array,
		words: Phrase) -> Dictionary:
	var known := {}
	for booster: Variant in boosters:
		if booster is Dictionary:
			known[str((booster as Dictionary).get("booster_id", ""))] = booster
	var org: Dictionary = known.get(org_id, {})
	if org.is_empty() or component_ids.is_empty():
		return {}
	var by_id := ComposedBill.index(components)
	var visitor := {
		"visitor_id": "PV_%s" % org_id,
		"name_en": words.say("patron_visit.name", {"org": str(org.get("name_en", org_id))}),
		"name_jp": str(org.get("name_jp", "")) if org.get("name_jp") != null else "",
		"title": words.say("patron_visit.name", {"org": str(org.get("name_en", org_id))}),
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
		entry["question"] = _question(org_id, component, index, known, words)
		visitors.append(entry)
	return {"visitor": visitor, "visitors": visitors}


static func _question(org_id: String, component: Dictionary, index: int, known: Dictionary,
		words: Phrase) -> Dictionary:
	var friend := _first_other(component.get("gains", []), org_id, 1, known)
	var rival := _first_other(component.get("loses", []), org_id, -1, known)
	var question := {
		"question_id": "PVQ_%s_%d" % [str(component.get("component_id", "")), index],
		"question_text": words.say("patron_visit.question_first" if index == 0 else "patron_visit.question_second",
			{"phrase": str(component.get("phrase", ""))}),
		"correct_choice": "",
	}
	var said := _words(words)
	for key: String in CHOICES:
		question["choice_%s" % key] = str(said[key]["choice"])
		question["response_%s" % key] = str(said[key]["response"])
		question["reaction_%s" % key] = str(said[key]["reaction"])
		var effects: Array = [{"target": org_id, "delta": delta("patron", key)}]
		if not friend.is_empty() and delta("friend", key) != 0:
			effects.append({"target": friend, "delta": delta("friend", key)})
		if not rival.is_empty() and delta("rival", key) != 0:
			effects.append({"target": rival, "delta": delta("rival", key)})
		question["effects_%s" % key] = effects
	return question


## The four choices' words, each key written out so the exporter can check it.
static func _words(words: Phrase) -> Dictionary:
	return {
		"a": {"choice": words.say("patron_visit.choice_a"), "response": words.say("patron_visit.response_a"),
			"reaction": words.say("patron_visit.reaction_a")},
		"b": {"choice": words.say("patron_visit.choice_b"), "response": words.say("patron_visit.response_b"),
			"reaction": words.say("patron_visit.reaction_b")},
		"c": {"choice": words.say("patron_visit.choice_c"), "response": words.say("patron_visit.response_c"),
			"reaction": words.say("patron_visit.reaction_c")},
		"d": {"choice": words.say("patron_visit.choice_d"), "response": words.say("patron_visit.response_d"),
			"reaction": words.say("patron_visit.reaction_d")},
	}


## The first organization in a gains/loses list, other than the patron, with
## the wanted sign; "" when there is none.
static func _first_other(entries: Variant, org_id: String, sign_wanted: int, known: Dictionary) -> String:
	if not (entries is Array):
		return ""
	for entry: Variant in (entries as Array):
		if not (entry is Dictionary):
			continue
		var target := str((entry as Dictionary).get("target", ""))
		var delta := SafeNum.to_int((entry as Dictionary).get("delta"))
		if target != org_id and delta * sign_wanted > 0 and known.has(target):
			return target
	return ""
