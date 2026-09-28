class_name CosmeticPieces
extends RefCounted
## Purely decorative cosmetic packages (2026-09-28): whether one can be
## bought, what it costs, and which equip slots it has a piece for.
##
## Pure, like everything in scripts/rules/: no autoload, no file, no scene.
## A package is the PURCHASE unit — whatever pieces it bundles are sold
## together, once, via buy_refusal()/cost() below. The SLOT (Outfit / Office
## Background / Music) is the EQUIP unit: GameState.active_cosmetics picks
## one owned package per slot independently, so a player can mix and match
## across everything they own. This file only answers "can this package be
## bought" and "does this package have a piece for this slot" — equipping
## itself is just picking among already-owned packages, no rules to refuse.

const OUTFIT := "outfit"
const BACKGROUND := "background"
const MUSIC := "music"
const SLOTS := [OUTFIT, BACKGROUND, MUSIC]


## A blank-safe string read: a JSON null cell (a genuinely blank workbook
## column) reads as "" here, never the literal text "<null>" str() would
## otherwise give — the same guard this project's Title/Party-name fields
## already needed for the same reason.
static func field(package: Dictionary, key: String) -> String:
	var value: Variant = package.get(key)
	return "" if value == null else str(value).strip_edges()


## Whether `package` includes a piece for `slot` at all — the equip picker
## only ever offers a package for a slot when this is true.
static func has_piece(package: Dictionary, slot: String) -> bool:
	match slot:
		OUTFIT:
			return not field(package, "outfit_variant").is_empty()
		BACKGROUND:
			return not field(package, "background_variant").is_empty()
		MUSIC:
			return not field(package, "music_office_sound").is_empty() \
				or not field(package, "music_battle_sound").is_empty()
	return false


## What a package costs — the same { "XP": n, "Funds": n } shape every other
## purchase in the game uses, read off the same cost_xp/cost_yen columns
## Items.gd already reads for Supplies.
static func cost(package: Dictionary) -> Dictionary:
	return Items.costs(package)


## Why a package cannot be bought right now, or "" when it can — the same
## "already yours" then "can you afford it" shape Ledger.card_refusal() uses
## for a one-time unlock, not a stackable consumable.
static func buy_refusal(package: Dictionary, owned: Array, xp: int, funds: int,
		words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var package_id := str(package.get("package_id", ""))
	if package_id.is_empty():
		return say.say("shop.item_no_id")
	if owned.has(package_id):
		return say.say("shop.already_yours")

	var price := cost(package)
	if xp < int(price["XP"]):
		return say.say("shop.xp_short", {"count": int(price["XP"]) - xp})
	if funds < int(price["Funds"]):
		return say.say("shop.funds_short", {"count": int(price["Funds"]) - funds})
	return ""
