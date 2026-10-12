class_name QuestionAskers
extends RefCounted
## Who asks each question in a room (2026-10-12, Cameron).
##
## The exporter gives every question an asker in rotation, from the people the
## workbook seats in its stage. Two things can only be settled once the game
## knows the room and the player:
##  - the room may only seat some of them (a party caucus seats only the
##    player's own party, Stages tab "Own Party Only");
##  - a question may say who is allowed to ask it (the question tabs'
##    "Asked By Party": PTxx IDs, or OWN for the player's own party).
##
## So each question keeps its asker when that person is in the room and of an
## allowed party; otherwise someone who is replaces them, picked the same way
## every time for the same question. A party-limited question nobody in the
## room may ask is left out of the room altogether, rather than being put in
## the wrong mouth. Pure: everything it needs is passed in.

const OWN := "OWN"


## `questions`: the room's questions. `eligible`: the opponents the room may
## seat (dictionaries with opp_id and party). `own_party`: the player's party
## name. `party_names`: party_id -> party name. Returns new question
## dictionaries; the inputs are not changed.
static func resolve(questions: Array, eligible: Array, own_party: String,
		party_names: Dictionary) -> Array:
	var resolved: Array = []
	for question: Dictionary in questions:
		var limited := is_party_limited(question)
		var allowed := _allowed_parties(question, own_party, party_names)
		var candidates: Array[String] = []
		for opponent: Dictionary in eligible:
			if not limited or allowed.has(str(opponent.get("party", ""))):
				candidates.append(str(opponent.get("opp_id", "")))
		candidates.sort()

		var asker := str(question.get("asked_by", ""))
		if candidates.has(asker):
			resolved.append(question)
			continue
		if candidates.is_empty():
			# Nobody here may ask it. A question with no party limit keeps its
			# original asker (a room with no seated askers, such as a Town Hall
			# question pool used elsewhere); a party-limited one is dropped.
			if not limited:
				resolved.append(question)
			continue
		var moved := question.duplicate()
		moved["asked_by"] = candidates[absi(hash(str(question.get("id", "")))) % candidates.size()]
		resolved.append(moved)
	return resolved


## Whether the question names any party in its Asked By Party cell.
static func is_party_limited(question: Dictionary) -> bool:
	var raw: Variant = question.get("asked_by_parties")
	return raw is Array and not (raw as Array).is_empty()


## The party names a question may be asked by (meaningful only when it is
## party-limited; OWN with no player party yet matches nobody).
static func _allowed_parties(question: Dictionary, own_party: String,
		party_names: Dictionary) -> Array[String]:
	var names: Array[String] = []
	var raw: Variant = question.get("asked_by_parties")
	if not (raw is Array):
		return names
	for party_id in (raw as Array):
		var id := str(party_id).strip_edges()
		if id == OWN:
			if not own_party.is_empty():
				names.append(own_party)
		elif party_names.has(id):
			names.append(str(party_names[id]))
	return names
