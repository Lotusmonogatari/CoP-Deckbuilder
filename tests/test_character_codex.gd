extends GutTest
## The Characters list rules (CharacterCodex) and the saved "met" record.

const BOOSTERS := [
	{"booster_id": "BO03", "name_en": "Local Koenkai", "tier": "Constituency"},
	{"booster_id": "BO05", "name_en": "Chamber", "tier": "National"},
	{"booster_id": "BO01", "name_en": "Party Headquarters", "tier": "Party"},
]
const PARTIES := [
	{"name": "Butsutou", "r": 255, "g": 140, "b": 0},
	{"name": "Frontier Party", "r": 0, "g": 128, "b": 0},
]
const BALANCE := {"characters_colour_national_red": 10, "characters_colour_national_green": 20,
	"characters_colour_national_blue": 30}


func _opp(id: String, name: String, party: Variant, affiliation: Variant) -> Dictionary:
	return {"opp_id": id, "name": name, "title": null, "role": "Member", "party": party, "affiliation": affiliation}


func _entries(people: Array, met: Dictionary, kind: String = "opponent") -> Array[Dictionary]:
	return CharacterCodex.entries(kind, people, BOOSTERS, PARTIES, "Frontier Party", met, BALANCE)


func test_met_first_a_to_z_unmet_last_by_id() -> void:
	var people := [_opp("OP3", "Zed", null, null), _opp("OP2", "Amy", null, null),
		_opp("OP1", "Bob", null, null), _opp("OP4", "Cat", null, null)]
	var got := _entries(people, {"OP3": true, "OP2": true})
	assert_eq(got.map(func(e: Dictionary) -> String: return e["id"]), ["OP2", "OP3", "OP1", "OP4"])


func test_party_member_takes_party_colour() -> void:
	var got := _entries([_opp("OP1", "A", "Butsutou", "BO01")], {})
	assert_eq(got[0]["color"], Color(1.0, 140 / 255.0, 0.0))


func test_party_body_without_a_party_takes_player_party_colour() -> void:
	var got := _entries([_opp("OP1", "A", null, "BO01")], {})
	assert_eq(got[0]["color"], Color(0.0, 128 / 255.0, 0.0))


func test_tier_colours_come_from_balance_with_fallback() -> void:
	var got := _entries([_opp("OP1", "A", null, "BO05"), _opp("OP2", "B", null, "BO03"),
		_opp("OP3", "C", null, null)], {})
	var by_id := {}
	for e: Dictionary in got:
		by_id[e["id"]] = e["color"]
	assert_eq(by_id["OP1"], Color(10 / 255.0, 20 / 255.0, 30 / 255.0))
	assert_eq(by_id["OP2"], Color(160 / 255.0, 140 / 255.0, 100 / 255.0))
	assert_eq(by_id["OP3"], Color(120 / 255.0, 120 / 255.0, 120 / 255.0))


func test_visitors_use_japanese_name_and_first_reward_organization_and_survive_null() -> void:
	var visitors := [
		{"visitor_id": "VI1", "name_en": "Hanako", "name_jp": "花子", "title": "Chair",
			"reward": [{"target": "BO05", "delta": 1}, {"target": "BO03", "delta": 1}]},
		{"visitor_id": "VI2", "name_en": "Nobody", "name_jp": null, "title": null, "reward": null, "stages": null},
	]
	var got := _entries(visitors, {"VI1": true, "VI2": true}, "visitor")
	assert_eq(got[0]["name_jp"], "花子")
	assert_eq(got[0]["organizations"], ["Chamber", "Local Koenkai"])
	assert_eq(got[1]["name_jp"], "")
	assert_eq(got[1]["organizations"], [])


func test_opponents_have_no_japanese_name() -> void:
	assert_eq(_entries([_opp("OP1", "A", null, null)], {"OP1": true})[0]["name_jp"], "")


func test_meet_character_is_saved_and_reloaded() -> void:
	GameState.start_new_run(str(DataDB.player.get("player_id", "")))
	GameState.meet_character("OP1")
	GameState.meet_character("")
	var saved := GameState.to_save()
	GameState.start_new_run(str(DataDB.player.get("player_id", "")))
	assert_false(GameState.met_characters.has("OP1"), "a new run starts unmet")
	GameState.load_save(saved)
	assert_true(GameState.met_characters.has("OP1"))
	assert_false(GameState.met_characters.has(""))


func test_unmet_label_is_the_exact_japanese() -> void:
	assert_eq(Text.say("characters.unmet_name"), "誰ですか。")
