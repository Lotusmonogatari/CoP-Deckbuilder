class_name CharacterCodex
extends RefCounted
## The Characters list in Administration (2026-11-13, Cameron): every opponent
## and visitor, whether the player has met them, and the colour of their button.
##
## Pure and UI-free (CLAUDE.md section 12): every input is an argument, no autoload.
##
## Colour rule:
##   - an opponent with a named party: that party's own colour;
##   - a character whose organization is a party body (tier "Party": Party
##     Headquarters, Faction, Activists, Selection Committee) but who has no
##     named party: the PLAYER's party colour;
##   - otherwise one muted colour for the organization's tier (Constituency or
##     National), or one for "no organization". Those three are Balance rows.
## A visitor has no party field; their organization is the first target of
## their reward list.
##
## "Met" = faced in a stage, spoke in a transition, or appeared in Office Hours,
## a member visit or a lobbyist trade. GameState records that in
## `met_characters`.

const TIER_PARTY := "Party"
const TIER_CONSTITUENCY := "Constituency"
const TIER_NATIONAL := "National"

## Fallback colours (0-255) if a Balance row is missing, so a button is never invisible.
const FALLBACK := {
	"constituency": [160, 140, 100],
	"national": [100, 120, 150],
	"none": [120, 120, 120],
}


## True when `id` has been met once.
static func is_met(id: String, met_characters: Dictionary) -> bool:
	return met_characters.has(id)


## One entry per person in `people`, in list order: unmet last, met A to Z.
## `kind` is "opponent" or "visitor". Each entry:
## { id, kind, met, name, name_jp, title, organizations (Array of names), party, color }
static func entries(kind: String, people: Array, boosters: Array, parties: Array,
		player_party: String, met_characters: Dictionary,
		balance: Dictionary) -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	for person: Variant in people:
		if person is Dictionary:
			made.append(_entry(kind, person as Dictionary, boosters, parties, player_party,
				met_characters, balance))
	made.sort_custom(_before)
	return made


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if bool(a["met"]) != bool(b["met"]):
		return bool(a["met"])
	if bool(a["met"]):
		var left := str(a["name"]).to_lower()
		var right := str(b["name"]).to_lower()
		if left != right:
			return left < right
	# Unmet characters sort by id, not by name: the order must not give away who they are.
	return str(a["id"]) < str(b["id"])


static func _entry(kind: String, person: Dictionary, boosters: Array, parties: Array,
		player_party: String, met_characters: Dictionary,
		balance: Dictionary) -> Dictionary:
	var is_opponent := kind == "opponent"
	var id := str(person.get("opp_id" if is_opponent else "visitor_id", ""))
	var org_ids: Array[String] = _organization_ids(person, is_opponent)
	var party := PartyDisplay.party_name(person) if is_opponent else ""
	var organizations: Array[String] = []
	for org_id: String in org_ids:
		var booster := _booster(boosters, org_id)
		if not booster.is_empty():
			organizations.append(str(booster.get("name_en", org_id)))
	return {
		"id": id,
		"kind": kind,
		"met": is_met(id, met_characters),
		"name": str(person.get("name" if is_opponent else "name_en", id)),
		"name_jp": "" if is_opponent else _text_or_empty(person.get("name_jp")),
		"title": OpponentDisplay.title_for(person) if is_opponent else _text_or_empty(person.get("title")),
		"organizations": organizations,
		"party": party,
		"color": color_for(party, org_ids, boosters, parties, player_party, balance),
	}


## The button colour; see the rule in the file header.
static func color_for(party: String, org_ids: Array[String], boosters: Array, parties: Array,
		player_party: String, balance: Dictionary) -> Color:
	if not party.is_empty():
		return PartyDisplay.color_for(_party_row(parties, party))
	var tier := ""
	if not org_ids.is_empty():
		tier = str(_booster(boosters, org_ids[0]).get("tier", ""))
	match tier:
		TIER_PARTY: return PartyDisplay.color_for(_party_row(parties, player_party))
		TIER_CONSTITUENCY: return _balance_color(balance, "constituency")
		TIER_NATIONAL: return _balance_color(balance, "national")
	return _balance_color(balance, "none")


## Dark text on a light button and light text on a dark one.
static func text_color_for(background: Color) -> Color:
	return Color(0.08, 0.08, 0.08) if background.get_luminance() > 0.45 else Color(1, 1, 1)


static func _balance_color(balance: Dictionary, which: String) -> Color:
	var fallback: Array = FALLBACK[which]
	return Color(
		float(balance.get("characters_colour_%s_red" % which, fallback[0])) / 255.0,
		float(balance.get("characters_colour_%s_green" % which, fallback[1])) / 255.0,
		float(balance.get("characters_colour_%s_blue" % which, fallback[2])) / 255.0)


## An opponent's organization is its affiliation; a visitor's are the organizations
## their reward list names (blank cell = null = none).
static func _organization_ids(person: Dictionary, is_opponent: bool) -> Array[String]:
	var ids: Array[String] = []
	if is_opponent:
		var affiliation := str(person.get("affiliation", "")).strip_edges()
		if not affiliation.is_empty() and affiliation != "<null>":
			ids.append(affiliation)
		return ids
	var rewards: Variant = person.get("reward")
	if rewards is Array:
		for reward: Variant in (rewards as Array):
			if reward is Dictionary:
				var target := str((reward as Dictionary).get("target", ""))
				if not target.is_empty() and not ids.has(target):
					ids.append(target)
	return ids


static func _booster(boosters: Array, booster_id: String) -> Dictionary:
	for booster: Variant in boosters:
		if booster is Dictionary and str((booster as Dictionary).get("booster_id", "")) == booster_id:
			return booster as Dictionary
	return {}


static func _party_row(parties: Array, party_name: String) -> Dictionary:
	for party: Variant in parties:
		if party is Dictionary and str((party as Dictionary).get("name", "")) == party_name:
			return party as Dictionary
	return {}


static func _text_or_empty(value: Variant) -> String:
	return "" if value == null else str(value).strip_edges()
