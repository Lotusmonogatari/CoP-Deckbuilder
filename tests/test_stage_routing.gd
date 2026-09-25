extends GutTest
## StageRouting.gd — which scene plays a given stage. Small and pure, but
## three screens all depend on it agreeing with itself (OfficeScreen opening
## a level or resuming one, BattleScreen and VisitorScreen moving on to the
## next stage of the same level), so it gets its own direct coverage rather
## than only being exercised indirectly through those screens.

func test_a_non_combat_stage_plays_on_the_visitor_screen() -> void:
	assert_eq(StageRouting.scene_for({"mode": "Non-combat"}), StageRouting.VISITOR_SCENE)


func test_a_combat_stage_plays_on_the_battle_screen() -> void:
	assert_eq(StageRouting.scene_for({"mode": "Combat"}), StageRouting.BATTLE_SCENE)


func test_a_stage_with_no_mode_at_all_defaults_to_the_battle_screen() -> void:
	# Every hand-written playtest fixture predates "mode" existing at all —
	# the same "missing means Combat" default LevelRunner.problems() already
	# applies to its own opponents-or-questions check.
	assert_eq(StageRouting.scene_for({}), StageRouting.BATTLE_SCENE)
