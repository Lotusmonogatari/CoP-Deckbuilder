extends GutTest
## Topic-room player lines mixed into a bill level (Cameron, 2026-11-09): a
## share of moments use the room's own line on the player's side.


func test_the_share_follows_the_chance() -> void:
	var used := 0
	for moment in 1000:
		if CardCues.use_room_line(moment, 25):
			used += 1
	assert_eq(used, 250)
	assert_false(CardCues.use_room_line(7, 0), "0 turns it off")


func test_a_generic_room_has_no_room_lines() -> void:
	assert_eq(DataDB.get_room_player_cue_lines("ST05", "Earnest", "attack", "Support").size(), 0)


func test_room_lines_never_take_the_other_side() -> void:
	# Every topic room line returned for a lean is tagged with that lean or with none.
	for row: Dictionary in DataDB.player_cues:
		var stages: Variant = row.get("stage_ids")
		if not (stages is Array) or (stages as Array).is_empty():
			continue
		var stance := "" if row.get("stance") == null else str(row.get("stance"))
		if stance.is_empty():
			continue
		var other := "Oppose" if stance == "Support" else "Support"
		var sid := str((stages as Array)[0])
		for line: Dictionary in DataDB.get_room_player_cue_lines(sid, str(row["suit"]), str(row.get("verb", "")), other):
			assert_false(str(line["line_id"]).begins_with(str(row["cue_id"]) + "_"),
				"%s is %s and must not be said by a player leaning %s" % [row["cue_id"], stance, other])
	pass_test("no topic-room line is offered to the other side")
