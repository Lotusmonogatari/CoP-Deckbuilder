extends GutTest
## Cards that make you discard (2026-10-21): "discard to play" (a cost) and
## "discard for draw" (cycling), plus the 20% audience scale.


func _engine(extra: Dictionary = {}, overrides: Dictionary = {}) -> BattleEngine:
	var config := TestFixtures.battle_config(overrides)
	var cards: Dictionary = config["cards"]
	cards["CYCLE"] = TestFixtures.card({"card_id": "CYCLE", "cost": 1, "draw": 2, "discard_for_draw": 1})
	cards["SAC2"] = TestFixtures.card({"card_id": "SAC2", "cost": 1, "self_plus": 10, "discard_to_play": 2})
	cards["SAC1"] = TestFixtures.card({"card_id": "SAC1", "cost": 1, "self_plus": 12, "discard_to_play": 1})
	for id: String in extra:
		cards[id] = extra[id]
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "setup failed: %s" % [engine.setup_problems])
	return engine


func test_a_cycle_card_discards_the_chosen_card_then_draws() -> void:
	var engine := _engine()
	engine.state.deck.assign(["GAIN3", "ATTACK3", "GUARD5"])
	engine.state.hand.assign(["CYCLE", "GAFFE2", "GAIN3"])
	var result := engine.play_card("CYCLE", ["GAFFE2"])
	assert_true(result["ok"], str(result.get("reason", "")))
	assert_false(engine.state.hand.has("GAFFE2"), "the chosen card left the hand")
	assert_true(engine.state.discard.has("GAFFE2"))
	assert_eq(engine.state.hand.size(), 3, "GAIN3 stayed and two were drawn")
	assert_eq(result["discarded"], ["GAFFE2"])


func test_a_discard_to_play_card_needs_exactly_its_number() -> void:
	var engine := _engine()
	engine.state.hand.assign(["SAC2", "GAIN3", "GAIN3", "GUARD5"])
	var short := engine.play_card("SAC2", ["GAIN3"])
	assert_false(short["ok"], "one discard is not two")
	assert_true(engine.state.hand.has("SAC2"), "a refused card stays in hand")
	assert_eq(engine.state.energy, 3, "and nothing is paid")
	var done := engine.play_card("SAC2", ["GAIN3", "GUARD5"])
	assert_true(done["ok"])
	assert_eq(engine.state.hand, ["GAIN3"] as Array[String])
	assert_eq(engine.state.discard.size(), 3, "the played card and two discards")


func test_the_discards_must_come_from_the_rest_of_the_hand() -> void:
	var engine := _engine()
	engine.state.hand.assign(["SAC1", "GAIN3"])
	assert_false(engine.play_card("SAC1", ["SAC1"])["ok"], "the card cannot discard itself")
	assert_false(engine.play_card("SAC1", ["ATTACK3"])["ok"], "a card not in hand cannot be discarded")
	assert_true(engine.play_card("SAC1", ["GAIN3"])["ok"])


func test_a_card_that_discards_nothing_refuses_discards() -> void:
	var engine := _engine()
	engine.state.hand.assign(["GAIN3", "GAIN3"])
	assert_false(engine.play_card("GAIN3", ["GAIN3"])["ok"])


func test_too_few_cards_blocks_the_card_in_preview() -> void:
	var engine := _engine()
	engine.state.hand.assign(["SAC2", "GAIN3"])
	var preview := engine.preview(engine._cards["SAC2"])
	assert_eq(preview["needs_discard"], 2)
	assert_eq(preview["play_block"], "few_cards")
	assert_false(engine.play_card("SAC2", ["GAIN3"])["ok"])


func test_a_room_that_does_not_refill_the_hand_blocks_discard_cards() -> void:
	var engine := _engine({}, {"stage": TestFixtures.stage({"draw_mode": "none"})})
	engine.state.hand.assign(["CYCLE", "GAIN3", "GAIN3"])
	assert_eq(engine.preview(engine._cards["CYCLE"])["play_block"], "no_refill")
	assert_false(engine.play_card("CYCLE", ["GAIN3"])["ok"])


func test_the_audience_scale_adds_one_per_twenty_percent_up_to_five() -> void:
	var base := {"self_plus": 4, "flags": {}}
	for case: Array in [[0.0, 0], [0.19, 0], [0.2, 1], [0.5, 2], [0.6, 3], [1.0, 5]]:
		var out := SpecialEffects.apply("scale_per_20_target_segment", 1, base, {"segment_share": case[0]})
		assert_eq(int(out["self_plus"]) - 4, int(case[1]), "share %s" % case[0])


func test_the_audience_scale_never_passes_five_either_way() -> void:
	var base := {"self_plus": 4, "flags": {}}
	assert_eq(int(SpecialEffects.apply("scale_per_20_target_segment", 3, base, {"segment_share": 1.0})["self_plus"]), 9)
	assert_eq(int(SpecialEffects.apply("scale_per_20_target_segment", -3, base, {"segment_share": 1.0})["self_plus"]), -1)


func test_the_real_discard_cards_follow_the_tier_and_suit_rules() -> void:
	var suits := ["Duplicitous", "Divisive", "Emotional", "Data Driven"]
	var counts := {"cycle": 0, "play": 0}
	for card: Dictionary in DataDB.cards:
		var to_play := int(card.get("discard_to_play") if card.get("discard_to_play") != null else 0)
		var for_draw := int(card.get("discard_for_draw") if card.get("discard_for_draw") != null else 0)
		if to_play == 0 and for_draw == 0:
			continue
		assert_true(suits.has(str(card["suit"])), "%s suit" % card["card_id"])
		assert_true(["1", "2"].has(str(card["tier"])), "%s is not Tier 0 or 3" % card["card_id"])
		if to_play > 0:
			counts["play"] += 1
			assert_eq(to_play, 2 if str(card["tier"]) == "1" else 1, str(card["card_id"]))
		if for_draw > 0:
			counts["cycle"] += 1
			assert_eq(for_draw, 1)
			assert_lte(int(card["draw"]), 1 if str(card["tier"]) == "1" else 2, str(card["card_id"]))
			assert_gte(int(card["draw"]), 1)
	assert_eq(counts["cycle"], 8, "one cycle card per suit and tier")
	assert_eq(counts["play"], 8, "one discard-to-play card per suit and tier")
