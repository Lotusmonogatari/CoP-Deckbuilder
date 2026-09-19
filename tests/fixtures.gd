class_name TestFixtures
extends RefCounted
## Small, hand-written stand-ins for the real game data.
##
## The tests deliberately do NOT read data/*.json. Two reasons:
##
##   1. A test should fail when the CODE is wrong, not when Cameron rebalances
##      a card. If every test read the real numbers, tuning the workbook would
##      break the test suite, and nobody would trust it.
##
##   2. The rules engine is supposed to work on any data at all. Feeding it
##      made-up numbers is how we prove that.
##
## The values below are chosen to make the arithmetic interesting — halves
## that have to round, guards that have to survive a multiplier — rather than
## to mirror the workbook.


## A card with sensible defaults. Override anything by passing it in.
static func card(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"card_id": "TEST01",
		"name_en": "Test Card",
		"suit": "Earnest",
		"type": "Gain",
		"cost": 1,
		"self_plus": 0,
		"opp_minus": 0,
		"guard": 0,
		"draw": 0,
		"gaffe": 0,
		"target_segment": "Any",
		"target_segment_id": null,
		"special": null,
		"special_value": null,
	}
	base.merge(overrides, true)
	return base


## A combat stage with sensible defaults.
static func stage(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"stage_id": "ST02",
		"name_en": "Floor Debate",
		"mode": "Combat",
		"bar_unit": "Seats",
		"bar_max": 101,
		"win_threshold": 51,
		"turn_limit": 8,
		"energy_per_turn": 3,
		"hand_size": 5,
		"gaffe_limit": 6,
		"player_start": 40,
		"opp_start": 40,
		"segment_mix": {"SG01": 0.2, "SG02": 0.6, "SG03": 0.1, "SG04": 0.0, "SG05": 0.1},
	}
	base.merge(overrides, true)
	return base


## The five committee starting stances, as committee.json writes them.
static func committee_member(name: String, stance: String = "Undecided") -> Dictionary:
	return {"member": name, "party": "Test Party", "starting_stance": stance}


## The default switches, matching rules.json.
static func rules(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"turn_limit_outcome": "loss",
		"opponent_can_win_by_threshold": false,
		"opponent_engine": "intent_patterns",
		"press_answer_timer": false,
		"discard_hand_end_of_turn": true,
		# Distinctive numbers, so a test can tell the fallback apart from
		# whatever an opponent brought with them.
		"default_intent_pattern": [["attack", 6], ["gain", 4], ["block", 5]],
	}
	base.merge(overrides, true)
	return base


## An opponent that does the same thing every turn, so a test can predict it.
static func opponent(pattern: Array = [["attack", 5]]) -> Dictionary:
	return {
		"opp_id": "OPTEST",
		"name": "Test Opponent",
		"element_1": "Earnest",
		"element_2": "Data Driven",
		"intent_pattern": pattern,
	}


## An affinity table. Defaults to "every suit is neutral everywhere", so a
## test only has to say the multipliers it actually cares about.
static func affinity(overrides: Dictionary = {}) -> Dictionary:
	var table := {
		"Earnest": {"ST01": 1.0, "ST02": 1.0, "ST04": 1.2},
		"Emotional": {"ST01": 0.8, "ST02": 1.1, "ST05": 1.3},
		"Data Driven": {"ST01": 1.3, "ST02": 1.1, "ST04": 1.0},
		"Duplicitous": {"ST01": 1.1, "ST02": 1.0, "ST04": 0.7},
	}
	table.merge(overrides, true)
	return table


## A ready-to-play battle. Pass overrides for the parts a test cares about.
static func battle_config(overrides: Dictionary = {}) -> Dictionary:
	var cards := {
		"GAIN3": card({"card_id": "GAIN3", "self_plus": 3, "cost": 1}),
		"ATTACK3": card({"card_id": "ATTACK3", "opp_minus": 3, "cost": 1, "suit": "Data Driven"}),
		"GUARD5": card({"card_id": "GUARD5", "guard": 5, "cost": 1, "suit": "Duplicitous"}),
		"GAFFE2": card({"card_id": "GAFFE2", "self_plus": 2, "gaffe": 2, "cost": 1}),
		"DRAW2": card({"card_id": "DRAW2", "draw": 2, "cost": 1}),
	}
	var base := {
		"stage": stage(),
		"opponent": opponent(),
		"cards": cards,
		"affinity": affinity(),
		"rules": rules(),
		"meta": {"Reputation": 50},
		"deck": ["GAIN3", "GAIN3", "ATTACK3", "GUARD5", "GAFFE2", "DRAW2"],
		"seed": 12345,   # fixed, so the shuffle is the same every run
	}
	base.merge(overrides, true)
	return base
