extends GutTest
## 2026-10-16, Cameron: standing is hard to hold. Every answer counts, gains
## shrink and penalties grow as standing rises, and an organization nobody
## dealt with drifts back toward where it started.

const CFG := {
	"per_please": 5, "per_displease": 3, "per_opposed": 3, "question_swing_cap": 10,
	"instant_win_penalty": 2, "start": 30,
	"gain_bands": [{"below": 40, "factor": 1.0}, {"below": 60, "factor": 0.6}, {"factor": 0.4}],
	"loss_bands": [{"below": 60, "factor": 1.0}, {"factor": 1.5}],
}


func test_every_strong_answer_counts_not_just_the_first() -> void:
	var one := BoosterStanding.net_for({"pleased": 1}, 30, CFG)
	var two := BoosterStanding.net_for({"pleased": 2}, 30, CFG)
	assert_eq(one, 5)
	assert_eq(two, 10)


func test_a_weak_answer_costs_as_much_as_a_strong_one_gains() -> void:
	assert_eq(BoosterStanding.net_for({"displeased": 1}, 30, CFG), -3)
	assert_eq(BoosterStanding.net_for({"pleased": 1, "displeased": 1}, 30, CFG), 2)


func test_gains_shrink_as_standing_rises() -> void:
	assert_eq(BoosterStanding.net_for({"pleased": 1}, 30, CFG), 5)
	assert_eq(BoosterStanding.net_for({"pleased": 1}, 50, CFG), 3)
	assert_eq(BoosterStanding.net_for({"pleased": 1}, 70, CFG), 2)


func test_penalties_grow_at_high_standing() -> void:
	assert_eq(BoosterStanding.net_for({"displeased": 1}, 50, CFG), -3)
	assert_eq(BoosterStanding.net_for({"displeased": 1}, 70, CFG), -5)


func test_the_stage_total_is_capped_both_ways() -> void:
	assert_eq(BoosterStanding.net_for({"pleased": 9}, 30, CFG), 10)
	assert_eq(BoosterStanding.net_for({"displeased": 9}, 30, CFG), -10)


func test_a_small_amount_never_rounds_to_nothing() -> void:
	var cfg := CFG.duplicate(true)
	cfg["per_please"] = 1
	assert_eq(BoosterStanding.net_for({"pleased": 1}, 80, cfg), 1)


func test_without_a_tally_each_listed_organization_counts_once() -> void:
	var out := BoosterChange.compute(["BO01"], ["BO02"], [], CFG, ["BO03"])
	assert_eq(int(out[0]["net"]), 5)
	assert_eq(int(out[1]["net"]), -3)
	assert_eq(int(out[2]["net"]), -3)


func test_a_tally_counts_repeats_and_current_standing_sets_the_band() -> void:
	var tally := {"BO01": {"pleased": 2, "displeased": 0, "opposed": 0}}
	var low := BoosterChange.compute([], [], [], CFG, [], tally, {"BO01": 30})
	var high := BoosterChange.compute([], [], [], CFG, [], tally, {"BO01": 70})
	assert_eq(int(low[0]["net"]), 10)
	assert_eq(int(high[0]["net"]), 4, "two answers at 0.4 each")


func test_a_crushed_organization_still_pays_the_flat_penalty_on_top() -> void:
	var out := BoosterChange.compute(["BO01"], [], ["BO01"], CFG)
	assert_eq(int(out[0]["net"]), 3)


func test_decay_moves_toward_the_start_and_stops_there() -> void:
	assert_eq(BoosterStanding.decayed(50, 30, 1), 49)
	assert_eq(BoosterStanding.decayed(10, 30, 1), 11)
	assert_eq(BoosterStanding.decayed(30, 30, 1), 30)
	assert_eq(BoosterStanding.decayed(31, 30, 5), 30, "never overshoots")
	assert_eq(BoosterStanding.decayed(50, 30, 0), 50, "zero turns it off")


func test_the_engine_counts_every_strong_answer() -> void:
	var config := TestFixtures.battle_config({"stage": TestFixtures.stage({
		"stage_id": "PT_S2", "draw_mode": "none", "opening_hand": 6,
		"bar_max": 100, "win_threshold": 90, "player_start": 45, "opp_start": 45,
		"gaffe_limit": 4, "questions_per_turn": 2,
		"questions": [
			{"id": "Q1", "text": "1", "prefers_suit": "Earnest", "pleases_boosters": ["BO08"]},
			{"id": "Q2", "text": "2", "prefers_suit": "Earnest", "pleases_boosters": ["BO08"]}]}),
		"opponent": TestFixtures.opponent([["block", 1]])})
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "setup failed")
	var card := TestFixtures.card({"card_id": "E1", "suit": "Earnest", "cost": 0})
	engine._answer_question(card)
	engine._answer_question(card)
	assert_eq(int(engine.booster_tally()["BO08"]["pleased"]), 2)
	assert_eq(engine.pleased_boosters().size(), 1, "the icon list stays one per organization")


func test_an_organization_nobody_dealt_with_drifts_toward_its_start() -> void:
	GameState.reset_booster_standing()
	GameState.booster_standing["BO05"] = 50
	GameState.booster_standing["BO09"] = 10
	GameState.booster_standing["BO03"] = 50
	GameState.booster_moved_in_period = {"BO03": true}
	GameState._apply_neglect_decay()
	assert_eq(int(GameState.booster_standing["BO05"]), 49)
	assert_eq(int(GameState.booster_standing["BO09"]), 11)
	assert_eq(int(GameState.booster_standing["BO03"]), 50, "dealt with since decay last ran, so left alone")
