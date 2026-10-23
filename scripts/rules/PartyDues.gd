class_name PartyDues
extends RefCounted
## Party dues (2026-10-23, Cameron). At each week end the player owes the party:
##
##   base 50,000円, plus 50,000円 for every full 15 points of Party support above 40,
##   plus 30% of the Funds earned Monday to Friday that week,
##   minus whatever the awareness effects take off the base (National Awareness).
##
## Whatever cannot be paid rolls over. An unpaid balance costs Party support,
## withdraws the party's backings, and applies penalties that grow by a factor
## for every full 100,000円 overdue. Pure and UI-free (CLAUDE.md section 12):
## every number comes from Balance through `settings()`.


static func settings(balance: Dictionary) -> Dictionary:
	return {
		"base": int(balance.get("dues_base", 50000)),
		"reward_percent": float(balance.get("dues_reward_percent", 30)),
		"support_start": int(balance.get("dues_party_support_start", 40)),
		"support_step": maxi(1, int(balance.get("dues_party_support_step", 15))),
		"step_amount": int(balance.get("dues_step_amount", 50000)),
		"overdue_party_support": int(balance.get("dues_overdue_party_support", 10)),
		"overdue_hq": int(balance.get("dues_overdue_party_hq", 20)),
		"overdue_other_parties": int(balance.get("dues_overdue_other_parties", 5)),
		"overdue_selection": int(balance.get("dues_overdue_selection_committee", 5)),
		"scale_per": maxi(1, int(balance.get("dues_overdue_scale_per", 100000))),
		"scale_factor": float(balance.get("dues_overdue_scale_factor", 1.5)),
	}


## The base dues: the flat amount plus a step for every full `support_step`
## points of Party support above the start, less `reduction` (never below 0).
@warning_ignore("integer_division")
static func base_dues(cfg: Dictionary, party_support: int, reduction: int = 0) -> int:
	var steps := maxi(0, (party_support - int(cfg["support_start"])) / int(cfg["support_step"]))
	return maxi(0, int(cfg["base"]) + steps * int(cfg["step_amount"]) - maxi(0, reduction))


## This week's dues: the base plus the share of the Funds earned Monday to Friday.
static func week_dues(cfg: Dictionary, party_support: int, funds_earned: int,
		reduction: int = 0) -> int:
	var share := roundi(maxi(0, funds_earned) * float(cfg["reward_percent"]) / 100.0)
	return base_dues(cfg, party_support, reduction) + share


## How much of `total` the player's Funds can cover, and what is left over.
static func settle(total: int, funds: int) -> Dictionary:
	var paid := clampi(funds, 0, maxi(0, total))
	return {"paid": paid, "owed": maxi(0, total) - paid}


## The multiplier on the overdue penalties: the factor for every full
## `scale_per` yen owed (nothing under one step is 1.0).
@warning_ignore("integer_division")
static func overdue_multiplier(cfg: Dictionary, owed: int) -> float:
	return pow(float(cfg["scale_factor"]), float(maxi(0, owed) / int(cfg["scale_per"])))


## The penalties for an unpaid balance: whole numbers, already scaled.
##   party_support:   lost once (not scaled)
##   hq / selection:  standing lost with BO01 / BO32 (scaled)
##   other_parties:   favorability each other party gains (scaled)
static func overdue_penalties(cfg: Dictionary, owed: int) -> Dictionary:
	if owed <= 0:
		return {}
	var multiplier := overdue_multiplier(cfg, owed)
	return {
		"party_support": int(cfg["overdue_party_support"]),
		"hq": roundi(int(cfg["overdue_hq"]) * multiplier),
		"other_parties": roundi(int(cfg["overdue_other_parties"]) * multiplier),
		"selection": roundi(int(cfg["overdue_selection"]) * multiplier),
		"multiplier": multiplier,
	}


## The owned backings that belong to the party and are withdrawn when dues go
## unpaid: any whose trigger organization is a Party-tier organization.
static func party_backings(owned: Array, modifiers: Array, boosters: Array) -> Array[String]:
	var party_orgs := {}
	for booster: Dictionary in boosters:
		if str(booster.get("tier", "")) == "Party":
			party_orgs[str(booster.get("booster_id", ""))] = true
	var found: Array[String] = []
	for modifier: Dictionary in modifiers:
		var mod_id := str(modifier.get("mod_id", ""))
		if not owned.has(mod_id):
			continue
		for org: Variant in modifier.get("trigger_booster_ids", []):
			if party_orgs.has(str(org)):
				found.append(mod_id)
				break
	return found
