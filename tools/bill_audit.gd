extends Node
## Audit of composed bills (patron bills and Draft a Bill, 2026-11-02): does the
## vote engine, under the REAL influence gates, let a player of a given strength
## carry them? Prints Markdown. The game's own "winnable" test
## (PatronLevel.carryable) opens every gate at once; this asks what a player who
## really has Reputation / standings / Funds at a given level can do.
##
##     godot --headless --path . tools/bill_audit.tscn

const PROFILES := {
	"none (no influence gates met)": {"rep": 40, "stand": 40, "funds": 50000, "con": 40, "party": 50},
	"mid (Reputation 65, standings 60)": {"rep": 65, "stand": 60, "funds": 100000, "con": 65, "party": 60},
	"good (Reputation 80, standings 72, Funds 100k)": {"rep": 80, "stand": 72, "funds": 100000, "con": 80, "party": 80},
	"standings 75, Funds 100k (cap not raised)": {"rep": 80, "stand": 75, "funds": 100000, "con": 80, "party": 80},
	"standings 80, Funds 100k (cap not raised)": {"rep": 80, "stand": 80, "funds": 100000, "con": 80, "party": 80},
	"standings 80, Funds 500k, Reputation 60": {"rep": 60, "stand": 80, "funds": 500000, "con": 60, "party": 60},
	"strong (everything 80, Funds 500k)": {"rep": 90, "stand": 80, "funds": 500000, "con": 90, "party": 90},
	"full (everything 100, Funds 1M)": {"rep": 100, "stand": 100, "funds": 1000000, "con": 100, "party": 100},
}


func _ready() -> void:
	_run.call_deferred()


func _engine(bill: Dictionary, party_name: String, profile: Dictionary, assist_seats: int) -> FloorVoteEngine:
	var standing := {}
	for booster: Dictionary in DataDB.boosters:
		standing[str(booster.get("booster_id"))] = int(profile["stand"])
	var resistance := {}
	for party: Dictionary in DataDB.parties:
		if party.get("vote_resistance") != null:
			resistance[str(party.get("name", ""))] = int(party["vote_resistance"])
	var engine := FloorVoteEngine.new()
	var config := {
		"bill": bill.duplicate(true), "player_party": party_name,
		"meta": {"Reputation": profile["rep"], "Funds": profile["funds"], "Constituency support": profile["con"], "Party support": profile["party"]},
		"booster_standing": standing, "triggers": DataDB.vote_influence_triggers,
		"default_threshold": int(DataDB.balance.get("vote_influence_default_threshold", 85)),
		"resistance_by_party": resistance,
		"default_resistance": int(DataDB.balance.get("vote_swing_resistance_default", 70)),
	}
	if assist_seats > 0:
		config["assist"] = {"won_over": [{"seats": assist_seats}]} if false else BillAssist.empty()
	engine.setup(config)
	return engine


func _passes(bill: Dictionary, party_name: String, profile: Dictionary) -> bool:
	var engine := _engine(bill, party_name, profile, 0)
	return bool(engine.choose("Yes").get("passed", false))


func _run() -> void:
	var parties: Array = []
	for protagonist: Dictionary in DataDB.protagonists:
		parties.append([str(protagonist.get("player_id")), str(protagonist.get("party", ""))])
	print("# Composed-bill vote audit\n")
	print("Gate rows enabled: %d. Funds-gate rows: %s\n" % [DataDB.vote_influence_triggers.size(),
		DataDB.vote_influence_triggers.filter(func(r: Dictionary) -> bool: return str(r.get("variable")) == "Funds").size()])

	# 1. The 54 patron bills.
	print("## Patron bills (54): carried with a Yes vote\n")
	print("| Profile | " + " | ".join(parties.map(func(p: Array) -> String: return str(p[0]))) + " |")
	print("|---|" + "---|".repeat(parties.size()))
	var patron_rows: Array = DataDB.patron_bills
	for name: String in PROFILES:
		var cells: Array[String] = []
		for p: Array in parties:
			var won := 0
			var total := 0
			for row: Dictionary in patron_rows:
				var composed := PatronLevel.compose(str(row.get("patron_bill_id")), [])
				if not bool(composed.get("ok", false)):
					continue
				total += 1
				if _passes(composed["bill"], str(p[1]), PROFILES[name]):
					won += 1
			cells.append("%d / %d" % [won, total])
		print("| %s | %s |" % [name, " | ".join(cells)])

	# 2. Random drafts of two and three parts.
	print("\n## Random drafts: share the game ALLOWS, and share carried (200 mixes each, seed 7)\n")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ids: Array = []
	for component: Dictionary in DataDB.bill_components:
		ids.append(str(component["component_id"]))
	print("| Parts | Allowed by the game | " + " | ".join(PROFILES.keys()) + " |")
	print("|---|---|" + "---|".repeat(PROFILES.size()))
	for count in [2, 3]:
		var allowed := 0
		var wins: Dictionary = {}
		for name: String in PROFILES:
			wins[name] = 0
		var sample := 0
		var guard := 0
		while sample < 200 and guard < 5000:
			guard += 1
			var pick: Array = []
			var pool := ids.duplicate()
			pool.shuffle()
			for i in count:
				pick.append(pool[i])
			var by_id := ComposedBill.index(DataDB.bill_components)
			if ComposedBill.has_conflict(pick, by_id):
				continue
			sample += 1
			var bill := DraftBill.bill_for(pick)
			if PatronLevel.carryable(bill):
				allowed += 1
			for name: String in PROFILES:
				if _passes(bill, str(parties[1][1]), PROFILES[name]):
					wins[name] += 1
		var cells: Array[String] = []
		for name: String in PROFILES:
			cells.append("%d" % [wins[name]])
		print("| %d | %d / %d | %s |" % [count, allowed, sample, " | ".join(cells)])

	# 3. Can a default player ever afford to draft?
	print("\n## Draft affordability against the Funds cap\n")
	GameState.start_new_run("PC01")
	var first := [str(DataDB.bill_components[0]["component_id"]), str(DataDB.bill_components[40]["component_id"])]
	GameState.xp = 2000
	for petitions in [0, 1, 2]:
		GameState.funds_cap_bonus = petitions * 100000
		GameState.meta["Funds"] = 1000000   # clamped by the cap
		GameState._move_meta("Funds", 0)
		GameState.meta["Funds"] = mini(int(GameState.meta["Funds"]), int(GameState._sanban_row("Funds").get("max", 0)))
		print("- Funds cap petitions bought: %d, cap %d, Funds %d -> draft refusal: '%s'" % [petitions,
			int(GameState._sanban_row("Funds").get("max", 0)), int(GameState.meta["Funds"]), GameState.draft_refusal(first)])
	get_tree().quit(0)
