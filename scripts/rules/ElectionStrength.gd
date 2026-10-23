class_name ElectionStrength
extends RefCounted
## Election strength (2026-10-23, Cameron): one slow, long-term score from 0 to
## 100 for how ready the player's campaign is. It fires no outcome yet; it is
## only built and shown.
##
## Eight inputs each contribute up to a maximum (the maximums add to 100):
## district and national awareness, Constituency support, how many
## organizations are on side, the war chest, experience, the legislative record
## and party backing. Added together they are the campaign's POTENTIAL; the
## strength itself is a stock that moves toward the potential by at most a
## capped amount each week, so even an easy start cannot jump to the top.
##
## Pure and UI-free (CLAUDE.md section 12): numbers come from Balance through
## settings(), the run's readings through `inputs`.

const IDS := ["district", "national", "constituency", "organizations", "war_chest",
	"experience", "record", "party"]


static func settings(balance: Dictionary) -> Dictionary:
	return {
		"gain": float(balance.get("election_gain_per_week", 2.5)),
		"fall": float(balance.get("election_fall_per_week", 1.5)),
		"max": {
			"district": float(balance.get("election_max_district_awareness", 15)),
			"national": float(balance.get("election_max_national_awareness", 15)),
			"constituency": float(balance.get("election_max_constituency_support", 15)),
			"organizations": float(balance.get("election_max_organizations", 15)),
			"war_chest": float(balance.get("election_max_war_chest", 10)),
			"experience": float(balance.get("election_max_experience", 10)),
			"record": float(balance.get("election_max_record", 10)),
			"party": float(balance.get("election_max_party_backing", 10)),
		},
		"org_standing": int(balance.get("election_organization_standing", 50)),
		"war_chest_target": maxf(1.0, float(balance.get("election_war_chest_target", 500000))),
		"experience_target": maxf(1.0, float(balance.get("election_experience_target", 25000))),
		"record_target": maxf(1.0, float(balance.get("election_record_target", 30))),
	}


## Each input's points and maximum, in a fixed order: [{ id, points, max }].
## `inputs`: district, national, constituency (0-100), org_share (0-1),
## funds, xp_earned, laws_passed, party_support (0-100), dues_overdue (bool).
static func components(cfg: Dictionary, inputs: Dictionary) -> Array:
	var max_points: Dictionary = cfg["max"]
	var party_share := clampf(float(inputs.get("party_support", 0)) / 100.0, 0.0, 1.0)
	if bool(inputs.get("dues_overdue", false)):
		party_share *= 0.5
	var shares := {
		"district": clampf(float(inputs.get("district", 0)) / 100.0, 0.0, 1.0),
		"national": clampf(float(inputs.get("national", 0)) / 100.0, 0.0, 1.0),
		"constituency": clampf(float(inputs.get("constituency", 0)) / 100.0, 0.0, 1.0),
		"organizations": clampf(float(inputs.get("org_share", 0)), 0.0, 1.0),
		"war_chest": clampf(float(inputs.get("funds", 0)) / float(cfg["war_chest_target"]), 0.0, 1.0),
		"experience": clampf(float(inputs.get("xp_earned", 0)) / float(cfg["experience_target"]), 0.0, 1.0),
		"record": clampf(float(inputs.get("laws_passed", 0)) / float(cfg["record_target"]), 0.0, 1.0),
		"party": party_share,
	}
	var found: Array = []
	for id: String in IDS:
		found.append({"id": id, "points": snappedf(float(shares[id]) * float(max_points[id]), 0.01),
			"max": float(max_points[id])})
	return found


## What the inputs add up to right now.
static func potential(parts: Array) -> float:
	var total := 0.0
	for part: Dictionary in parts:
		total += float(part["points"])
	return clampf(total, 0.0, 100.0)


## The strength after one week end: toward the potential, by at most the gain
## (up) or the fall (down).
static func step(stock: float, potential_now: float, cfg: Dictionary) -> float:
	var moved := stock
	if potential_now > stock:
		moved = minf(potential_now, stock + float(cfg["gain"]))
	elif potential_now < stock:
		moved = maxf(potential_now, stock - float(cfg["fall"]))
	return clampf(moved, 0.0, 100.0)
