class_name LevelBonusView
extends RefCounted
## The level briefing's "Level Bonus" block (2026-11-19, Cameron): what winning the whole level pays on top
## of its rooms. A heading, one bullet for each meter number (a range when it is one), then the organizations
## as chips with their ranges. Built from LevelBonus.preview(), which reads the same columns, with the same
## Campaign Pressure scaling, as the payout, so a number shown is a number that can be paid. Empty for a level
## that pays no bonus. Every word is a Text row.


## The block's rows, in order; [] when the level pays no bonus.
static func rows(level: Dictionary, tier: String, base_balance: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var bonus := LevelBonus.preview(level, tier, base_balance)
	if LevelBonus.is_empty(bonus):
		return out
	out.append(UiKit.line(Text.say("briefing.level_bonus")))
	var meta: Dictionary = bonus["meta"]
	for name: String in BriefingSummary.ordered(meta):
		out.append(UiKit.line(Text.say("briefing.bullet", {"line": meta_line(name, meta[name] as Dictionary)})))
	var orgs: Array = bonus["orgs"]
	if not orgs.is_empty():
		out.append(UiKit.line(Text.say("briefing.level_bonus_orgs")))
		out.append(OrgChip.row(chip_entries(orgs), true))
	return out


## "Reputation +2", "Funds 0円 to +6,000円", "XP Growth +15 to +30".
static func meta_line(name: String, bounds: Dictionary) -> String:
	var low := int(bounds["min"])
	var high := int(bounds["max"])
	var is_xp := name == BriefingSummary.XP
	if low == high:
		var amount := Phrase.meta_amount(name, high, true)
		if is_xp:
			return Text.say("briefing.xp_growth", {"amount": amount})
		return Text.say("reward.delta", {"name": name, "amount": amount})
	var values := {"low": Phrase.meta_amount(name, low, true), "high": Phrase.meta_amount(name, high, true)}
	if is_xp:
		return Text.say("briefing.xp_growth_range", values)
	values["name"] = name
	return Text.say("reward.delta_range", values)


## The preview's organizations as OrgChip entries: a fixed amount shows its number, a range shows both ends.
static func chip_entries(orgs: Array) -> Array:
	var entries: Array = []
	for org: Dictionary in orgs:
		var low := int(org["min"])
		var high := int(org["max"])
		var entry := {"id": str(org["id"]), "delta": high}
		if low != high:
			entry["label"] = Text.say("reward.chip_range", LevelBonus.chip_numbers(low, high))
		entries.append(entry)
	return entries
