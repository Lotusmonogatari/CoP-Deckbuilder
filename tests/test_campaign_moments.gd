extends GutTest
## P20 phase C (2026-11-26, Cameron): the Campaign Moment! rules. Which Random scenes may be drawn, the weighted draw, the colleague, the
## challenge and the follow-ups a challenge decides.


func _scene(id: String, extra: Dictionary = {}) -> Dictionary:
	var base := {"scene_id": id, "event_id": "EV" + id, "kind": "Random", "card": "Campaign", "office": "District", "weight": 3, "weight_late": null,
		"repeat": null, "cooldown_weeks": null, "phase": null, "needs": null, "speaker": null}
	base.merge(extra, true)
	return base


func _context(extra: Dictionary = {}) -> Dictionary:
	var base := {"phase": "building", "office": "District", "locked": "", "colleague": true,
		"facts": {"office_open": true, "van": false, "van_speech_done": false, "staff_hired": false, "staff_free": false}}
	base.merge(extra, true)
	return base


func test_weight_late_applies_after_building_only_when_filled() -> void:
	var scene := _scene("A", {"weight": 2, "weight_late": 5})
	assert_eq(CampaignMoments.weight_in(scene, "building"), 2)
	assert_eq(CampaignMoments.weight_in(scene, "mustering"), 5)
	assert_eq(CampaignMoments.weight_in(scene, "announcement"), 5, "the announcement day counts as mustering")
	assert_eq(CampaignMoments.weight_in(_scene("B", {"weight": 4}), "campaign"), 4, "an empty Weight Late keeps Weight")


func test_phase_lists() -> void:
	var scene := _scene("A", {"phase": ["building", "mustering"]})
	assert_true(CampaignMoments.phase_allows(scene, "building"))
	assert_true(CampaignMoments.phase_allows(scene, "mustering"))
	assert_false(CampaignMoments.phase_allows(scene, "campaign"))
	assert_true(CampaignMoments.phase_allows(_scene("B", {"phase": ["any"]}), "campaign"))
	assert_true(CampaignMoments.phase_allows(_scene("C"), "campaign"), "a blank list means any")


func test_needs() -> void:
	var facts := {"office_open": true, "van": false, "van_speech_done": false, "staff_hired": true, "staff_free": false}
	assert_true(CampaignMoments.needs_met(["office_open", "campaign_staff_hired"], facts))
	assert_false(CampaignMoments.needs_met(["van_speech_done"], facts))
	assert_false(CampaignMoments.needs_met(["campaign_staff_free"], facts))
	assert_true(CampaignMoments.needs_met([], facts))


func test_eligibility_phase_office_log_and_cooldown() -> void:
	var scenes := [_scene("A"), _scene("B", {"office": "Capitol"}), _scene("C", {"phase": ["campaign"]}), _scene("D", {"needs": ["van_speech_done"]}),
		_scene("E", {"repeat": "Y", "cooldown_weeks": 4})]
	var ids := func(list: Array) -> Array:
		return list.map(func(s: Dictionary) -> String: return str(s["scene_id"]))
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {}, {}, 100, _context())), ["A", "E"], "District, building, no van speech")
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {"A": {"day": 1, "choice": "A"}}, {}, 100, _context())), ["E"], "a scene that has fired does not come again")
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {"E": {"day": 1, "choice": "A"}}, {"E": 90}, 100, _context())), ["A"], "a repeat scene waits out its cooldown (28 days)")
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {}, {"E": 60}, 100, _context())), ["A", "E"], "and comes back after it")


func test_a_colleague_scene_needs_a_colleague_and_other_cycles_only_allow_colleagues() -> void:
	var scenes := [_scene("A"), _scene("B", {"speaker": "colleague"})]
	var ids := func(list: Array) -> Array:
		return list.map(func(s: Dictionary) -> String: return str(s["scene_id"]))
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {}, {}, 1, _context({"colleague": false}))), ["A"])
	assert_eq(ids.call(CampaignMoments.eligible(scenes, {}, {}, 1, _context({"locked": "stepped_aside"}))), ["B"], "when the player is not standing, only colleagues ask")
	assert_eq(CampaignMoments.eligible(scenes, {}, {}, 1, _context({"locked": "not_selected"})), [], "nothing after Not Selected")


func test_the_draw_is_by_weight_and_repeatable() -> void:
	var candidates := [_scene("A", {"weight": 1}), _scene("B", {"weight": 3})]
	assert_eq(CampaignMoments.draw(candidates, "building", 0.0)["scene_id"], "A")
	assert_eq(CampaignMoments.draw(candidates, "building", 0.24)["scene_id"], "A")
	assert_eq(CampaignMoments.draw(candidates, "building", 0.26)["scene_id"], "B")
	assert_eq(CampaignMoments.draw(candidates, "building", 0.999)["scene_id"], "B")
	assert_eq(CampaignMoments.draw([], "building", 0.5), {})


func test_the_colleague_is_never_the_leader_or_a_whip() -> void:
	var party := {"name": "P", "short_name": "P", "leader_opp_id": "OP1", "assistant_whip_opp_id": "OP2", "deputy_whip_opp_id": "OP3", "chief_whip_opp_id": "OP4"}
	var opponents := []
	for i in range(1, 8):
		opponents.append({"opp_id": "OP%d" % i, "party": "P", "party_acronym": "P"})
	opponents.append({"opp_id": "OP9", "party": "Q", "party_acronym": "Q"})
	var seen := {}
	for step in 20:
		seen[CampaignMoments.pick_colleague(opponents, party, float(step) / 20.0)] = true
	assert_eq(seen.keys().size(), 3, "only OP5, OP6 and OP7 can be drawn")
	assert_false(seen.has("OP1") or seen.has("OP2") or seen.has("OP3") or seen.has("OP4") or seen.has("OP9"))
	assert_eq(CampaignMoments.pick_colleague(opponents, party, 0.5), CampaignMoments.pick_colleague(opponents, party, 0.5), "the same roll, the same person")
	assert_eq(CampaignMoments.pick_colleague([], party, 0.5), "")


func test_challenges_count_inside_their_window_and_are_judged() -> void:
	var spec := CampaignMoments.parse_challenge("CM01x3in14")
	assert_eq(spec, {"activity": "CM01", "count": 3, "days": 14})
	assert_eq(CampaignMoments.parse_challenge("nonsense"), {})
	var challenge := CampaignMoments.start_challenge("DS16", spec, 100)
	challenge = CampaignMoments.counted(challenge, "CM01", 101)
	challenge = CampaignMoments.counted(challenge, "CM02", 101)
	assert_eq(int(challenge["done"]), 1, "another activity does not count")
	assert_eq(CampaignMoments.verdict(challenge, 105), "")
	challenge = CampaignMoments.counted(challenge, "CM01", 110)
	challenge = CampaignMoments.counted(challenge, "CM01", 114)
	assert_eq(CampaignMoments.verdict(challenge, 114), CampaignMoments.CHALLENGE_MET)
	var late := CampaignMoments.counted(CampaignMoments.start_challenge("DS16", spec, 100), "CM01", 120)
	assert_eq(int(late["done"]), 0, "a call after the window does not count")
	assert_eq(CampaignMoments.verdict(late, 114), CampaignMoments.CHALLENGE_FAILED)


func test_follow_ups_that_a_challenge_decides() -> void:
	var scenes := [
		{"scene_id": "S1", "follows": null, "kind": "Mandatory"},
		{"scene_id": "S2", "follows": "S1", "delay": 14, "follow_if": ["CHALLENGE_MET"], "kind": "Mandatory"},
		{"scene_id": "S3", "follows": "S1", "delay": 14, "follow_if": ["CHALLENGE_FAILED"], "kind": "Mandatory"}]
	var log := {"S1": {"day": 100, "choice": "A"}}
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 114, {}), [], "undecided: neither opens")
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 114, {"S1": "challenge_met"}).map(func(s: Dictionary) -> String: return str(s["scene_id"])), ["S2"])
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 114, {"S1": "challenge_failed"}).map(func(s: Dictionary) -> String: return str(s["scene_id"])), ["S3"])
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 110, {"S1": "challenge_met"}), [], "not before its Delay")


func test_activation_kinds_and_campaign_staff_speakers() -> void:
	var parsed := DecisionScenes.parse_activates("venue:VN10; campaign_staff:CS02@A; challenge:CM01x3in14@A")
	assert_eq(parsed.map(func(p: Dictionary) -> String: return str(p["kind"])), ["venue", "campaign_staff", "challenge"])
	assert_eq(DecisionScenes.person_kind("CS04"), "campaign_staff")
