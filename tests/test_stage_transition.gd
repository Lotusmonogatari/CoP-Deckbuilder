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
