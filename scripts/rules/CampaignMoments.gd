class_name CampaignMoments
extends RefCounted
## Campaign Moment! scenes (P20 phase C, 2026-11-26, Cameron): the Random Decision! scenes that come on their own while the campaign is
## being built. Pure and UI-free (CLAUDE.md section 12): this decides which scenes may be drawn today, draws one by weight, picks the
## colleague who speaks in the party's scenes and judges a challenge. The run's side (the log, cooldowns, the budget count) is GameState's.
##
## A scene is a Campaign Moment! when its Card is `Campaign`. A Random scene carries Weight (and Weight Late), Repeat, Cooldown Weeks, a Phase
## list and a Needs list. The phases the tab names are any, building, mustering and campaign; the calendar's announcement day counts as
## mustering (the sprint starts that day) and Election Day as campaign.

const RANDOM := "Random"
const CARD_CAMPAIGN := "Campaign"
const COLLEAGUE := "colleague"
const CHALLENGE_MET := "challenge_met"
const CHALLENGE_FAILED := "challenge_failed"


static func is_random(scene: Dictionary) -> bool:
	return str(scene.get("kind", "")) == RANDOM


static func is_campaign_card(scene: Dictionary) -> bool:
	return str(scene.get("card", "")) == CARD_CAMPAIGN


## A list cell (Phase, Needs) as its words; the exporter keeps these as lists, a hand-written string is split on semicolons.
static func words(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if raw == null:
		return out
	var pieces: Array = raw as Array if raw is Array else str(raw).split(";")
	for piece: Variant in pieces:
		if not str(piece).strip_edges().is_empty():
			out.append(str(piece).strip_edges())
	return out


static func phases(scene: Dictionary) -> Array[String]:
	return words(scene.get("phase"))


static func needs(scene: Dictionary) -> Array[String]:
	return words(scene.get("needs"))


static func repeats(scene: Dictionary) -> bool:
	return str(scene.get("repeat", "")).strip_edges().to_upper() == "Y"


## The tab's phase word for a calendar phase: announcement is mustering, Election Day is the campaign.
static func scene_phase(calendar_phase: String) -> String:
	match calendar_phase:
		ElectionCycle.ANNOUNCEMENT, ElectionCycle.MUSTERING: return "mustering"
		ElectionCycle.CAMPAIGN, ElectionCycle.ELECTION_DAY: return "campaign"
	return "building"


## Whether the scene's Phase list lets it come in the calendar phase (a blank list means any).
static func phase_allows(scene: Dictionary, calendar_phase: String) -> bool:
	var listed := phases(scene)
	return listed.is_empty() or listed.has("any") or listed.has(scene_phase(calendar_phase))


## The scene's weight in the calendar phase: Weight while building, Weight Late in mustering and the campaign when it is filled.
static func weight_in(scene: Dictionary, calendar_phase: String) -> int:
	var early: Variant = scene.get("weight")
	var late: Variant = scene.get("weight_late")
	if scene_phase(calendar_phase) != "building" and late != null:
		return int(late)
	return 0 if early == null else int(early)


## How many Campaign Moments! may come in a week in the calendar phase (Balance).
static func weekly_budget(calendar_phase: String) -> int:
	return Levers.whole("campaign_moments_per_week_building") if scene_phase(calendar_phase) == "building" \
		else Levers.whole("campaign_moments_per_week_late")


## Whether every Needs word holds. `facts` is {office_open, van, van_speech_done, staff_hired, staff_free} (booleans).
static func needs_met(wanted: Array, facts: Dictionary) -> bool:
	for word: Variant in wanted:
		match str(word):
			"office_open":
				if not bool(facts.get("office_open", false)): return false
			"van":
				if not bool(facts.get("van", false)): return false
			"van_speech_done":
				if not bool(facts.get("van_speech_done", false)): return false
			"campaign_staff_hired":
				if not bool(facts.get("staff_hired", false)): return false
			"campaign_staff_free":
				if not bool(facts.get("staff_free", false)): return false
	return true


## The Random scenes that may be drawn today. `context`: {phase (calendar phase), office, locked ("" or "stepped_aside" or "not_selected"),
## facts (see needs_met), colleague (true when a colleague exists to speak)}. `log` is the decision log; `cooldowns` {scene_id: last day}.
## In a cycle the player does not run in only the scenes a colleague speaks can come; none when the campaign is closed for another reason.
static func eligible(scenes: Array, log: Dictionary, cooldowns: Dictionary, today: int, context: Dictionary) -> Array:
	var out: Array = []
	var locked := str(context.get("locked", ""))
	for entry: Variant in scenes:
		var scene := entry as Dictionary
		if not is_random(scene) or weight_in(scene, str(context.get("phase", ""))) <= 0:
			continue
		var id := str(scene.get("scene_id", ""))
		var by_colleague := str(scene.get("speaker", "")) == COLLEAGUE
		if locked == "not_selected" or (locked == "stepped_aside" and not by_colleague):
			continue
		if by_colleague and not bool(context.get("colleague", false)):
			continue
		if not phase_allows(scene, str(context.get("phase", ""))) or not needs_met(needs(scene), context.get("facts", {})):
			continue
		var office := DecisionScenes.office(scene)
		if office != "Either" and office != str(context.get("office", "")):
			continue
		if repeats(scene):
			var cool: Variant = scene.get("cooldown_weeks")
			if cooldowns.has(id) and today - int(cooldowns[id]) < (0 if cool == null else int(cool)) * 7:
				continue
		elif log.has(id):
			continue
		out.append(scene)
	return out


## One scene from `candidates` by weight; `roll` is a number from 0 up to but not including 1 (the caller's seeded roll). {} when none.
static func draw(candidates: Array, calendar_phase: String, roll: float) -> Dictionary:
	var total := 0
	for scene: Variant in candidates:
		total += weight_in(scene as Dictionary, calendar_phase)
	if total <= 0:
		return {}
	var target := roll * float(total)
	var running := 0.0
	for scene: Variant in candidates:
		running += float(weight_in(scene as Dictionary, calendar_phase))
		if target < running:
			return scene as Dictionary
	return candidates[candidates.size() - 1] as Dictionary


## A member of the player's own party for the colleague speaker: never the leader or the three whips; the same `roll` gives the same person.
## Returns the opponent ID, or "" when the party has no one else.
static func pick_colleague(opponents: Array, party: Dictionary, roll: float) -> String:
	if party.is_empty():
		return ""
	var barred: Array[String] = []
	for key: String in ["leader_opp_id", "assistant_whip_opp_id", "deputy_whip_opp_id", "chief_whip_opp_id"]:
		barred.append(str(party.get(key, "")))
	var pool: Array[String] = []
	for opponent: Variant in opponents:
		var row := opponent as Dictionary
		if WhipPick.in_party(row, party) and not barred.has(str(row.get("opp_id", ""))):
			pool.append(str(row.get("opp_id", "")))
	if pool.is_empty():
		return ""
	pool.sort()
	return pool[mini(pool.size() - 1, int(floor(roll * float(pool.size()))))]


# --- Challenges ---------------------------------------------------------------------------------------------------------------------

## A challenge cell `CM01x3in14` as {activity, count, days}; {} when it does not read that way.
static func parse_challenge(text: String) -> Dictionary:
	var rest := text.strip_edges()
	if not rest.contains("x") or not rest.contains("in"):
		return {}
	var activity := rest.get_slice("x", 0)
	var tail := rest.substr(activity.length() + 1)
	var count_text := tail.get_slice("in", 0)
	var days_text := tail.substr(count_text.length() + 2)
	if activity.is_empty() or not count_text.is_valid_int() or not days_text.is_valid_int():
		return {}
	return {"activity": activity, "count": int(count_text), "days": int(days_text)}


## A started challenge: {scene_id, activity, count, days, start, done}.
static func start_challenge(scene_id: String, spec: Dictionary, today: int) -> Dictionary:
	return {"scene_id": scene_id, "activity": str(spec["activity"]), "count": int(spec["count"]), "days": int(spec["days"]), "start": today, "done": 0}


## The challenge after the player completed `activity` on `today`: counted only inside its window.
static func counted(challenge: Dictionary, activity: String, today: int) -> Dictionary:
	if str(challenge.get("activity", "")) != activity or today < int(challenge.get("start", 0)) or today > int(challenge.get("start", 0)) + int(challenge.get("days", 0)):
		return challenge
	var next := challenge.duplicate()
	next["done"] = int(challenge.get("done", 0)) + 1
	return next


## "challenge_met" once the count is reached, "challenge_failed" once the window has closed short of it, "" while it is open.
static func verdict(challenge: Dictionary, today: int) -> String:
	if int(challenge.get("done", 0)) >= int(challenge.get("count", 0)):
		return CHALLENGE_MET
	if today >= int(challenge.get("start", 0)) + int(challenge.get("days", 0)):
		return CHALLENGE_FAILED
	return ""
