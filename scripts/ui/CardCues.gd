class_name CardCues
extends RefCounted
## What the player says out loud when they play a card.
##
## Cameron wrote five spoken lines for each of the 54 cards, in the
## workbook's Flavor Text tab. One of them is shown when the card lands,
## through the same queue as everything else the screen says in passing.
##
## THE CHOICE IS NOT RANDOM. It is worked out from the card, the stage and
## the turn, so the same card on the same turn of the same stage always says
## the same thing, and the same card twice in one stage does not. That gets
## the variety without a generator to seed, and without touching the
## engine's own, whose stream the deck order depends on.
##
## This is presentation. The rules never see a cue, and a card with none
## written yet simply says nothing — the same bargain ArtLoader strikes with
## art that has not been drawn.

## Who is speaking: the chosen protagonist's ID, which is also their key in
## sounds.json's speech table.
static func speaker() -> String:
	return str(DataDB.player.get("player_id", ""))


## One of the card's lines for this moment: what is said, and the key a
## recording of it would live under in data/sounds.json.
##
## Comes back empty where the card has no cues written, which is what the
## screen checks before it says anything.
##
## FIRST the Player Cues tab (2026-10-12): lines written for the card's suit
## and for what it just did (`applied`, BattleEngine.play_card()'s own
## record), most specific first — this stage, then any stage
## (DataDB.get_player_cue_lines()). Only when nothing is written there does
## the card fall back to its own five Flavor Text lines, so nothing goes
## quiet while the new tab is being filled in.
##
## In a bill room (2026-11-01) the question just asked comes first: a reply
## written for its Reply Kind (Cost, Evidence, ...) in the card's suit and the
## player's lean, so the answer fits the question. The bill's own lines follow
## when the question has no kind or no reply is written for it.
static func for_card(card_id: String, stage_id: String, turn: int,
		applied: Dictionary = {}, bill_id: String = "", lean: String = "",
		reply_kind: String = "") -> Dictionary:
	var suit := str(DataDB.get_card(card_id).get("suit", ""))
	if not suit.is_empty() and not bill_id.is_empty() and not reply_kind.is_empty():
		var replies: Array = DataDB.get_reply_player_cue_lines(reply_kind, suit, lean)
		if not replies.is_empty():
			var index := _index_for(card_id, stage_id, turn)
			var reply: Dictionary = replies[index % replies.size()]
			return {"text": fill_bill(str(reply.get("text", "")), bill_id, index),
					"line_id": str(reply.get("line_id", ""))}
	if not suit.is_empty() and not bill_id.is_empty():
		# A level about a bill (2026-10-18): lines written for that bill, and
		# for the lean the player took, come before every other tier.
		var about_bill: Array = DataDB.get_bill_player_cue_lines(bill_id, suit, verb_for(applied), lean)
		# Now and then the room's own topic line on the player's side instead
		# (Balance "Player Cues: Room Line Chance"; Cameron, 2026-11-09).
		var room_lines: Array = DataDB.get_room_player_cue_lines(stage_id, suit, verb_for(applied), lean)
		var moment := _index_for(card_id, stage_id, turn)
		if not room_lines.is_empty() and use_room_line(moment, int(DataDB.balance.get("player_cues_room_line_chance", 0))):
			var room: Dictionary = room_lines[(moment / 100) % room_lines.size()]
			return {"text": str(room.get("text", "")), "line_id": str(room.get("line_id", ""))}
		if not about_bill.is_empty():
			var chosen: Dictionary = about_bill[_index_for(card_id, stage_id, turn) % about_bill.size()]
			return {"text": str(chosen.get("text", "")), "line_id": str(chosen.get("line_id", ""))}
	if not suit.is_empty():
		var by_suit: Array = DataDB.get_player_cue_lines(suit, verb_for(applied), stage_id)
		if not by_suit.is_empty():
			var picked: Dictionary = by_suit[_index_for(card_id, stage_id, turn) % by_suit.size()]
			return {"text": str(picked.get("text", "")), "line_id": str(picked.get("line_id", ""))}

	var lines: Array = DataDB.card_cues.get(card_id, [])
	if lines.is_empty():
		return {"text": "", "line_id": ""}

	var which := _index_for(card_id, stage_id, turn) % lines.size()
	return {
		"text": str(lines[which]),
		# The same numbering the workbook uses: Cue 1 is _1, not _0.
		"line_id": "%s_%d" % [card_id, which + 1],
	}


## True on roughly `chance` percent of moments: whether a room line is used.
## Worked out from the moment's stable number, so a moment always reads the same.
static func use_room_line(moment: int, chance: int) -> bool:
	return chance > 0 and (moment % 100) < chance


## A reply line with the bill's name put in. {bill} and {Bill} (the same, at
## the start of a sentence) become the bill's full name on roughly the
## Balance tab's "Player Cues: Full Bill Name Chance" percent of lines, and
## "the Act" / "the bill" (or "the Agreement", for a bill so named) on the
## rest — a full title in every line reads like a press release. Which one is
## worked out from the same stable number that chose the line, so a moment
## always reads the same way.
static func fill_bill(text: String, bill_id: String, index: int) -> String:
	if not ("{bill}" in text or "{Bill}" in text):
		return text
	var name := _bill_name_for(bill_id)
	var chance := int(DataDB.balance.get("player_cues_full_bill_name_chance", 25))
	# Half the short mentions say "the Act" and half "the bill", for a bill named so.
	var use_full := not name.is_empty() and (index % 100) < chance
	var lower := BillName.phrase(name) if use_full else BillName.short(name, index / 100)
	var upper := lower.substr(0, 1).to_upper() + lower.substr(1)
	return text.replace("{Bill}", upper).replace("{bill}", lower)


## The bill's own name: a floor vote bill's, or a patron or drafted bill's.
static func _bill_name_for(bill_id: String) -> String:
	return str((DataDB.floor_votes.get(bill_id, {}) as Dictionary).get("bill_name", ""))


## What a played card did, in the Player Cues tab's own words — the same
## attack / gain / block the Opponent Cues tab uses, read in the same order
## the player's portrait reacts (PlayerPortraitPresenter.face_for_card()):
## arguing the room away beats winning it over beats banking guard. "" when
## the card did none of the three (a draw, a special), which matches only
## a row whose Verb is blank.
static func verb_for(applied: Dictionary) -> String:
	if int(applied.get("opponent_lost", 0)) > 0:
		return "attack"
	if int(applied.get("gained", 0)) > 0:
		return "gain"
	if int(applied.get("guard", 0)) > 0:
		return "block"
	return ""


## Which of the five, as a number that is stable for a given moment.
##
## hash() over the three things that identify the moment. absi() because a
## negative hash would index backwards through the list, which is legal in
## GDScript and would quietly halve the variety.
static func _index_for(card_id: String, stage_id: String, turn: int) -> int:
	return absi(hash("%s|%s|%d" % [card_id, stage_id, turn]))
