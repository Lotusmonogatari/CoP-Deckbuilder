extends Node
## Fuzzes the seven purchase-time Supplies effects built for SH13-19 (and,
## for comparison, the pre-existing SH27-29 they were modeled on): random
## XP/Funds/ownership states, hundreds of purchases each, checking
## invariants after every single call rather than a few hand-picked
## scenarios — the same shape as tools/stress_crisis_triggers.gd.
##
##     godot --headless --path . tools/stress_shot_items.tscn
##     (actual scene name: tools/stress_shop_items.tscn)
##
## Not part of tools/verify.sh — a debugging pass, not a fixed regression
## test (no fixed seed on purpose, so a bad run can be reported and then
## reproduced by hand with the printed state).

const ITERATIONS := 400

var _failures: Array[String] = []
var _iterations_run := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	randomize()
	_reset_state()

	for i in range(ITERATIONS):
		_iterations_run = i + 1
		match randi() % 7:
			0: _try_buy_random_card()
			1: _try_buy_random_level()
			2: _try_recruitment_tier()
			3: _try_funds_cap()
			4: _occasionally_drain_ownership()
			5: _occasionally_scramble_funds_and_xp()
			6: _occasionally_reset_a_field()
		if not _failures.is_empty():
			break

	_report()


func _reset_state() -> void:
	GameState.owned_cards = []
	GameState.levels_unlocked = []
	GameState.staff_recruitment_tier = 0
	GameState.funds_cap_bonus = 0
	GameState.xp = randi_range(0, 3000)
	GameState.meta["Funds"] = randi_range(0, 200000)
	GameState.shop_bought_this_level = {}


# ---------------------------------------------------------------------------
# The seven effects under test
# ---------------------------------------------------------------------------

func _try_buy_random_card() -> void:
	var item_id: String = ["SH15", "SH16", "SH17", "SH27", "SH28", "SH29"][randi() % 6]
	var item := DataDB.get_shop_item(item_id)
	var tier := int(item.get("card_tier", 0))
	var owned_before := GameState.owned_cards.duplicate()
	var xp_before := GameState.xp
	var funds_before := int(GameState.meta.get("Funds", 0))

	var result := GameState.buy_random_card(item_id)

	if result.get("ok", false):
		var added: Array[String] = []
		for card_id: String in GameState.owned_cards:
			if not owned_before.has(card_id):
				added.append(card_id)
		if added.size() != 1:
			_fail("%s: a successful buy changed owned_cards by %d, not 1" % [item_id, added.size()])
			return
		var card := DataDB.get_card(added[0])
		if int(card.get("tier", -1)) != tier:
			_fail("%s: granted %s, which is Tier %s, not Tier %d"
				% [item_id, added[0], card.get("tier"), tier])
		if owned_before.has(added[0]):
			_fail("%s: granted a card (%s) the player already owned" % [item_id, added[0]])
	else:
		if GameState.owned_cards != owned_before:
			_fail("%s: a refused buy still changed owned_cards" % item_id)
		if GameState.xp != xp_before or int(GameState.meta.get("Funds", 0)) != funds_before:
			_fail("%s: a refused buy still spent something" % item_id)
	if str(result.get("message", "")).is_empty():
		_fail("%s: buy_random_card() returned no message either way" % item_id)


func _try_buy_random_level() -> void:
	var item_id: String = ["SH13", "SH14"][randi() % 2]
	var item := DataDB.get_shop_item(item_id)
	var tier := int(item.get("level_tier", 0))
	var unlocked_before := GameState.levels_unlocked.duplicate()
	var xp_before := GameState.xp

	var result := GameState.buy_random_level(item_id)

	if result.get("ok", false):
		var added: Array[String] = []
		for level_id: String in GameState.levels_unlocked:
			if not unlocked_before.has(level_id):
				added.append(level_id)
		if added.size() != 1:
			_fail("%s: a successful buy changed levels_unlocked by %d, not 1" % [item_id, added.size()])
			return
		var level := DataDB.get_level(added[0])
		if int(level.get("tier", -1)) != tier:
			_fail("%s: unlocked %s, which is Tier %s, not Tier %d"
				% [item_id, added[0], level.get("tier"), tier])
		if GameState.xp >= xp_before:
			_fail("%s: a successful buy did not spend XP (%d -> %d)" % [item_id, xp_before, GameState.xp])
	else:
		if GameState.levels_unlocked != unlocked_before:
			_fail("%s: a refused buy still changed levels_unlocked" % item_id)
		if GameState.xp != xp_before:
			_fail("%s: a refused buy still spent XP" % item_id)


func _try_recruitment_tier() -> void:
	var tier_before := GameState.staff_recruitment_tier
	var xp_before := GameState.xp
	var highest := 0
	for candidate: Dictionary in DataDB.staff:
		highest = maxi(highest, int(candidate.get("highest_tier", 0)))

	var result := GameState.buy_staff_recruitment_tier("SH18")

	if result.get("ok", false):
		if GameState.staff_recruitment_tier != tier_before + 1:
			_fail("SH18: a successful buy moved the tier from %d to %d, not +1"
				% [tier_before, GameState.staff_recruitment_tier])
		if GameState.staff_recruitment_tier > highest:
			_fail("SH18: recruitment tier (%d) went past the highest tier any real candidate has (%d)"
				% [GameState.staff_recruitment_tier, highest])
		if GameState.xp >= xp_before:
			_fail("SH18: a successful buy did not spend XP")
	else:
		if GameState.staff_recruitment_tier != tier_before:
			_fail("SH18: a refused buy still changed the tier")
		if GameState.xp != xp_before:
			_fail("SH18: a refused buy still spent XP")
		# A refusal is legitimate either because the tier is already maxed or
		# because XP/Funds fell short (Items.buy_refusal checks price first) —
		# only a refusal that is NEITHER of those is actually suspicious.
		var item := DataDB.get_shop_item("SH18")
		var price_short := xp_before < int(item.get("cost_xp", 0))
		if tier_before < highest and not price_short:
			_fail("SH18: refused at tier %d (xp=%d, cost=%d), below the real highest tier %d, and XP was enough"
				% [tier_before, xp_before, int(item.get("cost_xp", 0)), highest])


func _try_funds_cap() -> void:
	var bonus_before := GameState.funds_cap_bonus
	var xp_before := GameState.xp
	var item := DataDB.get_shop_item("SH19")
	var increase := int(item.get("funds_cap_increase", 0))

	var result := GameState.buy_funds_cap("SH19")

	if result.get("ok", false):
		if GameState.funds_cap_bonus != bonus_before + increase:
			_fail("SH19: bonus moved from %d to %d, not +%d"
				% [bonus_before, GameState.funds_cap_bonus, increase])
		if GameState.xp >= xp_before:
			_fail("SH19: a successful buy did not spend XP")
		# The bonus must actually be repeatable and unbounded from this side —
		# SH19's whole point is "no limit" (CLAUDE.md §5, funds_cap_bonus).
		if GameState.funds_cap_bonus < 0:
			_fail("SH19: funds_cap_bonus went negative")
	else:
		if GameState.funds_cap_bonus != bonus_before:
			_fail("SH19: a refused buy still changed the bonus")
		if GameState.xp != xp_before:
			_fail("SH19: a refused buy still spent XP")

	# The raised cap has to actually clamp Funds where it says it will —
	# proven directly against _sanban_row()'s own math via a real _move_meta.
	var row := _funds_row()
	var expected_cap := int(row.get("max", 0)) + GameState.funds_cap_bonus
	GameState.meta["Funds"] = 0
	GameState._move_meta("Funds", expected_cap + 999999)
	if int(GameState.meta["Funds"]) != expected_cap:
		_fail("Funds cap: clamped to %d, expected base+bonus = %d"
			% [int(GameState.meta["Funds"]), expected_cap])


# ---------------------------------------------------------------------------
# State perturbation — the point of a fuzz test: hit the edges, not just the
# middle. Owning everything at a tier, XP=0, Funds=0, every tier maxed.
# ---------------------------------------------------------------------------

func _occasionally_drain_ownership() -> void:
	if randf() < 0.3:
		var tier := randi_range(1, 3)
		for card: Dictionary in DataDB.cards:
			if int(card.get("tier", -1)) == tier:
				GameState.owned_cards.append(str(card.get("card_id", "")))
	if randf() < 0.3:
		var tier := randi_range(1, 2)
		for level: Dictionary in DataDB.levels:
			var level_id := str(level.get("level_id", ""))
			if int(level.get("tier", -1)) == tier and not GameState.levels_unlocked.has(level_id):
				GameState.levels_unlocked.append(level_id)
	if randf() < 0.2:
		var highest := 0
		for candidate: Dictionary in DataDB.staff:
			highest = maxi(highest, int(candidate.get("highest_tier", 0)))
		GameState.staff_recruitment_tier = highest


func _occasionally_scramble_funds_and_xp() -> void:
	if randf() < 0.4:
		GameState.xp = [0, 1, 39, 40, 249, 250, 499, 500, 999, 1000, 100000][randi() % 11]
	if randf() < 0.4:
		GameState.meta["Funds"] = [0, 99999, 100000][randi() % 3]


func _occasionally_reset_a_field() -> void:
	match randi() % 4:
		0: GameState.owned_cards = []
		1: GameState.levels_unlocked = []
		2: GameState.staff_recruitment_tier = 0
		3: GameState.funds_cap_bonus = 0


func _funds_row() -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == "Funds":
			return row
	return {}


func _fail(message: String) -> void:
	_failures.append("iteration %d: %s" % [_iterations_run, message])


func _report() -> void:
	print("Ran %d/%d iterations." % [_iterations_run, ITERATIONS])
	print("final state: xp=%d Funds=%d owned_cards=%d levels_unlocked=%d "
		% [GameState.xp, int(GameState.meta.get("Funds", 0)),
			GameState.owned_cards.size(), GameState.levels_unlocked.size()]
		+ "staff_recruitment_tier=%d funds_cap_bonus=%d"
		% [GameState.staff_recruitment_tier, GameState.funds_cap_bonus])

	if _failures.is_empty():
		print("STRESS TEST: PASS")
		get_tree().quit(0)
	else:
		print("STRESS TEST: FAIL")
		for f: String in _failures:
			print("  X " + f)
		get_tree().quit(1)
