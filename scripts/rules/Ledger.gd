class_name Ledger
extends RefCounted
## What a thing costs, and whether you may have it.
##
## Pure rules: no autoloads, no scene tree, no file access. Everything is
## handed in and a plain answer comes back, which is what lets the Office
## screens and the tests ask exactly the same questions.
##
## WHY ONE FILE FOR ALL OF IT. Cameron has said other kinds of power-up are
## coming beyond cards and modifiers. Spreading "can I afford this" across
## three screens would mean three subtly different answers to the same
## question the first time a price becomes conditional. A purchase here is a
## row of data plus a currency, so a third kind is a new row rather than a
## new system.
##
## THE TWO CURRENCIES
##   XP     earned by winning stages, spent on cards.
##   Funds  the Kaban meta-variable, earned the same way, spent on the
##          organisations' modifiers.
##
## THE WORDING COMES IN, IT IS NOT HELD HERE. Every refusal below is a
## sentence a player reads on a button, so it belongs in the workbook with
## the rest of the prose. This file is pure rules and cannot reach an
## autoload, so a caller hands it a Phrase — the same table, arriving the way
## `balance` and `settings` already arrive. Left out, the refusals come back
## as their keys, which is what the headless tests see and is harmless.
##
## Cards have no upgrades: Cameron settled that. XP buys new cards out of a
## growing set, and the deck is a fixed size, so taking a new card in means
## leaving one out. That trade is the whole point of the deck screen.

## The Staff roles, and the order the Recruitment shop lists them in — the
## same order data/staff.json's own SF01-21 rows come in (see the workbook's
## Staff tab), not a rule this file invented.
const STAFF_ROLES := ["Policy Research Assistant", "Media Spokesperson", "District Representative"]

## Why a purchase was refused, in words a screen can show as-is.
const AFFORDABLE := ""

## The tier a player owns from the first moment, named once.
##
## It was "Starter" until the 2026-09-21 card slate renamed the tiers to
## 0-3. Seven places checked that string; now they ask here instead, so the
## next rename is one line.
const OPENING_TIER := "0"

enum Currency { XP, FUNDS }


# ---------------------------------------------------------------------------
# Cards
# ---------------------------------------------------------------------------

## What a card costs in XP. Starter cards are free — you begin with them.
static func card_cost(card: Dictionary) -> int:
	return int(card.get("xp_to_unlock", 0))


## Whether a card can be bought right now, and if not, why not.
##
## Returns an empty string when it can. Anything else is the reason, ready to
## put on screen: a refusal the player cannot read is the same as a button
## that does nothing.
static func card_refusal(card: Dictionary, owned: Array, xp: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var card_id := str(card.get("card_id", ""))
	if card_id.is_empty():
		return say.say("shop.card_no_id")
	if owned.has(card_id):
		return say.say("shop.already_yours")

	var cost := card_cost(card)
	if cost <= 0:
		return ""   # a free card you somehow do not own: let it through
	if xp < cost:
		return say.say("shop.xp_short", {"count": cost - xp})
	return ""


static func can_buy_card(card: Dictionary, owned: Array, xp: int,
		words: Phrase = null) -> bool:
	return card_refusal(card, owned, xp, words) == AFFORDABLE


# ---------------------------------------------------------------------------
# Modifiers — the organisations' backing
# ---------------------------------------------------------------------------

## 2026-09-22 workbook: a modifier's price is no longer one "Kaban cost"
## column. It is three separate activation costs — reputation_cost,
## jiban_cost, funds_cost — any or all of which can be non-zero. There is
## also no more "available_to" column saying whether a modifier is something
## only an opponent can carry, so every modifier with a price on it is
## treated as something the player can buy. (If some of these are meant to be
## opponent-only or free-standing, that is a workbook question for Cameron,
## not something this code can tell from the data it has.)

## Every activation cost a modifier asks for, by the meta-variable it is
## charged against. A cost of 0 means that currency is not part of the price.
static func modifier_costs(modifier: Dictionary) -> Dictionary:
	return {
		"Funds": int(modifier.get("funds_cost", 0)),
		"Reputation": int(modifier.get("reputation_cost", 0)),
		"Constituency support": int(modifier.get("jiban_cost", 0)),
	}


## The Funds part of the price alone, for the shop lines that show one number
## next to a modifier's name. Where Reputation or Constituency support is also
## charged, `modifier_costs()` is what actually gates the purchase.
static func modifier_cost(modifier: Dictionary) -> int:
	return int(modifier.get("funds_cost", 0))


static func is_for_sale(modifier: Dictionary) -> bool:
	for cost: int in modifier_costs(modifier).values():
		if cost > 0:
			return true
	return false


## How much standing with the backing organisation a modifier asks for.
##
## Cameron chose standing as the gate: an organisation backs you when you
## have given it reason to, which is what the press conference has been
## earning all along and had nowhere to spend.
static func standing_needed(modifier: Dictionary, settings: Dictionary) -> int:
	var per_modifier: Dictionary = settings.get("required_standing_by_modifier", {})
	var mod_id := str(modifier.get("mod_id", ""))
	if per_modifier.has(mod_id):
		return int(per_modifier[mod_id])
	return int(settings.get("required_standing", 60))


## The organisation behind a modifier, or empty where none is.
##
## 2026-09-22 workbook: modifiers.json no longer carries a "source_booster"
## column naming its own owner — the split "Trigger segment or booster" is
## about what switches the modifier ON in a room, which is a different
## question (see MetaRules.active_modifiers). Which organisation SELLS a
## modifier is read the other way round instead: boosters.json's own
## "linked_modifiers" list is the real ownership link, so this searches that.
static func backing_booster(modifier: Dictionary, boosters: Array) -> String:
	var mod_id := str(modifier.get("mod_id", ""))
	for booster: Dictionary in boosters:
		if (booster.get("linked_modifiers", []) as Array).has(mod_id):
			return str(booster.get("booster_id", ""))
	return ""


## Whether a modifier can be bought, and if not, why not.
##
## `meta` is the player's current standing on every meta-variable a modifier
## might charge against (Funds, Reputation, Constituency support) — not just
## Funds, now that a modifier can cost any mix of the three.
static func modifier_refusal(modifier: Dictionary, owned: Array, meta: Dictionary,
		standing: Dictionary, settings: Dictionary, boosters: Array,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var mod_id := str(modifier.get("mod_id", ""))
	if mod_id.is_empty():
		return say.say("shop.mod_no_id")
	if owned.has(mod_id):
		return say.say("shop.already_yours")
	if not is_for_sale(modifier):
		return say.say("shop.not_for_sale")

	# Standing first: being told the price of something you are not allowed
	# to buy is worse than being told why you cannot buy it.
	var booster := backing_booster(modifier, boosters)
	if not booster.is_empty():
		var needed := standing_needed(modifier, settings)
		var have := int(standing.get(booster, 0))
		if have < needed:
			return say.say("shop.standing_needed",
				{"have": have, "needed": needed})

	# Every currency this modifier charges, checked in the order the workbook
	# lists them (Funds, then Reputation, then Constituency support). The
	# wording is the same generic "N short" for all three — there is no
	# per-currency phrasing in the Text tab yet — but which one is short is
	# still findable from the shop line showing the price.
	for name: String in modifier_costs(modifier).keys():
		var cost: int = modifier_costs(modifier)[name]
		if cost <= 0:
			continue
		var have := int(meta.get(name, 0))
		if have < cost:
			return say.say("shop.funds_short", {"count": cost - have})
	return ""


static func can_buy_modifier(modifier: Dictionary, owned: Array, meta: Dictionary,
		standing: Dictionary, settings: Dictionary, boosters: Array,
		words: Phrase = null) -> bool:
	return modifier_refusal(modifier, owned, meta, standing, settings,
		boosters, words) == AFFORDABLE


# ---------------------------------------------------------------------------
# The deck
# ---------------------------------------------------------------------------

## How many cards a deck holds. One lever, so the size is Cameron's to turn.
static func deck_size(balance: Dictionary) -> int:
	return maxi(int(balance.get("starter_deck_size", 12)), 1)


## Whether a chosen deck is legal, and if not, why not.
##
## A deck is exactly the right size and holds only cards you own. Exact
## rather than "at least" on purpose: with no upgrades and a growing card
## set, the only thing making an unlock a decision is having to leave
## something out.
static func deck_refusal(deck: Array, owned: Array, balance: Dictionary,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var wanted := deck_size(balance)

	for card_id: String in deck:
		if not owned.has(card_id):
			return say.say("shop.not_yours", {"card": card_id})

	var seen := {}
	for card_id: String in deck:
		if seen.has(card_id):
			return say.say("shop.in_twice", {"card": card_id})
		seen[card_id] = true

	if deck.size() < wanted:
		return say.say("shop.more_to_choose", {"count": wanted - deck.size()})
	if deck.size() > wanted:
		return say.say("shop.too_many", {"count": deck.size() - wanted})
	return ""


static func deck_is_legal(deck: Array, owned: Array, balance: Dictionary,
		words: Phrase = null) -> bool:
	return deck_refusal(deck, owned, balance, words) == AFFORDABLE


# ---------------------------------------------------------------------------
# Staff — the Recruitment shop
# ---------------------------------------------------------------------------
# One hired candidate per role, Yen-only. A role can be fired and instantly
# re-filled with a different candidate, but a fired candidate never comes
# back for the rest of the run — Cameron's decision, 2026-09-25
# (design/proposals/staff_firing.md). Every price funnels through the same
# "shop.funds_short" wording the modifier shop already uses, so a
# short-Funds refusal reads the same everywhere.

## Whether a role's chosen candidate can be hired right now, and if not, why.
## `hired` is whatever staff_hired.json/GameState already has for this ROLE
## (not this candidate) — empty means the role is vacant. `fired` is whether
## THIS candidate was fired earlier this run (GameState.staff_fired) — once
## true, they are never hireable again, even into a role that is vacant now.
## `recruitment_tier` is GameState.staff_recruitment_tier — a candidate whose
## own highest_tier is above it is not offered yet (SH18, "Unlock New Staff
## Recruitment Tier", raises it by 1 per purchase; 0 at a fresh run, so only
## the three highest_tier-0 candidates — one per role — start hireable).
static func staff_hire_refusal(candidate: Dictionary, hired_for_role: Dictionary,
		fired: bool, funds: int, recruitment_tier: int, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	if str(candidate.get("staff_id", "")).is_empty():
		return say.say("shop.mod_no_id")
	if fired:
		return say.say("office.staff_fired")
	if not hired_for_role.is_empty():
		return say.say("shop.already_yours")
	if int(candidate.get("highest_tier", 0)) > recruitment_tier:
		return say.say("office.recruitment_tier_locked")

	var cost := int(candidate.get("hiring_cost_yen", 0))
	if funds < cost:
		return say.say("shop.funds_short", {"count": cost - funds})
	return ""


static func can_hire_staff(candidate: Dictionary, hired_for_role: Dictionary,
		fired: bool, funds: int, recruitment_tier: int, words: Phrase = null) -> bool:
	return staff_hire_refusal(candidate, hired_for_role, fired, funds,
		recruitment_tier, words) == AFFORDABLE


## What upgrading a hired candidate from `tier` to `tier + 1` costs, or null
## when that step does not exist for them — either because they are already
## at their highest_tier, or because the column for that step is blank (a
## candidate who starts at tier 1, like SF05 or SF07, has no 0-to-1 cost:
## tier 0 was never on offer for them).
static func staff_upgrade_cost(candidate: Dictionary, tier: int) -> Variant:
	if tier >= int(candidate.get("highest_tier", 0)):
		return null
	match tier:
		0: return candidate.get("upgrade_cost_0_to_1_yen")
		1: return candidate.get("upgrade_cost_1_to_2_yen")
		_: return null


## Whether the hired candidate at `tier` can be upgraded right now.
static func staff_upgrade_refusal(candidate: Dictionary, tier: int, funds: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var cost_value: Variant = staff_upgrade_cost(candidate, tier)
	if cost_value == null:
		return say.say("office.staff_at_max")

	var cost := int(cost_value)
	if funds < cost:
		return say.say("shop.funds_short", {"count": cost - funds})
	return ""


static func can_upgrade_staff(candidate: Dictionary, tier: int, funds: int,
		words: Phrase = null) -> bool:
	return staff_upgrade_refusal(candidate, tier, funds, words) == AFFORDABLE


## The severance it costs to fire a hired candidate. The workbook's own
## "Firing Cost from Funds (Yen)" column (data/staff.json's firing_cost_yen);
## the 10%-of-hiring-cost fallback is only for a candidate dict built by hand
## without that field (a test, or an older save's cached copy), never the
## real data, which always has it filled in.
static func staff_firing_cost(candidate: Dictionary) -> int:
	var explicit: Variant = candidate.get("firing_cost_yen")
	if explicit != null:
		return int(explicit)
	return int(round(int(candidate.get("hiring_cost_yen", 0)) * 0.10))


## Whether the hired candidate in a role can be fired right now. There is no
## "nobody's hired" case here — the Fire button only exists on a filled
## role's row, so an empty `hired_for_role` is a caller bug, not a refusal a
## player reads; see GameState.fire_staff().
static func staff_fire_refusal(candidate: Dictionary, funds: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var cost := staff_firing_cost(candidate)
	if funds < cost:
		return say.say("shop.funds_short", {"count": cost - funds})
	return ""


static func can_fire_staff(candidate: Dictionary, funds: int,
		words: Phrase = null) -> bool:
	return staff_fire_refusal(candidate, funds, words) == AFFORDABLE


# ---------------------------------------------------------------------------
# Levels — unlock cost and cooldown
# ---------------------------------------------------------------------------
# Gated by rules.json's "level_gating_enabled" (default false, so every level
# stays open today) — see GameState.gd's levels_unlocked/levels_completed_count
# and OfficeScreen.gd's _level_row().

## What each staff tier count costs to unlock a level, when unlock_cost_2 is
## the last tier the workbook prices (LV01-30 all have exactly _vacant,
## _tier_0, _tier_1, _tier_2 — see data/levels.json).
const LEVEL_UNLOCK_MAX_TIER := 2

## The Staff role whose tier decides a level's unlock price — see
## data/levels.json's own unlock_cost_vacant/_tier_0/_1/_2 columns and
## Ledger.STAFF_ROLES.
const LEVEL_UNLOCK_ROLE := "Policy Research Assistant"


## What unlocking a level costs right now, in XP, given who (if anyone) is
## hired as the Policy Research Assistant.
##
## A vacant role charges unlock_cost_vacant; a hired one charges whichever
## unlock_cost_tier_N matches their CURRENT tier, clamped to the highest tier
## the workbook prices (a PRA tier above that just keeps the cheapest price).
static func level_unlock_cost(level: Dictionary, staff_hired: Dictionary) -> int:
	var hired: Dictionary = staff_hired.get(LEVEL_UNLOCK_ROLE, {})
	if hired.is_empty():
		return int(level.get("unlock_cost_vacant", 0))
	var tier: int = clampi(int(hired.get("tier", 0)), 0, LEVEL_UNLOCK_MAX_TIER)
	return int(level.get("unlock_cost_tier_%d" % tier, 0))


## Whether a level is playable without a purchase: either it was already
## bought (its ID is in `unlocked`), or the cost that applies right now is
## zero — most of LV01-10 never charge anything at all, so nothing needs to
## be added to `unlocked` just to make them playable from the start.
static func is_level_unlocked(level: Dictionary, unlocked: Array,
		staff_hired: Dictionary) -> bool:
	var level_id := str(level.get("level_id", ""))
	if unlocked.has(level_id):
		return true
	return level_unlock_cost(level, staff_hired) <= 0


## Whether a level can be bought right now, and if not, why not. Only about
## the PURCHASE — a level that is unlocked but on cooldown is a different
## question, answered by level_cooldown_remaining() below.
static func level_unlock_refusal(level: Dictionary, unlocked: Array,
		staff_hired: Dictionary, xp: int, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var level_id := str(level.get("level_id", ""))
	if level_id.is_empty():
		return say.say("shop.level_no_id")
	if is_level_unlocked(level, unlocked, staff_hired):
		return ""

	var cost := level_unlock_cost(level, staff_hired)
	if xp < cost:
		return say.say("shop.xp_short", {"count": cost - xp})
	return ""


## How many MORE level completions (win or loss — see the note on
## GameState.levels_completed_count) must happen before this level is
## playable again, or 0 when it is not on cooldown at all.
##
## `completed_count` is the running total of every level finished so far in
## this sitting; `last_completed_at` is { level_id -> that total's value the
## last time THIS level finished }. A level never played has no entry, so it
## is never on cooldown regardless of its cooldown number.
static func level_cooldown_remaining(level: Dictionary, completed_count: int,
		last_completed_at: Dictionary) -> int:
	var level_id := str(level.get("level_id", ""))
	var cooldown := int(level.get("cooldown", 0))
	if cooldown <= 0:
		return 0

	var last: Variant = last_completed_at.get(level_id)
	if last == null:
		return 0

	var since := completed_count - int(last)
	return maxi(cooldown - since, 0)


# ---------------------------------------------------------------------------
# The deck
# ---------------------------------------------------------------------------

## The deck a new run starts with.
##
## Every opening-tier card first — those are yours from the beginning and
## there is one per suit. The 2026-09-21 slate has six of them against a
## deck of twelve, so the rest is filled a suit at a time from the next
## tiers up, lowest card ID first.
##
## That fill is a SUGGESTION, not a design decision: it keeps all six suits
## represented so a first battle is playable, and the deck screen exists
## precisely so the player changes it. Nothing downstream depends on which
## cards these are.
static func opening_deck(cards: Array, balance: Dictionary) -> Array[String]:
	var wanted := deck_size(balance)
	var deck: Array[String] = []

	for card: Dictionary in cards:
		if str(card.get("tier", "")) == OPENING_TIER:
			deck.append(str(card.get("card_id", "")))

	if deck.size() > wanted:
		return deck.slice(0, wanted)

	# Round-robin by suit so the fill cannot hand out six cards of one
	# element and none of another.
	var suits: Array[String] = []
	for card: Dictionary in cards:
		var suit := str(card.get("suit", ""))
		if not suit.is_empty() and not suits.has(suit):
			suits.append(suit)

	while deck.size() < wanted:
		var added := false
		for suit: String in suits:
			if deck.size() >= wanted:
				break
			for card: Dictionary in cards:
				var card_id := str(card.get("card_id", ""))
				if str(card.get("suit", "")) != suit or deck.has(card_id):
					continue
				deck.append(card_id)
				added = true
				break
		if not added:
			break   # every card there is, is already in

	return deck
