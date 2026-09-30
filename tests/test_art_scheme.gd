extends GutTest
## Where art is looked for (data/art.json, ArtLoader).


func test_each_kind_of_character_has_its_own_folder() -> void:
	assert_eq(ArtLoader.character_folder("PC01"), ArtLoader.folder("protagonist"))
	assert_eq(ArtLoader.character_folder("OP03"), ArtLoader.folder("opponent"))
	assert_eq(ArtLoader.character_folder("SF02"), ArtLoader.folder("staff"))
	assert_eq(ArtLoader.character_folder("VI01"), ArtLoader.folder("visitor"))
	# Journalists are opponents.json rows now (Role=Journalist), no separate
	# folder or ID prefix of their own (2026-09-26 pull) — OP110 (a real
	# journalist) goes with the opponents, same as any other OPxx.
	assert_eq(ArtLoader.character_folder("OP110"), ArtLoader.folder("opponent"))


func test_a_committee_members_name_goes_with_the_opponents() -> void:
	assert_eq(ArtLoader.character_folder("Member Tanaka"), ArtLoader.folder("opponent"))


func test_the_file_a_placeholder_asks_for() -> void:
	assert_eq(ArtLoader.expected_character_path("OP03", "guarding"),
		ArtLoader.folder("opponent") + "OP03_guarding.png")


func test_the_five_expressions_are_the_ones_the_art_file_lists() -> void:
	assert_eq(DataDB.art.get("expressions"),
		[ArtLoader.NEUTRAL, ArtLoader.ATTACKING, ArtLoader.GUARDING, ArtLoader.GAINING, ArtLoader.DAMAGED])


func test_a_missing_face_falls_back_to_neutral_in_the_end() -> void:
	assert_eq(ArtLoader.expression_chain("attacking"), ["attacking", "neutral"] as Array[String])
	assert_eq(ArtLoader.expression_chain("defeated"), ["defeated", "damaged", "neutral"] as Array[String])
	assert_eq(ArtLoader.expression_chain("neutral"), ["neutral"] as Array[String])


func test_art_that_is_not_drawn_gives_a_placeholder_not_nothing() -> void:
	assert_eq(ArtLoader.character_path("OP99", "attacking"), "")
	assert_not_null(ArtLoader.character("OP99", "attacking"))
	assert_not_null(ArtLoader.card("C999"))
	assert_not_null(ArtLoader.background("ST99"))


# ---------------------------------------------------------------------------
# Stage outfits (entirely optional, 2026-09-27) — a character can have one
# drawing for one room, without anything else needing to change.
# ---------------------------------------------------------------------------

func test_a_stage_id_is_tried_before_the_plain_file_of_the_same_expression() -> void:
	var candidates := ArtLoader.character_path_candidates("OP03", "attacking", "ST04")
	var folder := ArtLoader.folder("opponent")
	var stage_specific := candidates.find(folder + "OP03_ST04_attacking.png")
	var plain := candidates.find(folder + "OP03_attacking.png")
	assert_gte(stage_specific, 0, "the stage outfit is offered at all")
	assert_gte(plain, 0, "the plain drawing is still offered")
	assert_lt(stage_specific, plain, "the stage outfit comes first")


func test_a_plain_drawing_of_the_right_expression_still_beats_a_stage_outfit_of_the_wrong_one() -> void:
	# neutral (fallback) should never be offered, stage-specific or not,
	# before the plain RIGHT expression — expression_chain() order still
	# governs which expression is tried first.
	var candidates := ArtLoader.character_path_candidates("OP03", "attacking", "ST04")
	var folder := ArtLoader.folder("opponent")
	var plain_attacking := candidates.find(folder + "OP03_attacking.png")
	var stage_neutral := candidates.find(folder + "OP03_ST04_neutral.png")
	assert_gte(stage_neutral, 0)
	assert_lt(plain_attacking, stage_neutral)


func test_no_stage_id_means_no_stage_candidates_at_all() -> void:
	for candidate: String in ArtLoader.character_path_candidates("OP03", "attacking"):
		assert_false(candidate.contains("_ST"), candidate)


func test_a_stage_id_with_nothing_drawn_for_it_still_falls_back_cleanly() -> void:
	assert_eq(ArtLoader.character_path("OP99", "attacking", "ST04"), "")
	assert_not_null(ArtLoader.character("OP99", "attacking", "ST04"))


# ---------------------------------------------------------------------------
# PlaceholderArt's own art draws behind any child already in the scene
# (regression: the battle screen's "you" chip was hidden by the opponent
# portrait's own texture, which used to always land on top — 2026-09-27).
# ---------------------------------------------------------------------------

func test_the_art_and_label_are_always_the_back_two_children() -> void:
	var art := PlaceholderArt.new()
	var pretend_static_child := Control.new()
	pretend_static_child.name = "AlreadyThere"
	art.add_child(pretend_static_child)
	add_child_autofree(art)   # enters the tree -> _ready() -> _build()
	assert_eq(art.get_child_count(), 3)
	assert_eq(art.get_child(2).name, "AlreadyThere",
		"a child present before _build() runs stays in front of the art")


# ---------------------------------------------------------------------------
# Cosmetic packages (2026-09-28) — a bought-and-equipped outfit/background
# variant, resolved automatically from GameState.active_cosmetics, never
# passed explicitly by a call site. See CosmeticPieces.gd.
# ---------------------------------------------------------------------------

var _active_cosmetics_before: Dictionary = {}

# The workbook's own CP01/CP02 seed rows were removed 2026-09-30 (nothing
# to sell yet); these two fixtures stand in for them for this file's own
# duration, injected straight into DataDB the same way
# floor_vote_driver.gd/level_intro_driver.gd fake a row for a table that
# has nothing real in it.
const _FIXTURE_OUTFIT_BG := {"package_id": "CPTEST1", "outfit_variant": "RED",
	"background_variant": "UPGRADED"}
const _FIXTURE_MUSIC_ONLY := {"package_id": "CPTEST2", "music_office_sound": "music_office_test"}


func before_each() -> void:
	_active_cosmetics_before = GameState.active_cosmetics.duplicate(true)
	DataDB.cosmetic_packages.append(_FIXTURE_OUTFIT_BG)
	DataDB.cosmetic_packages.append(_FIXTURE_MUSIC_ONLY)
	DataDB._cosmetic_packages_by_id = DataDB._index(DataDB.cosmetic_packages, "package_id")


func after_each() -> void:
	GameState.active_cosmetics = _active_cosmetics_before
	DataDB.cosmetic_packages = DataDB.cosmetic_packages.filter(
		func(p: Dictionary) -> bool: return str(p.get("package_id", "")).begins_with("CPTEST") == false)
	DataDB._cosmetic_packages_by_id = DataDB._index(DataDB.cosmetic_packages, "package_id")


func test_an_explicit_variant_is_tried_before_stage_and_plain_candidates() -> void:
	var candidates := ArtLoader.character_path_candidates("OP03", "attacking", "ST04", "RED")
	var folder := ArtLoader.folder("opponent")
	var variant_stage := candidates.find(folder + "OP03_RED_ST04_attacking.png")
	var variant_plain := candidates.find(folder + "OP03_RED_attacking.png")
	var stage_only := candidates.find(folder + "OP03_ST04_attacking.png")
	assert_gte(variant_stage, 0)
	assert_gte(variant_plain, 0)
	assert_lt(variant_stage, variant_plain, "the variant's own stage outfit comes first")
	assert_lt(variant_plain, stage_only, "any variant candidate beats a plain stage outfit")


func test_no_variant_means_no_variant_candidates_at_all() -> void:
	for candidate: String in ArtLoader.character_path_candidates("OP03", "attacking"):
		assert_false(candidate.contains("_RED_"), candidate)


func test_an_equipped_outfit_only_ever_applies_to_the_current_protagonists_own_id() -> void:
	GameState.active_cosmetics = {CosmeticPieces.OUTFIT: "CPTEST1"}   # outfit_variant RED
	var protagonist_id := str(DataDB.player.get("player_id", ""))
	assert_eq(ArtLoader._outfit_variant(protagonist_id), "RED",
		"the protagonist's own portrait picks up the equipped outfit")
	assert_eq(ArtLoader._outfit_variant("OP03"), "",
		"an opponent never picks up the player's own cosmetic")
	assert_eq(ArtLoader._outfit_variant(""), "")


func test_no_outfit_equipped_means_the_plain_chain_unchanged() -> void:
	GameState.active_cosmetics = {}
	var protagonist_id := str(DataDB.player.get("player_id", ""))
	assert_false(ArtLoader.character_path(protagonist_id, "attacking").contains("_RED_"))


func test_an_equipped_background_only_ever_applies_to_office() -> void:
	GameState.active_cosmetics = {CosmeticPieces.BACKGROUND: "CPTEST1"}   # background_variant UPGRADED
	assert_eq(ArtLoader._background_variant("OFFICE"), "UPGRADED")
	assert_eq(ArtLoader._background_variant("ST02"), "",
		"a plain stage is never touched by the Office's own variant")
	# Real art or not, background() never comes back empty — either the
	# drawn OFFICE_UPGRADED.png/OFFICE.png, or a placeholder if neither is.
	assert_not_null(ArtLoader.background("OFFICE"))
	assert_not_null(ArtLoader.background("ST02"))


func test_a_music_only_package_never_touches_the_outfit_or_background_slots() -> void:
	GameState.active_cosmetics = {CosmeticPieces.MUSIC: "CPTEST2"}   # music-only package
	var protagonist_id := str(DataDB.player.get("player_id", ""))
	var with_music_only := ArtLoader.character_path(protagonist_id, "attacking")
	var office_with_music_only := ArtLoader.background_path("OFFICE")
	GameState.active_cosmetics = {}
	var with_nothing_equipped := ArtLoader.character_path(protagonist_id, "attacking")
	var office_with_nothing_equipped := ArtLoader.background_path("OFFICE")
	assert_eq(with_music_only, with_nothing_equipped,
		"CPTEST2 has no outfit_variant, so the plain (no-variant) chain is untouched")
	assert_eq(office_with_music_only, office_with_nothing_equipped,
		"CPTEST2 has no background_variant, so the Office background is untouched")
