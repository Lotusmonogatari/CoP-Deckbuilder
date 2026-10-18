class_name ModifierEffects
extends RefCounted
## What an organisation's backing actually does.
##
## 2026-09-22 workbook: modifiers.json now carries the machine-readable half
## directly — "Effect Type" / "Effect Target" / "Effect Value" columns — so
## the hand-written bridge (data/modifier_effects.json) that used to fill in
## for a missing "effect key" column is gone, and so is this file's old
## key/magnitude scheme. Every modifier row now says exactly what it does.
##
## THE FIVE TYPES (CLAUDE.md's migration brief, 2026-09-22):
##
##   RESOURCE_BONUS_ON_WIN  target XP/Yen/Jiban/PartySupport, value a flat
##                          amount paid out when a LEVEL is won — not a
##                          stage. The workbook's own Effect column says so
##                          ("...after successful completion of a level"),
##                          which is why GameState pays this out only once
##                          the whole level finishes, not stage by stage.
##   STAGE_START_BONUS      target an STxx, value added to that stage's
##                          starting support before the first turn.
##   HAND_SIZE_BONUS        target an STxx, value +N cards drawn at the start
##                          of that stage.
##   GAFFE_LIMIT_BONUS      target an STxx, value +N to the gaffe limit for
##                          that stage.
##
## (UNLOCK_DISCOUNT, a fifth type, was removed 2026-10-11 with the only two
## modifiers that used it, M10 Cold Shoulder and M12 Faction Patronage: no
## price ever applied it.)
##
## All four are genuinely wired now — the old file only ever implemented two
## of eleven hand-written keys and called the rest "not active yet". Where a
## modifier is not owned, or its trigger condition (MetaRules.active_modifiers)
## is not met in this stage's room, it simply contributes nothing; that is a
## normal day for a modifier, not a bug.
##
## A SIXTH TYPE, added 2026-09-25 alongside CLAUDE.md §8's wiring:
##
##   FUNDS_INCOME_FREEZE    no target/value. M32 (Funding Freeze) is the one
##                          row that uses it — purely descriptive; unlike
##                          the four above it is never owned or purchased
##                          (M32 prices at 0 everywhere, so Ledger.
##                          is_for_sale() always refuses it). The freeze
##                          itself is enforced directly in
##                          GameState._apply_stage_rewards(), checked live
##                          off MetaRules.party_support_modifiers() — this
##                          type exists so the mechanic has a name and a
##                          description in the Backing panel like every
##                          other effect, not so this file does anything
##                          with it.

const RESOURCE_BONUS_ON_WIN := "RESOURCE_BONUS_ON_WIN"
const STAGE_START_BONUS := "STAGE_START_BONUS"
const HAND_SIZE_BONUS := "HAND_SIZE_BONUS"
const GAFFE_LIMIT_BONUS := "GAFFE_LIMIT_BONUS"
const FUNDS_INCOME_FREEZE := "FUNDS_INCOME_FREEZE"
## Target PartySupport, value a flat amount: paid at the vote when the
## player's influence turns a bill their own party backs from failing to
## passing (GameState.apply_flip_backing()).
const PARTY_BILL_FLIP_BONUS := "PARTY_BILL_FLIP_BONUS"

const KNOWN_TYPES := [
	RESOURCE_BONUS_ON_WIN, STAGE_START_BONUS, HAND_SIZE_BONUS,
	GAFFE_LIMIT_BONUS, FUNDS_INCOME_FREEZE, PARTY_BILL_FLIP_BONUS,
]

## Which sanban.json meta-variable a RESOURCE_BONUS_ON_WIN target name means.
## "XP" is not a sanban row (it lives on GameState instead), so it is handled
## separately wherever this map is used.
const RESOURCE_TARGET_TO_META := {
	"Yen": "Funds",
	"Jiban": "Constituency support",
	"PartySupport": "Party support",
}


## The effect_value column, as a float — the workbook stores it as a real
## number already (10, 0.1, ...), never a "Magnitude" placeholder to resolve.
static func value_of(modifier: Dictionary) -> float:
	var value: Variant = modifier.get("effect_value")
	return 0.0 if value == null else float(value)


## The stages a stage-scoped modifier names: one STxx, or several separated
## by semicolons ("ST03; ST05"), so one backing can cover a whole family of
## rooms (2026-10-18).
static func targets_of(modifier: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for part: String in str(modifier.get("effect_target", "")).split(";"):
		if not part.strip_edges().is_empty():
			out.append(part.strip_edges())
	return out


static func type_of(modifier: Dictionary) -> String:
	return str(modifier.get("effect_type", ""))


static func target_of(modifier: Dictionary) -> String:
	return str(modifier.get("effect_target", ""))


## True where the modifier's effect_type is one this file knows how to run.
## Every modifier in the 2026-09-22 workbook has one of the four, so this is
## really "is the Effect Type column filled in", but it is asked the same way
## a missing/blank value would be.
static func is_implemented(modifier: Dictionary) -> bool:
	return KNOWN_TYPES.has(type_of(modifier))


## What a modifier does, in words for the player.
##
## RESOURCE_BONUS_ON_WIN targeting Yen has a Text tab line already
## (modifier.reputation_per_stage_win) from when this used to be the one
## hand-built case; every other combination is shown straight from the
## workbook's own "Effect" column, which — unlike the old "+Magnitude..."
## wording — already reads as a finished sentence with the real number in it.
## That column is exactly what CLAUDE.md calls display-only prose: showing it
## verbatim is not the rules engine parsing a sentence, any more than showing
## a card's effect_text is.
##
## `stage_names` (stage_id -> name_en, e.g. from DataDB.stages) lets a
## stage-scoped effect ("ST06 TV Debate gaffe limit +1.") drop the internal
## STxx code and read as "TV Debate gaffe limit +1." — the code is workbook
## bookkeeping, not something a player needs to see. Left empty, the sentence
## is shown exactly as written, so every existing call site is unaffected.
static func describe(modifier: Dictionary, words: Phrase = null,
		stage_names: Dictionary = {}) -> String:
	var say := words if words != null else Phrase.new()
	if type_of(modifier) == RESOURCE_BONUS_ON_WIN and target_of(modifier) == "Yen":
		return say.say("modifier.reputation_per_stage_win", {"count": int(round(value_of(modifier)))})
	var text := str(modifier.get("effect", "")).strip_edges()
	var target := target_of(modifier)
	if target.begins_with("ST") and stage_names.has(target):
		var name := str(stage_names[target])
		var with_name := "%s %s" % [target, name]
		if text.contains(with_name):
			text = text.replace(with_name, name)
		elif text.contains(target):
			text = text.replace(target, name)
	return text


## What the owned, active modifiers add to a stage before its first turn.
##
## `active` is already filtered to modifiers whose trigger condition is met
## in this stage's room (MetaRules.active_modifiers). `stage_id` narrows the
## three stage-scoped types to the ones actually aimed at this stage — a
## STAGE_START_BONUS written for ST04 does nothing in ST02.
static func battle_start_bonus(active: Array, stage_id: String) -> Dictionary:
	var bonus := {"start_support": 0, "hand_size_bonus": 0, "gaffe_limit_bonus": 0}

	for modifier: Dictionary in active:
		if not targets_of(modifier).has(stage_id):
			continue
		var value := int(round(value_of(modifier)))
		match type_of(modifier):
			STAGE_START_BONUS:
				bonus["start_support"] += value
			HAND_SIZE_BONUS:
				bonus["hand_size_bonus"] += value
			GAFFE_LIMIT_BONUS:
				bonus["gaffe_limit_bonus"] += value

	return bonus


## What the owned modifiers pay a resource when a LEVEL is won.
##
## `resource` is "XP", or one of RESOURCE_TARGET_TO_META's meta-variable
## names ("Funds", "Constituency support", "Party support") — whichever the
## caller is about to pay out. Unlike battle_start_bonus this does not filter
## by room: the workbook's own wording says these pay out for winning the
## level, not for who was watching.
static func level_win_resource_bonus(owned: Array, resource: String) -> int:
	var target := resource
	for key: String in RESOURCE_TARGET_TO_META.keys():
		if RESOURCE_TARGET_TO_META[key] == resource:
			target = key
			break

	var total := 0
	for modifier: Dictionary in owned:
		if type_of(modifier) == RESOURCE_BONUS_ON_WIN and target_of(modifier) == target:
			total += int(round(value_of(modifier)))
	return total




## Game-clock units a bought backing lasts (the Modifiers tab's Duration
## Units, 2026-10-18); 0 = permanent. Never shown to the player.
static func duration_units(modifier: Dictionary) -> int:
	var raw: Variant = modifier.get("duration_units")
	if raw == null or str(raw).strip_edges().is_empty():
		return 0
	return maxi(int(raw), 0)
