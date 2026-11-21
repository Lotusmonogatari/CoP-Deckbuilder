extends GutTest
## The red outfit (cosmetic package CP01, outfit variant RED) has a picture for every protagonist and every expression
## (2026-11-21: PC02 and PC03 joined PC01 and PC04). The loader looks for <ID>_RED_<expression>.png; a file named any other way is
## never found, so the picture check below is the whole wiring.

const EXPRESSIONS := ["neutral", "attacking", "damaged", "gaining", "guarding", "victory"]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false


func after_each() -> void:
	GameState.active_cosmetics.clear()


func test_every_protagonist_has_a_red_outfit_picture_for_every_expression() -> void:
	GameState.owned_cosmetic_packages.append("CP01")
	GameState.active_cosmetics[CosmeticPieces.OUTFIT] = "CP01"
	for id: String in ["PC01", "PC02", "PC03", "PC04"]:
		DataDB.use_protagonist(id)   # the outfit is worn only by the current protagonist's own id
		GameState.protagonist_id = id
		for expression: String in EXPRESSIONS:
			var path := ArtLoader.character_path(id, expression)
			assert_true(path.ends_with("%s_RED_%s.png" % [id, expression]), "%s %s wears red: %s" % [id, expression, path])


func test_without_the_outfit_the_plain_picture_is_used() -> void:
	for id: String in ["PC02", "PC03"]:
		DataDB.use_protagonist(id)
		GameState.protagonist_id = id
		assert_true(ArtLoader.character_path(id, "neutral").ends_with("%s_neutral.png" % id))
