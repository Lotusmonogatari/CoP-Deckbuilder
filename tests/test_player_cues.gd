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


# --- Bill-room replies by question kind (2026-11-01) --------------------------

func _reply(cue_id: String, kind: String, stance: Variant, line: String) -> Dictionary:
	return {"cue_id": cue_id, "suit": _suit(), "verb": null, "stage_ids": null,
		"stance": stance, "reply_kinds": [kind], "cue_1": line}


func test_a_reply_for_the_question_kind_comes_before_the_bills_own_lines() -> void:
	var bill_line := {"cue_id": "PL02", "suit": _suit(), "verb": null, "stage_ids": null,
		"bill_ids": ["BI01"], "stance": null, "cue_1": "Bill slogan."}
	DataDB.player_cues = [_reply("PL01", "Cost", "Support", "It is worth the price."), bill_line]
	DataDB._build_lookups()
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"gained": 2}, "BI01", "Support", "Cost")["text"],
		"It is worth the price.")
	# Another kind of question, or no kind, falls back to the bill's lines.
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"gained": 2}, "BI01", "Support", "Risk")["text"],
		"Bill slogan.")
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {"gained": 2}, "BI01", "Support", "")["text"],
		"Bill slogan.")


func test_a_reply_follows_the_players_lean_and_a_blank_lean_reads_the_neutral_lines() -> void:
	DataDB.player_cues = [_reply("PL01", "Cost", "Support", "For it."),
		_reply("PL02", "Cost", "Oppose", "Against it."),
		_reply("PL03", "Cost", null, "Weighing it.")]
	DataDB._build_lookups()
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {}, "BI01", "Oppose", "Cost")["text"], "Against it.")
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {}, "BI01", "", "Cost")["text"], "Weighing it.")


func test_a_reply_line_never_speaks_outside_a_bill_room() -> void:
	DataDB.player_cues = [_reply("PL01", "Cost", null, "Weighing it.")]
	DataDB._build_lookups()
	DataDB.card_cues[CARD] = ["Card's own line."] as Array[String]
	assert_eq(CardCues.for_card(CARD, "ST02", 1, {}, "", "", "Cost")["text"], "Card's own line.")


func test_the_bill_name_is_full_on_about_a_quarter_of_lines() -> void:
	var name := str(DataDB.floor_votes["BI01"].get("bill_name", ""))
	var full := 0
	var short := 0
	for index in range(400):
		var text := CardCues.fill_bill("{Bill} matters.", "BI01", index * 37)
		if text == "The %s matters." % name:
			full += 1
		elif text == "The Act matters." or text == "The bill matters.":
			short += 1
	assert_eq(full + short, 400, "every line says either the full name or a short one")
	var chance := int(DataDB.balance.get("player_cues_full_bill_name_chance", 25))
	assert_almost_eq(float(full) / 400.0 * 100.0, float(chance), 8.0)


func test_every_reply_kind_asked_has_lines_in_every_style() -> void:
	var kinds := {}
	for q: Variant in DataDB.questions.get("stage", []):
		if q is Dictionary and str(q.get("reply_kind", "")) != "":
			kinds[str(q["reply_kind"])] = true
	assert_gt(kinds.size(), 0, "Stage Questions carry Reply Kinds")
	for kind: String in kinds:
		for suit: Variant in DataDB.suits:
			var suit_name := str(suit.get("element", "")) if suit is Dictionary else str(suit)
			for lean in ["Support", "Oppose", ""]:
				assert_false(DataDB.get_reply_player_cue_lines(kind, suit_name, lean).is_empty(),
					"%s / %s / '%s' has reply lines" % [kind, suit_name, lean])
