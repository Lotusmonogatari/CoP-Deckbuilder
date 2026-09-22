extends Node
## Loads every game content file from data/ and hands it out on request.
##
## This is the only place that reads data/*.json. Everything else asks DataDB.
##
## Nothing in this game hardcodes a card's numbers, a stage's rules, or a
## character's name — it all comes from the design workbook, via the JSON
## files that tools/export_data.py writes. If a value looks wrong in-game,
## the fix is in the workbook, not in the code.
##
## On startup it also re-runs the same cross-reference checks the exporter
## runs, and prints a report. That is deliberate belt-and-braces: the exporter
## catches problems at Cameron's desk, and this catches a data file that was
## hand-edited or half-copied afterwards.

## Emitted once every file has loaded and been checked.
signal data_ready(had_errors: bool)

const DATA_PATH := "res://data/"

## Every file that must be present for the game to start.
const REQUIRED_FILES := [
	"affinity", "balance", "bills", "booster_standing", "boosters", "cards",
	"committee", "intent_patterns", "journalists", "levels", "lists",
	"modifier_effects", "modifiers", "modules", "opponents",
	"player", "playtest_cards", "playtest_level", "rules", "sanban",
	"card_cues", "questions",
	"sounds", "stage_types", "strings",
	"segments", "stages", "suits", "yoron",
]

# --- Raw loaded content ----------------------------------------------------
# Lists of dictionaries, exactly as they appear in the JSON files.
var cards: Array = []
var stages: Array = []
var suits: Array = []
var segments: Array = []
var modifiers: Array = []

## Which named effect each modifier runs, by mod_id. Hand-written bridge;
## the workbook's own column wins where it exists.
var modifier_effects: Dictionary = {}

## What each of the workbook's MPs does on their turn, by opp_id. The same
## kind of hand-written bridge, for the same reason: opponents.json is
## regenerated from the workbook and would throw away anything written into
## it. The workbook's own column wins where it exists.
var intent_patterns: Dictionary = {}
var boosters: Array = []
var opponents: Array = []
var yoron: Array = []
var bills: Array = []
var committee: Array = []
var modules: Array = []
var sanban: Array = []
var affinity: Array = []

# Objects rather than lists.
var balance: Dictionary = {}
var lists: Dictionary = {}
var rules: Dictionary = {}

## The playtest level. Hand-written like rules.json rather than generated
## from the workbook, because its shape is still being tried out.
var playtest_level: Dictionary = {}

## The six playtest levels, and the nine kinds of stage they are built from.
## Hand-written; see each file's own README.
var levels: Array = []
var stage_types: Dictionary = {}

## Who the player is. Hand-written; a placeholder until the protagonist is
## cast for real.
var player: Dictionary = {}

## The press pack, hand-written. They ask the questions at a press
## conference; they do not take turns.
var journalists: Array = []

## What plays when, and who says what. Hand-written; see the file's README.
## Every sound is blank so far, so the game ships silent.
var sounds: Dictionary = {}
var speech: Dictionary = {}

## Every line the game says to the player, by key, from the workbook's Text
## tab. Flattened to key -> English here so nothing downstream has to know
## the sheet has a Where or a Notes column. Text.gd hands these out.
var strings: Dictionary = {}

## The five spoken lines each card can say when it is played, by card ID,
## from the workbook's Flavor Text tab. Flattened here from the sheet's five
## columns into one list per card, so nothing downstream counts columns.
var card_cues: Dictionary = {}

## The questions each kind of room can ask, by stage type, from the five
## question tabs. A stage draws from the pool for its type rather than
## naming its own, so a new question is one row in the workbook.
var questions: Dictionary = {}

## How standing with the ten organisations works: where it starts, what it
## is bounded by, and what pleasing one is worth. Hand-written.
var booster_standing: Dictionary = {}

## The IDs of cards that came from playtest_cards.json rather than the
## workbook. They sit in `cards` like any other, and this is only here so
## that a count against a workbook number knows how many are not the
## workbook's to account for.
var playtest_card_ids: Array[String] = []

# --- Lookup tables ---------------------------------------------------------
# Built once at startup so nothing has to search a list at runtime.
var _cards_by_id: Dictionary = {}
var _stages_by_id: Dictionary = {}
var _opponents_by_id: Dictionary = {}
var _segments_by_id: Dictionary = {}
var _modifiers_by_id: Dictionary = {}
var _boosters_by_id: Dictionary = {}
var _bills_by_id: Dictionary = {}
var _yoron_by_id: Dictionary = {}
var _sanban_by_name: Dictionary = {}
var _journalists_by_id: Dictionary = {}
var _affinity: Dictionary = {}   ## element -> { stage_id -> multiplier }

## Problems found at startup. Errors mean something is genuinely broken;
## warnings mean a known gap that the game can still run around.
var errors: PackedStringArray = []
var warnings: PackedStringArray = []

var _loaded := false


func _ready() -> void:
	load_all()


## Loads and checks everything. Safe to call again — it starts from scratch.
func load_all() -> void:
	errors.clear()
	warnings.clear()

	for file_name in REQUIRED_FILES:
		var content: Variant = _read_json(file_name)
		if content == null:
			continue
		match file_name:
			"cards": cards = content
			"stages": stages = content
			"suits": suits = content
			"segments": segments = content
			"modifiers": modifiers = content
			# A temporary bridge until the workbook carries an "Effect key"
			# column; see the file's own README.
			"modifier_effects": modifier_effects = _map_under(content, file_name, "effects")
			# The same bridge again, for opponent behaviour.
			"intent_patterns": intent_patterns = _map_under(content, file_name, "patterns")
			"boosters": boosters = content
			"opponents": opponents = content
			"yoron": yoron = content
			"bills": bills = content
			"committee": committee = content
			"modules": modules = content
			"sanban": sanban = content
			"affinity": affinity = content
			"balance": balance = content
			"lists": lists = content
			"rules": rules = _flatten_rules(content)
			"playtest_level": playtest_level = content
			"levels": levels = _list_under(content, file_name, "levels")
			"stage_types": stage_types = _map_under(content, file_name, "types")
			"player": player = content

			"journalists": journalists = _list_under(content, file_name, "journalists")
			"strings": strings = _strings_by_key(content)
			"card_cues": card_cues = _cues_by_card(content)
			"questions": questions = content
			"sounds":
				sounds = _map_under(content, file_name, "sounds")
				speech = _map_under(content, file_name, "speech")
			"booster_standing": booster_standing = content
			# Cards that exist for the playtest but are not in the workbook
			# yet. Appended rather than kept apart, so everything downstream —
			# the card table, the starter deck, every lookup — treats them as
			# ordinary cards without knowing where they came from. This runs
			# after "cards" because REQUIRED_FILES is in alphabetical order,
			# and "cards" is reassigned on every load, so reloading cannot
			# stack them up twice.
			"playtest_cards": _add_playtest_cards(_list_under(content, file_name, "cards"))

	_fill_name_tokens()
	_build_lookups()
	_validate()
	_loaded = true

	print_report()
	data_ready.emit(not errors.is_empty())


func is_loaded() -> bool:
	return _loaded


## Substitutes {party} in stage names with the player's actual party.
##
## The caucus is the player's OWN party's caucus, so its name has to follow
## whoever the protagonist turns out to be — and CLAUDE.md still lists the
## protagonist's party as an open decision. Writing a party name into
## playtest_level.json would quietly settle it.
##
## Resolved here, once, at load: everything downstream — the rules engine,
## every screen, the web build — then sees an ordinary name and no consumer
## has to know tokens exist. This is the same cross-file resolution DataDB
## already does elsewhere, not presentation.
func _fill_name_tokens() -> void:
	var party := str(player.get("party", "")).strip_edges()

	for stage: Variant in playtest_level.get("stages", []):
		if typeof(stage) != TYPE_DICTIONARY:
			continue
		var name_en := str(stage.get("name_en", ""))
		if not name_en.contains("{party}"):
			continue
		if party.is_empty():
			# No party settled yet. "Party Caucus" reads worse than plain
			# "Caucus", so the token takes its trailing space with it.
			stage["name_en"] = (name_en.replace("{party} ", "")
				.replace("{party}", "").strip_edges())
		else:
			stage["name_en"] = name_en.replace("{party}", party)


# ---------------------------------------------------------------------------
# Reading files
# ---------------------------------------------------------------------------

func _read_json(file_name: String) -> Variant:
	var path := DATA_PATH + file_name + ".json"
	if not FileAccess.file_exists(path):
		errors.append("%s.json is missing. Run: python3 tools/export_data.py" % file_name)
		return null

	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		errors.append("%s.json is not valid JSON: line %d, %s"
			% [file_name, json.get_error_line(), json.get_error_message()])
		return null

	return json.data


## Folds the hand-written playtest cards in with the workbook's.
##
## A card here that uses an ID the workbook already has would shadow it, so
## that is refused rather than quietly replacing a real card.
func _add_playtest_cards(extras: Array) -> void:
	playtest_card_ids.clear()

	for card: Dictionary in extras:
		var card_id := str(card.get("card_id", ""))
		if card_id.is_empty():
			errors.append("a card in playtest_cards.json has no card_id")
			continue

		var clash := false
		for existing: Dictionary in cards:
			if str(existing.get("card_id", "")) == card_id:
				clash = true
				break
		if clash:
			errors.append(("playtest_cards.json has a card called '%s', but the "
				+ "workbook already has one. Give it a different ID.") % card_id)
			continue

		cards.append(card)
		playtest_card_ids.append(card_id)


## Pulls a list out of a hand-written file that wraps it in an object.
##
## The hand-written files carry a "_README" beside their content, so their
## top level is an object rather than the bare array the exporter writes.
## This reaches in for the list and returns an empty one rather than failing
## if the file has been edited into a shape it did not expect.
##
## `file_name` is passed in rather than assumed from `key`: the two are
## usually different, and building the message out of the key sent the reader
## to a file that was not the broken one. `playtest_cards.json` reported its
## problems against `cards.json` — a real file, and an innocent one.
func _list_under(content: Variant, file_name: String, key: String) -> Array:
	if not (content is Dictionary):
		errors.append("%s.json should be an object with a '%s' list in it."
			% [file_name, key])
		return []
	var found: Variant = (content as Dictionary).get(key)
	if not (found is Array):
		errors.append("%s.json has no '%s' list in it." % [file_name, key])
		return []
	return found


## The same, for a file whose payload is an object rather than a list.
func _map_under(content: Variant, file_name: String, key: String) -> Dictionary:
	if not (content is Dictionary):
		errors.append("%s.json should be an object with a '%s' map in it."
			% [file_name, key])
		return {}
	var found: Variant = (content as Dictionary).get(key)
	if not (found is Dictionary):
		errors.append("%s.json has no '%s' map in it." % [file_name, key])
		return {}
	return found


## The Flavor Text tab's five cue columns, folded into one list per card.
##
## A card with no cues written yet comes back as an empty list rather than
## five blanks, so "has this card anything to say" is one is_empty() call.
func _cues_by_card(rows: Variant) -> Dictionary:
	var by_card := {}
	if not (rows is Array):
		return by_card
	for row: Variant in rows:
		if not (row is Dictionary):
			continue
		var card_id := str(row.get("card_id", "")).strip_edges()
		if card_id.is_empty():
			continue
		var lines: Array[String] = []
		for index in range(1, 6):
			var line := str(row.get("cue_%d" % index, "")).strip_edges()
			if not line.is_empty():
				lines.append(line)
		by_card[card_id] = lines
	return by_card



## Turns the Text tab's rows into a plain key -> English lookup.
##
## The sheet carries Where, Placeholders and Notes columns so that Cameron can
## find and understand a line; none of that reaches the game, so it is dropped
## here rather than everywhere downstream.
func _strings_by_key(content: Variant) -> Dictionary:
	var table := {}
	if not (content is Array):
		errors.append("strings.json should be a list of lines from the Text tab.")
		return table
	for row: Variant in content:
		if not (row is Dictionary):
			continue
		var key := str((row as Dictionary).get("key", "")).strip_edges()
		if key.is_empty():
			continue
		table[key] = str((row as Dictionary).get("english", ""))
	return table


## rules.json keeps each switch alongside notes explaining the options.
## The game only needs the chosen value, so pull that out and drop the prose.
func _flatten_rules(raw: Variant) -> Dictionary:
	var flat := {}
	if raw is Dictionary:
		for key: String in (raw as Dictionary).keys():
			if key.begins_with("_"):
				continue   # "_README" and friends are documentation
			var entry: Variant = raw[key]
			flat[key] = entry["value"] if entry is Dictionary and entry.has("value") else entry
	return flat


func _build_lookups() -> void:
	_cards_by_id = _index(cards, "card_id")
	_stages_by_id = _index(stages, "stage_id")
	_opponents_by_id = _index(opponents, "opp_id")
	_segments_by_id = _index(segments, "segment_id")
	_modifiers_by_id = _index(modifiers, "mod_id")
	_boosters_by_id = _index(boosters, "booster_id")
	_bills_by_id = _index(bills, "bill_id")
	_yoron_by_id = _index(yoron, "topic_id")
	_sanban_by_name = _index(sanban, "name_en")
	_journalists_by_id = _index(journalists, "journalist_id")

	_affinity.clear()
	for row: Dictionary in affinity:
		_affinity[row.get("element", "")] = row.get("multipliers", {})


func _index(records: Array, key: String) -> Dictionary:
	var table := {}
	for record: Dictionary in records:
		var id_value: Variant = record.get(key)
		if id_value != null:
			table[id_value] = record
	return table


# ---------------------------------------------------------------------------
# Getters
# ---------------------------------------------------------------------------
# Each returns an empty dictionary rather than crashing when an ID is unknown,
# and says so in the console. A missing card should never take the game down
# mid-battle.

func get_card(card_id: String) -> Dictionary:
	return _lookup(_cards_by_id, card_id, "card")


## A reporter by ID. An empty ID gives an empty result without complaining:
## a question nobody is credited with is missing an attribution, not broken.
func get_journalist(journalist_id: String) -> Dictionary:
	if journalist_id.is_empty():
		return {}
	return _lookup(_journalists_by_id, journalist_id, "journalist")


func get_stage(stage_id: String) -> Dictionary:
	return _lookup(_stages_by_id, stage_id, "stage")


## An opponent, with their intent pattern filled in if it is not on the row.
##
## opponents.json comes out of the workbook, which has no Intent pattern
## column yet, so the patterns live in the hand-written bridge instead. The
## merge happens here rather than at each call site: an opponent handed out
## without their behaviour is an opponent who plays as the generic default,
## and that is a bug nobody notices until a battle feels wrong.
##
## The row's own value always wins, so the day the column lands this stops
## doing anything.
func get_opponent(opp_id: String) -> Dictionary:
	var opponent := _lookup(_opponents_by_id, opp_id, "opponent")
	if opponent.is_empty() or opponent.get("intent_pattern") != null:
		return opponent
	if not intent_patterns.has(opp_id):
		return opponent

	# Copied rather than written into: _opponents_by_id holds the loaded
	# data, and a caller that edits what it is given must not change it for
	# everyone else.
	var filled := opponent.duplicate(true)
	filled["intent_pattern"] = intent_patterns[opp_id]
	return filled


func get_segment(segment_id: String) -> Dictionary:
	return _lookup(_segments_by_id, segment_id, "segment")


func get_modifier(mod_id: String) -> Dictionary:
	return _lookup(_modifiers_by_id, mod_id, "modifier")


func get_booster(booster_id: String) -> Dictionary:
	return _lookup(_boosters_by_id, booster_id, "booster")


func get_bill(bill_id: String) -> Dictionary:
	return _lookup(_bills_by_id, bill_id, "bill")


func get_topic(topic_id: String) -> Dictionary:
	return _lookup(_yoron_by_id, topic_id, "opinion topic")


## Meta-variables are looked up by their English name: "Constituency support",
## "Reputation", "Funds", "Party support".
func get_sanban(variable_name: String) -> Dictionary:
	return _lookup(_sanban_by_name, variable_name, "meta-variable")


func _lookup(table: Dictionary, key: String, kind: String) -> Dictionary:
	if table.has(key):
		return table[key]
	push_warning("DataDB: no %s with ID '%s'." % [kind, key])
	return {}


## The suit power multiplier for a suit in a stage. Defaults to 1.0 (no
## effect) when the pairing isn't listed, which is the case for Office Hours.
func get_affinity(element: String, stage_id: String) -> float:
	var row: Variant = _affinity.get(element)
	if row is Dictionary and (row as Dictionary).has(stage_id):
		return float(row[stage_id])
	return 1.0


## A global tuning number from the Balance tab, e.g. "bill_difficulty_factor".
func get_balance(lever: String, fallback: float = 0.0) -> float:
	if balance.has(lever):
		return float(balance[lever])
	push_warning("DataDB: no balance lever called '%s'." % lever)
	return fallback


## XP needed to unlock a card of a given tier ("0", "1", "2", "3").
func get_tier_cost(tier: String) -> int:
	var tiers: Variant = balance.get("xp_tiers", {})
	if tiers is Dictionary and (tiers as Dictionary).has(tier):
		return int(tiers[tier])
	push_warning("DataDB: no XP tier called '%s'." % tier)
	return 0


## The allowed committee size for a difficulty, as { "min": x, "max": y }.
func get_committee_size_band(difficulty: String) -> Dictionary:
	var bands: Variant = balance.get("committee_size_bands", {})
	if bands is Dictionary and (bands as Dictionary).has(difficulty):
		return bands[difficulty]
	return {}


## One of the open-design switches from rules.json.
func get_rule(flag: String, fallback: Variant = null) -> Variant:
	if rules.has(flag):
		return rules[flag]
	push_warning("DataDB: no rule flag called '%s'." % flag)
	return fallback


## The ordered list of stages in a module, e.g. "MOD01".
func get_module_steps(module_id: String) -> Array:
	var steps: Array = []
	for row: Dictionary in modules:
		if row.get("module") == module_id:
			steps.append(row)
	steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("seq", 0)) < int(b.get("seq", 0)))
	return steps


## The members of the committee for one step of a module.
func get_committee_members(module_id: String, seq: int) -> Array:
	var members: Array = []
	for row: Dictionary in committee:
		if row.get("module") == module_id and int(row.get("seq", -1)) == seq:
			members.append(row)
	return members


## Every card of a given tier — used by the XP shop.
func get_cards_by_tier(tier: String) -> Array:
	return cards.filter(func(card: Dictionary) -> bool: return card.get("tier") == tier)


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
# The same checks tools/export_data.py runs. Kept here as well so a data file
# that was edited by hand after export still gets caught.

func _validate() -> void:
	if errors.size() > 0:
		return   # files are missing or unreadable; the rest would be noise

	var suit_names := _values(suits, "element")
	var stage_ids := _values(stages, "stage_id")
	var segment_names := _values(segments, "name_en")
	var mod_ids := _values(modifiers, "mod_id")
	var booster_ids := _values(boosters, "booster_id")
	var opp_ids := _values(opponents, "opp_id")
	var topic_ids := _values(yoron, "topic_id")
	var bill_ids := _values(bills, "bill_id")

	for card: Dictionary in cards:
		var cid: String = str(card.get("card_id"))
		if not suit_names.has(card.get("suit")):
			errors.append("Card %s has suit '%s', which is not in suits.json" % [cid, card.get("suit")])
		var target: Variant = card.get("target_segment")
		if target != null and target != "Any" and not segment_names.has(target):
			errors.append("Card %s targets '%s', which is not in segments.json" % [cid, target])

	for row: Dictionary in affinity:
		if not suit_names.has(row.get("element")):
			errors.append("affinity.json has a row for '%s', which is not a suit" % row.get("element"))
		for stage_id: String in (row.get("multipliers", {}) as Dictionary).keys():
			if not stage_ids.has(stage_id):
				errors.append("affinity.json has a column for '%s', which is not a stage" % stage_id)

	for stage: Dictionary in stages:
		var sid: String = str(stage.get("stage_id"))
		var favored: Variant = stage.get("favored_suit")
		if favored != null and not suit_names.has(favored):
			errors.append("Stage %s favours '%s', which is not a suit" % [sid, favored])
		if stage.get("mode") == "Combat":
			var total := 0.0
			for share: float in (stage.get("segment_mix", {}) as Dictionary).values():
				total += share
			if absf(total - 1.0) > 0.001:
				errors.append("Stage %s audience shares add up to %d%%, not 100%%" % [sid, roundi(total * 100.0)])

	for mod: Dictionary in modifiers:
		var trigger: Variant = mod.get("trigger_segment")
		if trigger != null and not segment_names.has(trigger):
			errors.append("Modifier %s triggers on '%s', which is not a segment" % [mod.get("mod_id"), trigger])

	for booster: Dictionary in boosters:
		for mod_id: String in (booster.get("linked_modifiers", []) as Array):
			if not mod_ids.has(mod_id):
				errors.append("Booster %s links '%s', which is not a modifier" % [booster.get("booster_id"), mod_id])

	for opp: Dictionary in opponents:
		var oid: String = str(opp.get("opp_id"))
		for field: String in ["element_1", "element_2"]:
			var element: Variant = opp.get(field)
			if element != null and not suit_names.has(element):
				errors.append("Opponent %s has %s '%s', which is not a suit" % [oid, field, element])
		# Their own column first, then the hand-written bridge, then nothing.
		var pattern: Variant = opp.get("intent_pattern")
		if pattern == null:
			pattern = intent_patterns.get(oid)
		if pattern == null:
			warnings.append(
				("Opponent %s has no intent pattern of their own, so they fall back to "
				+ "the shared default in rules.json and play generically.") % oid)
		else:
			# A pattern that cannot be played is worse than none at all: the
			# fallback would at least let the battle start.
			for problem: String in IntentRunner.new(pattern).problems():
				errors.append("Opponent %s's intent pattern: %s" % [oid, problem])

	for bill: Dictionary in bills:
		if not topic_ids.has(bill.get("topic_id")):
			errors.append("Bill %s uses topic '%s', which is not in yoron.json" % [bill.get("bill_id"), bill.get("topic_id")])

	for row: Dictionary in modules:
		var label := "%s step %s" % [row.get("module"), row.get("seq")]
		if not stage_ids.has(row.get("stage_id")):
			errors.append("%s uses stage '%s', which does not exist" % [label, row.get("stage_id")])
		if row.get("opp_id") != null and not opp_ids.has(row.get("opp_id")):
			errors.append("%s names opponent '%s', who does not exist" % [label, row.get("opp_id")])
		if row.get("bill_id") != null and not bill_ids.has(row.get("bill_id")):
			errors.append("%s uses bill '%s', which does not exist" % [label, row.get("bill_id")])
		if row.get("stage_id") == "ST01":
			var members := get_committee_members(str(row.get("module")), int(row.get("seq", -1)))
			if members.is_empty():
				errors.append("%s is a committee stage with no members listed" % label)

	for mod: Dictionary in modifiers:
		var source: Variant = mod.get("source_booster")
		if source is String and (source as String).begins_with("BO") and not booster_ids.has(source):
			errors.append("Modifier %s names booster '%s', which does not exist" % [mod.get("mod_id"), source])

	_validate_rules()


func _validate_rules() -> void:
	## Each switch and the values it accepts. Anything else is a typo in
	## rules.json and would otherwise cause confusing behaviour in a battle.
	var allowed := {
		"turn_limit_outcome": ["loss", "highest_support_wins", "tie_retry"],
		"opponent_can_win_by_threshold": [true, false],
		"opponent_engine": ["intent_patterns", "deck_ai"],
		"press_answer_timer": [true, false],
		"discard_hand_end_of_turn": [true, false],
	}
	for flag: String in allowed.keys():
		if not rules.has(flag):
			errors.append("rules.json is missing the '%s' switch" % flag)
		elif not (allowed[flag] as Array).has(rules[flag]):
			errors.append("rules.json has '%s' set to %s; allowed values are %s"
				% [flag, rules[flag], allowed[flag]])

	# Every opponent without a pattern of their own uses this one, so a typo
	# here would break every battle in the game at the same time.
	if not rules.has("default_intent_pattern"):
		errors.append("rules.json is missing the 'default_intent_pattern' switch")
	else:
		var runner := IntentRunner.new(rules["default_intent_pattern"])
		for problem: String in runner.problems():
			errors.append("rules.json default_intent_pattern: %s" % problem)

	# And every pattern written into a level. These are the opponents the
	# playtest actually fights, so a typo here is the one that gets noticed.
	for level: Variant in levels:
		if typeof(level) != TYPE_DICTIONARY:
			continue
		var level_id := str((level as Dictionary).get("level_id", "?"))
		for stage: Variant in (level as Dictionary).get("stages", []):
			if typeof(stage) != TYPE_DICTIONARY:
				continue
			for opponent: Variant in (stage as Dictionary).get("opponents", []):
				if typeof(opponent) != TYPE_DICTIONARY:
					continue
				var row: Dictionary = opponent
				var pattern: Variant = row.get("intent_pattern")
				if pattern == null:
					warnings.append(
						("%s: %s has no intent pattern, so they fall back to the "
						+ "shared default and play generically.")
						% [level_id, row.get("name", row.get("opp_id", "?"))])
					continue
				for problem: String in IntentRunner.new(pattern).problems():
					errors.append("%s: %s's intent pattern: %s"
						% [level_id, row.get("name", row.get("opp_id", "?")), problem])


func _values(records: Array, key: String) -> Array:
	var found: Array = []
	for record: Dictionary in records:
		var value: Variant = record.get(key)
		if value != null and not found.has(value):
			found.append(value)
	return found


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

func print_report() -> void:
	print("\n" + "=".repeat(70))
	print("GAME DATA")
	print("=".repeat(70))
	print("  %d cards, %d stages, %d opponents, %d modifiers, %d boosters"
		% [cards.size(), stages.size(), opponents.size(), modifiers.size(), boosters.size()])

	if not warnings.is_empty():
		print("\n  %d warning(s) — known gaps in the design data:" % warnings.size())
		for line: String in warnings:
			print("    ! " + line)

	if errors.is_empty():
		print("\n  No errors. All game data loaded and cross-checked.")
	else:
		print("\n  %d ERROR(S) — fix these in the workbook and re-export:" % errors.size())
		for line: String in errors:
			print("    X " + line)

	print("=".repeat(70) + "\n")


## A one-line summary for the boot check screen.
func summary_line() -> String:
	if not errors.is_empty():
		return "%d error(s), %d warning(s)" % [errors.size(), warnings.size()]
	return "OK — %d cards, %d stages, %d opponents (%d warnings)" \
		% [cards.size(), stages.size(), opponents.size(), warnings.size()]
