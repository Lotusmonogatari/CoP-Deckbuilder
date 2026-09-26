extends GutTest
## The messages a broken data file produces.
##
## Cameron is the one who reads these, and he is not a programmer. A report
## that names the wrong file is worse than a vague one: it sends him to open
## something that is not broken.
##
## The hand-written files carry their content under a named key — "effects",
## "patterns", "types", "cards" — which is usually NOT the filename. The
## error text used to be built out of that key, so a malformed
## playtest_cards.json reported its problem against cards.json: a real file,
## and an innocent one.

var _errors_before: PackedStringArray = []


func before_each() -> void:
	# DataDB is an autoload and these helpers append to its error list, so
	# put it back afterwards — another test file asserts the data is clean.
	_errors_before = DataDB.errors.duplicate()


func after_each() -> void:
	DataDB.errors = _errors_before.duplicate()


func _last_error() -> String:
	return "" if DataDB.errors.is_empty() else str(DataDB.errors[-1])


# ---------------------------------------------------------------------------
# A map that is not there
# ---------------------------------------------------------------------------

func test_a_missing_map_names_the_file_it_is_missing_from() -> void:
	DataDB._map_under({"something_else": {}}, "sounds", "speech")

	assert_string_contains(_last_error(), "sounds.json",
		"the reader has to be sent to the file that is actually broken")
	assert_string_contains(_last_error(), "'speech'",
		"and told which part of it is missing")


func test_a_file_of_the_wrong_shape_names_itself() -> void:
	DataDB._map_under([], "stage_types", "types")

	# Anchored at the start, because every message opens with the filename —
	# and because "stage_types.json" contains "types.json" as a substring, so
	# a looser check here would pass whether or not the bug was fixed.
	assert_true(_last_error().begins_with("stage_types.json"),
		"the message should open by naming the real file, not 'types.json': %s"
			% _last_error())


# ---------------------------------------------------------------------------
# A list that is not there
# ---------------------------------------------------------------------------

func test_a_missing_list_names_the_file_it_is_missing_from() -> void:
	DataDB._list_under({"nothing": []}, "playtest_cards", "cards")

	# The worst of the six: cards.json is a real file, and an innocent one,
	# so this error used to send the reader somewhere there was nothing to
	# find. Anchored at the start for the same reason as above —
	# "playtest_cards.json" contains "cards.json".
	assert_true(_last_error().begins_with("playtest_cards.json"),
		"this used to open by blaming cards.json: %s" % _last_error())


func test_a_list_file_of_the_wrong_shape_names_itself() -> void:
	DataDB._list_under("not an object at all", "level_opponent_overrides", "overrides")
	assert_string_contains(_last_error(), "level_opponent_overrides.json")


# ---------------------------------------------------------------------------
# And nothing is reported when the file is fine
# ---------------------------------------------------------------------------

func test_a_good_file_reports_nothing() -> void:
	var before := DataDB.errors.size()
	var got := DataDB._map_under({"sounds": {"a": {}}}, "sounds", "sounds")

	assert_eq(DataDB.errors.size(), before, "a file that is fine is not complained about")
	assert_true(got.has("a"), "and its contents come back")
