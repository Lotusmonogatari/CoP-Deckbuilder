extends "res://tools/playtest_optimal.gd"
## A strategy playtest (2026-11-02, Cameron): the same bot that plays real
## fights and rooms (tools/playtest_optimal.gd), run for a fixed number of
## game WEEKS under a named strategy, then scored on the three things a
## long-term player wants: Funds, Election Strength and Party support.
##
##     PLAYTEST_STRATEGY=money_adaptive PLAYTEST_WEEKS=30 PLAYTEST_SEED=1 \
##     PLAYTEST_PROTAGONIST=PC02 PLAYTEST_OUT=/tmp/runs.jsonl \
##     godot --headless --path . tools/strategy_playtest.tscn
##
## One line, "RESULT {json}", is printed (and appended to PLAYTEST_OUT) with
## the final numbers, a per-week series, a per-level log (what each level paid
## per hour), card, item, event and promise tallies. tools/strategy_report.py
## reads those lines and writes the analysis.
##
## What a strategy can change (every key is optional; STRATEGIES lists them):
##   level      how the next level is chosen (seq, money, party, election, all
##              (the adaptive ones learn each level's real pay per hour),
##              short, low_tier, random)
##   deck       strongest, suit:<Suit>, guard, cheap
##   gaffe      multiplier on how dearly a gaffe is priced when playing cards
##   items      battle (buy and use battle items) or none
##   backing    base, heavy, none
##   staff      cheap or none
##   events     none, random (only the ones that arrive), buy (also arrange)
##   weekend    play weekend-flagged levels and events instead of going home
##   visitors   net (standing only, ignores costs: the old bot), value (weighs
##              standing, Funds, hours and promises), funds, frugal, random
##   promises   ignore (take them, never keep), keep, avoid
##   patron     take patron bills or not
##   reserve    keep this week's party dues in hand before buying anything
##   random_cards   play random cards (a stress mode, expected to lose)
## Nothing here changes a rule; it only chooses among the choices a player has.

const STRATEGIES := {
	"baseline": {},
	"hoarder": {"items": "none", "backing": "none", "staff": "none", "level": "money", "patron": false},
	"money_adaptive": {"level": "money"},
	"party_adaptive": {"level": "party"},
	"election_adaptive": {"level": "election", "events": "buy", "weekend": true},
	"balanced_adaptive": {"level": "all", "events": "buy", "weekend": true, "visitors": "value", "promises": "keep"},
	"short_levels": {"level": "short"},
	"low_tier_grind": {"level": "low_tier"},
	"random_levels": {"level": "random"},
	"events_random": {"events": "random"},
	"events_buy": {"events": "buy"},
	"weekend_warrior": {"weekend": true, "events": "buy"},
	"promise_keeper": {"visitors": "value", "promises": "keep"},
	"promise_breaker": {"visitors": "value", "promises": "ignore"},
	"promise_avoider": {"visitors": "value", "promises": "avoid"},
	"frugal_visitors": {"visitors": "frugal"},
	"visitors_funds": {"visitors": "funds"},
	"random_visitors": {"visitors": "random"},
	"no_items": {"items": "none"},
	"no_backing": {"backing": "none"},
	"heavy_backing": {"backing": "heavy"},
	"no_staff": {"staff": "none"},
	"no_patron": {"patron": false},
	"dues_first": {"reserve": true},
	"hoard_and_pay": {"items": "none", "backing": "none", "staff": "none", "level": "money", "patron": false, "reserve": true},
	"money_reserve": {"level": "money", "reserve": true},
	"balanced_reserve": {"level": "all", "events": "buy", "weekend": true, "visitors": "value", "promises": "keep", "reserve": true},
	"election_reserve": {"level": "election", "events": "buy", "weekend": true, "reserve": true},
	"party_reserve": {"level": "party", "reserve": true},
	"reckless_cards": {"gaffe": 0.25},
	"cautious_cards": {"gaffe": 2.5},
	"earnest_deck": {"deck": "suit:Earnest"},
	"emotional_deck": {"deck": "suit:Emotional"},
	"appeal_deck": {"deck": "suit:Appeal"},
	"data_deck": {"deck": "suit:Data Driven"},
	"divisive_deck": {"deck": "suit:Divisive"},
	"duplicitous_deck": {"deck": "suit:Duplicitous"},
	"guard_deck": {"deck": "guard"},
	"cheap_deck": {"deck": "cheap"},
	"random_cards": {"random_cards": true},
}

const DEFAULTS := {"level": "seq", "deck": "strongest", "gaffe": 1.0, "items": "battle", "backing": "base",
	"staff": "cheap", "events": "none", "weekend": false, "visitors": "net", "promises": "ignore",
	"patron": true, "random_cards": false, "reserve": false}

const MAX_WEEK_VISITS := 40   ## a safety valve on the loop inside one week

var _s: Dictionary = {}
var _name := ""
var _horizon := 30
var _weeks := 0
var _series: Array = []
var _level_log: Array = []
var _level_pay: Dictionary = {}     ## level_id -> {n, hours, funds, party, election, xp}
var _weights := {"funds": 1.0, "party": 1.0, "election": 1.0}
var _events := {"seen": 0, "taken": 0, "arranged": 0, "refused": 0, "hours": 0, "funds": 0, "by_id": {}}
var _visitors := {"questions": 0, "paid_hours": 0, "paid_funds": 0, "promises_made": 0, "kept": 0, "stuck": 0}
var _weeks_overdue := 0
var _idle_weeks := 0
var _weekend_levels := 0
var _items_by_id: Dictionary = {}
var _suit_plays: Dictionary = {}
var _levels_played_by_tier: Dictionary = {}
var _stage_wins: Dictionary = {}
var _train_spent := 0
var _last_units := -1
var _still := 0
var _stalls := 0
var _last_week_dues := 0
var _last_week_earned := 0
var _last_week_paid := 0


func _run() -> void:
	MAX_STAGES = 100000
	_name = OS.get_environment("PLAYTEST_STRATEGY")
	if _name.is_empty() or not STRATEGIES.has(_name):
		_name = "baseline"
	_s = DEFAULTS.duplicate()
	_s.merge(STRATEGIES[_name], true)
	var weeks := OS.get_environment("PLAYTEST_WEEKS")
	_horizon = int(weeks) if not weeks.is_empty() else 30
	var seed_text := OS.get_environment("PLAYTEST_SEED")
	if not seed_text.is_empty():
		seed(int(seed_text))
	var protagonist := OS.get_environment("PLAYTEST_PROTAGONIST")
	if not protagonist.is_empty():
		_protagonist = protagonist
	_random_moves = bool(_s["random_cards"])
	_patron_on = bool(_s["patron"])
	_gaffe_price = 0.8 * float(_s["gaffe"])
	match str(_s["level"]):
		"money": _weights = {"funds": 1.0, "party": 0.0, "election": 0.0}
		"party": _weights = {"funds": 0.0, "party": 1.0, "election": 0.0}
		"election": _weights = {"funds": 0.0, "party": 0.0, "election": 1.0}

	GameState.start_new_run(_protagonist)
	_record_week()   # week 0: the starting line

	var guard := 0
	while _weeks < _horizon and _level_attempts < 2500 and _stages_played < 8000 and guard < 3000:
		guard += 1
		if OS.get_environment("PLAYTEST_DEBUG") == "1" and _weeks >= 28:
			print("LOOP week=%d cal=%s units=%d full=%s weekend=%s attempts=%d" % [_weeks, GameState.calendar, GameState.time_units,
				GameState.work_week_is_full(), GameState.in_weekend(), _level_attempts])
		# A guard against a week that stops moving (nothing here should ever stall it).
		if GameState.time_units == _last_units:
			_still += 1
		else:
			_still = 0
			_last_units = GameState.time_units
		if _still >= 6:
			_stalls += 1
			var where := ""
			if GameState.is_in_level():
				var runner := GameState.level_runner
				var ids: Array = []
				for st: Variant in runner.stages:
					ids.append(str((st as Dictionary).get("stage_id", "?")))
				where = " runner index=%d stages=%s level=%s" % [runner.index, ids, runner.level.get("level_id", "?")]
			_bug("clock stalled for %d iterations at week %d: calendar %s, strategy %s, full=%s, in_level=%s%s" % [
				_still, _weeks, GameState.calendar, _name, GameState.work_week_is_full(), GameState.is_in_level(), where])
			_still = 0
			_end_week()
			continue
		_office_visit()
		var forced := GameState.take_forced_special()
		_play_patron_requests()
		var level_id := str(forced.get("level_id", "")) if not forced.is_empty() else _choose_level()
		if level_id.is_empty():
			_end_week()
			continue
		_level_attempts += 1
		_play_level(level_id)
	_finish()


# ---------------------------------------------------------------------------
# The Office between levels
# ---------------------------------------------------------------------------

func _office_visit() -> void:
	# With "reserve", nothing is bought out of the money the party will ask for.
	FUNDS_BUFFER = 5000
	if bool(_s["reserve"]):
		FUNDS_BUFFER = maxi(5000, int(float(GameState.dues_preview()["total"]) * 1.2))
	# Cards, level unlocks and staff first, as the base bot does.
	_unlock_affordable_cards()
	_rebuild_deck()
	_unlock_next_level_if_affordable()
	if str(_s["staff"]) != "none":
		_hire_cheap_staff()
	_buy_backing()
	_buy_items()
	if str(_s["promises"]) == "keep":
		_keep_promises()
	if str(_s["events"]) != "none":
		_handle_events()


func _buy_backing() -> void:
	match str(_s["backing"]):
		"none": return
		"heavy":
			super._buy_backing()
			super._buy_backing()
			super._buy_backing()
		_: super._buy_backing()


func _buy_items() -> void:
	if str(_s["items"]) == "none":
		return
	super._buy_items()


func _use_held_items(engine: BattleEngine, repro: String) -> void:
	if str(_s["items"]) == "none":
		return
	super._use_held_items(engine, repro)


## Deck building weighs a card by the strategy's focus on top of its paper value.
func _card_strength(card: Dictionary) -> float:
	var base := super._card_strength(card)
	var deck := str(_s["deck"])
	if deck.begins_with("suit:") and str(card.get("suit", "")) == deck.substr(5):
		return base + 1.5 + absf(base) * 0.5
	if deck == "guard":
		return base + 0.6 * float(card.get("guard", 0))
	if deck == "cheap":
		return base + (1.0 if int(card.get("cost", 1)) <= 1 else 0.0)
	return base


# ---------------------------------------------------------------------------
# Choosing a level and running the week
# ---------------------------------------------------------------------------

func _choose_level() -> String:
	if GameState.work_week_is_full():
		return ""   # the loop ends the week
	var candidates: Array = []
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		if SpecialLevels.is_special(level) or GameState.is_event_only(level):
			continue
		if Ledger.level_is_hidden(level, GameState.level_last_completed_at):
			continue
		if not GameState.is_level_discovered(level) or not GameState.in_season(level):
			continue
		if not Ledger.is_level_unlocked(level, GameState.levels_unlocked, GameState.staff_hired):
			continue
		if Ledger.level_cooldown_remaining(level, GameState.time_units, GameState.level_cleared_units) > 0:
			continue
		if not GameState.level_calendar_refusal(level).is_empty():
			continue
		candidates.append(level)
	if candidates.is_empty():
		return ""
	var mode := str(_s["level"])
	if mode == "random":
		return str((candidates[randi() % candidates.size()] as Dictionary).get("level_id", ""))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _level_rank(a, mode) > _level_rank(b, mode))
	return str((candidates[0] as Dictionary).get("level_id", ""))


## Higher is better. Sequential = never-played first, lowest id first.
func _level_rank(level: Dictionary, mode: String) -> float:
	var level_id := str(level.get("level_id", ""))
	var hours := maxf(float(GameState.level_hours(level)), 1.0)
	match mode:
		"seq":
			var fresh := 0.0 if GameState.level_last_completed_at.has(level_id) else 1000.0
			return fresh - float(level_id.substr(2).to_int())
		"short":
			return -hours
		"low_tier":
			return -float(int(level.get("tier", 0))) * 100.0 - float(level_id.substr(2).to_int()) * 0.01
		"money", "party", "election", "all":
			if _level_pay.has(level_id):
				var pay: Dictionary = _level_pay[level_id]
				return _objective(pay) / maxf(float(pay["hours"]), 1.0)
			# An untried level gets its paper estimate, a little optimistic so each is tried once.
			return _prior(level) / hours + 0.5
	return 0.0


## The weighted worth of a level's pay (realised totals or a paper estimate).
func _objective(pay: Dictionary) -> float:
	var n := maxf(float(pay.get("n", 1)), 1.0)
	return (float(_weights["funds"]) * float(pay.get("funds", 0)) / 5000.0
		+ float(_weights["party"]) * float(pay.get("party", 0)) * 1.0
		+ float(_weights["election"]) * float(pay.get("election", 0)) * 1.0
		+ 0.02 * float(pay.get("xp", 0))) / n


func _prior(level: Dictionary) -> float:
	var funds := 0.0
	var party := 0.0
	var election := 0.0
	var xp := 0.0
	for slot in range(1, 11):
		var raw: Variant = level.get("stage_%d" % slot)
		if raw == null or str(raw).is_empty() or str(raw) == "N/A":
			continue
		var stage := DataDB.get_stage("ST23" if str(raw).begins_with("BI") else str(raw))
		funds += _num(stage.get("win_delta_yen"))
		party += _num(stage.get("win_delta_party_support"))
		election += _num(stage.get("win_delta_jiban")) + _num(stage.get("win_delta_awareness_district")) \
			+ _num(stage.get("win_delta_awareness_national"))
		xp += _num(stage.get("win_delta_xp"))
	var bonus: Variant = level.get("bonus_win_range_yen")
	if bonus is Dictionary:
		funds += (_num((bonus as Dictionary).get("min")) + _num((bonus as Dictionary).get("max"))) / 2.0
	return _objective({"n": 1, "funds": funds, "party": party, "election": election, "xp": xp})


func _num(value: Variant) -> float:
	return float(value) if value != null else 0.0


func _play_level(level_id: String) -> void:
	var before := _snapshot()
	var level := DataDB.get_level(level_id)
	var wins_before := _wins
	var losses_before := _losses
	super._play_level(level_id)
	var after := _snapshot()
	var tier := int(level.get("tier", 0))
	_levels_played_by_tier[tier] = int(_levels_played_by_tier.get(tier, 0)) + 1
	var hours := maxi(int(after["t"]) - int(before["t"]), 1)
	var election_move := (float(after["dist"]) - float(before["dist"])) + (float(after["nat"]) - float(before["nat"])) \
		+ (float(after["con"]) - float(before["con"]))
	var entry := {"level": level_id, "tier": tier, "week": _weeks, "hours": hours,
		"funds": int(after["funds"]) - int(before["funds"]), "party": int(after["party"]) - int(before["party"]),
		"con": int(after["con"]) - int(before["con"]), "rep": int(after["rep"]) - int(before["rep"]),
		"xp": int(after["xp_total"]) - int(before["xp_total"]), "dist": int(after["dist"]) - int(before["dist"]),
		"nat": int(after["nat"]) - int(before["nat"]), "stage_wins": _wins - wins_before,
		"stage_losses": _losses - losses_before}
	_level_log.append(entry)
	var pay: Dictionary = _level_pay.get(level_id, {"n": 0, "hours": 0, "funds": 0, "party": 0, "election": 0, "xp": 0})
	pay["n"] = int(pay["n"]) + 1
	pay["hours"] = int(pay["hours"]) + hours
	pay["funds"] = int(pay["funds"]) + int(entry["funds"])
	pay["party"] = int(pay["party"]) + int(entry["party"])
	pay["election"] = float(pay["election"]) + election_move
	pay["xp"] = int(pay["xp"]) + int(entry["xp"])
	_level_pay[level_id] = pay


func _snapshot() -> Dictionary:
	return {"funds": int(GameState.meta.get("Funds", 0)), "party": int(GameState.meta.get("Party support", 0)),
		"con": int(GameState.meta.get("Constituency support", 0)), "rep": int(GameState.meta.get("Reputation", 0)),
		"xp": GameState.xp, "xp_total": GameState.xp_earned_total, "t": GameState.time_units,
		"dist": int(GameState.awareness.get("district", 0)), "nat": int(GameState.awareness.get("national", 0))}


## The work week is over (full, or nothing playable): optionally use the
## weekend, then pay the party and go home.
func _end_week() -> void:
	if GameState.dues_balance > 0:
		_weeks_overdue += 1
	if bool(_s["weekend"]):
		GameState.end_work_week()
		var guard := 0
		while guard < MAX_WEEK_VISITS and GameState.in_weekend() and not WeekCalendar.is_full(GameState.calendar, GameState.calendar_config()):
			guard += 1
			var played := false
			var weekend_levels: Array = []
			for level: Dictionary in DataDB.levels:
				var level_id := str(level.get("level_id", ""))
				if SpecialLevels.is_special(level) or GameState.is_event_only(level) \
						or Ledger.level_is_hidden(level, GameState.level_last_completed_at):
					continue
				if not GameState.is_level_discovered(level) or not GameState.in_season(level):
					continue
				if not Ledger.is_level_unlocked(level, GameState.levels_unlocked, GameState.staff_hired):
					continue
				if Ledger.level_cooldown_remaining(level, GameState.time_units, GameState.level_cleared_units) > 0:
					continue
				if GameState.level_calendar_refusal(level).is_empty():
					weekend_levels.append(level)
			if not weekend_levels.is_empty():
				var rank_mode := "money" if str(_s["level"]) == "seq" else str(_s["level"])
				weekend_levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
					return _level_rank(a, rank_mode) > _level_rank(b, rank_mode))
				_weekend_levels += 1
				_level_attempts += 1
				_play_level(str((weekend_levels[0] as Dictionary).get("level_id", "")))
				played = true
			if not played and str(_s["events"]) != "none":
				played = _handle_events()
			if not played:
				break
	var dues := GameState.dues_preview()
	_last_week_dues = int(dues["week_dues"])
	_last_week_earned = GameState.week_funds_earned
	var funds_before_dues := int(GameState.meta.get("Funds", 0))
	GameState.go_home()
	_last_week_paid = funds_before_dues - int(GameState.meta.get("Funds", 0))
	_weeks += 1
	_record_week()


func _record_week() -> void:
	var snap := _snapshot()
	snap["week"] = _weeks
	snap["es"] = snappedf(GameState.election_strength, 0.01)
	snap["pot"] = snappedf(GameState.election_potential(), 0.01)
	snap["dues_owed"] = GameState.dues_balance
	snap["week_dues"] = _last_week_dues
	snap["week_earned"] = _last_week_earned
	snap["week_paid"] = _last_week_paid
	snap["orgs_on_side"] = _orgs_on_side()
	snap["promises_open"] = GameState.promises.size()
	_series.append(snap)


func _orgs_on_side() -> int:
	var count := 0
	for id: String in GameState.booster_standing.keys():
		if int(GameState.booster_standing[id]) >= 50:
			count += 1
	return count


# ---------------------------------------------------------------------------
# Visitor rooms: now with the choices' real costs and promises
# ---------------------------------------------------------------------------

func _play_visitor_stage(stage: Dictionary) -> void:
	var stage_id := str(stage.get("stage_id", ""))
	var engine := OfficeHoursEngine.new()
	if not engine.setup({"visitors": stage.get("visitors", [])}):
		_bug("%s: OfficeHoursEngine.setup() failed: %s" % [stage_id, engine.setup_problems])
		_force_end_stage(LevelRunner.LOST)
		return
	var guard := 0
	while not engine.is_finished() and guard < 20:
		guard += 1
		var question: Dictionary = engine.current_question()
		var letter := _choose_letter(question)
		var commitments := Commitments.of(question, "commitment_" + letter.to_lower())
		_visitors["questions"] = int(_visitors["questions"]) + 1
		if str(_s["visitors"]) != "net" or not commitments.is_empty():
			if not GameState.commitment_refusal(commitments).is_empty():
				_visitors["stuck"] = int(_visitors["stuck"]) + 1
			else:
				_visitors["paid_hours"] = int(_visitors["paid_hours"]) + Commitments.hours(commitments)
				_visitors["paid_funds"] = int(_visitors["paid_funds"]) + Commitments.funds(commitments)
				for entry: Variant in commitments:
					if entry is Dictionary and str((entry as Dictionary).get("kind", "")).begins_with("promise"):
						_visitors["promises_made"] = int(_visitors["promises_made"]) + 1
				GameState.pay_commitments(commitments, str(engine.current_visitor().get("name_en", "")),
					GameState._first_pleased_org(question.get("effects_" + letter.to_lower())))
		var result := engine.answer(letter)
		GameState.apply_visitor_reward_entries(result.get("effects", []))
		engine.advance()
	_log("  %s: visitor room complete (%d visitors)" % [stage_id, engine.visitor_count()])
	_wins += 1
	var level_over := GameState.finish_stage(LevelRunner.WON)
	if level_over:
		GameState.end_level()


## The letter to answer with under the strategy's visitor policy. A choice that
## cannot be paid for (hours, Funds, an item) is never picked while another can.
func _choose_letter(question: Dictionary) -> String:
	var mode := str(_s["visitors"])
	var options: Array[String] = []
	for letter in ["A", "B", "C", "D"]:
		var text: Variant = question.get("choice_%s" % letter.to_lower())
		if text == null or str(text).is_empty():
			continue
		var commitments := Commitments.of(question, "commitment_" + letter.to_lower())
		if mode != "net" and not GameState.commitment_refusal(commitments).is_empty():
			continue
		options.append(letter)
	if options.is_empty():
		return "A"
	if mode == "random":
		return options[randi() % options.size()]
	var best := options[0]
	var best_score := -1.0e9
	for letter in options:
		var effects: Variant = question.get("effects_%s" % letter.to_lower())
		var standing := OfficeHoursEngine.net_delta(effects as Array) if effects is Array else 0.0
		var commitments := Commitments.of(question, "commitment_" + letter.to_lower())
		var score := standing
		if mode != "net":
			var hours := float(Commitments.hours(commitments))
			var funds := float(Commitments.funds(commitments))
			var promises := 0.0
			for entry: Variant in commitments:
				if entry is Dictionary and str((entry as Dictionary).get("kind", "")).begins_with("promise"):
					promises += 1.0
			var funds_weight := 5.0 if mode == "funds" else 1.0
			score -= hours * (6.0 if mode == "frugal" else 1.0)
			score -= funds / 1000.0 * funds_weight
			if str(_s["promises"]) == "avoid":
				score -= promises * 50.0
			elif str(_s["promises"]) == "ignore" and promises > 0:
				score -= promises * 2.0   # a promise nobody will keep is a small standing loss waiting to happen
			if mode == "frugal" and hours + funds > 0:
				score -= 30.0
		if score > best_score:
			best_score = score
			best = letter
	return best


func _keep_promises() -> void:
	var guard := 0
	while guard < 20 and not GameState.promises.is_empty():
		guard += 1
		var kept := false
		for promise: Dictionary in GameState.promises.duplicate():
			if GameState.promise_keep_refusal(promise).is_empty():
				if GameState.keep_promise(str(promise.get("id", ""))).is_empty():
					_visitors["kept"] = int(_visitors["kept"]) + 1
					kept = true
					break
		if not kept:
			return


# ---------------------------------------------------------------------------
# Events: the ones that arrive, and (optionally) the ones the player arranges
# ---------------------------------------------------------------------------

## Runs whatever event is due. Returns true when one was played.
func _handle_events() -> bool:
	var played := false
	var due := GameState.take_due_followup()
	if due.is_empty():
		due = GameState.due_dated_event()
	if due.is_empty():
		due = GameState.roll_random_event()
	if not due.is_empty():
		_events["seen"] = int(_events["seen"]) + 1
		played = _play_event(due, false)
	if str(_s["events"]) == "buy" and not GameState.work_week_is_full():
		var best_id := ""
		var best_score := 0.0
		for event: Dictionary in GameState.buyable_events():
			if not GameState.event_refusal(event).is_empty():
				continue
			var cost := _num(event.get("cost_funds"))
			if int(GameState.meta.get("Funds", 0)) - cost < FUNDS_BUFFER * 2:
				continue
			var letter := _best_event_choice(event)
			if letter.is_empty():
				continue
			var score := _event_choice_score(event, _choice_row(str(event.get("event_id", "")), letter)) \
				- cost / 5000.0 * float(_weights["funds"])
			if score > best_score:
				best_score = score
				best_id = str(event.get("event_id", ""))
		if not best_id.is_empty() and GameState.start_event(best_id):
			_events["arranged"] = int(_events["arranged"]) + 1
			played = _play_event(best_id, true) or played
	return played


func _choice_row(event_id: String, letter: String) -> Dictionary:
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		if str(row.get("choice", "")) == letter:
			return row
	return {}


func _mid(value: Variant) -> float:
	if value is Dictionary:
		return (_num((value as Dictionary).get("min")) + _num((value as Dictionary).get("max"))) / 2.0
	return _num(value)


## What an event choice is worth, in the same units as a level's pay.
func _event_choice_score(event: Dictionary, choice: Dictionary) -> float:
	if choice.is_empty():
		return -1.0e9
	var score := 0.0
	var election := _mid(choice.get("district_delta")) + _mid(choice.get("national_delta")) \
		+ _mid(choice.get("constituency_delta"))
	var rewards: Variant = choice.get("rewards")
	score += float(_weights["election"]) * election
	score += float(_weights["party"]) * _mid(choice.get("party_support_delta"))
	score += float(_weights["funds"]) * _mid(choice.get("funds_delta")) / 5000.0
	score += 0.3 * _mid(choice.get("reputation_delta"))
	if rewards is Array:
		score += 0.7 * OfficeHoursEngine.net_delta(rewards as Array)
	score -= _num(choice.get("funds_cost")) / 5000.0 * float(_weights["funds"])
	score -= float(EventEngine.hours_of(event) + Commitments.hours(Commitments.of(choice))) * 0.4
	if GameState.event_choice_level(choice) != "":
		score -= 1000.0   # event-started levels are not driven by this bot
	return score


func _best_event_choice(event: Dictionary) -> String:
	var best := ""
	var best_score := -1.0e8
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, str(event.get("event_id", ""))):
		if not GameState.commitment_refusal(Commitments.of(row)).is_empty():
			continue
		var price := int(row.get("funds_cost", 0)) if row.get("funds_cost") != null else 0
		if price > int(GameState.meta.get("Funds", 0)):
			continue
		if not GameState.event_choice_refusal(event, row).is_empty():
			continue
		var score := _event_choice_score(event, row)
		if score > best_score:
			best_score = score
			best = str(row.get("choice", ""))
	return best


func _play_event(event_id: String, arranged: bool) -> bool:
	var event := GameState.get_event(event_id)
	if event.is_empty():
		return false
	var letter := _best_event_choice(event)
	if letter.is_empty():
		_events["refused"] = int(_events["refused"]) + 1
		return false
	var before := _snapshot()
	var outcome := GameState.apply_event_choice(event_id, letter)
	if not bool(outcome.get("ok", false)):
		_events["refused"] = int(_events["refused"]) + 1
		return false
	var after := _snapshot()
	_events["taken"] = int(_events["taken"]) + 1
	_events["hours"] = int(_events["hours"]) + int(outcome.get("hours", 0))
	_events["funds"] = int(_events["funds"]) + int(after["funds"]) - int(before["funds"])
	var by_id: Dictionary = _events["by_id"]
	var rec: Dictionary = by_id.get(event_id, {"n": 0, "arranged": 0, "dfunds": 0, "ddist": 0, "dnat": 0, "dcon": 0, "dparty": 0})
	rec["n"] = int(rec["n"]) + 1
	rec["arranged"] = int(rec["arranged"]) + (1 if arranged else 0)
	rec["dfunds"] = int(rec["dfunds"]) + int(after["funds"]) - int(before["funds"])
	rec["ddist"] = int(rec["ddist"]) + int(after["dist"]) - int(before["dist"])
	rec["dnat"] = int(rec["dnat"]) + int(after["nat"]) - int(before["nat"])
	rec["dcon"] = int(rec["dcon"]) + int(after["con"]) - int(before["con"])
	rec["dparty"] = int(rec["dparty"]) + int(after["party"]) - int(before["party"])
	by_id[event_id] = rec
	return true


# ---------------------------------------------------------------------------
# The result
# ---------------------------------------------------------------------------

func _finish() -> void:
	var snap := _snapshot()
	var suit_plays := {}
	for card_id: String in _card_tally.keys():
		var suit := str(DataDB.get_card(card_id).get("suit", "?"))
		suit_plays[suit] = int(suit_plays.get(suit, 0)) + int(_card_tally[card_id])
	var laws := 0
	for law: Dictionary in GameState.statute_book:
		if bool(law.get("passed", false)):
			laws += 1
	var result := {
		"strategy": _name, "protagonist": _protagonist, "seed": OS.get_environment("PLAYTEST_SEED"),
		"weeks": _weeks, "horizon": _horizon,
		"funds": snap["funds"], "net_funds": int(snap["funds"]) - GameState.dues_balance, "es": snappedf(GameState.election_strength, 0.01),
		"potential": snappedf(GameState.election_potential(), 0.01), "party": snap["party"],
		"con": snap["con"], "rep": snap["rep"], "xp": GameState.xp, "xp_total": GameState.xp_earned_total,
		"dist": snap["dist"], "nat": snap["nat"], "dues_owed": GameState.dues_balance,
		"weeks_overdue": _weeks_overdue, "laws": laws, "orgs_on_side": _orgs_on_side(),
		"election_parts": GameState.election_parts(),
		"level_attempts": _level_attempts, "stages": _stages_played, "wins": _wins, "losses": _losses,
		"weekend_levels": _weekend_levels,
		"levels_cleared": GameState.level_last_completed_at.size(),
		"levels_by_tier": _levels_played_by_tier,
		"owned_cards": GameState.owned_cards.size(), "deck": GameState.deck,
		"backing_owned": GameState.owned_modifiers.size(), "backing_bought": _backing_bought,
		"items_bought": _items_bought, "items_used": _items_used,
		"staff": GameState.staff_hired.size(),
		"gaffes": GameState.lifetime_gaffes,
		"card_tally": _card_tally, "suit_plays": suit_plays,
		"stage_type_results": GameState.stage_type_results,
		"events": _events, "visitors": _visitors,
		"promises_open": GameState.promises.size(), "promises_broken_unseen": GameState.promises_broken_unseen.size(),
		"patron": _patron, "bugs": _bugs, "stalls": _stalls,
		"series": _series, "levels": _level_log,
	}
	var line := "RESULT " + JSON.stringify(result)
	print(line)
	var out := OS.get_environment("PLAYTEST_OUT")
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.READ_WRITE) if FileAccess.file_exists(out) else FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.seek_end()
			file.store_line(line.substr(7))
			file.close()
	get_tree().quit(0)
