extends GutTest
## GameState.party_favorability()/apply_floor_vote_favorability(): the
## player's own party reads straight off "Party support" (no second number
## to keep in sync); every other party lives in party_standing, clamped the
## same way booster_standing already is. GameState is an autoload, so these
## tests put it back the way they found it.

var _meta_before: Dictionary = {}
var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}
var _player_before: Dictionary = {}


func before_each() -> void:
	_meta_before = GameState.meta.duplicate(true)
	_standing_before = GameState.party_standing.duplicate(true)
	_change_before = GameState.last_party_change.duplicate(true)
	_player_before = DataDB.player.duplicate(true)
	DataDB.player["party"] = "Frontier Party"
	GameState.meta["Party support"] = 50
	GameState.party_standing = {"Keizaijiyuutou": 50, "Country Initiative": 50}


func after_each() -> void:
	GameState.meta = _meta_before.duplicate(true)
	GameState.party_standing = _standing_before.duplicate(true)
	GameState.last_party_change = _change_before.duplicate(true)
	DataDB.player = _player_before.duplicate(true)


func test_the_players_own_party_reads_party_support() -> void:
	GameState.meta["Party support"] = 63
	assert_eq(GameState.party_favorability("Frontier Party"), 63)


func test_another_party_reads_its_own_entry() -> void:
	assert_eq(GameState.party_favorability("Keizaijiyuutou"), 50)


func test_an_unknown_partys_favorability_falls_back_to_fifty() -> void:
	assert_eq(GameState.party_favorability("Five Point Independents"), 50)


func test_applying_favorability_moves_the_players_own_party_through_party_support() -> void:
	GameState.apply_floor_vote_favorability({"Frontier Party": 5})
	assert_eq(int(GameState.meta["Party support"]), 55)
	assert_false(GameState.party_standing.has("Frontier Party"))


func test_applying_favorability_moves_another_partys_own_entry() -> void:
	GameState.apply_floor_vote_favorability({"Keizaijiyuutou": -8})
	assert_eq(GameState.party_favorability("Keizaijiyuutou"), 42)
	assert_eq(int(GameState.last_party_change["Keizaijiyuutou"]), -8)


func test_a_zero_delta_touches_nothing() -> void:
	GameState.apply_floor_vote_favorability({"Country Initiative": 0})
	assert_false(GameState.last_party_change.has("Country Initiative"))


func test_several_parties_move_in_one_call() -> void:
	GameState.apply_floor_vote_favorability({
		"Frontier Party": 3, "Keizaijiyuutou": -2, "Country Initiative": 1,
	})
	assert_eq(int(GameState.meta["Party support"]), 53)
	assert_eq(GameState.party_favorability("Keizaijiyuutou"), 48)
	assert_eq(GameState.party_favorability("Country Initiative"), 51)
