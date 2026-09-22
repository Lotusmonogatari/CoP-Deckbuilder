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

## The player's constant name in the speech table. Not a character name:
## who the protagonist is remains open, and CLAUDE.md says not to decide it.
const SPEAKER := "PROTAGONIST"


## One of the card's lines for this moment: what is said, and the key a
## recording of it would live under in data/sounds.json.
##
## Comes back empty where the card has no cues written, which is what the
## screen checks before it says anything.
static func for_card(card_id: String, stage_id: String, turn: int) -> Dictionary:
	var lines: Array = DataDB.card_cues.get(card_id, [])
	if lines.is_empty():
		return {"text": "", "line_id": ""}

	var which := _index_for(card_id, stage_id, turn) % lines.size()
	return {
		"text": str(lines[which]),
		# The same numbering the workbook uses: Cue 1 is _1, not _0.
		"line_id": "%s_%d" % [card_id, which + 1],
	}


## Which of the five, as a number that is stable for a given moment.
##
## hash() over the three things that identify the moment. absi() because a
## negative hash would index backwards through the list, which is legal in
## GDScript and would quietly halve the variety.
static func _index_for(card_id: String, stage_id: String, turn: int) -> int:
	return absi(hash("%s|%s|%d" % [card_id, stage_id, turn]))
