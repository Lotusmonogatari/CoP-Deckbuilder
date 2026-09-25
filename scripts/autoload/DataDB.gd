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
##
## 2026-09-22 workbook: "committee", "intent_patterns" and "modifier_effects"
## were hand-written bridge files for columns the workbook now carries
## directly (a committee's roster comes from opponents.json's own "stages"
## list; an opponent's intent_*_range fields build their pattern; a
## modifier's effect_type/target/value replace the old key lookup) — see
## get_opponent(), is_committee_stage() and ModifierEffects.gd. "modules" is
## gone the same way: a level's stage order is levels.json's own
## stage_1..stage_10 now (see BattleSetup.expand_level()). All four bridge
## files are deleted; nothing reads them any more.
##
## "level_opponent_overrides" is new: the hand-written pin file that lets
## Cameron name a specific opponent for a specific level+stage slot, for the
## rare case the dynamic "every eligible opponent" pick should not decide.
const REQUIRED_FILES := [
	"affinity", "art", "balance", "bills", "booster_standing", "boosters", "cards",
	"journalists", "level_opponent_overrides", "level_visitor_overrides", "levels", "lists",
	"modifiers", "opponent_cues", "opponents",
	"player", "playtest_cards", "playtest_level", "rules", "sanban",
	"card_cues", "questions", "shop", "visitors", "visitor_questions",
	"sounds", "staff", "stage_types", "strings",
	"segments", "stages", "suits", "yoron",
]

# --- Raw loaded content ----------------------------------------------------
# Lists of dictionaries, exactly as they appear in the JSON files.
var cards: Array = []
var stages: Array = []
var suits: Array = []
var segments: Array = []
var modifiers: Array = []
var boosters: Array = []
var opponents: Array = []
var yoron: Array = []
var bills: Array = []
var sanban: Array = []
var affinity: Array = []

## data/shop.json's SHxx rows — one-time Office actions (see the file's own
## comments), not previously loaded by anything. Added 2026-09-25 so a
## reward column (a visitor's, a modifier's, anywhere else an ID list names
## a target) can actually resolve a SHxx it finds by prefix, the same way it
## already resolves a BOxx or MODxx.
var shop: Array = []

## Office Hours (design/proposals/office_hours.md): visitors.json is one row
## per character — identity, which STxx they can be drawn for, and their
## Reward/Penalty target_delta_list. visitor_questions.json is one row per
## POSSIBLE exchange — many rows can share a visitor_id, the "several
## questions per visitor" shape Cameron asked for 2026-09-25.
var visitors: Array = []
var visitor_questions: Array = []

## The 21 hireable Staff candidates (SF01-21): 3 roles x 7 candidates each.
## Names come from the workbook's own Name column where it is filled in, and
## from data/staff_names.json (a hand-written fallback) where it is not — see
## tools/export_data.py's apply_staff_names(). Read by the Office's
## Recruitment shop; see GameState.staff_hired for who is actually hired.
var staff: Array = []

## The 30 rows of the workbook's Levels tab (LV01-30), flat: level_id,
## description, unlock costs, stage_1..stage_10, bonus win ranges, win deltas
## per booster. Retired Cameron's old hand-written six-level draft
## (level_id LV01-06, nested stage/opponent objects) 2026-09-22 — this IS the
## level data now. BattleSetup.expand_level() turns one row into the ordered,
## opponent-filled shape LevelRunner.gd plays.
var levels: Array = []

## The hand-written pin file letting a level+stage slot name a specific
## opponent instead of the dynamic "every eligible opponent" pick. One entry
## per pin: { level_id, slot (1-10, matching stage_1..stage_10), opp_id }.
## Most levels have none. See data/level_opponent_overrides.json's own
## README for how Cameron uses it.
var level_opponent_overrides: Array = []

## Same shape and purpose as level_opponent_overrides, for a Non-combat
## stage's visitors instead of a Combat stage's opponent. Separate file
## rather than widened onto the opponent one — see its own README.
var level_visitor_overrides: Array = []

# Objects rather than lists.
var balance: Dictionary = {}
var lists: Dictionary = {}
var rules: Dictionary = {}

## The playtest level. Hand-written like rules.json rather than generated
## from the workbook, because its shape is still being tried out.
var playtest_level: Dictionary = {}

## The nine kinds of stage the OLD hand-written playtest levels were built
## from. Hand-written; see the file's own README. (`levels` — the real
## per-level data — is declared above, alongside level_opponent_overrides.)
var stage_types: Dictionary = {}

## Who the player is: the protagonist in play, one row of `protagonists`.
## Hand-written placeholders until the cast is decided (data/player.json).
## Switched by use_protagonist(), which GameState calls at New Game and on
## loading a save.
var player: Dictionary = {}

## Every main character the player can choose, in data/player.json's order.
var protagonists: Array = []

## Where art lives and what it is called (data/art.json). ArtLoader reads it.
var art: Dictionary = {}

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

## What an opponent might say on their turn, from the workbook's Opponent
## Cues tab — raw rows, kept for OpponentCues.gd and the tests; see
## _opponent_cues_by_suit_verb / _opponent_cues_by_opponent_verb below for
## what actually gets looked up.
var opponent_cues: Array = []

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
var _shop_by_id: Dictionary = {}
var _visitors_by_id: Dictionary = {}

## visitor_id -> Array of that visitor's own rows in visitor_questions.json.
## Built once here rather than filtered fresh on every draw, the same reason
## _index() exists at all.
var _questions_by_visitor: Dictionary = {}

## "{suit}|{verb}" -> Array[String] of lines, for the general pool every
## opponent with that suit draws from. "{opp_id}|{verb}" -> Array[String],
## for a bespoke row that names one or more Opponent IDs — checked first,
## and never blended with the general pool (OpponentCues.gd).
var _opponent_cues_by_suit_verb: Dictionary = {}
var _opponent_cues_by_opponent_verb: Dictionary = {}
var _bills_by_id: Dictionary = {}
var _yoron_by_id: Dictionary = {}
var _sanban_by_name: Dictionary = {}
var _journalists_by_id: Dictionary = {}
var _levels_by_id: Dictionary = {}
var _staff_by_id: Dictionary = {}
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
			"boosters": boosters = content
			"opponents": opponents = content
			"yoron": yoron = content
			"bills": bills = content
			"sanban": sanban = content
			"affinity": affinity = content
			"art": art = content if content is Dictionary else {}
			"staff": staff = content
			"balance": balance = content
			"lists": lists = content
			"rules": rules = _flatten_rules(content)
			"playtest_level": playtest_level = content
			# 2026-09-22: the workbook's Levels tab exports straight to
			# levels.json now, as a plain 30-row array — not wrapped the way
			# the old hand-written file was, so this is a direct assignment
			# rather than a _list_under() unwrap.
			"levels": levels = content if content is Array else []
			"level_opponent_overrides":
				level_opponent_overrides = _list_under(content, file_name, "overrides")
			"level_visitor_overrides":
				level_visitor_overrides = _list_under(content, file_name, "overrides")
			"stage_types": stage_types = _map_under(content, file_name, "types")
			"player": _load_protagonists(content)

			"journalists": journalists = _list_under(content, file_name, "journalists")
			"strings": strings = _strings_by_key(content)
			"card_cues": card_cues = _cues_by_card(content)
			"opponent_cues": opponent_cues = content if content is Array else []
			"questions": questions = content
			"sounds":
				sounds = _map_under(content, file_name, "sounds")
				speech = _map_under(content, file_name, "speech")
			"booster_standing": booster_standing = content
			"shop": shop = content
			"visitors": visitors = content
			"visitor_questions": visitor_questions = content
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
		# The unfilled name is kept, so choosing a different protagonist
		# refills it with the new party instead of finding the token gone.
		if not stage.has("_name_template"):
			stage["_name_template"] = str(stage.get("name_en", ""))
		var name_en := str(stage["_name_template"])
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
# The protagonist
# ---------------------------------------------------------------------------

func _load_protagonists(content: Variant) -> void:
	protagonists = _list_under(content, "player", "protagonists")
	var default_id := ""
	if content is Dictionary:
		default_id = str((content as Dictionary).get("default_protagonist", ""))
	player = get_protagonist(default_id)
	if player.is_empty() and not protagonists.is_empty():
		player = protagonists[0]


## One protagonist by ID, or an empty dictionary.
func get_protagonist(player_id: String) -> Dictionary:
	for entry: Variant in protagonists:
		if entry is Dictionary and str((entry as Dictionary).get("player_id", "")) == player_id:
			return entry
	return {}


## Makes `player_id` the protagonist in play. False, and nothing changes,
## when there is no such protagonist.
func use_protagonist(player_id: String) -> bool:
	var chosen := get_protagonist(player_id)
	if chosen.is_empty():
		return false
	player = chosen
	_fill_name_tokens()
	return true


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
		by_card[card_id] = _cue_lines(row)
	return by_card


## The five "Cue N" columns Flavor Text and Opponent Cues both use, flattened
## into one list — blank cells dropped, so a row with fewer than five lines
## written still works.
func _cue_lines(row: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for index in range(1, 6):
		var line := str(row.get("cue_%d" % index, "")).strip_edges()
		if not line.is_empty():
			lines.append(line)
	return lines



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
	_shop_by_id = _index(shop, "item_id")
	_visitors_by_id = _index(visitors, "visitor_id")

	_questions_by_visitor.clear()
	for question: Dictionary in visitor_questions:
		# "VI01; VI02" — one question shared by several visitors — is already
		# a list by the time it gets here (tools/export_data.py's "id_list"),
		# so it is registered under every one of them.
		for vid: String in (question.get("visitor_ids", []) as Array):
			if not _questions_by_visitor.has(vid):
				_questions_by_visitor[vid] = []
			(_questions_by_visitor[vid] as Array).append(question)

	_opponent_cues_by_suit_verb.clear()
	_opponent_cues_by_opponent_verb.clear()
	for row: Dictionary in opponent_cues:
		var suit := str(row.get("suit", ""))
		var verb := str(row.get("verb", ""))
		var lines: Array[String] = _cue_lines(row)
		if lines.is_empty():
			continue
		var opp_ids: Array = row.get("opponent_ids", [])
		if opp_ids.is_empty():
			# The general pool: every opponent with this suit draws from it
			# for this verb.
			var key := "%s|%s" % [suit, verb]
			_opponent_cues_by_suit_verb[key] = (
				_opponent_cues_by_suit_verb.get(key, []) as Array) + lines
		else:
			# A bespoke row: registered under EACH named opponent, never
			# folded into the general pool.
			for opp_id: String in opp_ids:
				var opp_key := "%s|%s" % [opp_id, verb]
				_opponent_cues_by_opponent_verb[opp_key] = (
					_opponent_cues_by_opponent_verb.get(opp_key, []) as Array) + lines

	_bills_by_id = _index(bills, "bill_id")
	_yoron_by_id = _index(yoron, "topic_id")
	_sanban_by_name = _index(sanban, "name_en")
	_journalists_by_id = _index(journalists, "journalist_id")
	_levels_by_id = _index(levels, "level_id")
	_staff_by_id = _index(staff, "staff_id")

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


## An opponent, with their intent pattern built from the workbook's own
## intent_attack_range / intent_gain_range / intent_block_range columns.
##
## 2026-09-22 workbook: those three columns replace the old single
## "intent_pattern" JSON blob (and the hand-written bridge that used to fill
## it in before the workbook had one). Each is either null — this opponent
## never uses that move — or {"min": x, "max": y}, in the fixed order attack,
## gain, block. IntentRunner.gd's pattern shape is a list of
## [verb, low, high] moves, so this is a straight translation, not a design
## choice: which three verbs exist and what order they cycle in is
## CLAUDE.md §7.6's, unchanged since M1.
##
## The row's own "intent_pattern" wins if a row somehow has one (a hand-built
## fixture in the old shape, say), so nothing here fights real data.
func get_opponent(opp_id: String) -> Dictionary:
	var opponent := _lookup(_opponents_by_id, opp_id, "opponent")
	if opponent.is_empty() or opponent.get("intent_pattern") != null:
		return opponent

	var pattern := _intent_pattern_from_ranges(opponent)
	if pattern.is_empty():
		return opponent

	# Copied rather than written into: _opponents_by_id holds the loaded
	# data, and a caller that edits what it is given must not change it for
	# everyone else.
	var filled := opponent.duplicate(true)
	filled["intent_pattern"] = pattern
	return filled


## The [verb, low, high] pattern IntentRunner.gd wants, built from one
## opponent row's three intent_*_range columns. A verb whose range is null —
## the hard sentinel for "this opponent never does this" — is left out of the
## pattern entirely, rather than turned into a [verb, 0, 0] move: the zero
## rule in IntentRunner.gd already treats a move worth zero as skipped, but a
## real range that happens to roll 0-0 is a different fact than "never rolls
## this at all", and collapsing them would hide the difference in a report.
func _intent_pattern_from_ranges(opponent: Dictionary) -> Array:
	var pattern: Array = []
	for pair: Array in [
		["attack", "intent_attack_range"], ["gain", "intent_gain_range"],
		["block", "intent_block_range"],
	]:
		var range_value: Variant = opponent.get(pair[1])
		if range_value is Dictionary and (range_value as Dictionary).has("min"):
			pattern.append([pair[0], int(range_value["min"]), int(range_value["max"])])
	return pattern


## Whether a stage plays the per-member committee model (CLAUDE.md §7.5).
## DataDB is allowed to call scripts/rules/ (only the reverse is forbidden —
## CLAUDE.md §5, §12), so the one real list of which stage IDs use this
## model — BattleEngine.COMMITTEE_STAGE_IDS, ST01 plus the ten workbook
## committees ST09-ST18 — lives in exactly one place. An unknown stage_id
## resolves the same way BattleEngine.is_committee_stage({}) would: not a
## committee.
func is_committee_stage(stage_id: String) -> bool:
	return BattleEngine.is_committee_stage(get_stage(stage_id))


## Every opponent eligible for a stage — every row whose own "stages" list
## names this STxx. Used by BattleSetup to pick who a level's stage fights,
## and to build a committee's roster; kept here too since DataDB is where
## opponents.json itself lives and this is a pure lookup over it.
func get_opponents_for_stage(stage_id: String) -> Array:
	var found: Array = []
	for opponent: Dictionary in opponents:
		if (opponent.get("stages", []) as Array).has(stage_id):
			found.append(opponent)
	return found


## A level row from levels.json, by its LV-number ID.
func get_level(level_id: String) -> Dictionary:
	return _lookup(_levels_by_id, level_id, "level")


func get_staff(staff_id: String) -> Dictionary:
	return _lookup(_staff_by_id, staff_id, "staff candidate")


## Every candidate for one Staff role ("Policy Research Assistant", "Media
## Spokesperson", "District Representative"), in staff.json's own order
## (SF01-07, SF08-14, SF15-21) — that order is Cameron's own workbook layout,
## not something this file decides.
func get_staff_by_role(role: String) -> Array:
	return staff.filter(func(member: Dictionary) -> bool: return member.get("role") == role)


func get_segment(segment_id: String) -> Dictionary:
	return _lookup(_segments_by_id, segment_id, "segment")


func get_modifier(mod_id: String) -> Dictionary:
	return _lookup(_modifiers_by_id, mod_id, "modifier")


func get_booster(booster_id: String) -> Dictionary:
	return _lookup(_boosters_by_id, booster_id, "booster")


## Every booster of one tier ("Party"/"Constituency"/"National"), read live —
## a booster added to the workbook later joins this with no other edit.
## Used both for a "TIER:X" reward target (a random pick from the tier) and
## for the player-choice picker (Items.is_player_choice()), which offers
## every one of them.
func boosters_for_tier(tier: String) -> Array:
	return boosters.filter(func(b: Dictionary) -> bool: return str(b.get("tier", "")) == tier)


## The real options a Player Choice item's picker offers — every booster in
## Items.choice_pool_spec(item)'s pool or tier, as full records (names,
## current everything). Empty when the item has nothing to choose from.
func choice_options(item: Dictionary) -> Array:
	var spec: Variant = Items.choice_pool_spec(item)
	if spec is String and RewardTargets.is_booster_tier(str(spec)):
		return boosters_for_tier(str(spec).substr(RewardTargets.TIER_PREFIX.length()))
	if spec is Array:
		var found: Array = []
		for target_id: Variant in spec:
			var booster := get_booster(str(target_id))
			if not booster.is_empty():
				found.append(booster)
		return found
	return []


func get_shop_item(item_id: String) -> Dictionary:
	return _lookup(_shop_by_id, item_id, "shop item")


## Pulls the real record a reward/penalty target ID names — a
## "target_delta_list" entry (RewardTargets.gd's classification plus the
## actual DataDB row), e.g. from a Visitor's Reward/Penalty column:
## { "target": "SH04", "delta": null } in, { "kind": "shop_item", "id":
## "SH04", "delta": null, "record": {...the real SH04 row...} } out.
##
## An unknown prefix or a target that doesn't actually exist both come back
## with an empty "record" and a warning — same "readable problem, not a
## crash" contract as every other DataDB lookup — rather than the caller
## having to know three different getters and three different empty shapes.
func resolve_reward_target(entry: Dictionary) -> Dictionary:
	var target_id := str(entry.get("target", ""))
	var kind := RewardTargets.kind_of(target_id)
	var record: Dictionary
	match kind:
		RewardTargets.BOOSTER:
			record = get_booster(target_id)
		RewardTargets.MODIFIER:
			record = get_modifier(target_id)
		RewardTargets.SHOP_ITEM:
			record = get_shop_item(target_id)
		RewardTargets.SEGMENT:
			record = get_segment(target_id)
		RewardTargets.BOOSTER_TIER:
			# Not a row of its own — every booster of that tier, live.
			record = {"tier": target_id.substr(RewardTargets.TIER_PREFIX.length()),
				"boosters": boosters_for_tier(target_id.substr(RewardTargets.TIER_PREFIX.length()))}
		RewardTargets.STAGE_EFFECT:
			# Not a row anywhere — one of RewardTargets.STAGE_EFFECT_TOKENS.
			record = {"token": target_id.to_upper()}
		_:
			warnings.append("reward target '%s' does not match any known ID prefix "
				% target_id + "(BOxx, Mxx, SHxx, SGxx) or stage effect")
	return {
		"kind": kind,
		"id": target_id,
		"delta": entry.get("delta"),
		"record": record,
	}


func get_visitor(visitor_id: String) -> Dictionary:
	return _lookup(_visitors_by_id, visitor_id, "visitor")


## Every visitor eligible for a stage — every visitors.json row whose own
## "stages" list names this STxx — same shape as get_opponents_for_stage().
func get_visitors_for_stage(stage_id: String) -> Array:
	var found: Array = []
	for visitor: Dictionary in visitors:
		if (visitor.get("stages", []) as Array).has(stage_id):
			found.append(visitor)
	return found


## Every possible question a visitor might ask — visitor_questions.json rows
## sharing that visitor_id. Which ONE is actually asked in a given stage is
## drawn from this list elsewhere (BattleSetup), not decided here.
func get_questions_for_visitor(visitor_id: String) -> Array:
	return (_questions_by_visitor.get(visitor_id, []) as Array).duplicate()


## What a specific opponent might say on this verb, if the Opponent Cues tab
## has a bespoke row naming them — checked first by OpponentCues.gd, and
## never blended with the general per-suit pool below.
func get_bespoke_opponent_cue_lines(opponent_id: String, verb: String) -> Array[String]:
	var key := "%s|%s" % [opponent_id, verb]
	var found: Array = _opponent_cues_by_opponent_verb.get(key, [])
	var lines: Array[String] = []
	lines.assign(found)
	return lines


## The general pool every opponent with this suit draws from for this verb,
## when no bespoke row names them.
func get_general_opponent_cue_lines(suit: String, verb: String) -> Array[String]:
	var key := "%s|%s" % [suit, verb]
	var found: Array = _opponent_cues_by_suit_verb.get(key, [])
	var lines: Array[String] = []
	lines.assign(found)
	return lines


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
	var segment_ids := _values(segments, "segment_id")
	var mod_ids := _values(modifiers, "mod_id")
	var opp_ids := _values(opponents, "opp_id")
	var topic_ids := _values(yoron, "topic_id")

	_validate_protagonists()

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
			# 2026-09-22 workbook: "% Other" (pct_other) isn't a segments.json
			# row, but it's still part of the room, so it belongs in the 100%
			# check the same way tools/export_data.py's own copy of this
			# check already counts it. Without this, every stage with any
			# "Other" share in its audience looked broken.
			total += float(stage.get("pct_other", 0.0))
			if absf(total - 1.0) > 0.001:
				errors.append("Stage %s audience shares add up to %d%%, not 100%%" % [sid, roundi(total * 100.0)])

	# 2026-09-22 workbook: "trigger_segment" was split into trigger_segment_ids
	# / trigger_booster_ids by the exporter (see tools/export_data.py); only
	# the segment half is a segments.json cross-reference. A modifier can name
	# more than one now ("SG03; SG05" — any one of them can trigger it).
	for mod: Dictionary in modifiers:
		for trigger: String in (mod.get("trigger_segment_ids", []) as Array):
			if not segment_ids.has(trigger):
				errors.append("Modifier %s triggers on '%s', which is not a segment" % [mod.get("mod_id"), trigger])

	for booster: Dictionary in boosters:
		for mod_id: String in (booster.get("linked_modifiers", []) as Array):
			if not mod_ids.has(mod_id):
				errors.append("Booster %s links '%s', which is not a modifier" % [booster.get("booster_id"), mod_id])

	# 2026-09-22 workbook: element_1/element_2 were renamed suit_1/suit_2, and
	# a third, suit_3, was added. The intent pattern used to be one JSON blob
	# column with a hand-written fallback for when it was missing; now it is
	# three range columns (get_opponent()/_intent_pattern_from_ranges()
	# builds the pattern IntentRunner.gd wants from them), so what used to be
	# "no pattern written" is now "all three ranges are null".
	for opp: Dictionary in opponents:
		var oid: String = str(opp.get("opp_id"))
		for field: String in ["suit_1", "suit_2", "suit_3"]:
			var element: Variant = opp.get(field)
			if element != null and not suit_names.has(element):
				errors.append("Opponent %s has %s '%s', which is not a suit" % [oid, field, element])
		for stage_id: String in (opp.get("stages", []) as Array):
			if not stage_ids.has(stage_id):
				errors.append("Opponent %s is eligible for stage '%s', which does not exist" % [oid, stage_id])

		var pattern: Variant = opp.get("intent_pattern")
		if pattern == null:
			pattern = _intent_pattern_from_ranges(opp)
			if (pattern as Array).is_empty():
				pattern = null
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

	# 2026-09-22 workbook: modules.json/committee.json are retired — a
	# level's stage order is its own stage_1..stage_10 now, and a committee's
	# roster is opponents eligible for that STxx (see
	# get_opponents_for_stage()). Checked the same way modules used to be.
	for level: Dictionary in levels:
		var lid := str(level.get("level_id", "?"))
		var named_any := false
		for slot in range(1, 11):
			var stage_id: Variant = level.get("stage_%d" % slot)
			if stage_id == null or str(stage_id).is_empty():
				continue
			named_any = true
			if not stage_ids.has(str(stage_id)):
				errors.append("%s names stage '%s' at slot %d, which does not exist" % [lid, stage_id, slot])
				continue
			if is_committee_stage(str(stage_id)):
				if get_opponents_for_stage(str(stage_id)).is_empty():
					errors.append(
						"%s's committee stage '%s' (slot %d) has no eligible opponents in opponents.json"
						% [lid, stage_id, slot])
			elif str(get_stage(str(stage_id)).get("mode", "")) == "Non-combat":
				# Office Hours: draws visitors, not opponents — checking
				# opponents.json here always warned, even once VI01 existed,
				# because nothing about this stage was ever going to have one.
				if get_visitors_for_stage(str(stage_id)).is_empty():
					warnings.append(
						("%s's stage '%s' (slot %d) has no eligible visitor in visitors.json, "
						+ "so it cannot open until level_visitor_overrides.json pins one "
						+ "or the workbook adds one.") % [lid, stage_id, slot])
			elif get_opponents_for_stage(str(stage_id)).is_empty():
				warnings.append(
					("%s's stage '%s' (slot %d) has no eligible opponent in opponents.json, "
					+ "so it cannot be fought until level_opponent_overrides.json pins one "
					+ "or the workbook adds one.") % [lid, stage_id, slot])
		if not named_any:
			errors.append("%s names no stages at all" % lid)

	for override_row: Dictionary in level_opponent_overrides:
		var lid := str(override_row.get("level_id", ""))
		var slot := int(override_row.get("slot", -1))
		var opp_id := str(override_row.get("opp_id", ""))
		var level := get_level(lid)
		if level.is_empty():
			errors.append("level_opponent_overrides.json pins slot %d of '%s', which is not a level" % [slot, lid])
			continue
		if slot < 1 or slot > 10:
			errors.append("level_opponent_overrides.json: the slot for '%s' must be 1-10, not %d" % [lid, slot])
			continue
		# An unused slot is JSON null, not "" — str(null) is the literal text
		# "<null>", so the null check has to come before the str() cast (see
		# BattleSetup.expand_level()'s matching note).
		var raw_stage_id: Variant = level.get("stage_%d" % slot)
		var stage_id := "" if raw_stage_id == null else str(raw_stage_id)
		if stage_id.is_empty():
			errors.append("level_opponent_overrides.json pins %s slot %d, which %s does not use" % [lid, slot, lid])
			continue
		if not opp_ids.has(opp_id):
			errors.append("level_opponent_overrides.json pins unknown opponent '%s' for %s slot %d" % [opp_id, lid, slot])
		elif not (get_opponent(opp_id).get("stages", []) as Array).has(stage_id):
			warnings.append(
				("level_opponent_overrides.json pins %s to %s slot %d (%s), but %s is not "
				+ "eligible for %s, so the game will fall back to the dynamic pick there.")
				% [opp_id, lid, slot, stage_id, opp_id, stage_id])

	# Office Hours (design/proposals/office_hours.md). Every Visitor's stage
	# eligibility and Reward/Penalty targets, and every Visitor Question's
	# link back to a real Visitor and a real, answerable set of choices.
	var visitor_ids := _values(visitors, "visitor_id")

	for override_row: Dictionary in level_visitor_overrides:
		var lid := str(override_row.get("level_id", ""))
		var slot := int(override_row.get("slot", -1))
		var visitor_id := str(override_row.get("visitor_id", ""))
		var level := get_level(lid)
		if level.is_empty():
			errors.append("level_visitor_overrides.json pins slot %d of '%s', which is not a level" % [slot, lid])
			continue
		if slot < 1 or slot > 10:
			errors.append("level_visitor_overrides.json: the slot for '%s' must be 1-10, not %d" % [lid, slot])
			continue
		var raw_stage_id: Variant = level.get("stage_%d" % slot)
		var stage_id := "" if raw_stage_id == null else str(raw_stage_id)
		if stage_id.is_empty():
			errors.append("level_visitor_overrides.json pins %s slot %d, which %s does not use" % [lid, slot, lid])
			continue
		if not visitor_ids.has(visitor_id):
			errors.append("level_visitor_overrides.json pins unknown visitor '%s' for %s slot %d" % [visitor_id, lid, slot])
		elif not (get_visitor(visitor_id).get("stages", []) as Array).has(stage_id):
			warnings.append(
				("level_visitor_overrides.json pins %s to %s slot %d (%s), but %s is not "
				+ "eligible for %s, so the game will fall back to the dynamic pick there.")
				% [visitor_id, lid, slot, stage_id, visitor_id, stage_id])

	for visitor: Dictionary in visitors:
		var vid := str(visitor.get("visitor_id"))
		for stage_id: String in (visitor.get("stages", []) as Array):
			if not stage_ids.has(stage_id):
				errors.append("Visitor %s is eligible for stage '%s', which does not exist" % [vid, stage_id])
		for entry: Dictionary in (visitor.get("reward", []) as Array):
			_validate_reward_target(vid, "Reward", entry)
		for entry: Dictionary in (visitor.get("penalty", []) as Array):
			_validate_reward_target(vid, "Penalty", entry)
		if get_questions_for_visitor(vid).is_empty():
			# Not an error: a visitor mid-authoring (identity written, no
			# question yet) is a normal draft state, not broken data — but a
			# stage could draw this visitor and have nothing to ask them,
			# which is worth knowing about before it happens at runtime.
			warnings.append("Visitor %s has no Visitor Questions, so it has nothing to ask if drawn" % vid)

	for question: Dictionary in visitor_questions:
		var qid := str(question.get("question_id"))
		var q_vids: Array = question.get("visitor_ids", [])
		if q_vids.is_empty():
			errors.append("Visitor Question %s names no visitor" % qid)
		for q_vid: String in q_vids:
			if not visitor_ids.has(q_vid):
				errors.append("Visitor Question %s names visitor '%s', which does not exist" % [qid, q_vid])
		var correct := str(question.get("correct_choice", "")).strip_edges().to_upper()
		if not ["A", "B", "C", "D"].has(correct):
			errors.append("Visitor Question %s's Correct Choice is '%s', not A/B/C/D"
				% [qid, question.get("correct_choice")])
		for letter in ["A", "B", "C", "D"]:
			if str(question.get("choice_%s" % letter.to_lower(), "")).strip_edges().is_empty():
				errors.append("Visitor Question %s has no Choice %s text" % [qid, letter])

	# The Shop tab's item columns (design/proposals/inventory.md). A typo in
	# a Yes/No or Duration cell would otherwise quietly read as "No" or
	# "Stage", so anything unrecognised is reported rather than guessed at.
	for item: Dictionary in shop:
		var iid := str(item.get("item_id", ""))
		for column: String in ["use_in_office", "use_in_stage", "player_choice"]:
			var yes_no: Variant = item.get(column)
			if yes_no != null and not ["yes", "no", "y", "n", "true", "false", "1", "0"].has(
					str(yes_no).strip_edges().to_lower()):
				errors.append("Shop item %s's %s is '%s', not Yes or No" % [iid, column, yes_no])
		var duration: Variant = item.get("duration")
		if duration != null and not ["stage", "level"].has(str(duration).strip_edges().to_lower()):
			errors.append("Shop item %s's Duration is '%s', not Stage or Level" % [iid, duration])
		var grants: Variant = item.get("grants")
		if grants is Array:
			for entry: Dictionary in grants:
				_validate_reward_target(iid, "Grants", entry)

		# Player Choice needs something to choose from — a pool or a tier —
		# or the picker it opens would have nothing to show.
		if Items.is_player_choice(item) and Items.choice_pool_spec(item) == null:
			errors.append("Shop item %s is Player Choice but its Grants has no pool or tier to choose from" % iid)

		# The Bonus 1/2/3 Role columns (design/proposals/inventory.md,
		# 2026-09-25 follow-up): each named role has to be a real Staff role,
		# or the bonus can never actually trigger.
		for row: Dictionary in Items.staff_bonus_rows(item):
			if not Ledger.STAFF_ROLES.has(row["role"]):
				errors.append("Shop item %s names Staff role '%s', which is not %s"
					% [iid, row["role"], ", ".join(Ledger.STAFF_ROLES)])

	_validate_rules()


## A single target_delta_list entry (a Visitor's Reward or Penalty column) —
## its target must match a known ID prefix (RewardTargets.gd) AND actually
## exist, or the reward silently does nothing the moment a player earns it.
func _validate_protagonists() -> void:
	if protagonists.is_empty():
		errors.append("player.json has no protagonists")
		return
	var seen: Array[String] = []
	for entry: Variant in protagonists:
		var player_id := str((entry as Dictionary).get("player_id", "")) if entry is Dictionary else ""
		if player_id.is_empty():
			errors.append("a protagonist in player.json has no player_id")
		elif seen.has(player_id):
			errors.append("player.json lists protagonist %s twice" % player_id)
		else:
			seen.append(player_id)


func _validate_reward_target(owner_id: String, column: String, entry: Dictionary) -> void:
	# A pool ("BO01|BO02 +1") is checked member by member: every one of them
	# has to be real, since any one of them can be the one picked.
	var pool: Variant = entry.get("target_pool")
	if pool is Array:
		if (pool as Array).is_empty():
			errors.append("%s's %s has an empty pool" % [owner_id, column])
		for member: Variant in pool:
			_validate_reward_target(owner_id, column, {"target": str(member), "delta": entry.get("delta")})
		return

	var target_id := str(entry.get("target", ""))
	var kind := RewardTargets.kind_of(target_id)
	var record: Dictionary
	match kind:
		RewardTargets.BOOSTER:
			record = get_booster(target_id)
		RewardTargets.MODIFIER:
			record = get_modifier(target_id)
		RewardTargets.SHOP_ITEM:
			record = get_shop_item(target_id)
		RewardTargets.SEGMENT:
			record = get_segment(target_id)
		RewardTargets.STAGE_EFFECT:
			return   # one of a closed list; recognising it is the whole check
		RewardTargets.BOOSTER_TIER:
			var tier_name := target_id.substr(RewardTargets.TIER_PREFIX.length())
			if not ["Party", "Constituency", "National"].has(tier_name):
				errors.append("%s's %s names tier '%s', which is not Party, Constituency or National"
					% [owner_id, column, tier_name])
			return
		_:
			errors.append(("%s's %s names '%s', which doesn't match any known ID prefix "
				+ "(BOxx, Mxx, SHxx, SGxx), a stage effect (%s), or a tier (TIER:Party etc.)")
				% [owner_id, column, target_id, ", ".join(RewardTargets.STAGE_EFFECT_TOKENS)])
			return
	if record.is_empty():
		errors.append("%s's %s names '%s', which does not exist" % [owner_id, column, target_id])


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

	# 2026-09-22 workbook: a level no longer embeds its own opponent rows —
	# every one it can fight is a row of opponents.json, and every one of
	# those was already walked, and had its pattern checked, in the main
	# opponents loop above. Nothing further to check here per level.


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
