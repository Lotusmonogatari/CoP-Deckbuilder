extends GutTest
## Tests for what an organisation's backing actually does.
##
## The point of these is that a modifier's strength stays a number in the
## workbook and its behaviour stays a named key — never a sentence the code
## reads. If prose ever starts driving a rule, one of these breaks.


const BRIDGE := {
	"M01": "player_start_support",
	"M03": "starting_gaffe",
	"M02": "kaban_per_stage_win",
	"M13": "jiban_per_module_win",
}


func _mod(mod_id: String, magnitude: float, overrides: Dictionary = {}) -> Dictionary:
	var base := {"mod_id": mod_id, "magnitude": magnitude}
	base.merge(overrides, true)
	return base


# ---------------------------------------------------------------------------
# Where the key comes from
# ---------------------------------------------------------------------------

func test_the_workbook_column_wins_over_the_bridge() -> void:
	# The bridge is temporary. The day the column lands it must take over
	# without anybody remembering to delete the file.
	var modifier := _mod("M01", 3.0, {"effect_key": "starting_gaffe"})
	assert_eq(ModifierEffects.key_for(modifier, BRIDGE), "starting_gaffe")


func test_the_bridge_is_used_when_the_column_is_missing() -> void:
	assert_eq(ModifierEffects.key_for(_mod("M01", 3.0), BRIDGE), "player_start_support")


func test_a_modifier_nobody_has_mapped_has_no_key() -> void:
	assert_eq(ModifierEffects.key_for(_mod("M99", 1.0), BRIDGE), "")


func test_an_empty_column_falls_through_to_the_bridge() -> void:
	var modifier := _mod("M01", 3.0, {"effect_key": "   "})
	assert_eq(ModifierEffects.key_for(modifier, BRIDGE), "player_start_support",
		"a blank cell is not a key")


# ---------------------------------------------------------------------------
# Built, versus known but not built
# ---------------------------------------------------------------------------

func test_a_built_effect_reports_itself_as_built() -> void:
	assert_true(ModifierEffects.is_implemented(_mod("M01", 3.0), BRIDGE))
	assert_true(ModifierEffects.is_implemented(_mod("M02", 5.0), BRIDGE))


func test_a_module_level_effect_is_known_but_not_built() -> void:
	# The shop must say "not active yet" rather than selling it silently.
	var modifier := _mod("M13", 3.0)
	assert_false(ModifierEffects.is_implemented(modifier, BRIDGE))
	assert_true(ModifierEffects.is_known_but_unbuilt(modifier, BRIDGE))


func test_an_unmapped_modifier_is_neither() -> void:
	var modifier := _mod("M99", 1.0)
	assert_false(ModifierEffects.is_implemented(modifier, BRIDGE))
	assert_false(ModifierEffects.is_known_but_unbuilt(modifier, BRIDGE))


# ---------------------------------------------------------------------------
# What they do to a battle
# ---------------------------------------------------------------------------

func test_backing_raises_where_you_start() -> void:
	var bonus := ModifierEffects.battle_start_bonus([_mod("M01", 3.0)], BRIDGE)
	assert_eq(bonus["start_support"], 3)


func test_two_backers_stack() -> void:
	var bonus := ModifierEffects.battle_start_bonus(
		[_mod("M01", 3.0), _mod("M01", 4.0)], BRIDGE)
	assert_eq(bonus["start_support"], 7)


func test_a_friendly_reporter_takes_the_heat_off() -> void:
	# The column reads "−Magnitude starting gaffe meter", so the sign lives
	# in the prose and the number is taken off here.
	var bonus := ModifierEffects.battle_start_bonus([_mod("M03", 1.0)], BRIDGE)
	assert_eq(bonus["starting_gaffe"], -1)


func test_backing_nobody_bought_changes_nothing() -> void:
	var bonus := ModifierEffects.battle_start_bonus([], BRIDGE)
	assert_eq(bonus["start_support"], 0)
	assert_eq(bonus["starting_gaffe"], 0)


func test_a_magnitude_that_is_not_set_is_worth_nothing() -> void:
	assert_eq(ModifierEffects.magnitude_of({"mod_id": "M01"}), 0)


func test_a_fractional_magnitude_rounds() -> void:
	# The workbook stores these as floats; the meters are whole numbers.
	assert_eq(ModifierEffects.magnitude_of({"magnitude": 3.0}), 3)
	assert_eq(ModifierEffects.magnitude_of({"magnitude": 2.5}), 3)


# ---------------------------------------------------------------------------
# What they pay out
# ---------------------------------------------------------------------------

func test_a_business_circle_pays_for_a_stage_won() -> void:
	assert_eq(ModifierEffects.stage_win_funds([_mod("M02", 5.0)], BRIDGE), 5)


func test_only_the_paying_kind_pays() -> void:
	assert_eq(ModifierEffects.stage_win_funds([_mod("M01", 9.0)], BRIDGE), 0,
		"start support is not an income")


# ---------------------------------------------------------------------------
# Against the real data
# ---------------------------------------------------------------------------

func test_every_mapped_modifier_in_the_bridge_is_real() -> void:
	# A typo in the bridge file would otherwise silently map nothing.
	for mod_id: String in DataDB.modifier_effects.keys():
		assert_false(DataDB.get_modifier(mod_id).is_empty(),
			"%s is mapped to an effect but is not a modifier" % mod_id)


func test_every_bridged_effect_is_one_the_code_knows() -> void:
	for mod_id: String in DataDB.modifier_effects.keys():
		var key := str(DataDB.modifier_effects[mod_id])
		assert_true(
			ModifierEffects.AT_BATTLE_START.has(key)
			or ModifierEffects.AFTER_STAGE_WIN.has(key)
			or ModifierEffects.NOT_YET_BUILT.has(key),
			"%s is mapped to '%s', which nothing implements or lists" % [mod_id, key])


# ---------------------------------------------------------------------------
# What the player is told it does
# ---------------------------------------------------------------------------
# The effect column says "Magnitude" where a number belongs, because it was
# written for a designer. Putting that on a shop screen asks the player to
# read a spreadsheet.

## Stand-in wording, so this test checks that the real NUMBER reaches the
## sentence rather than pinning Cameron's phrasing. The real sentences are
## pinned once, in test_text.gd.
const EFFECT_WORDS := {
	"modifier.player_start_support": "start {count} ahead",
	"modifier.kaban_per_stage_win": "{count} funds a win",
}


func _words() -> Phrase:
	return Phrase.new(EFFECT_WORDS)


func test_a_built_effect_is_described_with_its_real_number() -> void:
	assert_eq(ModifierEffects.describe(_mod("M01", 3.0), BRIDGE, _words()),
		"start 3 ahead")
	assert_eq(ModifierEffects.describe(_mod("M02", 5.0), BRIDGE, _words()),
		"5 funds a win")


func test_an_unbuilt_effect_keeps_its_prose_but_gains_its_number() -> void:
	# A display substitution, not the rules reading a sentence.
	var modifier := _mod("M13", 3.0, {"effect": "+Magnitude Jiban per module win"})
	assert_eq(ModifierEffects.describe(modifier, BRIDGE, _words()),
		"+3 Jiban per module win")


func test_a_modifier_with_nothing_written_describes_itself_as_nothing() -> void:
	assert_eq(ModifierEffects.describe(_mod("M99", 1.0), BRIDGE, _words()), "")


func test_no_description_leaves_the_word_magnitude_on_screen() -> void:
	# The guard on the whole idea: whatever a modifier is, the player must
	# never be shown the designer's placeholder word.
	for modifier: Dictionary in DataDB.modifiers:
		var text := ModifierEffects.describe(modifier, DataDB.modifier_effects,
			Text.phrase())
		assert_false(text.contains("Magnitude"),
			"%s still shows the word Magnitude: '%s'" % [modifier.get("mod_id"), text])


func test_an_effect_with_nothing_to_bite_on_is_not_called_built() -> void:
	# Taking a point off a meter that always opens at zero is a point off
	# nothing. The shop must not sell it as working.
	var modifier := _mod("M03", 1.0)
	assert_true(ModifierEffects.is_inert_today(modifier, BRIDGE))
	assert_false(ModifierEffects.is_implemented(modifier, BRIDGE),
		"correct, wired, and currently worth nothing")


func test_the_effects_that_do_bite_still_report_as_built() -> void:
	assert_true(ModifierEffects.is_implemented(_mod("M01", 3.0), BRIDGE))
	assert_false(ModifierEffects.is_inert_today(_mod("M01", 3.0), BRIDGE))
