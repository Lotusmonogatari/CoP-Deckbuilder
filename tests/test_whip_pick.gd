extends GutTest
## Whip scenes (P15, 2026-11-23): who whips the player by Party support, the party's line, and what lost whip fights lock.

const BANDS := {"assistant": [0, 30], "deputy": [31, 71], "chief": [72, 89], "minister": [90, 97], "leader": [98, 100]}
const PARTY := {"party_id": "PT03", "name": "Frontier Party", "short_name": "FP", "leader_opp_id": "OP27",
	"assistant_whip_opp_id": "OP132", "deputy_whip_opp_id": "OP133", "chief_whip_opp_id": "OP134"}
const FP_MINISTER := {"opp_id": "OP82", "party": "Frontier Party", "party_acronym": "FP"}


func test_every_band_edge_picks_the_role_on_its_side() -> void:
	for pair: Array in [[0, "assistant"], [30, "assistant"], [31, "deputy"], [71, "deputy"], [72, "chief"], [89, "chief"],
			[90, "minister"], [97, "minister"], [98, "leader"], [100, "leader"]]:
		assert_eq(WhipPick.role_for(int(pair[0]), BANDS), pair[1], "Party support %d" % int(pair[0]))
	assert_eq(WhipPick.role_for(-5, BANDS), "assistant", "below zero counts as zero")
	assert_eq(WhipPick.role_for(140, BANDS), "leader", "above 100 counts as 100")


func test_the_bands_must_cover_zero_to_one_hundred_once() -> void:
	assert_true(WhipPick.bands_cover(BANDS))
	var gap := BANDS.duplicate(true)
	gap["deputy"] = [32, 71]
	assert_false(WhipPick.bands_cover(gap), "31 is in no band")
	var overlap := BANDS.duplicate(true)
	overlap["chief"] = [71, 89]
	assert_false(WhipPick.bands_cover(overlap), "71 is in two bands")


func test_the_pick_is_the_partys_whip_for_that_band() -> void:
	assert_eq(WhipPick.pick(10, BANDS, PARTY, FP_MINISTER), "OP132")
	assert_eq(WhipPick.pick(50, BANDS, PARTY, FP_MINISTER), "OP133")
	assert_eq(WhipPick.pick(80, BANDS, PARTY, FP_MINISTER), "OP134")
	assert_eq(WhipPick.pick(99, BANDS, PARTY, FP_MINISTER), "OP27", "the party leader")


func test_a_minister_whips_only_when_in_the_players_party() -> void:
	assert_eq(WhipPick.pick(93, BANDS, PARTY, FP_MINISTER), "OP82")
	var other := {"party": "Butsutou", "party_acronym": "BU"}
	var bu_party := PARTY.duplicate()
	bu_party["name"] = "Butsutou"
	bu_party["short_name"] = "BU"
	assert_eq(WhipPick.pick(93, BANDS, bu_party, FP_MINISTER), "OP134", "the Chief Whip stands in for another party's minister")
	assert_eq(WhipPick.pick(93, BANDS, PARTY, {}), "OP134", "a blank Minister is the Chief Whip too")
	assert_eq(WhipPick.pick(93, BANDS, PARTY, other), "OP134")


func test_a_missing_whip_cell_gives_no_pick() -> void:
	var bare := {"name": "Frontier Party", "short_name": "FP", "assistant_whip_opp_id": null}
	assert_eq(WhipPick.pick(5, BANDS, bare, {}), "", "a blank cell is no pick, not 'null'")


func test_the_partys_line_comes_from_its_floor_vote_position() -> void:
	var bill := {"positions": [{"party_id": "PT01", "disposition": "Supportive"}, {"party_id": "PT02", "disposition": "Opposed"},
		{"party_id": "PT03", "disposition": "Neutral"}]}
	assert_eq(WhipPick.party_line(bill, "PT01"), WhipPick.YES)
	assert_eq(WhipPick.party_line(bill, "PT02"), WhipPick.NO)
	assert_eq(WhipPick.party_line(bill, "PT03"), "", "a free vote has no line")
	assert_eq(WhipPick.party_line(bill, "PT09"), "", "no position, no line")


func test_a_scene_can_name_its_own_line() -> void:
	var bill := {"positions": [{"party_id": "PT01", "disposition": "Supportive"}]}
	assert_eq(WhipPick.line_for({"whip_line": "Nay"}, bill, "PT01"), WhipPick.NO)
	assert_eq(WhipPick.line_for({"whip_line": "Aye"}, bill, "PT01"), WhipPick.YES)
	assert_eq(WhipPick.line_for({"whip_line": null}, bill, "PT01"), WhipPick.YES, "blank means the party's line")


func test_no_lock_leaves_the_vote_free() -> void:
	var state := WhipPick.resolve([])
	assert_eq(state["state"], "free")
	assert_eq(state["allowed"], ["Yes", "No", "Abstain"])


func test_one_lock_holds_the_vote_to_what_the_whip_asked() -> void:
	var state := WhipPick.resolve([{"choice": "No", "by": "OP29", "scene_id": "DS05"}])
	assert_eq(state["state"], "locked")
	assert_eq(state["allowed"], ["No"])


func test_two_locks_force_an_abstention() -> void:
	var state := WhipPick.resolve([{"choice": "No", "by": "OP29", "scene_id": "DS06"}, {"choice": "Yes", "by": "OP133", "scene_id": "DS07"}])
	assert_eq(state["state"], "abstain")
	assert_eq(state["allowed"], ["Abstain"])


func test_the_same_scene_never_locks_a_bill_twice() -> void:
	var once := WhipPick.with_lock([], {"choice": "No", "by": "OP29", "scene_id": "DS06"})
	var again := WhipPick.with_lock(once, {"choice": "No", "by": "OP29", "scene_id": "DS06"})
	assert_eq(again.size(), 1)
	assert_eq(WhipPick.resolve(again)["state"], "locked")
