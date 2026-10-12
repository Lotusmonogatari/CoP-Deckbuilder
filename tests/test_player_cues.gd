extends GutTest
## Player Cues (2026-10-12): what the player says by the suit of the card and
## what it did, before falling back to the card's own Flavor Text lines.
## Fake rows throughout, the same way test_opponent_cues.gd works.

var _cues_before: Array = []
var _card_cues_before: Dictionary = {}

const CARD := "C01"


func before_each() -> void:
	_cues_before = DataDB.player_cues.duplicate(true)
	_card_cues_before = DataDB.card_cues.duplicate(true)


func after_each() -> void:
	DataDB.player_cues = _cues_before.duplicate(true)
	DataDB.card_cues = _card_cues_before.duplicate(true)
	DataDB._build_lookups()


func _suit() -> String:
	return str(DataDB.get_card(CARD).get("suit", ""))


func _row(cue_id: String, verb: Variant, stages: Variant, line: String) -> Dictionary:
	return {"cue_id": cue_id, "suit": _suit(), "verb": verb, "stage_ids": stages,
		"cue_1": line, "cue_2": null}


func test_the_verb_follows_what_the_card_did() -> void:
	assert_eq(CardCues.verb_for({"opponent_lost": 2, "gained": 3}), "attack")
	assert_eq(CardCues.verb_for({"gained": 3, "guard": 1}), "gain")
	assert_eq(CardCues.verb_for({"guard": 1}), "block")
	assert_eq(CardCues.verb_for({}), "")


func test_with_nothing_written_the_card_keeps_its_own_lines() -> void:
	DataDB.player_cues = []
	DataDB._build_lookups()
	DataDB.card_cues[CARD] = ["Card's own line."] as Array[String]
	var cue := CardCues.for_card(CARD, "ST02", 1, {"gained": 2})
	assert_eq(cue["text"], "Card's own line.")


func test_a_suit_line_is_used_before_the_cards_own() -> void:
	DataDB.player_cues = [_row("PL01", "gain", null, "Suit gain line.")]
	DataDB._build_lookups()
	DataDB.card_cues[CARD] = ["Card's own line."] as Array[String]
	var cue := CardCues.for_card(CARD, "ST02", 1, {"gained": 2})
	assert_eq(cue["text"], "Suit gain line.")
	assert_eq(cue["line_id"], "PL01_1")


func test_a_different_verb_does_not_match() -> void:
	DataDB.player_cues = [_row("PL01", "block", null, "Suit block line.")]
	DataDB._build_lookups()
	DataDB.card_cues[CARD] = ["Card's own line."] as Array[String]
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"gained": 2})["text"], "Card's own line.")


func test_a_blank_verb_fits_any_card() -> void:
	DataDB.player_cues = [_row("PL01", null, null, "Any-verb line.")]
	DataDB._build_lookups()
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"guard": 1})["text"], "Any-verb line.")
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {})["text"], "Any-verb line.")


func test_a_stage_line_wins_in_its_own_stage_only() -> void:
	DataDB.player_cues = [
		_row("PL01", "gain", null, "Anywhere line."),
		_row("PL02", "gain", ["ST16"], "Finance line."),
	]
	DataDB._build_lookups()
	assert_eq(CardCues.for_card(CARD, "ST16", 1, {"gained": 2})["text"], "Finance line.")
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"gained": 2})["text"], "Anywhere line.")


func test_the_real_tab_loads_without_error() -> void:
	# Ships empty; this only proves the file is there and reads as rows.
	assert_true(DataDB.player_cues is Array)
