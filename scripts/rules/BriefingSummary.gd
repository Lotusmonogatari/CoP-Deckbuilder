class_name BriefingSummary
extends RefCounted
## What the level briefing lists (Cameron, 2026-10-30): each stage's hours and
## win rewards, and the level's totals, in one fixed order -- Reputation,
## Constituency support, Party support, anything else, then XP and Funds last.
## Pure and UI-free; OfficeScreen draws it.

## The key XP is listed under (it is not a meta-variable).
const XP := "XP"
## Listed first, in this order.
const FIRST := ["Reputation", "Constituency support", "Party support"]
## Listed last, in this order.
const LAST := [XP, "Funds"]


## A stage's win rewards as {name: amount}, XP included, zeros left out.
static func stage_rewards(stage: Dictionary) -> Dictionary:
	var found := LevelRunner.win_rewards(stage)
	var xp := MetaRules.stage_delta(stage, "win_delta_xp")
	if xp != 0:
		found[XP] = xp
	return found


## Every stage's rewards added together.
static func total_rewards(stages: Array) -> Dictionary:
	var sum := {}
	for stage: Dictionary in stages:
		var rewards := stage_rewards(stage)
		for name: String in rewards:
			sum[name] = int(sum.get(name, 0)) + int(rewards[name])
	for name: String in sum.keys():
		if int(sum[name]) == 0:
			sum.erase(name)
	return sum


## The names of `rewards` in briefing order.
static func ordered(rewards: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for name: String in FIRST:
		if rewards.has(name):
			names.append(name)
	var middle: Array[String] = []
	for name: String in rewards:
		if name not in FIRST and name not in LAST:
			middle.append(name)
	middle.sort()
	names.append_array(middle)
	for name: String in LAST:
		if rewards.has(name):
			names.append(name)
	return names


## True when the briefing lists the stages one by one. A level with a single
## shown stage lists none: the level's own totals already are that stage's
## numbers (Cameron, 2026-10-31). Hidden stages (Reveal In Briefing = No) do
## not count, so a level of one real room and a surprise shows only the room's
## totals.
static func lists_stages(shown: Array) -> bool:
	return shown.size() > 1
