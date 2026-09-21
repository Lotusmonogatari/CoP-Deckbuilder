class_name ModifierEffects
extends RefCounted
## What an organisation's backing actually does.
##
## The same shape as SpecialEffects.gd, and for the same reason. The
## `effect` column in modifiers.json is prose written for a designer —
## "+Magnitude player start support" — and CLAUDE.md forbids parsing it: a
## rule that lives in a sentence breaks the moment the sentence is reworded.
##
## So the machine-readable half is a KEY plus the `magnitude` column the
## workbook already has. The key is a new column Cameron has been asked to
## approve; until it lands, `data/modifier_effects.json` supplies the same
## mapping by mod_id so the five straightforward ones work now. That file is
## a bridge and says so — when the column is approved it goes away.
##
## WHAT IS AND IS NOT BUILT. Five of the eleven purchasable modifiers change
## something at the start of a battle or at the end of a stage, which is all
## the machinery that exists today. The other six are module-level or depend
## on a bill's tags, and need the module runner at M4. Those are listed here
## as known-but-unbuilt rather than left out, so the shop can say "not active
## yet" instead of selling something inert.

## Effects that change the battle the moment it is set up.
const AT_BATTLE_START := [
	"player_start_support",   # +magnitude seats/support before the first turn
	"starting_gaffe",         # -magnitude on the gaffe meter
]

## Effects that pay out when a stage is won.
const AFTER_STAGE_WIN := [
	"kaban_per_stage_win",    # +magnitude Funds
]

## Named, understood, and waiting on machinery that does not exist yet.
## Listed so the shop tells the truth rather than staying quiet.
const NOT_YET_BUILT := [
	"opp_start_support_on_tag",   # needs bills to carry tags
	"kaban_per_module",           # needs the module runner (M4)
	"party_support_per_module",
	"jiban_per_module_win",
	"negates_cold_shoulder",
	"start_lean_in_committee",
	"halve_jiban_losses",
]


## The key for a modifier, from the workbook column if it is there and from
## the bridge file if it is not.
static func key_for(modifier: Dictionary, bridge: Dictionary = {}) -> String:
	var key := str(modifier.get("effect_key", "")).strip_edges()
	if not key.is_empty():
		return key
	return str(bridge.get(str(modifier.get("mod_id", "")), ""))


## How much of it. The workbook's own column, so the strength of a modifier
## stays a number Cameron tunes rather than one written into code.
static func magnitude_of(modifier: Dictionary) -> int:
	var value: Variant = modifier.get("magnitude")
	return 0 if value == null else int(round(float(value)))


## Effects that are wired but cannot bite yet, because nothing else in the
## game produces the situation they answer.
##
## "starting_gaffe" is the whole list so far. The meter always opens at zero
## and backing cannot put it into credit, so taking a point off zero is a
## point off nothing. It will matter the moment something raises where the
## player starts — an opponent modifier like M07 Scandal Coverage, or a
## reputation penalty. Until then the shop says so rather than selling it.
##
## Cameron may prefer it to raise the gaffe LIMIT instead, which would make
## it bite immediately; that is his call, not a bug to fix here.
const INERT_TODAY := ["starting_gaffe"]


## True where buying this modifier will actually change a battle today.
static func is_implemented(modifier: Dictionary, bridge: Dictionary = {}) -> bool:
	var key := key_for(modifier, bridge)
	if INERT_TODAY.has(key):
		return false
	return AT_BATTLE_START.has(key) or AFTER_STAGE_WIN.has(key)


## True where the effect is built and correct, but nothing yet creates the
## situation it responds to.
static func is_inert_today(modifier: Dictionary, bridge: Dictionary = {}) -> bool:
	return INERT_TODAY.has(key_for(modifier, bridge))


## True where the effect is understood but the machinery is still to come.
static func is_known_but_unbuilt(modifier: Dictionary, bridge: Dictionary = {}) -> bool:
	return NOT_YET_BUILT.has(key_for(modifier, bridge))


## What a modifier does, in words for the player.
##
## The `effect` column is written for a designer and says "Magnitude" where
## a number belongs — "+Magnitude player start support". Putting that on a
## shop screen asks the player to read a spreadsheet.
##
## Where the effect is one the code implements, the sentence is built from
## the key and the number. Where it is not, the prose is used but with the
## word "Magnitude" replaced by the actual figure, which is a display
## substitution and not the rules reading a sentence.
static func describe(modifier: Dictionary, bridge: Dictionary = {},
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var magnitude := magnitude_of(modifier)

	match key_for(modifier, bridge):
		"player_start_support":
			return say.say("modifier.player_start_support", {"count": magnitude})
		"starting_gaffe":
			return say.say("modifier.starting_gaffe", {"count": magnitude})
		"kaban_per_stage_win":
			return say.say("modifier.kaban_per_stage_win", {"count": magnitude})

	var prose := str(modifier.get("effect", "")).strip_edges()
	if prose.is_empty():
		return ""
	return prose.replace("Magnitude", str(magnitude))


## What the owned modifiers do to a battle before the first turn.
##
## Returns the adjustments as plain numbers rather than touching any state,
## so the same answer can be shown on a screen and asserted in a test.
##
## A modifier only fires where its audience is actually in the room: that is
## MetaRules.active_modifiers' job, and the caller passes in what it chose.
static func battle_start_bonus(active: Array, bridge: Dictionary = {}) -> Dictionary:
	var bonus := {"start_support": 0, "starting_gaffe": 0}

	for modifier: Dictionary in active:
		var magnitude := magnitude_of(modifier)
		match key_for(modifier, bridge):
			"player_start_support":
				bonus["start_support"] += magnitude
			"starting_gaffe":
				# The column reads "−Magnitude starting gaffe meter": the
				# sign is in the prose, so the number is taken off here.
				bonus["starting_gaffe"] -= magnitude

	return bonus


## What the owned modifiers pay out when a stage is won.
static func stage_win_funds(owned: Array, bridge: Dictionary = {}) -> int:
	var funds := 0
	for modifier: Dictionary in owned:
		if key_for(modifier, bridge) == "kaban_per_stage_win":
			funds += magnitude_of(modifier)
	return funds
