extends GutTest
## Costed venue activities, the pure rules (2026-11-24): daily limits, the use log, the staff-hour bonus, the shrine's milestones.

var _clean := {"activity_id": "VA08", "venue_id": "VN08", "kind": "act", "per_day": 2}
var _read := {"activity_id": "VA15", "venue_id": "VN02", "kind": "act", "per_day": 1, "staff_hours": 1,
	"bonus_after_uses": 50, "bonus_staff_hours": 1}


func test_a_daily_limit_counts_uses_today_and_starts_again_tomorrow() -> void:
	var log := {}
	assert_eq(VenueActivities.left_today(_clean, log, 10), 2)
	log = VenueActivities.with_use(log, "VA08", 10)
	assert_eq(VenueActivities.left_today(_clean, log, 10), 1, "one use of two is gone")
	log = VenueActivities.with_use(log, "VA08", 10)
	assert_eq(VenueActivities.left_today(_clean, log, 10), 0, "the limit is reached")
	assert_eq(VenueActivities.left_today(_clean, log, 11), 2, "a new day starts again")
	assert_eq(VenueActivities.uses_today(log, "VA08", 11), 0)


func test_an_activity_with_no_limit_is_never_used_up() -> void:
	assert_eq(VenueActivities.left_today({"activity_id": "VA99", "per_day": null}, {}, 1), -1)


func test_the_log_is_not_changed_by_adding_a_use() -> void:
	var log := {"VA08": {"day": 3, "count": 1}}
	var next := VenueActivities.with_use(log, "VA08", 3)
	assert_eq(int(log["VA08"]["count"]), 1, "the old log is untouched")
	assert_eq(int(next["VA08"]["count"]), 2)


func test_reading_gives_one_staff_hour_and_two_after_fifty_uses() -> void:
	assert_eq(VenueActivities.staff_hours(_read, 0), 1)
	assert_eq(VenueActivities.staff_hours(_read, 49), 1, "the 50th use is still the base")
	assert_eq(VenueActivities.staff_hours(_read, 50), 2, "the 51st use gets the bonus")
	assert_eq(VenueActivities.staff_hours(_read, 300), 2, "a flat bonus, not a growing one")
	assert_eq(VenueActivities.staff_hours(_clean, 100), 0, "an activity with no staff hours gives none")


func test_a_milestone_is_reached_once_when_the_count_crosses_it() -> void:
	var rows := [{"activity_id": "VA11", "count": 5}, {"activity_id": "VA11", "count": 30}, {"activity_id": "VA99", "count": 5}]
	assert_eq(VenueActivities.milestones_crossed(rows, "VA11", 3, 4).size(), 0)
	assert_eq(VenueActivities.milestones_crossed(rows, "VA11", 4, 5).size(), 1, "the 5th use")
	assert_eq(VenueActivities.milestones_crossed(rows, "VA11", 5, 6).size(), 0, "never again once passed")
	assert_eq(VenueActivities.milestones_crossed(rows, "VA11", 0, 40).size(), 2, "a jump crosses both, lowest first")
	assert_true(VenueActivities.has_milestones(rows, "VA11"))
	assert_false(VenueActivities.has_milestones(rows, "VA08"))


func test_a_venue_is_built_when_any_activity_is() -> void:
	var rows := [{"venue_id": "VN02", "kind": "read"}, {"venue_id": "VN02", "kind": "act"}, {"venue_id": "VN05", "kind": "show"}]
	assert_true(VenueRules.venue_built(rows, "VN02"), "the Library has two usable activities beside a greyed one")
	assert_false(VenueRules.venue_built(rows, "VN05"))
	assert_eq(VenueActivities.activities_of(rows, "VN02").size(), 2)
