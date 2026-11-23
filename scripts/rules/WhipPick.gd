class_name WhipPick
extends RefCounted
## Whip scenes (P15, 2026-11-23, Cameron): who whips the player, what the whip asks, and what a lost fight locks.
##
## A whip scene is a Decision! scene that has a Whip Bill. The whip is either named on the scene (a Speaker, like the Minister of
## Agriculture, who whips every player) or picked by the player's Party support from the Rules tab's `whip_bands`: the Assistant,
## Deputy or Chief Party Whip, the minister named on the scene (only if that minister is in the player's party, else the Chief
## Whip stands in), or the party leader. What the whip asks is the party's own line on the bill (its Floor Votes position:
## Supportive is Aye, Opposed is Nay, Neutral is a free vote and no line) unless the scene names a Whip Line.
##
## Beating the whip in the "Whipped into Line" stage frees the vote; losing it records a lock on that bill. One lock holds the
## vote to what that whip asked; two locks mean the player abstains. Pure: no screens, no autoloads, no files (the tests prove it).

const ASSISTANT := "assistant"
const DEPUTY := "deputy"
const CHIEF := "chief"
const MINISTER := "minister"
const LEADER := "leader"
const ROLES: Array[String] = [ASSISTANT, DEPUTY, CHIEF, MINISTER, LEADER]

## The three answers a vote can be locked to (the Floor Vote screen's own words).
const YES := "Yes"
const NO := "No"
const ABSTAIN := "Abstain"


## The role whose band holds `support` (0 to 100); "" when no band does. `bands` is {role: [first, last]}, inclusive.
static func role_for(support: int, bands: Dictionary) -> String:
	var value := clampi(support, 0, 100)
	for role: String in ROLES:
		var span: Variant = bands.get(role)
		if span is Array and (span as Array).size() == 2 and value >= int((span as Array)[0]) and value <= int((span as Array)[1]):
			return role
	return ""


## True when the bands cover 0 to 100 once each, with no gap and no overlap (the exporter checks the same thing).
static func bands_cover(bands: Dictionary) -> bool:
	for support in range(0, 101):
		var hits := 0
		for role: String in ROLES:
			var span: Variant = bands.get(role)
			if span is Array and (span as Array).size() == 2 and support >= int((span as Array)[0]) and support <= int((span as Array)[1]):
				hits += 1
		if hits != 1:
			return false
	return true


## True when the opponent row belongs to the party (by name or by short name).
static func in_party(opponent: Dictionary, party: Dictionary) -> bool:
	if opponent.is_empty() or party.is_empty():
		return false
	var name := str(opponent.get("party", "")).strip_edges()
	var short := str(opponent.get("party_acronym", "")).strip_edges()
	return (not name.is_empty() and name == str(party.get("name", "")).strip_edges()) \
		or (not short.is_empty() and short == str(party.get("short_name", "")).strip_edges())


## The opponent ID that whips the player: the party's Assistant, Deputy or Chief Whip, the scene's minister (if in the party),
## or the party leader. "" when the pick cannot be made (a missing cell); the Chief Whip stands in for a minister who is not in
## the player's party and for a blank Minister.
static func pick(support: int, bands: Dictionary, party: Dictionary, minister: Dictionary) -> String:
	var role := role_for(support, bands)
	match role:
		ASSISTANT: return _cell(party, "assistant_whip_opp_id")
		DEPUTY: return _cell(party, "deputy_whip_opp_id")
		CHIEF: return _cell(party, "chief_whip_opp_id")
		LEADER: return _cell(party, "leader_opp_id")
		MINISTER:
			if in_party(minister, party):
				return str(minister.get("opp_id", ""))
			return _cell(party, "chief_whip_opp_id")
	return ""


static func _cell(row: Dictionary, key: String) -> String:
	var raw: Variant = row.get(key)
	return "" if raw == null else str(raw).strip_edges()


## The party's line on a bill: YES for Supportive, NO for Opposed, "" for Neutral or no position (a free vote).
static func party_line(bill: Dictionary, party_id: String) -> String:
	for position: Variant in bill.get("positions", []):
		if position is Dictionary and str((position as Dictionary).get("party_id", "")) == party_id:
			match str((position as Dictionary).get("disposition", "")):
				"Supportive": return YES
				"Opposed": return NO
	return ""


## What a scene's Whip Line cell asks: Aye is YES, Nay is NO, anything else is "" (use the party's line).
static func fixed_line(cell: Variant) -> String:
	match ("" if cell == null else str(cell).strip_edges().to_lower()):
		"aye", "yes": return YES
		"nay", "no": return NO
	return ""


## The line a whip scene asks for: the scene's own Whip Line if it has one, else the player's party's line on the Whip Bill.
static func line_for(scene: Dictionary, bill: Dictionary, party_id: String) -> String:
	var fixed := fixed_line(scene.get("whip_line"))
	return fixed if not fixed.is_empty() else party_line(bill, party_id)


# --- The lock ------------------------------------------------------------------------------------------------------------------
# A lock is {"choice": YES or NO, "by": the whip's opponent ID, "scene_id": ...}. `locks` is every lock recorded on one bill.

## What the player may press on a bill with these locks: {"state": "free", "allowed": [all three]}, {"state": "locked",
## "allowed": [the choice], "by": [...]} or {"state": "abstain", "allowed": [ABSTAIN], "by": [...]} when two or more whips won.
static func resolve(locks: Array) -> Dictionary:
	var by: Array[String] = []
	for lock: Variant in locks:
		if lock is Dictionary:
			by.append(str((lock as Dictionary).get("by", "")))
	if by.size() >= 2:
		return {"state": "abstain", "allowed": [ABSTAIN], "by": by}
	if by.size() == 1:
		return {"state": "locked", "allowed": [str((locks[0] as Dictionary).get("choice", ""))], "by": by}
	return {"state": "free", "allowed": [YES, NO, ABSTAIN], "by": by}


## The locks with this one added (one lock per scene: a scene that already locked this bill is not counted twice).
static func with_lock(locks: Array, lock: Dictionary) -> Array:
	var out: Array = []
	for existing: Variant in locks:
		if existing is Dictionary and str((existing as Dictionary).get("scene_id", "")) != str(lock.get("scene_id", "")):
			out.append(existing)
	out.append(lock)
	return out
