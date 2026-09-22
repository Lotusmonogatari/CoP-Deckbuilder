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

## What a modifier costs in Funds. A modifier with no price is not for sale:
## the opponent-only ones and the two driven by party support are switched on
## by circumstance rather than bought.
static func modifier_cost(modifier: Dictionary) -> int:
	var cost: Variant = modifier.get("kaban_cost")
	return 0 if cost == null else int(cost)


static func is_for_sale(modifier: Dictionary) -> bool:
	if modifier_cost(modifier) <= 0:
		return false
	# Something only an opponent can carry is not on the player's shelf.
	var audience := str(modifier.get("available_to", "Both"))
	return audience == "Both" or audience == "Player"


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
## The party-support pair name a meta-variable here rather than a booster, so
## anything that is not a real booster ID is treated as "nobody backs this".
static func backing_booster(modifier: Dictionary, booster_ids: Array) -> String:
	var source := str(modifier.get("source_booster", ""))
	return source if booster_ids.has(source) else ""


## Whether a modifier can be bought, and if not, why not.
static func modifier_refusal(modifier: Dictionary, owned: Array, funds: int,
		standing: Dictionary, settings: Dictionary, booster_ids: Array,
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
	var booster := backing_booster(modifier, booster_ids)
	if not booster.is_empty():
		var needed := standing_needed(modifier, settings)
		var have := int(standing.get(booster, 0))
		if have < needed:
			return say.say("shop.standing_needed",
				{"have": have, "needed": needed})

	var cost := modifier_cost(modifier)
	if funds < cost:
		return say.say("shop.funds_short", {"count": cost - funds})
	return ""


static func can_buy_modifier(modifier: Dictionary, owned: Array, funds: int,
		standing: Dictionary, settings: Dictionary, booster_ids: Array,
		words: Phrase = null) -> bool:
	return modifier_refusal(modifier, owned, funds, standing, settings,
		booster_ids, words) == AFFORDABLE


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
