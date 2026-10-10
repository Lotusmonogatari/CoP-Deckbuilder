extends GutTest
## How a party sees the player: the blend of votes/rewards and stakeholders.

const BAL := {"party_opinion_direct_weight": 50, "party_opinion_stakeholder_weight": 50,
	"party_opinion_hostile_below": 20, "party_opinion_cold_below": 40,
	"party_opinion_neutral_below": 60, "party_opinion_warm_below": 80}


func _rows(pairs: Array) -> Array:
	var out := []
	for p: Array in pairs:
		out.append({"party_id": "PT01", "booster_id": p[0], "weight": p[1]})
	return out


func test_positive_weights_give_the_weighted_average() -> void:
	var got := PartyOpinion.stakeholder(_rows([["BO01", 1], ["BO02", 3]]), {"BO01": 40, "BO02": 80}, 30)
	assert_eq(got["score"], 70, "(40*1 + 80*3) / 4")


func test_a_negative_weight_is_a_rival() -> void:
	var friend := PartyOpinion.stakeholder(_rows([["BO01", 2], ["BO02", -2]]), {"BO01": 50, "BO02": 90}, 30)
	assert_lt(int(friend["score"]), 50, "a rival at 90 drags the party below neutral")
	var low := PartyOpinion.stakeholder(_rows([["BO01", 2], ["BO02", -2]]), {"BO01": 50, "BO02": 10}, 30)
	assert_gt(int(low["score"]), 50, "a rival at 10 lifts it above neutral")


func test_the_scale_of_the_weights_does_not_matter() -> void:
	var a := PartyOpinion.stakeholder(_rows([["BO01", 1], ["BO02", -1]]), {"BO01": 80, "BO02": 20}, 30)
	var b := PartyOpinion.stakeholder(_rows([["BO01", 10], ["BO02", -10]]), {"BO01": 80, "BO02": 20}, 30)
	assert_eq(a["score"], b["score"])


func test_no_rows_means_no_stakeholder_part_and_direct_stands_alone() -> void:
	var held := PartyOpinion.stakeholder([], {}, 30)
	assert_eq(held["score"], PartyOpinion.NO_SCORE)
	assert_eq(PartyOpinion.opinion(37, PartyOpinion.NO_SCORE, BAL), 37)


func test_the_default_blend_is_fifty_fifty() -> void:
	assert_eq(PartyOpinion.opinion(20, 60, BAL), 40)


func test_a_missing_standing_uses_the_default() -> void:
	var got := PartyOpinion.stakeholder(_rows([["BO09", 1]]), {}, 30)
	assert_eq(got["score"], 30)


func test_own_rows_apply_only_to_the_players_own_party() -> void:
	var table := [{"party_id": "OWN", "booster_id": "BO01", "weight": 5},
		{"party_id": "PT03", "booster_id": "BO10", "weight": 5}]
	assert_eq(PartyOpinion.rows_for(table, "PT03", "PT03").size(), 2)
	assert_eq(PartyOpinion.rows_for(table, "PT03", "PT01").size(), 1)
	assert_eq(PartyOpinion.rows_for(table, "PT01", "").size(), 0)


func test_bands_follow_the_balance_cut_offs() -> void:
	assert_eq(PartyOpinion.band(10, BAL), "hostile")
	assert_eq(PartyOpinion.band(39, BAL), "cold")
	assert_eq(PartyOpinion.band(59, BAL), "neutral")
	assert_eq(PartyOpinion.band(79, BAL), "warm")
	assert_eq(PartyOpinion.band(95, BAL), "allied")


# ---- against the real workbook data and GameState ---------------------------

func test_every_real_row_names_a_real_party_and_booster() -> void:
	var boosters := {}
	for b: Dictionary in DataDB.boosters:
		boosters[str(b["booster_id"])] = true
	var parties := {"OWN": true}
	for p: Dictionary in DataDB.parties:
		parties[str(p["party_id"])] = true
	assert_gt(DataDB.party_stakeholders.size(), 0)
	for row: Dictionary in DataDB.party_stakeholders:
		assert_true(parties.has(str(row["party_id"])), str(row))
		assert_true(boosters.has(str(row["booster_id"])), str(row))


func test_every_real_party_has_stakeholders() -> void:
	for p: Dictionary in DataDB.parties:
		var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, str(p["party_id"]), "")
		assert_gt(rows.size(), 0, str(p["name"]))


func test_the_players_own_party_reads_the_blend_not_the_raw_number() -> void:
	var before := GameState.meta.duplicate(true)
	var standing_before := GameState.booster_standing.duplicate(true)
	GameState.meta["Party support"] = 100
	for id: String in GameState.booster_standing.keys():
		GameState.booster_standing[id] = 30
	var own := GameState.own_party_id()
	if own.is_empty():
		pending("no player party loaded in this fixture")
	else:
		assert_lt(GameState.party_support_effective(), 100, "low organisations pull a maxed direct number down")
		assert_eq(GameState.effective_meta()["Party support"], GameState.party_support_effective())
	GameState.meta = before
	GameState.booster_standing = standing_before


func test_raising_a_tied_organisation_raises_the_opinion() -> void:
	var standing_before := GameState.booster_standing.duplicate(true)
	var party_id := "PT05"   # Keizaijiyuutou: Chamber of Commerce (BO05) is its biggest booster
	GameState.booster_standing["BO05"] = 30
	var low := GameState.party_opinion(party_id)
	GameState.booster_standing["BO05"] = 90
	var high := GameState.party_opinion(party_id)
	assert_gt(high, low)
	GameState.booster_standing = standing_before


func test_the_live_change_counts_both_votes_and_organisations() -> void:
	var meta_before := GameState.meta.duplicate(true)
	var change_before := GameState.last_meta_change.duplicate(true)
	var boost_before := GameState.last_booster_change.duplicate(true)
	var standing_before := GameState.booster_standing.duplicate(true)
	if GameState.own_party_id().is_empty():
		pending("no player party loaded in this fixture")
		return
	GameState.last_meta_change = {}
	GameState.last_booster_change = {}
	assert_eq(GameState.party_support_change_this_level(), 0, "nothing moved")
	# A vote raised the stored number by 20 this level; blended 50/50 that is +10.
	GameState.meta["Party support"] = int(GameState.meta["Party support"]) + 20
	GameState.last_meta_change = {"Party support": 20}
	assert_eq(GameState.party_support_change_this_level(), 10)
	# And an organisation tied to the party rising also counts.
	GameState.last_meta_change = {}
	var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, GameState.own_party_id(), GameState.own_party_id())
	var tied := str(rows[0]["booster_id"])
	GameState.booster_standing[tied] = int(GameState.booster_standing[tied]) + 20
	GameState.last_booster_change = {tied: 20}
	assert_ne(GameState.party_support_change_this_level(), 0)
	GameState.meta = meta_before
	GameState.last_meta_change = change_before
	GameState.last_booster_change = boost_before
	GameState.booster_standing = standing_before
