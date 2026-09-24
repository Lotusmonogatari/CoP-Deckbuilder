extends GutTest
## BattleEngine's side of items (design/proposals/inventory.md): the five
## stage effects applied at setup (an item used in the Office for "the next
## stage") and mid-stage (use_item()), and the per-turn cap on using one.


func _engine(bonuses: Dictionary = {}) -> BattleEngine:
	var stage := DataDB.get_stage("ST02").duplicate(true)
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST02")[0]]
	var config := BattleSetup.for_playtest_stage(stage)
	config["item_bonuses"] = bonuses
	config["seed"] = 7
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "%s" % [engine.setup_problems])
	return engine


# ---------------------------------------------------------------------------
# At setup — used in the Office, landing on the next stage
# ---------------------------------------------------------------------------

func test_energy_at_setup_raises_every_turns_allowance() -> void:
	var plain := _engine()
	var boosted := _engine({"ENERGY": 1})
	assert_eq(boosted.state.energy_per_turn, plain.state.energy_per_turn + 1)
	assert_eq(boosted.state.energy, plain.state.energy + 1, "the first turn too")


func test_guard_at_setup_starts_banked_and_capped() -> void:
	assert_eq(_engine({"GUARD": 2}).state.block, 2)
	var capped := _engine({"GUARD": 99})
	assert_eq(capped.state.block, capped.state.guard_cap)


func test_draw_at_setup_raises_the_hand() -> void:
	var plain := _engine()
	var boosted := _engine({"DRAW": 1})
	assert_eq(boosted.state.hand_size, plain.state.hand_size + 1)
	assert_eq(boosted.state.hand.size(), plain.state.hand.size() + 1)


func test_turns_at_setup_extend_the_clock_and_its_caption() -> void:
	var plain := _engine()
	var boosted := _engine({"TURNS": 2})
	assert_eq(boosted.turn_limit(), plain.turn_limit() + 2)
	assert_string_contains(boosted.turn_caption(), str(plain.turn_limit() + 2))


func test_gaffe_cap_at_setup_raises_the_limit() -> void:
	assert_eq(_engine({"GAFFE_CAP": 1}).state.gaffe_limit, _engine().state.gaffe_limit + 1)


# ---------------------------------------------------------------------------
# Mid-stage — use_item()
# ---------------------------------------------------------------------------

func test_using_energy_mid_stage_tops_up_now_and_every_turn_after() -> void:
	var engine := _engine()
	var before := engine.state.energy
	var per_turn := engine.state.energy_per_turn
	assert_true(engine.use_item("SH04", [{"token": "ENERGY", "amount": 1}], 1)["ok"])
	assert_eq(engine.state.energy, before + 1)
	assert_eq(engine.state.energy_per_turn, per_turn + 1)


func test_using_draw_mid_stage_deals_the_card_now() -> void:
	var engine := _engine()
	var held := engine.state.hand.size()
	engine.use_item("SH06", [{"token": "DRAW", "amount": 1}], 1)
	assert_eq(engine.state.hand.size(), held + 1)


func test_using_guard_turns_and_gaffe_cap_mid_stage() -> void:
	var engine := _engine()
	var limit := engine.turn_limit()
	var gaffe_limit := engine.state.gaffe_limit
	engine.use_item("SHX", [
		{"token": "GUARD", "amount": 1},
		{"token": "TURNS", "amount": 1},
		{"token": "GAFFE_CAP", "amount": 1},
	], 1)
	assert_eq(engine.state.block, 1)
	assert_eq(engine.turn_limit(), limit + 1)
	assert_eq(engine.state.gaffe_limit, gaffe_limit + 1)


func test_an_item_is_used_at_most_its_per_turn_cap() -> void:
	var engine := _engine()
	var effect := [{"token": "GUARD", "amount": 1}]
	assert_true(engine.use_item("SH08", effect, 1)["ok"])
	var second := engine.use_item("SH08", effect, 1)
	assert_false(second["ok"])
	assert_eq(second["reason"], Text.say("item.refused.turn_limit"))


func test_a_raised_per_turn_cap_allows_more_uses() -> void:
	var engine := _engine()
	var effect := [{"token": "GUARD", "amount": 1}]
	assert_true(engine.use_item("SH08", effect, 2)["ok"])
	assert_true(engine.use_item("SH08", effect, 2)["ok"])
	assert_false(engine.use_item("SH08", effect, 2)["ok"])


func test_the_per_turn_cap_resets_when_the_turn_ends() -> void:
	var engine := _engine()
	var effect := [{"token": "GUARD", "amount": 1}]
	engine.use_item("SH08", effect, 1)
	engine.end_turn()
	if engine.state.is_over():
		return   # the opponent's reply ended it; nothing left to check
	assert_true(engine.use_item("SH08", effect, 1)["ok"], "a new turn, a new use")


func test_using_an_item_is_not_a_card_play() -> void:
	# Free, and not a play — so it neither costs energy nor saves the
	# player from the pass penalty (Cameron, 2026-09-25).
	var engine := _engine()
	var energy := engine.state.energy
	engine.use_item("SH08", [{"token": "GUARD", "amount": 1}], 1)
	assert_eq(engine.state.cards_played_this_turn, 0)
	assert_eq(engine.state.energy, energy)


func test_an_item_cannot_be_used_once_the_stage_is_over() -> void:
	var engine := _engine()
	engine.state.outcome = "win"
	var result := engine.use_item("SH08", [{"token": "GUARD", "amount": 1}], 1)
	assert_false(result["ok"])
	assert_eq(result["reason"], Text.say("item.refused.battle_over"))
