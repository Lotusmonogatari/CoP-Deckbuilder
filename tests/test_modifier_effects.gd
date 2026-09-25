extends GutTest
## Tests for what an organisation's backing actually does.
##
## 2026-09-22 workbook: modifiers.json carries its own effect_type /
## effect_target / effect_value columns now, so there is no more hand-written
## bridge file to test the fallback of. These tests exercise the five
## effect_types ModifierEffects.gd now dispatches on directly.


func _mod(mod_id: String, effect_type: String, target: String, value: float,
		overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"mod_id": mod_id,
		"effect_type": effect_type,
		"effect_target": target,
		"effect_value": value,
	}
	base.merge(overrides, true)
	return base


# ---------------------------------------------------------------------------
# Which types are known
# ---------------------------------------------------------------------------

func test_all_five_documented_types_are_implemented() -> void:
	for pair: Array in [
		["RESOURCE_BONUS_ON_WIN", "XP"], ["STAGE_START_BONUS", "ST02"],
		["HAND_SIZE_BONUS", "ST04"], ["GAFFE_LIMIT_BONUS", "ST01"],
		["UNLOCK_DISCOUNT", "XPCost"],
	]:
		var modifier := _mod("M01", pair[0], pair[1], 1.0)
		assert_true(ModifierEffects.is_implemented(modifier), pair[0])


func test_an_unknown_type_is_not_implemented() -> void:
	assert_false(ModifierEffects.is_implemented(_mod("M99", "", "", 0.0)))


func test_a_value_that_is_not_set_is_worth_nothing() -> void:
	assert_eq(ModifierEffects.value_of({"mod_id": "M01"}), 0.0)


# ---------------------------------------------------------------------------
# Stage-start effects
# ---------------------------------------------------------------------------

func test_stage_start_bonus_raises_where_you_start() -> void:
	var active := [_mod("M01", "STAGE_START_BONUS", "ST02", 3.0)]
	var bonus := ModifierEffects.battle_start_bonus(active, "ST02")
	assert_eq(bonus["start_support"], 3)


func test_stage_start_bonus_ignores_a_different_stage() -> void:
	var active := [_mod("M01", "STAGE_START_BONUS", "ST04", 3.0)]
	var bonus := ModifierEffects.battle_start_bonus(active, "ST02")
	assert_eq(bonus["start_support"], 0)


func test_two_backers_stack() -> void:
	var active := [
		_mod("M01", "STAGE_START_BONUS", "ST02", 3.0),
		_mod("M02", "STAGE_START_BONUS", "ST02", 4.0),
	]
	var bonus := ModifierEffects.battle_start_bonus(active, "ST02")
	assert_eq(bonus["start_support"], 7)


func test_hand_size_bonus() -> void:
	var active := [_mod("M01", "HAND_SIZE_BONUS", "ST04", 2.0)]
	assert_eq(ModifierEffects.battle_start_bonus(active, "ST04")["hand_size_bonus"], 2)


func test_gaffe_limit_bonus() -> void:
	var active := [_mod("M01", "GAFFE_LIMIT_BONUS", "ST01", 1.0)]
	assert_eq(ModifierEffects.battle_start_bonus(active, "ST01")["gaffe_limit_bonus"], 1)


func test_nothing_owned_changes_nothing() -> void:
	var bonus := ModifierEffects.battle_start_bonus([], "ST02")
	assert_eq(bonus["start_support"], 0)
	assert_eq(bonus["hand_size_bonus"], 0)
	assert_eq(bonus["gaffe_limit_bonus"], 0)


# ---------------------------------------------------------------------------
# What a level win pays out
# ---------------------------------------------------------------------------

func test_a_resource_bonus_pays_the_target_it_names() -> void:
	var owned := [_mod("M01", "RESOURCE_BONUS_ON_WIN", "Yen", 10.0)]
	assert_eq(ModifierEffects.level_win_resource_bonus(owned, "Funds"), 10)


func test_a_resource_bonus_does_not_pay_a_different_resource() -> void:
	var owned := [_mod("M01", "RESOURCE_BONUS_ON_WIN", "Yen", 10.0)]
	assert_eq(ModifierEffects.level_win_resource_bonus(owned, "Constituency support"), 0)


func test_resource_bonuses_of_the_same_kind_stack() -> void:
	var owned := [
		_mod("M01", "RESOURCE_BONUS_ON_WIN", "XP", 10.0),
		_mod("M02", "RESOURCE_BONUS_ON_WIN", "XP", 15.0),
	]
	assert_eq(ModifierEffects.level_win_resource_bonus(owned, "XP"), 25)


func test_a_non_resource_modifier_pays_nothing() -> void:
	var owned := [_mod("M01", "STAGE_START_BONUS", "ST02", 9.0)]
	assert_eq(ModifierEffects.level_win_resource_bonus(owned, "XP"), 0,
		"start support is not an income")


# ---------------------------------------------------------------------------
# Unlock discounts
# ---------------------------------------------------------------------------

func test_unlock_discount_reads_the_matching_target() -> void:
	var owned := [_mod("M01", "UNLOCK_DISCOUNT", "XPCost", 0.1)]
	assert_almost_eq(ModifierEffects.unlock_discount(owned, "XPCost"), 0.1, 0.0001)


func test_unlock_discount_ignores_the_other_cost_kind() -> void:
	var owned := [_mod("M01", "UNLOCK_DISCOUNT", "Tier1Cost", 0.1)]
	assert_eq(ModifierEffects.unlock_discount(owned, "XPCost"), 0.0)


# ---------------------------------------------------------------------------
# What the player is told it does
# ---------------------------------------------------------------------------

## Stand-in wording, so this test checks that the real number reaches the
## sentence rather than pinning Cameron's phrasing. The real sentence is
## pinned once, in test_text.gd.
const EFFECT_WORDS := {
	"modifier.reputation_per_stage_win": "{count} funds a win",
}


func _words() -> Phrase:
	return Phrase.new(EFFECT_WORDS)


func test_a_resource_bonus_on_yen_uses_its_text_key() -> void:
	var modifier := _mod("M01", "RESOURCE_BONUS_ON_WIN", "Yen", 5.0)
	assert_eq(ModifierEffects.describe(modifier, _words()), "5 funds a win")


func test_everything_else_shows_the_workbooks_own_effect_sentence() -> void:
	# Unlike the old "+Magnitude..." column, the 2026-09-22 workbook's Effect
	# text is already a finished sentence with real numbers in it, so it is
	# shown as-is rather than built from a key. That is display-only prose —
	# the same rule CLAUDE.md sets for a card's effect_text — not the rules
	# engine parsing anything.
	var modifier := _mod("M13", "RESOURCE_BONUS_ON_WIN", "Jiban", 3.0,
		{"effect": "+3 Jiban after successful completion of a level."})
	assert_eq(ModifierEffects.describe(modifier, _words()),
		"+3 Jiban after successful completion of a level.")


func test_a_modifier_with_nothing_written_describes_itself_as_nothing() -> void:
	assert_eq(ModifierEffects.describe(_mod("M99", "", "", 1.0), _words()), "")


func test_a_stage_name_lookup_drops_the_internal_stxx_code() -> void:
	# "ST06 TV Debate gaffe limit +1." reads to the player as "TV Debate gaffe
	# limit +1." — the STxx code is workbook bookkeeping, not something a
	# player needs to see. Cameron, 2026-09-25.
	var modifier := _mod("M07", "GAFFE_LIMIT_BONUS", "ST06", 1.0,
		{"effect": "ST06 TV Debate gaffe limit +1."})
	assert_eq(ModifierEffects.describe(modifier, _words(), {"ST06": "TV Debate"}),
		"TV Debate gaffe limit +1.")


func test_a_stage_name_lookup_still_names_the_stage_when_the_sentence_lacked_one() -> void:
	# Some workbook rows name the STxx code with no stage name after it at
	# all ("ST04 starts with +5 Press tone."); the lookup fills that gap
	# rather than leaving a sentence with no subject.
	var modifier := _mod("M03", "STAGE_START_BONUS", "ST04", 5.0,
		{"effect": "ST04 starts with +5 Press tone."})
	assert_eq(ModifierEffects.describe(modifier, _words(), {"ST04": "Press Conference"}),
		"Press Conference starts with +5 Press tone.")


func test_a_stage_name_lookup_finds_the_code_mid_sentence_too() -> void:
	var modifier := _mod("M14", "HAND_SIZE_BONUS", "ST05", 1.0,
		{"effect": "+1 card drawn at the start of ST05 Town Hall."})
	assert_eq(ModifierEffects.describe(modifier, _words(), {"ST05": "Town Hall"}),
		"+1 card drawn at the start of Town Hall.")


func test_with_no_stage_name_lookup_the_stxx_code_is_left_alone() -> void:
	# Every existing call site that does not pass stage_names keeps seeing
	# exactly what the workbook wrote, unchanged.
	var modifier := _mod("M07", "GAFFE_LIMIT_BONUS", "ST06", 1.0,
		{"effect": "ST06 TV Debate gaffe limit +1."})
	assert_eq(ModifierEffects.describe(modifier, _words()),
		"ST06 TV Debate gaffe limit +1.")


# ---------------------------------------------------------------------------
# Against the real data
# ---------------------------------------------------------------------------

func test_every_modifier_in_the_workbook_has_a_type_the_code_knows() -> void:
	for modifier: Dictionary in DataDB.modifiers:
		assert_true(ModifierEffects.is_implemented(modifier),
			"%s has effect_type '%s', which ModifierEffects.gd does not know"
			% [modifier.get("mod_id"), modifier.get("effect_type")])


func test_no_description_from_real_data_shows_the_old_placeholder_word() -> void:
	# The guard on the whole idea: whatever a modifier is, the player must
	# never be shown a designer's raw placeholder.
	for modifier: Dictionary in DataDB.modifiers:
		var text := ModifierEffects.describe(modifier, Text.phrase())
		assert_false(text.contains("Magnitude"),
			"%s still shows the word Magnitude: '%s'" % [modifier.get("mod_id"), text])
