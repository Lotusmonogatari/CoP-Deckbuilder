extends GutTest
## Staff rank rewards stack (Cameron, 2026-10-30): each rank lists only what it
## ADDS, because GameState._apply_staff_reward() pays just the newly reached
## rank. A higher rank that repeats a lower rank's line would pay it twice.


func test_no_rank_repeats_a_lower_ranks_reward_line() -> void:
	var repeats: Array[String] = []
	for candidate: Dictionary in DataDB.staff:
		var seen := {}
		for tier in range(0, 3):
			var rewards: Variant = candidate.get("tier_%d_reward" % tier)
			if not (rewards is Array):
				continue
			for reward: Dictionary in rewards:
				var line := "%s %+d" % [reward.get("target"), int(reward.get("delta", 0))]
				if seen.has(line):
					repeats.append("%s rank %d repeats %s" % [candidate.get("staff_id"), tier, line])
				seen[line] = true
	assert_eq(repeats, [], "a rank's reward list should hold only what that rank adds")
