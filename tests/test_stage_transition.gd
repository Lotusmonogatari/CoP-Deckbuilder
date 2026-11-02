extends GutTest
## StageTransition.gd: which characters, background, and dialogue a stage's
## transition beat shows. Fake rows throughout, the same convention
## test_level_intro_cues.gd/test_office_ticker.gd already use.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_should_show_is_false_when_the_column_is_blank() -> void:
	assert_false(StageTransition.should_show({}))


func test_should_show_is_false_on_an_explicit_no() -> void:
	assert_false(StageTransition.should_show({"show_transition": "No"}))


func test_should_show_is_true_on_an_explicit_yes() -> void:
	assert_true(StageTransition.should_show({"show_transition": "Yes"}))


func test_speaker_count_defaults_to_one() -> void:
	assert_eq(StageTransition.speaker_count({}), 1)


func test_speaker_count_reads_the_column() -> void:
	assert_eq(StageTransition.speaker_count({"transition_speaker_count": 3}), 3)


func test_character_kind_tells_opponent_from_staff() -> void:
	assert_eq(StageTransition.character_kind("OP03"), "opponent")
	assert_eq(StageTransition.character_kind("SF08"), "staff")
	assert_eq(StageTransition.character_kind("BI01"), "")


func test_resolve_is_empty_when_the_stage_does_not_show_a_transition() -> void:
	var stage := {"stage_id": "ST02", "show_transition": "No"}
	var cast := [{"transition_cast_id": "TC01", "stage_id": "ST02", "character_id": "OP03"}]
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": "ST02", "character_id": "OP03",
		"character_line_en": "Line.", "player_reply_en": "Reply."}]
	assert_eq(StageTransition.resolve(stage, cast, [], dialogue, _rng(1)), {})


func test_resolve_is_empty_when_switched_on_but_nothing_is_eligible() -> void:
	var stage := {"stage_id": "ST02", "show_transition": "Yes"}
	assert_eq(StageTransition.resolve(stage, [], [], [], _rng(1)), {})


func test_resolve_picks_a_speaker_with_their_own_dialogue_and_a_background() -> void:
	var stage := {"stage_id": "ST02", "show_transition": "Yes"}
	var cast := [{"transition_cast_id": "TC01", "stage_id": "ST02", "character_id": "OP03"}]
	var backgrounds := [{"transition_background_id": "TB01", "stage_id": "ST02", "background_id": "ST02"}]
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": "ST02", "character_id": "OP03",
		"character_line_en": "You again.", "player_reply_en": "Let's talk."}]

	var result := StageTransition.resolve(stage, cast, backgrounds, dialogue, _rng(1))
	assert_eq(result["background_id"], "ST02")
	assert_eq(result["speakers"].size(), 1)
	assert_eq(result["speakers"][0], {
		"character_id": "OP03",
		"character_line": "You again.",
		"player_reply": "Let's talk.",
		"line_key": "OP03|You again.",
	})


func test_a_cast_candidate_with_no_written_dialogue_never_speaks() -> void:
	var stage := {"stage_id": "ST02", "show_transition": "Yes"}
	var cast := [
		{"transition_cast_id": "TC01", "stage_id": "ST02", "character_id": "OP03"},
		{"transition_cast_id": "TC02", "stage_id": "ST02", "character_id": "OP04"},
	]
	# Only OP04 has a written exchange.
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": "ST02", "character_id": "OP04",
		"character_line_en": "Hello.", "player_reply_en": "Hi."}]

	var speakers := StageTransition.pick_speakers(cast, dialogue, "ST02", 2, _rng(1))
	assert_eq(speakers.size(), 1)
	assert_eq(speakers[0]["character_id"], "OP04")


func test_pick_speakers_never_repeats_the_same_character_twice() -> void:
	var stage_id := "ST02"
	var cast := [
		{"transition_cast_id": "TC01", "stage_id": stage_id, "character_id": "OP03"},
		{"transition_cast_id": "TC02", "stage_id": stage_id, "character_id": "OP04"},
	]
	var dialogue := [
		{"transition_dialogue_id": "TD01", "stage_id": stage_id, "character_id": "OP03",
			"character_line_en": "A.", "player_reply_en": "a."},
		{"transition_dialogue_id": "TD02", "stage_id": stage_id, "character_id": "OP04",
			"character_line_en": "B.", "player_reply_en": "b."},
	]

	var speakers := StageTransition.pick_speakers(cast, dialogue, stage_id, 2, _rng(5))
	assert_eq(speakers.size(), 2)
	assert_ne(speakers[0]["character_id"], speakers[1]["character_id"])


func test_pick_speakers_stops_at_the_pool_size_rather_than_failing() -> void:
	var stage_id := "ST02"
	var cast := [{"transition_cast_id": "TC01", "stage_id": stage_id, "character_id": "OP03"}]
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": stage_id, "character_id": "OP03",
		"character_line_en": "A.", "player_reply_en": "a."}]

	# Asking for 3 speakers with only 1 real candidate plays with whoever
	# exists, the same bargain BattleSetup._opponents_for() already strikes.
	var speakers := StageTransition.pick_speakers(cast, dialogue, stage_id, 3, _rng(1))
	assert_eq(speakers.size(), 1)


func test_a_wildcard_stage_id_row_is_eligible_for_any_stage() -> void:
	var stage := {"stage_id": "ST09", "show_transition": "Yes"}
	var cast := [{"transition_cast_id": "TC01", "stage_id": "", "character_id": "SF08"}]
	var backgrounds := [{"transition_background_id": "TB01", "stage_id": "", "background_id": "OFFICE"}]
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": "", "character_id": "SF08",
		"character_line_en": "Good luck in there.", "player_reply_en": "Thanks."}]

	var result := StageTransition.resolve(stage, cast, backgrounds, dialogue, _rng(1))
	assert_eq(result["speakers"][0]["character_id"], "SF08")
	assert_eq(result["background_id"], "OFFICE")


func test_unhired_staff_never_speak_but_hired_staff_and_opponents_can() -> void:
	var cast := [
		{"stage_id": null, "character_id": "SF01"},
		{"stage_id": null, "character_id": "SF02"},
		{"stage_id": null, "character_id": "OP03"},
	]
	var dialogue: Array = []
	for id in ["SF01", "SF02", "OP03"]:
		dialogue.append({"stage_id": null, "character_id": id,
			"character_line_en": "Hello.", "player_reply_en": "Hi."})
	for seed_value in range(1, 30):
		var speakers := StageTransition.pick_speakers(cast, dialogue, "ST19", 3, _rng(seed_value), ["SF02"])
		var ids: Array = speakers.map(func(s: Dictionary) -> String: return s["character_id"])
		assert_false("SF01" in ids)
		assert_true("SF02" in ids)
		assert_true("OP03" in ids)
	# No staff hired: only the opponent can speak.
	var none := StageTransition.pick_speakers(cast, dialogue, "ST19", 3, _rng(1), [])
	assert_eq(none.size(), 1)


func test_with_nobody_to_speak_the_player_has_a_thought() -> void:
	var cast := [{"stage_id": null, "character_id": "SF01"}]
	var dialogue := [
		{"stage_id": null, "character_id": "SF01", "character_line_en": "Hi.", "player_reply_en": "Hello."},
		{"stage_id": null, "character_id": "PLAYER", "character_line_en": "Steady now.", "player_reply_en": null},
	]
	var stage := {"stage_id": "ST20", "show_transition": "Yes"}
	var result := StageTransition.resolve(stage, cast, [], dialogue, _rng(1), [])
	assert_eq(result["speakers"].size(), 0)
	assert_eq(result["thought"], "Steady now.")
	# With the staff hired, they speak instead and there is no thought.
	var hired := StageTransition.resolve(stage, cast, [], dialogue, _rng(1), ["SF01"])
	assert_eq(hired["speakers"].size(), 1)
	assert_eq(hired["thought"], "")


func test_no_thought_rows_means_no_transition() -> void:
	var stage := {"stage_id": "ST20", "show_transition": "Yes"}
	assert_true(StageTransition.resolve(stage, [], [], [], _rng(1), []).is_empty())


func test_no_media_ambush_stage_shows_a_transition() -> void:
	for stage: Dictionary in DataDB.stages:
		if "Media Ambush" in str(stage.get("name_en", "")):
			assert_false(StageTransition.should_show(stage), str(stage.get("stage_id")))


## Audit: a line anyone can pull (blank Stage ID) must not talk about a
## press, camera or studio room, and a topic line must only be scoped to
## a room of the matching kind.
func test_generic_transition_lines_fit_every_room() -> void:
	var banned := ["camera", "reporter", "journalist", "press", "studio", "headline", "broadcast"]
	for row: Dictionary in DataDB.transition_dialogue:
		var raw: Variant = row.get("stage_id")
		if raw != null and str(raw).strip_edges() != "":
			continue
		# A line about one bill (Bill ID) is about that bill's subject, which
		# may well be cameras or the press.
		var bill_raw: Variant = row.get("bill_id")
		if bill_raw != null and str(bill_raw).strip_edges() != "":
			continue
		var comp_raw: Variant = row.get("component_ids")
		if comp_raw is Array and not (comp_raw as Array).is_empty():
			continue
		var text := (str(row.get("character_line_en", "")) + " " + str(row.get("player_reply_en", ""))).to_lower()
		for word: String in banned:
			var hit := RegEx.create_from_string("\\b" + word + "(s|es)?\\b").search(text) != null
			assert_false(hit, "%s mentions '%s' but fits every room" % [row.get("transition_dialogue_id"), word])


func test_press_and_camera_lines_only_in_press_style_rooms() -> void:
	var ok_kinds := ["Press", "TV Debate", "Media Ambush"]
	for row: Dictionary in DataDB.transition_dialogue:
		var text := (str(row.get("character_line_en", "")) + " " + str(row.get("player_reply_en", ""))).to_lower()
		var raw: Variant = row.get("stage_id")
		if raw == null or str(raw) == "":
			continue
		var is_press_line := "reporter" in text or "studio" in text or "viewers" in text
		if not is_press_line:
			continue
		# The Stage ID cell may list several stages ("ST04; ST26").
		for stage_id: String in str(raw).split(";"):
			var name := str(DataDB.get_stage(stage_id.strip_edges()).get("name_en", ""))
			var fits := false
			for kind: String in ok_kinds:
				if name.begins_with(kind):
					fits = true
			assert_true(fits, "%s (%s) is a press/studio line in %s" % [row.get("transition_dialogue_id"), text, name])


func test_a_thought_can_open_a_transition_that_has_speakers() -> void:
	var stage := {"stage_id": "ST02", "show_transition": "Yes"}
	var cast := [{"stage_id": "ST02", "character_id": "OP03"}]
	var dialogue := [
		{"stage_id": "ST02", "character_id": "OP03", "character_line_en": "Hi.", "player_reply_en": "Hello."},
		{"stage_id": null, "character_id": "PLAYER", "character_line_en": "Steady now.", "player_reply_en": null},
	]
	var always := StageTransition.resolve(stage, cast, [], dialogue, _rng(1), null, 100)
	assert_eq(always["thought"], "Steady now.")
	assert_eq(always["speakers"].size(), 1)
	var never := StageTransition.resolve(stage, cast, [], dialogue, _rng(1), null, 0)
	assert_eq(never["thought"], "")


# ---------------------------------------------------------------------------
# Who speaks and what is repeated (2026-11-02)
# ---------------------------------------------------------------------------

func _mixed_room() -> Array:
	# A hired staff member (any stage) and a cast opponent, both with a line.
	var cast := [
		{"transition_cast_id": "TC01", "stage_id": null, "character_id": "SF01"},
		{"transition_cast_id": "TC02", "stage_id": "ST02", "character_id": "OP03"},
	]
	var dialogue := [
		{"transition_dialogue_id": "TD01", "stage_id": null, "character_id": "SF01",
			"character_line_en": "Staff line.", "player_reply_en": "Ok."},
		{"transition_dialogue_id": "TD02", "stage_id": "ST02", "character_id": "OP03",
			"character_line_en": "Opponent line.", "player_reply_en": "Ok."},
	]
	return [cast, dialogue]


func test_staff_chance_decides_between_staff_and_opponent() -> void:
	var room := _mixed_room()
	for seed_value in range(1, 21):
		var staff := StageTransition.pick_speakers(room[0], room[1], "ST02", 1, _rng(seed_value), ["SF01"], "", "", [], 100)
		assert_eq(staff[0]["character_id"], "SF01", "100 percent is always staff")
		var other := StageTransition.pick_speakers(room[0], room[1], "ST02", 1, _rng(seed_value), ["SF01"], "", "", [], 0)
		assert_eq(other[0]["character_id"], "OP03", "0 percent is always the opponent")


func test_staff_chance_cannot_pick_a_kind_that_is_not_there() -> void:
	var room := _mixed_room()
	# Staff not hired: only the opponent is eligible, whatever the chance says.
	var only := StageTransition.pick_speakers(room[0], room[1], "ST02", 1, _rng(3), [], "", "", [], 100)
	assert_eq(only[0]["character_id"], "OP03")


func test_the_last_speaker_is_not_picked_again_when_someone_else_will_do() -> void:
	var room := _mixed_room()
	for seed_value in range(1, 21):
		var next := StageTransition.pick_speakers(room[0], room[1], "ST02", 1, _rng(seed_value),
			["SF01"], "", "", [], -1, {"speaker": "SF01"})
		assert_eq(next[0]["character_id"], "OP03")


func test_the_last_speaker_may_repeat_when_they_are_the_only_one() -> void:
	var room := _mixed_room()
	var next := StageTransition.pick_speakers(room[0], room[1], "ST02", 1, _rng(1),
		[], "", "", [], -1, {"speaker": "OP03"})
	assert_eq(next[0]["character_id"], "OP03")


func test_a_line_already_heard_is_skipped_for_another() -> void:
	var cast := [{"transition_cast_id": "TC01", "stage_id": null, "character_id": "SF01"}]
	var dialogue := [
		{"transition_dialogue_id": "TD01", "stage_id": null, "character_id": "SF01",
			"character_line_en": "First.", "player_reply_en": "Ok."},
		{"transition_dialogue_id": "TD02", "stage_id": null, "character_id": "SF01",
			"character_line_en": "Second.", "player_reply_en": "Ok."},
	]
	var heard := {StageTransition.line_key("SF01", "First."): true}
	for seed_value in range(1, 21):
		var next := StageTransition.pick_speakers(cast, dialogue, "ST02", 1, _rng(seed_value),
			["SF01"], "", "", [], -1, {"lines": heard})
		assert_eq(next[0]["character_line"], "Second.")


func test_a_heard_line_is_repeated_when_it_is_the_only_one_written() -> void:
	var cast := [{"transition_cast_id": "TC01", "stage_id": null, "character_id": "SF01"}]
	var dialogue := [{"transition_dialogue_id": "TD01", "stage_id": null, "character_id": "SF01",
		"character_line_en": "Only.", "player_reply_en": "Ok."}]
	var heard := {StageTransition.line_key("SF01", "Only."): true}
	var next := StageTransition.pick_speakers(cast, dialogue, "ST02", 1, _rng(1),
		["SF01"], "", "", [], -1, {"lines": heard})
	assert_eq(next[0]["character_line"], "Only.")


func test_a_thought_already_heard_is_skipped_for_another() -> void:
	var rows := [
		{"character_id": "PLAYER", "stage_id": null, "character_line_en": "One."},
		{"character_id": "PLAYER", "stage_id": null, "character_line_en": "Two."},
	]
	var heard := {StageTransition.line_key("PLAYER", "One."): true}
	for seed_value in range(1, 21):
		assert_eq(StageTransition.player_thought(rows, "ST02", _rng(seed_value), heard), "Two.")


func test_every_staff_candidate_can_speak_in_a_transition() -> void:
	# Hiring any of the 21 staff must give a voice (2026-11-02): they were cast
	# and written for only six before.
	for staff: Dictionary in DataDB.staff:
		var staff_id := str(staff.get("staff_id", ""))
		var cast := DataDB.transition_cast.filter(func(row: Dictionary) -> bool:
			return str(row.get("character_id", "")) == staff_id and row.get("stage_id") == null)
		assert_false(cast.is_empty(), "%s is in Transition Cast for every stage" % staff_id)
		var lines := DataDB.transition_dialogue.filter(func(row: Dictionary) -> bool:
			return str(row.get("character_id", "")) == staff_id and row.get("stage_id") == null \
				and row.get("bill_id") == null)
		assert_gte(lines.size(), 8, "%s has general lines to say at any stage" % staff_id)


func test_the_floor_vote_gets_a_transition() -> void:
	assert_true(StageTransition.should_show(DataDB.get_stage("ST23")))


func test_a_party_leader_title_is_found_among_several_titles() -> void:
	var naizen := {"title": "Minister of Ethics and Prosecution; Chair of the Committee on Ethics and Prosecution; Leader of the Butsutou"}
	assert_eq(OpponentDisplay.party_leader_title(naizen), "Leader of the Butsutou")
	assert_eq(OpponentDisplay.title_for(naizen), "Minister of Ethics and Prosecution",
		"the first-title rule is unchanged elsewhere")
	assert_eq(OpponentDisplay.party_leader_title({"title": "Prime Minister"}), "")
	assert_eq(OpponentDisplay.party_leader_title({"title": null}), "")


func test_every_party_leader_is_cast_at_the_floor_vote() -> void:
	# The leaders come from the Title column ("Leader of the ..."), which agrees
	# with Parties' Leader Opp ID; each is cast at ST23 with lines written for it.
	for party: Dictionary in DataDB.parties:
		var leader_id := str(party.get("leader_opp_id", ""))
		assert_false(leader_id.is_empty(), "%s has a leader" % party.get("name"))
		assert_ne(OpponentDisplay.party_leader_title(DataDB.get_opponent(leader_id)), "",
			"%s's Title column says they lead a party" % leader_id)
		var cast := DataDB.transition_cast.filter(func(row: Dictionary) -> bool:
			return str(row.get("character_id", "")) == leader_id and str(row.get("stage_id", "")) == "ST23")
		assert_false(cast.is_empty(), "%s is cast at ST23" % leader_id)
		var lines := DataDB.transition_dialogue.filter(func(row: Dictionary) -> bool:
			return str(row.get("character_id", "")) == leader_id and str(row.get("stage_id", "")) == "ST23")
		assert_gte(lines.size(), 4, "%s has lines for the vote" % leader_id)
