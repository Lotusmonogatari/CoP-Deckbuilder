extends GutTest
## QC audit 2026-11-03: every crisis-trigger alert the game raises has its own
## Text row, now that the key is written out rather than built at runtime.

const OFFICE := preload("res://scripts/ui/OfficeScreen.gd")


func test_every_alert_key_has_a_text_row() -> void:
	for kind: String in OFFICE.TRIGGER_ALERT_KEYS:
		for edge: String in OFFICE.TRIGGER_ALERT_KEYS[kind]:
			var key: String = OFFICE.TRIGGER_ALERT_KEYS[kind][edge]
			assert_true(Text.has(key), key)


func test_every_alert_gamestate_raises_is_in_the_table() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/autoload/GameState.gd")
	var pattern := RegEx.new()
	pattern.compile('"kind": "([a-z_]+)", "edge": "([a-z]+)"')
	var found := 0
	for hit in pattern.search_all(source):
		found += 1
		var row: Dictionary = OFFICE.TRIGGER_ALERT_KEYS.get(hit.get_string(1), {})
		assert_true(row.has(hit.get_string(2)), "%s.%s" % [hit.get_string(1), hit.get_string(2)])
	assert_gt(found, 0)
