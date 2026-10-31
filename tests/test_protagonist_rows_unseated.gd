extends GutTest
## Each protagonist also has an Opponents-tab row (same name), which must never
## sit in a room: a player could otherwise argue against themself (2026-10-31,
## after OP06, PC03's row, was seated in two hearings by mistake). Names come
## from the workbook, never typed here.


func test_no_protagonist_row_is_seated_anywhere() -> void:
	var names := {}
	for protagonist: Dictionary in DataDB.protagonists:
		names[str(protagonist.get("name_en", ""))] = str(protagonist.get("player_id", ""))
	for opponent: Dictionary in DataDB.opponents:
		var name := str(opponent.get("name", ""))
		if names.has(name):
			var stages: Variant = opponent.get("stages")
			assert_true(stages == null or (stages as Array).is_empty(),
				"%s (%s, protagonist %s) sits in %s" % [opponent.get("opp_id"), name, names[name], stages])
