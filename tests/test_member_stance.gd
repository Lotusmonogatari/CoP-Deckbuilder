extends GutTest
## MemberStance (2026-11-04, Cameron): an opponent argues their own side of a
## bill, never the opposite of their party's position.

const PARTIES := [
	{"party_id": "PT01", "name": "Red", "leader_opp_id": "OP01"},
	{"party_id": "PT02", "name": "Blue", "leader_opp_id": "OP02"},
]


func _bill(red: String, blue: String, blue_votes := [10, 10, 0]) -> Dictionary:
	return {"bill_id": "BI99", "positions": [
		{"party_id": "PT01", "disposition": red, "votes_yes": 20, "votes_no": 0, "votes_abstain": 0, "cue_text": "Red line."},
		{"party_id": "PT02", "disposition": blue, "votes_yes": blue_votes[0], "votes_no": blue_votes[1],
			"votes_abstain": blue_votes[2], "cue_text": "Blue line."}]}


func test_members_and_leaders_argue_their_party_side() -> void:
	var bill := _bill("Supportive", "Opposed")
	assert_eq(MemberStance.sides({"opp_id": "OP05", "party": "Red"}, bill, PARTIES, {}, 30), ["Neutral", "For"])
	assert_eq(MemberStance.sides({"opp_id": "OP06", "party": "Blue"}, bill, PARTIES, {}, 30), ["Neutral", "Against"])
	assert_eq(MemberStance.sides({"opp_id": "OP01", "party": "Red"}, bill, PARTIES, {}, 30), ["Neutral", "For"])


## Cameron, 2026-11-04: a supporter argues FOR the bill against a player who
## opposes it, and the reverse; someone on the player's own side pushes them as
## a demanding ally instead, never with lines aimed at the other side.
func test_the_players_own_side_decides_argued_or_ally_lines() -> void:
	var bill := _bill("Supportive", "Opposed")
	var red := {"opp_id": "OP05", "party": "Red"}
	var blue := {"opp_id": "OP06", "party": "Blue"}
	assert_eq(MemberStance.sides(red, bill, PARTIES, {}, 30, "Against"), ["Neutral", "For"])
	assert_eq(MemberStance.sides(blue, bill, PARTIES, {}, 30, "For"), ["Neutral", "Against"])
	assert_eq(MemberStance.sides(red, bill, PARTIES, {}, 30, "For"), ["Neutral", "Ally"])
	assert_eq(MemberStance.sides(blue, bill, PARTIES, {}, 30, "Against"), ["Neutral", "Ally"])
	assert_eq(MemberStance.player_side_for("Support"), "For")
	assert_eq(MemberStance.player_side_for("Oppose"), "Against")
	assert_eq(MemberStance.player_side_for(""), "")


func test_a_neutral_partys_leader_takes_no_side() -> void:
	var bill := _bill("Supportive", "Neutral")
	assert_eq(MemberStance.sides({"opp_id": "OP02", "party": "Blue"}, bill, PARTIES, {}, 30), ["Neutral"])


func test_a_split_partys_members_follow_its_own_vote_split() -> void:
	# Blue is Opposed but half its seats abstain: members roll their own side
	# from 0 Aye / 10 Nay / 10 Abstain, so never For.
	var bill := _bill("Supportive", "Opposed", [0, 10, 10])
	var seen := {}
	for i in 60:
		var side := MemberStance.argued_side({"opp_id": "OPX%d" % i, "party": "Blue"}, bill, PARTIES, {}, 30)
		seen[side] = true
		assert_ne(side, "For", "a member never argues what none of the party voted for")
	assert_true(seen.has("Against") and seen.has(""), "both the party's Nay and its abstainers show up")
	# The leader still speaks for the party.
	assert_eq(MemberStance.argued_side({"opp_id": "OP02", "party": "Blue"}, bill, PARTIES, {}, 30), "Against")


func test_a_members_rolled_side_is_fixed() -> void:
	var bill := _bill("Supportive", "Neutral", [10, 10, 0])
	var member := {"opp_id": "OP77", "party": "Blue"}
	var first := MemberStance.argued_side(member, bill, PARTIES, {}, 30)
	for _i in 5:
		assert_eq(MemberStance.argued_side(member, bill, PARTIES, {}, 30), first)


func test_someone_without_a_party_follows_their_organization() -> void:
	var bill := _bill("Supportive", "Opposed")
	var sides := {"supporters": ["BO08"], "opponents": ["BO05"]}
	assert_eq(MemberStance.argued_side({"opp_id": "OP90", "affiliation": "BO08"}, bill, PARTIES, sides, 30), "For")
	assert_eq(MemberStance.argued_side({"opp_id": "OP91", "affiliation": "BO05"}, bill, PARTIES, sides, 30), "Against")
	assert_eq(MemberStance.argued_side({"opp_id": "OP92", "affiliation": "BO99"}, bill, PARTIES, sides, 30), "")


func test_only_a_leader_gets_the_party_vote_line() -> void:
	var bill := _bill("Supportive", "Opposed")
	assert_eq(MemberStance.leader_line({"opp_id": "OP02", "party": "Blue"}, bill, PARTIES), "Blue line.")
	assert_eq(MemberStance.leader_line({"opp_id": "OP06", "party": "Blue"}, bill, PARTIES), "")


## The real data: in every bill level, nobody seated in its rooms is ever
## handed a line on the side opposite to their own.
func test_no_one_in_a_bill_room_contradicts_their_side() -> void:
	var opposite := {"For": "Against", "Against": "For"}
	var split := int(DataDB.balance.get("member_stance_split_party_abstain_percent", 30))
	var side_of := {}   # "bill|line" -> side
	for row: Dictionary in DataDB.opponent_cues:
		for bill_id: Variant in (row.get("bill_ids") if row.get("bill_ids") is Array else []):
			for n in range(1, 6):
				var line: Variant = row.get("cue_%d" % n)
				if line != null:
					var side: Variant = row.get("cue_%d_side" % n)
					side_of["%s|%s" % [bill_id, line]] = "Neutral" if side == null else str(side)
	var bad: Array[String] = []
	var checked := 0
	for level: Dictionary in DataDB.levels:
		var bill: Dictionary = DataDB.get_floor_vote(str(level.get("level_id", "")))
		if bill.is_empty():
			continue
		var bill_id := str(bill["bill_id"])
		var stake := BillStance.sides(bill, DataDB.law_effects, GameState._party_tier_booster_ids())
		for i in range(1, 11):
			var stage := DataDB.get_stage(str(level.get("stage_%d" % i, "")))
			if str(stage.get("mode", "")) != "Combat":
				continue
			for opponent: Dictionary in DataDB.get_opponents_for_stage(str(stage.get("stage_id", ""))):
				var argued := MemberStance.argued_side(opponent, bill, DataDB.parties, stake, split)
				# Every player lean: none, For, Against. A same-side speaker
				# says only Neutral and Ally lines.
				for player_side: String in ["", "For", "Against"]:
					var allowed := MemberStance.sides(opponent, bill, DataDB.parties, stake, split, player_side)
					var ally := not argued.is_empty() and argued == player_side
					for suit_row: Dictionary in DataDB.suits:
						for verb: String in ["attack", "gain", "block"]:
							for line: String in DataDB.get_bill_opponent_cue_lines(bill_id, str(opponent["opp_id"]),
									str(suit_row.get("element", "")), verb, allowed):
								checked += 1
								var side := str(side_of.get("%s|%s" % [bill_id, line], "Neutral"))
								var wrong: bool = side == opposite.get(argued, "") \
									or (argued.is_empty() and side != "Neutral") \
									or (ally and side not in ["Neutral", "Ally"]) \
									or (not ally and side == "Ally")
								if wrong:
									bad.append("%s %s (%s, player %s) says %s line: %s"
										% [bill_id, opponent["opp_id"], argued, player_side, side, line])
	assert_gt(checked, 1000, "the audit looked at real lines")
	assert_eq(bad.slice(0, 5), [] as Array[String])
