extends GutTest
## What a card's face SAYS against what playing it DOES (2026-11-02, Cameron:
## "Work the Room First" often showed no "+2" line though its effect worked).
##
## For every real card, in several real rooms and in different situations, the
## face (CardView.describe_effect() on the engine's own preview) must carry every
## number and effect the card will have when played, and the played result must
## match the preview, the cost charged must match the cost shown, and the cards
## discarded must match the count on the face.

const ROOMS := ["ST02", "ST01", "ST04", "ST05", "ST06", "ST03"]
const SEED := 20261102


func _config_for(stage_id: String) -> Dictionary:
	for level: Dictionary in DataDB.levels:
		for i in range(1, 11):
			if str(level.get("stage_%d" % i, "")) == stage_id:
				var config := BattleSetup.for_level_stage(str(level.get("level_id", "")), stage_id)
				if not config.is_empty():
					return config
	return {}


## An engine whose hand is `card_id` plus four plain cards to discard, with
## energy to spare. `situation` bends the room: "ahead", "behind", "gaffe".
func _engine(stage_id: String, card_id: String, situation: String) -> BattleEngine:
	var config := _config_for(stage_id)
	config["seed"] = SEED
	var engine := BattleEngine.new()
	if not engine.setup(config):
		return null
	var hand: Array[String] = [card_id]
	for filler in ["C01", "C02", "C03", "C04"]:
		if filler != card_id:
			hand.append(filler)
	engine.state.hand.assign(hand)
	engine.state.energy = 9
	if engine.state.bar != null and situation != "":
		match situation:
			"behind":
				engine.state.bar.player = 5
				engine.state.bar.opponent = 40
			"ahead":
				engine.state.bar.player = 40
				engine.state.bar.opponent = 5
			"gaffe":
				engine.state.gaffe = 2
	return engine


func _special_marker(card: Dictionary) -> String:
	## A distinctive piece of the sentence each OUTCOME effect must put on the face.
	## The conditional bonuses that move the card's own number are deliberately not
	## said on the face (Cameron, 2026-11-02): the back explains them.
	var key := str(card.get("special", "")) if card.get("special") != null else ""
	match key:
		"buff_next_card_this_turn": return "next card this turn gets"
		"discount_next_card_this_turn": return "next card this turn costs"
		"reveal_next_intent": return "Reveal the opponent"
	return ""


func test_every_cards_face_carries_all_it_will_do_and_the_play_matches() -> void:
	var checked := 0
	for room in ROOMS:
		if _config_for(room).is_empty():
			continue
		for situation in ["", "behind", "ahead", "gaffe"]:
			for card: Dictionary in DataDB.cards:
				var card_id := str(card.get("card_id", ""))
				var engine := _engine(room, card_id, situation)
				if engine == null:
					continue
				var where := "%s %s in %s (%s)" % [card_id, card.get("name_en"), room, situation]
				var live: Dictionary = engine.card_by_id(card_id) if engine.has_method("card_by_id") else DataDB.get_card(card_id)
				var preview := engine.preview(live)
				var face := CardView.describe_effect(preview, live)

				# 1. The face says every number the card will use.
				if int(preview.get("self_plus", 0)) != 0:
					assert_string_contains(face, Text.say("card.gain", {"count": int(preview["self_plus"])}), where)
				if int(preview.get("opp_minus", 0)) != 0 and bool(preview.get("opp_minus_counts", true)):
					assert_string_contains(face, Text.say("card.opponent", {"count": int(preview["opp_minus"])}), where)
				if int(preview.get("draw", 0)) != 0:
					assert_string_contains(face, Text.say("card.draw", {"count": int(preview["draw"])}), where)
				if int(preview.get("gaffe", 0)) != 0:
					assert_string_contains(face, Text.say("card.gaffe", {"amount": "%+d" % int(preview["gaffe"])}), where)

				# 2. The face says the outcome effects, and nothing about conditions.
				var marker := _special_marker(live)
				if not marker.is_empty():
					assert_string_contains(face, marker, where + ": its special effect is on the face")
				if str(live.get("special", "")) == "pierce_guard" and bool(preview.get("opp_minus_counts", true)):
					assert_string_contains(face, "Ignores", where)

				# 3. No audience conditions, no "answers this question", no bonus commentary.
				for banned in ["more to gain", "Includes +", "Doubled", "≥", "Answers this question", "trail the opponent", "gaffe meter is 0"]:
					assert_false(face.contains(banned), where + ": the face does not say '%s'" % banned)

				# 4. Playing it does what the preview said, at the cost shown.
				var energy_before := engine.state.energy
				var shown_cost := engine.card_cost(live)
				var discards: Array = []
				var needed := engine.discard_required(live)
				var rest: Array = engine.state.hand.duplicate()
				rest.erase(card_id)
				for i in needed:
					if i < rest.size():
						discards.append(rest[i])
				if not str(engine.play_block(live)).is_empty():
					continue
				var result := engine.play_card(card_id, discards)
				if not result.get("ok", false):
					continue
				var played: Dictionary = result.get("effect", {})
				for number in ["self_plus", "opp_minus", "guard", "draw", "gaffe"]:
					assert_eq(int(played.get(number, 0)), int(preview.get(number, 0)), where + ": played %s matches the face" % number)
				for flag in ["next_card_bonus", "next_card_discount", "pierce_guard", "reveal_next_intent"]:
					assert_eq(played.get("flags", {}).get(flag), preview.get("flags", {}).get(flag), where + ": played flag %s matches" % flag)
				# (A card that wins the bout starts the next one on fresh energy, which says nothing about its cost.)
				if not result.has("bout_won") and not engine.state.is_over():
					assert_eq(energy_before - engine.state.energy, shown_cost, where + ": the cost charged is the cost shown")
				assert_eq(discards.size(), needed, where + ": the discards match the face")
				checked += 1
	assert_gt(checked, 200, "a real sweep of cards, rooms and situations was played")


func test_work_the_room_first_says_what_it_does_even_while_a_question_is_open() -> void:
	var engine := _engine("ST05", "C11", "")
	var card := DataDB.get_card("C11")
	var preview := engine.preview(card)
	preview["answers_question"] = true
	var face := CardView.describe_effect(preview, card)
	assert_eq(face, "Your next card this turn gets +2.", "the outcome, and no line about answering the question")


func test_a_conditional_card_shows_only_its_live_number() -> void:
	# C09 Call for Unity: Gain 4, +2 more with a party audience. The face has the
	# number that will be used here; the condition is on the back.
	var engine := _engine("ST03", "C09", "")
	var card := DataDB.get_card("C09")
	var preview := engine.preview(card)
	var face := CardView.describe_effect(preview, card)
	assert_string_contains(face, "Gain %d." % int(preview["self_plus"]))
	assert_false(face.contains("Party Members"))
