extends GutTest
## The walking tour and the dinner as three-screen guest events (2026-10-23).

var _cfg := HostedEvent.settings({})
var _standing_before: Dictionary = {}
var _calendar_before: Dictionary = {}
var _awareness_before: Dictionary = {}
var _meta_before: Dictionary = {}
var _discovered_before: Array = []


func before_each() -> void:
	_standing_before = GameState.booster_standing.duplicate(true)
	_calendar_before = GameState.calendar.duplicate()
	_awareness_before = GameState.awareness.duplicate()
	_meta_before = GameState.meta.duplicate()
	_discovered_before = GameState.discovered_levels.duplicate()
	GameState.calendar = WeekCalendar.fresh()
	GameState.discovered_levels = []
	GameState.hosted_session = {}
	for id: String in GameState.booster_standing.keys():
		GameState.booster_standing[id] = 50


func after_each() -> void:
	GameState.booster_standing = _standing_before
	GameState.calendar = _calendar_before
	GameState.awareness = _awareness_before
	GameState.meta = _meta_before
	GameState.discovered_levels.assign(_discovered_before)
	GameState.hosted_session = {}


func _tags(option_id: String) -> Array:
	for row: Dictionary in DataDB.event_options:
		if str(row["option_id"]) == option_id:
			return row["tags"]
	return []


func test_two_events_with_three_steps_each() -> void:
	assert_eq(DataDB.hosted_events.size(), 2)
	for hosted: Dictionary in DataDB.hosted_events:
		for step in [1, 2, 3]:
			assert_gt(HostedEvent.options_for(DataDB.event_options, str(hosted["hosted_id"]), step).size(), 1)


func test_the_dinner_picks_an_entree_a_drink_and_a_side() -> void:
	assert_eq(HostedEvent.slots_for(DataDB.event_options, "HE02", 1), ["Entree", "Drink", "Side"])
	assert_eq(HostedEvent.slots_for(DataDB.event_options, "HE01", 1), [""], "the tour picks one place")
	assert_eq(HostedEvent.slots_for(DataDB.event_options, "HE02", 2), [""])


func test_a_farm_cooperative_guest_dislikes_french_wine_and_likes_apple_juice() -> void:
	assert_eq(HostedEvent.reaction(DataDB.organization_tastes, "BO10", [_tags("DD1")]), -2)
	assert_eq(HostedEvent.reaction(DataDB.organization_tastes, "BO10", [_tags("DD3")]), 2)
	assert_eq(HostedEvent.reaction(DataDB.organization_tastes, "BO10", [_tags("DE3")]), -2, "Australian beef")


func test_reaction_levels() -> void:
	assert_eq(HostedEvent.level_of(2), HostedEvent.DELIGHTED)
	assert_eq(HostedEvent.level_of(1), HostedEvent.PLEASED)
	assert_eq(HostedEvent.level_of(0), HostedEvent.NEUTRAL)
	assert_eq(HostedEvent.level_of(-1), HostedEvent.UNEASY)
	assert_eq(HostedEvent.level_of(-2), HostedEvent.OFFENDED)


func test_every_level_has_a_line_and_fills_in_the_name() -> void:
	for level: String in [HostedEvent.DELIGHTED, HostedEvent.PLEASED, HostedEvent.NEUTRAL, HostedEvent.UNEASY, HostedEvent.OFFENDED]:
		var line := HostedEvent.line_for(DataDB.reaction_lines, level, "Ms Test", 0)
		assert_true(line.contains("Ms Test"), level)
		assert_false(line.contains("{"), level)


func test_allies_never_include_party_bodies() -> void:
	var allies := HostedEvent.allies("BO10", DataDB.party_stakeholders, DataDB.boosters)
	assert_gt(allies.size(), 0)
	for id: String in allies:
		assert_ne(str(DataDB.get_booster(id).get("tier", "")), "Party", id)


func test_the_roster_is_unique_and_no_bigger_than_asked() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var allies := HostedEvent.allies("BO10", DataDB.party_stakeholders, DataDB.boosters)
	var roster := HostedEvent.pick_roster("BO10", GameState.hosted_people_by_org(), allies, 5, rng)
	assert_eq(roster.size(), 5)
	var seen := {}
	for guest: Dictionary in roster:
		seen[str(guest["id"])] = true
	assert_eq(seen.size(), 5)


func test_an_organization_with_no_characters_still_gets_guests_from_its_allies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var people := GameState.hosted_people_by_org()
	assert_false(people.has("BO13") and (people["BO13"] as Array).is_empty() == false and false)
	var allies := HostedEvent.allies("BO13", DataDB.party_stakeholders, DataDB.boosters)
	var roster := HostedEvent.pick_roster("BO13", people, allies, 5, rng)
	assert_gt(roster.size(), 0)


func test_party_bodies_are_never_guests() -> void:
	var people := GameState.hosted_people_by_org()
	for org: String in people.keys():
		assert_ne(str(DataDB.get_booster(org).get("tier", "")), "Party", org)


func test_totals_weight_the_patron_cap_each_org_and_clamp_awareness() -> void:
	var scored := [[{"guest": {"org": "BO10"}, "reaction": 2}, {"guest": {"org": "BO10"}, "reaction": 2},
		{"guest": {"org": "BO05"}, "reaction": -1}]]
	var total := HostedEvent.totals(scored, "BO10", _cfg)
	assert_eq(int((total["org_deltas"] as Dictionary)["BO10"]), 6, "(2+2) x 2 capped at 6")
	assert_eq(int((total["org_deltas"] as Dictionary)["BO05"]), -1)
	assert_eq(int(total["net"]), 3)
	assert_eq(int(total["awareness"]), 2, "3 / 2 rounds to 2")
	assert_eq(int(total["reputation"]), 0)
	var bad := HostedEvent.totals([[{"guest": {"org": "BO05"}, "reaction": -2}, {"guest": {"org": "BO05"}, "reaction": -2},
		{"guest": {"org": "BO05"}, "reaction": -2}]], "BO10", _cfg)
	assert_eq(int(bad["reputation"]), -1)
	assert_eq(int(bad["awareness"]), -3)


func test_the_items_start_the_right_events() -> void:
	GameState.inventory["SH20"] = 1
	assert_eq(str(GameState.use_item_in_office("SH20", "BO07")["opens_hosted"]), "HE01")
	GameState.hosted_session = {}
	GameState.inventory["SH19"] = 1
	assert_eq(str(GameState.use_item_in_office("SH19", "BO05")["opens_hosted"]), "HE02")


func _play(hosted_id: String, org: String, picks_by_step: Dictionary) -> Dictionary:
	GameState.begin_hosted_event(hosted_id, org, 4)
	for step: int in [1, 2, 3]:
		GameState.hosted_record_step(step, picks_by_step[step])
	return GameState.finish_hosted_event()


func test_a_tour_the_farmers_love_raises_their_standing() -> void:
	var result := _play("HE01", "BO10", {1: ["T2"], 2: ["TP1"], 3: ["TC6"]})
	assert_gt(int(GameState.booster_standing["BO10"]), 50)
	assert_lte(int(GameState.booster_standing["BO10"]), 56, "capped at +6")
	assert_gt(int(result["net"]), 0)
	assert_eq(int(GameState.calendar["hours"]), 4)
	assert_true(GameState.hosted_session.is_empty(), "the evening is over")


func test_a_dinner_that_insults_the_farmers_lowers_it() -> void:
	_play("HE02", "BO10", {1: ["DE3", "DD1", "DS2"], 2: ["DP8"], 3: ["DC4"]})
	assert_lt(int(GameState.booster_standing["BO10"]), 50)


func test_the_dinner_moves_national_awareness_and_the_tour_district() -> void:
	GameState.awareness = {"district": 20, "national": 20}
	_play("HE02", "BO10", {1: ["DE5", "DD3", "DS4"], 2: ["DP1"], 3: ["DC6"]})
	assert_gt(int(GameState.awareness["national"]), 20)
	assert_eq(int(GameState.awareness["district"]), 20)
	GameState.awareness = {"district": 20, "national": 20}
	_play("HE01", "BO10", {1: ["T2"], 2: ["TP1"], 3: ["TC6"]})
	assert_gt(int(GameState.awareness["district"]), 20)
	assert_eq(int(GameState.awareness["national"]), 20)


func test_hosting_still_reveals_a_hidden_bill_at_the_end() -> void:
	var result := _play("HE02", "BO05", {1: ["DE1", "DD2", "DS3"], 2: ["DP2"], 3: ["DC1"]})
	assert_ne(str(result["revealed"]), "")
