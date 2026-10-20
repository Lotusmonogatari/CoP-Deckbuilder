extends Node
## Holds the state of the current run: which level is being played, how far
## through it the player is, where the player's standing sits, and how the
## last level went.
##
## This is the campaign's memory. It is deliberately separate from the rules
## engine, which is the maths of a single battle and remembers nothing.
##
## Everything here is written to disk by SaveManager (to_save() and
## load_save() below), so quitting and reopening carries on the same run.
## A battle itself is not saved: reopening mid-stage starts that stage again.

## Which of the four protagonists (data/player.json) this run is played as.
var protagonist_id: String = ""

## True from boot until a protagonist is chosen, when there was no save to
## load. The Office opens the New Game screen while it is set. SaveManager
## sets it; tests and the editor never do, so they start as the default.
var awaiting_new_game := false

## True while a stage is being fought. A save is not taken then — the last
## one, from the stage boundary, is the one to come back to.
var mid_stage := false

## The level being played, or null when the player is in the Office.
var level_runner: LevelRunner = null

## How the last finished level went: "win", "loss", or empty if none yet.
var last_level_outcome: String = ""

## The player's standing: constituency support, reputation, funds and party
## support, by the English names sanban.json gives them. Seeded from that
## file's starting values and then moved by what happens in a stage.
var meta: Dictionary = {}

## What the last finished stage did to those variables, e.g.
## { "Reputation": 3 }. Cleared when the next stage starts. The battle screen
## reads it to tell the player what just happened to them.
var last_meta_change: Dictionary = {}
## Why each variable in last_meta_change moved: { name: [{cause, amount}, ...] },
## in the order they happened, one entry per cause with its amounts summed
## (Your Record shows them, 2026-10-15; amounts added 2026-10-18).
var last_meta_cause: Dictionary = {}
## The same for organizations: { booster_id: [{cause, amount}, ...] }, filed
## beside last_booster_change (Important Stakeholders shows them).
var last_booster_cause: Dictionary = {}
## The cause the next recorded change is filed under; set around a block of
## rewards, cleared after.
var _cause := ""

## Experience earned so far, and by the stage just finished.
##
## CLAUDE.md puts the XP checkpoint at milestone M5, so nothing spends this
## yet. It is banked rather than discarded so the checkpoint has a real
## number to open with, and so a stage's win_delta_xp stops being a column the
## workbook exports and no code has ever read.
var xp := 0
var last_xp_gained := 0

## What the player owns, and what they are taking in.
##
## `owned_cards` starts as the Starter twelve and grows as XP is spent.
## `deck` is the subset carried into a battle — a fixed size, so unlocking a
## card means leaving another out. That trade is the whole point of the deck
## screen; without it an unlock would be a free upgrade.
##
## `owned_modifiers` is the organisations' backing bought with Funds. Held
## for the run rather than the level, like standing.
var owned_cards: Array[String] = []
var deck: Array[String] = []
var owned_modifiers: Array[String] = []

## Cosmetic packages (2026-09-28): purely decorative, bought with Funds/XP.
## `owned_cosmetic_packages` is what's been bought; `active_cosmetics` is
## what's currently equipped, independently per slot —
## { CosmeticPieces.OUTFIT/BACKGROUND/MUSIC : package_id }. A slot missing
## from the dictionary, or set to "", means Default (the base game look).
## See CosmeticPieces.gd, ArtLoader.gd's variant axis, Audio.gd's music
## override.
var owned_cosmetic_packages: Array[String] = []
var active_cosmetics: Dictionary = {}

## The inventory: shop items (SHxx) held and how many of each, e.g.
## { "SH04": 2 }. Filled by buying in the Office's Supplies shop and by an
## Office Hours visitor's reward; emptied one at a time by the Use button in
## the Office or during a stage. See design/proposals/inventory.md.
var inventory: Dictionary = {}

## How many of each item have been bought during the current level. An
## item's Purchase Limit is checked against this; it resets when a level
## concludes, win or loss.
var shop_bought_this_level: Dictionary = {}

## A Rhetoric Training draw in progress: { item_id, card_id, look, seen }.
## Empty when none is. Saved, so quitting the app with a card on screen
## brings the same card back rather than a fresh draw — see
## offer_random_card().
var card_draw: Dictionary = {}

## Stage effects waiting for the next stage — an item with Duration "Stage"
## used in the Office. { "ENERGY": 1, ... }; handed to that stage's setup and
## then cleared (take_item_bonuses_for_stage()).
var pending_stage_bonuses: Dictionary = {}

## Stage effects waiting for the next LEVEL — an item with Duration "Level"
## used in the Office. They become level_bonuses when that level begins.
var pending_level_bonuses: Dictionary = {}

## Stage effects active for every stage of the level in progress: a level
## buff used in the Office before it, or one used mid-stage (which covers the
## rest of the level). Cleared when the level concludes.
var level_bonuses: Dictionary = {}

## Item effects that last a number of game-clock units from use (the Shop
## tab's Duration Units, 2026-10-18): [{"bonuses": {token: amount},
## "expires_at": clock}]. Merged into every stage's item bonuses until they
## run out (take_item_bonuses_for_stage()). Saved.
var timed_bonuses: Array = []

## { mod_id: the clock at which that bought backing lapses } for backings with
## a Duration Units (the Modifiers tab). Saved; a lapsed backing leaves
## owned_modifiers and can be bought again (_expire_modifiers()).
var modifier_expires: Dictionary = {}

## Where the player stands with each of the ten organisations, by booster ID.
## Pleasing one at a press conference raises it, and it is held between
## levels — unlike the pleased list, which lasts one level.
var booster_standing: Dictionary = {}

## What the last finished level did to those, e.g. { "BO08": 5 }.
var last_booster_change: Dictionary = {}

## Where the player stands with each of the 5 audience segments, by segment
## ID (SG01-05). Starts at that segment's "Initial Favorability %" from
## segments.json and is held between levels, the same way booster_standing
## is. This is a DIFFERENT number from a card's "segment_share" (how much of
## a STAGE's audience is a given segment — CardResolver.segment_share(),
## static per-stage data) or a modifier's audience trigger (MetaRules.
## active_modifiers(), same static per-stage data) — those two read
## stages.json's segment_mix and are unrelated to this. This is the
## PERSISTENT sentiment score Staff tier rewards move (Ledger.gd / Staff
## section; a reward's SGxx target lands here).
var segment_favorability: Dictionary = {}

## What the last staff hire/upgrade did to those, e.g. { "SG03": 2 }.
var last_segment_change: Dictionary = {}

## Where the player stands with each of the six real-world parties, by
## party name (parties.json's own "name" — the same string opponents.json/
## player.json already carry in their "party" column). National Assembly
## Floor Voting (ST23) is the first stage to move more than one at once.
##
## The player's OWN party is a special case: rather than a second number to
## keep in sync, party_favorability() reads that party's live entry
## straight out of `meta["Party support"]` — the existing sanban variable
## IS that party's favorability, per Cameron's "the existing party favor
## will feed into the player character's party". Only the other five
## parties actually live in this dictionary.
var party_standing: Dictionary = {}

## What the last Floor Vote did to those, e.g. { "Keizaijiyuutou": -3 }.
var last_party_change: Dictionary = {}

## Who is hired into each of the three Staff roles, and at what tier:
## { "Policy Research Assistant": { "staff_id": "SF04", "tier": 1 }, ... }.
## A role with no entry is vacant, either because nobody has ever been
## hired into it or because its hire was fired (see staff_fired below and
## fire_staff()) — see Ledger.gd's Staff section and
## hire_staff()/upgrade_staff()/fire_staff().
var staff_hired: Dictionary = {}

## Every staff_id ever fired this run, { "SF04": true, ... }. Firing costs a
## severance (Ledger.staff_firing_cost()) and is permanent, Cameron's call,
## 2026-09-25 (design/proposals/staff_firing.md): a fired candidate never
## appears hireable again for the rest of this run, so the Recruitment shop
## checks this before listing anyone as a candidate.
var staff_fired: Dictionary = {}

## Level IDs the player has paid XP to unlock — only meaningful once
## rules.json's "level_gating_enabled" is true. A level whose relevant
## unlock_cost_* is already 0 does not need an entry here to be playable; see
## Ledger.is_level_unlocked().
var levels_unlocked: Array[String] = []

## How many levels have been FINISHED so far this sitting — win or loss both
## count. [DEFAULT] The workbook's own note on levels.json's cooldown column
## reads "# of OTHER LEVELS TO PLAY before this level is available to play
## again", and "play" most naturally means "finish", not "specifically win",
## so a loss burns down a cooldown exactly like a win does. If that reading
## is wrong, this is the one line to change (see Ledger.level_cooldown_remaining).
var levels_completed_count: int = 0

## { level_id -> the levels_completed_count value at the moment it last
## finished }. A level with no entry has never been finished and so is never
## on cooldown, no matter what its cooldown number says.
var level_last_completed_at: Dictionary = {}

## { level_id -> the game clock (time_units) when it last finished }. This is
## what a level's cooldown is measured against (2026-10-18; it used to count
## other levels played). Saved; cleared on a new run.
var level_cleared_units: Dictionary = {}

## The game-clock reading at which decay last ran; decay runs every Decay
## Interval units from here (_apply_time_decays()). Saved.
var last_decay_at := 0

## Organizations whose standing moved (other than by decay) since decay last
## ran -- the "dealt with" test for neglect decay. Saved.
var booster_moved_in_period: Dictionary = {}
var _decaying := false

## { level_id -> how many times that level has been WON }, unlike levels_
## completed_count above — this only counts a win, not any finish, and it's
## per level rather than one running total. "Your Record"'s own level-by-
## level tally; a level's own tier total is derived from this at display
## time (OfficeScreen._show_record()) rather than kept as a second counter.
var levels_cleared: Dictionary = {}

## How many of Staff's highest_tier steps are open to hire from, 0 at a
## fresh run (SF01/SF08/SF15, the three highest_tier-0 candidates, are the
## only ones hireable). SH18 ("Unlock New Staff Recruitment Tier") raises
## this by 1 — Ledger.staff_hire_refusal() is where it actually gates a
## candidate.
var staff_recruitment_tier: int = 0

## Added to rules.json's own "funds_starting_cap" every time Funds is
## clamped (see _sanban_row()) — SH19 ("Increase Office Funds Cap") raises
## this by its own funds_cap_increase (100,000) each time it's bought.
##
## Redesigned 2026-10-04 (Cameron, from a playtest report that the cap
## "is not applied by default"): the EFFECTIVE cap used to just be
## sanban.json's own Funds "max" (1,000,000) with this bonus added on top
## — meaning a fresh run already sat at the full 1,000,000 ceiling before
## buying anything, and every SH19 purchase after that pushed the cap
## PAST 1,000,000 with nothing to stop it. Now funds_starting_cap
## (100,000) is the real starting point, this bonus ratchets it up from
## there, and the sanban "max" is read as the one hard ceiling neither
## number is ever allowed to cross — see _sanban_row()'s own mini() call.
var funds_cap_bonus: int = 0


# ---------------------------------------------------------------------------
# Crisis triggers (CLAUDE.md §8) — Town Hall, Steering Committee, funding
# freeze, and lifetime win/loss/gaffe tracking. Wired 2026-09-25.
# ---------------------------------------------------------------------------
# Each "_active" flag tracks whether the trigger is CURRENTLY in its zone,
# not merely whether the condition is true this instant — that distinction
# is the whole mechanism (see _check_crisis_triggers()): a trigger fires
# once on the way IN and stays quiet, even while its condition keeps
# holding, until the player crosses back OUT. Cameron, 2026-09-25: losing
# the Town Hall while Jiban is still low must not immediately queue another
# one. Persisted, so this holds across levels, not just within one.

## Whether a Town Hall (ST05) is currently the queue's business — set the
## moment MetaRules.town_hall_triggered() first turns true, cleared the
## moment Jiban rises back above its threshold.
var town_hall_active := false

## How many times each person (an OPxx opponent or a VIxx visitor) has been
## seated against the player this run -- PeopleDraw leans the next draw toward
## whoever has been met least, so the same face can return but rarely back to
## back (Cameron, 2026-10-13). Saved; cleared on a new run.
var faced_people: Dictionary = {}

## Same shape, for the Party Steering Committee check-in (ST22).
var steering_committee_active := false

## The game clock (2026-10-18): units of time that have passed this run.
## Finishing a stage adds that stage's Time Units (Stages tab; blank = 1).
## Saved; cleared on a new run. Never shown to the player (TimeClock.gd).
var time_units := 0

## Special Levels waiting on a countdown or due: { trigger: {"armed_at": clock
## units} } (SpecialLevels.gd). Saved; cleared on a new run. An entry stays
## until that special level has been played, win or lose.
var special_levels: Dictionary = {}

## Set when an ordinary level finishes with a special level due: the Office
## starts it at once the next time it opens (take_forced_special()). Saved, so
## closing the app in between does not lose it.
var special_forced := false

## Same shape, for the Funding Freeze (M32) — tracked here purely to detect
## the edge for the Office alert; the freeze's actual enforcement
## (MetaRules.party_support_modifiers()) is checked live and needs no latch.
var funding_frozen_active := false

## News from the level just finished, for the Office to show once and
## forget — NOT in _SAVED_FIELDS on purpose, the same lifetime as
## last_level_outcome/last_meta_change. Each entry is
## {"kind": "town_hall"/"steering_committee"/"funding_freeze"/"gaffe_penalty",
## "edge": "entered"/"left"}.
var pending_trigger_alerts: Array[Dictionary] = []

## { stage_id: {"wins": N, "losses": N} }, lazily created per stage_id the
## first time it's played — keying by the real stage_id rather than some
## coarser category is what makes this track a stage type nobody has
## invented yet for free, with no code change needed when it arrives.
var stage_type_results: Dictionary = {}

## Every gaffe made, summed across every stage this run, this run's own
## final gaffe count each time (BattleState.gaffe at finish_stage()) —
## never reset mid-run, unlike a single stage's own gaffe meter.
var lifetime_gaffes := 0

## How many stages this run have been lost specifically to the gaffe
## meter filling, as opposed to the clock or any other loss reason.
var stages_lost_to_gaffes := 0

## Whether the one-time lifetime-gaffe penalty (Balance tab:
## gaffes_lifetime_penalty_threshold/_jiban_delta) has already fired.
## Lifetime gaffes never go back down, so unlike the three triggers above
## this never resets — it is a single event, not a zone.
var gaffe_penalty_applied := false

## Every bill_id the Floor Vote influence swing has flipped (§7.7), in the
## order they happened — "Your Record"'s own list. See record_bill_flip().
var bills_flipped_by_influence: Array[String] = []

## The statute book (2026-10-12): one entry per bill that came to a Floor
## Vote, passed or failed, in the order they were voted. See StatuteBook.gd
## for an entry's shape and record_floor_vote() for where it is written.
var statute_book: Array = []

## Patron Bills (2026-10-19). patron_requests: {patron_bill_id: {"status",
## "components", "amended", "tries"}} (statuses are PatronRequests.*);
## enacted_components: every component that has become law (Option A never
## offers one again); patron_runtime: the level in progress, {"patron_bill_id",
## "level"} ({} when none); patron_composed: {patron_bill_id: the composed bill
## and its components}, kept so the statute book can name a bill after the run
## is saved and reloaded.
var patron_requests: Dictionary = {}
var enacted_components: Array = []
var patron_runtime: Dictionary = {}
## When each request's countdown began ({patron_bill_id: clock units}); a
## request shows once special_level_delay units have run (step 4).
## What the latest sponsored-bill vote did (empty otherwise); read once by the
## Floor Vote result and never saved.
## The organization/audience changes of the latest visitor answer, for the
## chip row. Not saved.
var last_visitor_effects: Array = []
var last_patron_outcome: Dictionary = {}
## Draft a Bill (2026-10-19): the player's own bills as runtime patron rows
## ({id: row}), how many have been drafted, and the clock when the last was
## (-1 for never). Saved.
var patron_drafts: Dictionary = {}
var draft_counter := 0
var last_draft_at := -1
var patron_armed: Dictionary = {}
var patron_composed: Dictionary = {}

## Help and hindrance on the vote in front of the player (BillAssist), cleared
## when the vote has resolved. patron_news: {story key: clock units it runs
## until}; the Office ticker shows a line for each story running.
var bill_assist: Dictionary = BillAssist.empty()
var patron_news: Dictionary = {}

## The stance taken on this level's bill (2026-10-18, BillStance): {} when the
## level has no bill or no lean was picked; otherwise { "bill_id", "lean"
## ("Support"/"Oppose"), "cost": { booster_id: how much the win drift has taken
## from it this level }, "voted": bool }. Saved, so a resumed level keeps it;
## cleared when a level begins, ends or is abandoned.
var bill_stance: Dictionary = {}


func _ready() -> void:
	protagonist_id = str(DataDB.player.get("player_id", ""))
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()
	reset_party_standing()


## A fresh run as `player_id`: every number back to its start. False, and
## nothing changes, when there is no such protagonist.
func start_new_run(player_id: String) -> bool:
	if not DataDB.use_protagonist(player_id):
		return false
	protagonist_id = player_id
	_link_carry = {}
	level_runner = null
	last_level_outcome = ""
	mid_stage = false
	reset_meta()
	reset_booster_standing()
	reset_segment_favorability()
	reset_party_standing()
	faced_people = {}
	awaiting_new_game = false
	return true


# ---------------------------------------------------------------------------
# Saving
# ---------------------------------------------------------------------------
# One list of what a run is, used both ways, so a field added to the run and
# forgotten here is forgotten in both directions and caught by the round-trip
# test rather than half-saved.

const _SAVED_FIELDS := [
	"protagonist_id", "last_level_outcome", "meta", "xp",
	"owned_cards", "deck", "owned_modifiers",
	"owned_cosmetic_packages", "active_cosmetics",
	"inventory", "shop_bought_this_level", "card_draw",
	"pending_stage_bonuses", "pending_level_bonuses", "level_bonuses",
	"booster_standing", "segment_favorability", "party_standing", "staff_hired", "staff_fired",
	"levels_unlocked", "levels_completed_count", "level_last_completed_at", "levels_cleared", "level_cleared_units", "timed_bonuses", "modifier_expires", "last_decay_at", "booster_moved_in_period",
	"staff_recruitment_tier", "funds_cap_bonus",
	"town_hall_active", "steering_committee_active", "funding_frozen_active", "time_units", "special_levels", "special_forced",
	"stage_type_results", "lifetime_gaffes", "stages_lost_to_gaffes",
	"gaffe_penalty_applied", "bills_flipped_by_influence", "statute_book", "faced_people",
	"bill_stance",
	"patron_requests", "enacted_components", "patron_runtime", "patron_composed", "patron_armed",
	"bill_assist", "patron_news", "patron_drafts", "draft_counter", "last_draft_at",
]


## The run, as plain data.
func to_save() -> Dictionary:
	var saved := {}
	for field: String in _SAVED_FIELDS:
		var value: Variant = get(field)
		saved[field] = value.duplicate(true) if (value is Dictionary or value is Array) else value
	saved["level_runner"] = level_runner.snapshot() if level_runner != null else null
	return saved


## Puts a run from to_save() back. A field the save lacks (one written by an
## older build) keeps its fresh-run value rather than failing the load.
func load_save(saved: Dictionary) -> void:
	var player_id := str(saved.get("protagonist_id", protagonist_id))
	if not start_new_run(player_id):
		start_new_run(str(DataDB.player.get("player_id", "")))

	for field: String in _SAVED_FIELDS:
		if not saved.has(field) or field == "protagonist_id":
			continue
		var current: Variant = get(field)
		var value: Variant = saved[field]
		if current is Array and value is Array:
			(current as Array).assign(value)   # keeps Array[String] typed
		elif current is Dictionary and value is Dictionary and field in _KEYED_BY_CURRENT_DATA:
			# A save from an older build lacks the newest entries (a new meta
			# variable, a new organisation), and one from a renamed workbook
			# has entries that no longer exist: start from the fresh run's
			# entries and take only the saved values for those.
			for key: Variant in (value as Dictionary):
				if (current as Dictionary).has(key):
					(current as Dictionary)[key] = (value as Dictionary)[key]
		elif typeof(current) == typeof(value):
			set(field, value)

	_register_saved_patron_bills()
	var runner: Variant = saved.get("level_runner")
	level_runner = LevelRunner.restored(runner) if runner is Dictionary else null
	if level_runner != null and level_runner.is_finished():
		level_runner = null
	if level_runner == null:
		patron_runtime = {}
	drop_stale_ids()


## Fields whose keys are fixed by the current workbook (see load_save()).
const _KEYED_BY_CURRENT_DATA := ["meta", "booster_standing", "party_standing"]


## Forgets anything a loaded run names that the current data no longer has:
## a card, modifier, level, staff member, shop item or cosmetic package that
## was renumbered or removed in a workbook update. Without this a stale ID
## reached the screens as a blank name. Returns how many entries were dropped
## (also reported once as a warning), so tests can check it.
func drop_stale_ids() -> int:
	var dropped := 0
	dropped += _keep_known(owned_cards, DataDB.get_card)
	dropped += _keep_known(deck, DataDB.get_card)
	dropped += _keep_known(owned_modifiers, DataDB.get_modifier)
	dropped += _keep_known(owned_cosmetic_packages, DataDB.get_cosmetic_package)
	dropped += _keep_known(levels_unlocked, DataDB.get_level)
	for item_id: String in inventory.keys():
		if DataDB.get_shop_item(item_id).is_empty():
			inventory.erase(item_id)
			dropped += 1
	for role: String in staff_hired.keys():
		var hired: Variant = staff_hired[role]
		if not (hired is Dictionary) or DataDB.get_staff(str((hired as Dictionary).get("staff_id", ""))).is_empty():
			staff_hired.erase(role)
			dropped += 1
	for slot: String in active_cosmetics.keys():
		if str(active_cosmetics[slot]) not in owned_cosmetic_packages:
			active_cosmetics.erase(slot)
			dropped += 1
	for level_id: String in level_last_completed_at.keys():
		if DataDB.get_level(level_id).is_empty():
			level_last_completed_at.erase(level_id)
	for level_id: String in levels_cleared.keys():
		if DataDB.get_level(level_id).is_empty():
			levels_cleared.erase(level_id)
	for mod_id: String in modifier_expires.keys():
		if DataDB.get_modifier(mod_id).is_empty():
			modifier_expires.erase(mod_id)
	for level_id: String in level_cleared_units.keys():
		if DataDB.get_level(level_id).is_empty():
			level_cleared_units.erase(level_id)
	if not card_draw.is_empty() and (DataDB.get_card(str(card_draw.get("card_id", ""))).is_empty() \
			or DataDB.get_shop_item(str(card_draw.get("item_id", ""))).is_empty()):
		card_draw = {}
		dropped += 1
	# A deck emptied by the above is rebuilt from what the player still owns.
	if deck.is_empty() and not owned_cards.is_empty():
		var size := int(DataDB.get_balance("starter_deck_size", 15))
		for card_id: String in owned_cards:
			if deck.size() >= size:
				break
			deck.append(card_id)
	if dropped > 0:
		push_warning("GameState: dropped %d saved entries the current data no longer has." % dropped)
	return dropped


## Removes from `ids` every entry `lookup` finds nothing for; returns how
## many were removed.
func _keep_known(ids: Array[String], lookup: Callable) -> int:
	var kept: Array[String] = []
	for id: String in ids:
		if not (lookup.call(id) as Dictionary).is_empty():
			kept.append(id)
	var removed := ids.size() - kept.size()
	if removed > 0:
		ids.assign(kept)
	return removed


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}
	last_meta_cause = {}
	xp = BattleSetup.starting_xp()
	last_xp_gained = 0
	funds_cap_bonus = 0
	reset_collection()
	reset_staff()
	reset_levels()
	reset_crisis_triggers()


## Every crisis trigger back to its rest state, and the lifetime counters
## back to zero, for a fresh run.
func reset_crisis_triggers() -> void:
	town_hall_active = false
	steering_committee_active = false
	time_units = 0
	last_decay_at = 0
	booster_moved_in_period = {}
	timed_bonuses = []
	modifier_expires = {}
	special_levels = {}
	special_forced = false
	funding_frozen_active = false
	pending_trigger_alerts = []
	stage_type_results = {}
	lifetime_gaffes = 0
	stages_lost_to_gaffes = 0
	gaffe_penalty_applied = false
	bills_flipped_by_influence = []
	statute_book = []
	patron_requests = {}
	enacted_components = []
	patron_runtime = {}
	patron_composed = {}
	patron_armed = {}
	patron_drafts = {}
	draft_counter = 0
	last_draft_at = -1
	bill_assist = BillAssist.empty()
	patron_news = {}
	DataDB.clear_runtime()


## Every Staff role back to vacant, every firing forgotten, and recruitment
## back to only highest_tier-0 candidates.
func reset_staff() -> void:
	staff_hired = {}
	staff_fired = {}
	staff_recruitment_tier = 0


## Every level back to locked-by-its-price and off cooldown.
func reset_levels() -> void:
	levels_unlocked = []
	levels_completed_count = 0
	level_last_completed_at = {}
	level_cleared_units = {}
	levels_cleared = {}


## Back to the opening collection and a freshly rolled opening deck.
##
## A new run needs no decisions before the first battle: the opening deck is
## every Starter card, and the deck screen is where the player changes it.
func reset_collection() -> void:
	owned_cards = []
	owned_cosmetic_packages = []
	active_cosmetics = {}

	# PLAYTEST SETTING, rules.json's own "open_card_collection" (moved off a
	# hardcoded source constant 2026-09-22, so this is a switch like every
	# other open decision rather than a line only a programmer can flip).
	# True hands the player every card in the workbook from the first
	# moment, so a session can try the whole slate without earning it —
	# Cameron asked for the XP and card economy to be left aside while he
	# prices xp_to_unlock by playing. Flip it false and the collection
	# starts at the opening tier again; nothing else changes, because the
	# Ledger still refuses anything unaffordable.
	var open: bool = DataDB.get_rule("open_card_collection", true)
	for card: Dictionary in DataDB.cards:
		if open or str(card.get("tier", "")) == Ledger.OPENING_TIER:
			owned_cards.append(str(card.get("card_id", "")))

	deck = Ledger.opening_deck(DataDB.cards, DataDB.balance)

	# opening_deck() fills past the opening tier from the suits above it (see
	# its own test, "the rest is filled from above") whenever there aren't
	# enough opening-tier cards to fill a deck. Whatever it picked has to be
	# owned too, or the very first deck of a run would contain cards the
	# collection screen says the player doesn't have.
	if not open:
		for card_id: String in deck:
			if not owned_cards.has(card_id):
				owned_cards.append(card_id)
	owned_modifiers = []
	inventory = {}
	# A new run starts with some free Rhetoric Training draws (Balance lever).
	var coupons := int(DataDB.balance.get("starting_training_session_coupons", 0))
	if coupons > 0 and not DataDB.get_shop_item("SH21").is_empty():
		inventory["SH21"] = coupons
	shop_bought_this_level = {}
	card_draw = {}
	pending_stage_bonuses = {}
	pending_level_bonuses = {}
	level_bonuses = {}


# ---------------------------------------------------------------------------
# Spending
# ---------------------------------------------------------------------------
# Every purchase goes through the Ledger first, so a screen cannot spend
# what the rules would have refused. Each returns the refusal reason, or an
# empty string when it went through.

## Spends XP on a card. The card joins the collection, not the deck: what
## you take in is a separate decision, made on the deck screen.
func buy_card(card_id: String) -> String:
	var card := DataDB.get_card(card_id)
	var refusal := Ledger.card_refusal(card, owned_cards, xp, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_xp(-Ledger.card_cost(card))
	owned_cards.append(card_id)
	return ""


## Spends Funds and/or XP on a cosmetic package — purely decorative, no
## gameplay effect. Buying does not equip it: see equip_cosmetic().
func buy_cosmetic_package(package_id: String) -> String:
	var package := DataDB.get_cosmetic_package(package_id)
	var refusal := CosmeticPieces.buy_refusal(
		package, owned_cosmetic_packages, xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal

	var price := CosmeticPieces.cost(package)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	owned_cosmetic_packages.append(package_id)
	return ""


## Sets which owned package (or "" for Default) is active for one cosmetic
## slot. Each slot is independent — equipping an outfit does not touch the
## background or music slots. No refusal path: the UI only ever offers a
## slot's owned, piece-bearing packages plus Default.
func equip_cosmetic(slot: String, package_id: String) -> void:
	if package_id.is_empty():
		active_cosmetics.erase(slot)
	else:
		active_cosmetics[slot] = package_id


## Spends XP to unlock a level (rules.json's "level_gating_enabled" only —
## OfficeScreen does not offer this button while gating is off, but the
## Ledger refusal is the real gate either way).
func unlock_level(level_id: String) -> String:
	var level := DataDB.get_level(level_id)
	var refusal := Ledger.level_unlock_refusal(level, levels_unlocked, staff_hired, xp, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_xp(-Ledger.level_unlock_cost(level, staff_hired))
	levels_unlocked.append(level_id)
	return ""


## Spends an organisation's activation cost (Funds, and since 2026-09-22
## sometimes Reputation and/or Constituency support too) on its backing.
func buy_modifier(mod_id: String) -> String:
	var modifier := DataDB.get_modifier(mod_id)
	var refusal := Ledger.modifier_refusal(modifier, owned_modifiers,
		meta, booster_standing, DataDB.booster_standing,
		DataDB.boosters, Text.phrase())
	if not refusal.is_empty():
		return refusal

	# Announced, the same as spending XP is. This used to write the number
	# straight in, so the Office's two spending doors behaved differently:
	# buying a card told the world and buying backing did not. Every
	# non-zero currency the modifier charges is spent, not just Funds.
	var costs := Ledger.modifier_costs(modifier)
	for name: String in costs.keys():
		var cost: int = costs[name]
		if cost > 0:
			_move_meta(name, -cost)

	owned_modifiers.append(mod_id)
	var lasts := ModifierEffects.duration_units(modifier)
	if lasts > 0:
		modifier_expires[mod_id] = time_units + lasts
	return ""


## Backings with a Duration Units lapse once the clock reaches their expiry:
## they leave owned_modifiers (and can be bought again), and the Office tells
## the player which one lapsed. Runs each time the clock moves.
func _expire_modifiers() -> void:
	for mod_id: String in modifier_expires.keys():
		if time_units < int(modifier_expires[mod_id]):
			continue
		modifier_expires.erase(mod_id)
		if owned_modifiers.has(mod_id):
			owned_modifiers.erase(mod_id)
			pending_trigger_alerts.append({"kind": "backing_lapsed", "edge": "entered",
				"name": str(DataDB.get_modifier(mod_id).get("name_en", mod_id))})


## Hires a candidate into their role, spending Funds, if the role is vacant
## and the price is affordable. Immediately applies whichever tier_N_reward
## matches the tier they START at (candidates do not all start at tier 0 —
## SF05 and SF07 start at tier 1).
func hire_staff(staff_id: String) -> String:
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var role := str(candidate.get("role", ""))
	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_hire_refusal(candidate, staff_hired.get(role, {}),
		bool(staff_fired.get(staff_id, false)), funds, staff_recruitment_tier, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -int(candidate.get("hiring_cost_yen", 0)))
	var starting_tier := int(candidate.get("starting_tier", 0))
	staff_hired[role] = {"staff_id": staff_id, "tier": starting_tier}
	_apply_staff_reward(candidate, starting_tier)
	return ""


## Upgrades a role's hired candidate to the next tier, spending Funds, if that
## step exists for them and is affordable. Applies the new tier's reward on
## top of whatever hiring (and any earlier upgrade) already gave — these are
## one-time bonuses per tier reached, not a repeating income, the same way a
## modifier's RESOURCE_BONUS_ON_WIN tier is a flat payment rather than a rate
## (see ModifierEffects.gd).
func upgrade_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return Text.say("staff.nobody_hired")

	var candidate := DataDB.get_staff(str(hired.get("staff_id", "")))
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var tier := int(hired.get("tier", 0))
	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_upgrade_refusal(candidate, tier, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	var cost := int(Ledger.staff_upgrade_cost(candidate, tier))
	_move_meta("Funds", -cost)

	var new_tier := tier + 1
	hired["tier"] = new_tier
	staff_hired[role] = hired
	_apply_staff_reward(candidate, new_tier)
	return ""


## Fires a role's hired candidate, spending a severance (Ledger.
## staff_firing_cost()) from Funds. The role goes vacant and can be filled
## with a different candidate right away — but not with this one: whatever
## the hire and every upgrade already paid out (Funds spent, standing and
## favourability gained) stands; nothing is refunded or clawed back, and the
## fired candidate is marked in staff_fired so they never appear hireable
## again this run. Cameron's decision, 2026-09-25
## (design/proposals/staff_firing.md).
func fire_staff(role: String) -> String:
	var hired: Dictionary = staff_hired.get(role, {})
	if hired.is_empty():
		return Text.say("staff.nobody_hired")

	var staff_id := str(hired.get("staff_id", ""))
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return Text.say("staff.unknown_candidate")

	var funds := int(meta.get("Funds", 0))
	var refusal := Ledger.staff_fire_refusal(candidate, funds, Text.phrase())
	if not refusal.is_empty():
		return refusal

	_move_meta("Funds", -Ledger.staff_firing_cost(candidate))
	staff_hired.erase(role)
	staff_fired[staff_id] = true
	return ""


## A staff tier's reward, applied the moment it is reached (on hire, and
## again on every upgrade that reaches a new tier).
##
## Each reward is {"delta": int, "target": "BOxx or SGxx"}.
func _apply_staff_reward(candidate: Dictionary, tier: int) -> void:
	var rewards: Variant = candidate.get("tier_%d_reward" % tier)
	if not (rewards is Array):
		return

	for reward: Variant in rewards:
		if not (reward is Dictionary):
			continue
		var target := str((reward as Dictionary).get("target", ""))
		var delta := int((reward as Dictionary).get("delta", 0))
		if target.begins_with("BO"):
			_under_cause(Text.say("record.cause_staff"), func() -> void: _apply_booster_delta(target, delta))
		elif target.begins_with("SG"):
			_apply_segment_delta(target, delta)


## Replaces the deck, if the new one is legal.
func set_deck(chosen: Array[String]) -> String:
	var refusal := Ledger.deck_refusal(chosen, owned_cards, DataDB.balance, Text.phrase())
	if not refusal.is_empty():
		return refusal

	deck = chosen.duplicate()
	return ""


## Every organisation back to where it starts — its own "Starting Standing"
## column on the workbook's Boosters tab (`boosters.json`'s own
## `starting_standing`, Cameron's to write per organisation), or
## booster_standing.json's flat "start" for any booster that column leaves
## blank (2026-09-28: the flat 50 for every organisation read the same on
## the Backing screen whatever the group, so standing now differs per
## booster). A blank cell exports as JSON null, not 0 — the usual
## <null>-safe check, since a real "start at zero" has to stay possible.
func reset_booster_standing() -> void:
	booster_standing = {}
	last_booster_change = {}
	last_booster_cause = {}

	var start := int(DataDB.booster_standing.get("start", 30))
	for booster: Dictionary in DataDB.boosters:
		var own_start: Variant = booster.get("starting_standing")
		booster_standing[str(booster.get("booster_id"))] = start if own_start == null else int(own_start)

## Decay now runs on the game clock (2026-10-18): once for every Decay Interval
## units (Balance tab; 0 = off) that have passed since it last ran. Organizations
## nobody dealt with since then drift toward their starting standing, every
## organization settles by its own Decay Percent, and meta values with a Decay
## Percent settle. It used to run once at the end of every level.
func _apply_time_decays() -> void:
	var interval := int(DataDB.balance.get("decay_interval", 6))
	if interval <= 0:
		last_decay_at = time_units
		return
	while time_units - last_decay_at >= interval:
		last_decay_at += interval
		_decaying = true
		_apply_neglect_decay()
		_apply_standing_decay()
		_apply_meta_decay()
		_decaying = false
		booster_moved_in_period = {}



## Neglect (2026-10-16, Cameron): at the end of a level, every organisation
## whose standing did not move at all this level (last_booster_change, which
## covers answers, visitors, items and laws alike) drifts `neglect_decay`
## points toward its own starting standing. Standing has to be maintained.
func _apply_neglect_decay() -> void:
	var step := int(DataDB.booster_standing.get("neglect_decay", 0))
	if step <= 0:
		return
	var default_start := int(DataDB.booster_standing.get("start", 30))
	var touched := booster_moved_in_period.keys()
	var starts := {}
	for booster: Dictionary in DataDB.boosters:
		var own_start: Variant = booster.get("starting_standing")
		starts[str(booster.get("booster_id"))] = default_start if own_start == null else int(own_start)
	for booster_id: String in booster_standing.keys():
		if touched.has(booster_id):
			continue
		var now := int(booster_standing[booster_id])
		var target := BoosterStanding.decayed(now, int(starts.get(booster_id, default_start)), step)
		if target != now:
			_links_suspended = true
			_under_cause(Text.say("record.cause_neglect"),
				func() -> void: _apply_booster_delta(booster_id, target - now))
			_links_suspended = false


## Meta values that carry a Decay Percent on the Sanban tab (Reputation and
## Constituency support today) settle back toward the protagonist's starting
## value by that percent of the distance (at least 1 point) at the end of
## every level (2026-10-18, balance audit: they sat at 100 from level 40).
func _apply_meta_decay() -> void:
	var starts := BattleSetup.starting_meta_for(DataDB.player)
	for variable: Dictionary in DataDB.sanban:
		var percent: Variant = variable.get("decay_percent")
		if percent == null:
			continue
		var name := str(variable.get("name_en", ""))
		var now := int(meta.get(name, 0))
		var target := BoosterStanding.decayed_percent(now, int(starts.get(name, now)), float(percent))
		if target != now:
			_links_suspended = true
			_cause = Text.say("record.cause_decay")
			_apply_meta_reward(name, target - now)
			_cause = ""
			_links_suspended = false


## Every organization settles back toward its starting standing by its own
## Decay Percent of the distance (the Boosters tab; blank falls back to
## booster_standing.json's decay_percent). Triggers no Standing Links.
func _apply_standing_decay() -> void:
	var default_percent := float(DataDB.booster_standing.get("decay_percent", 0))
	var default_start := int(DataDB.booster_standing.get("start", 30))
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		if not booster_standing.has(id):
			continue
		var own_start: Variant = booster.get("starting_standing")
		var own_percent: Variant = booster.get("decay_percent")
		var now := int(booster_standing[id])
		var target := BoosterStanding.decayed_percent(now,
			default_start if own_start == null else int(own_start),
			default_percent if own_percent == null else float(own_percent))
		if target != now:
			_links_suspended = true
			_under_cause(Text.say("record.cause_decay"),
				func() -> void: _apply_booster_delta(id, target - now))
			_links_suspended = false


## The five parties the player isn't in, back to where party_standing.json
## starts them. The player's own party is never in here — see
## party_favorability()'s own comment.
func reset_party_standing() -> void:
	party_standing = {}
	last_party_change = {}

	var start := int(DataDB.party_standing.get("start", 50))
	var own_party := str(DataDB.player.get("party", ""))
	for party: Dictionary in DataDB.parties:
		var name := str(party.get("name", ""))
		if not name.is_empty() and name != own_party:
			party_standing[name] = start


## Every segment back to its own "Initial Favorability %" from the workbook.
## Unlike booster_standing, there's no hand-written config file for this —
## the workbook already gives each segment its own starting number, so there
## is nothing left for a config file to add. 50 is the fallback only for a
## segment row that somehow has no value at all.
func reset_segment_favorability() -> void:
	segment_favorability = {}
	last_segment_change = {}

	for segment: Dictionary in DataDB.segments:
		var segment_id := str(segment.get("segment_id"))
		var start: Variant = segment.get("initial_favorability_pct")
		segment_favorability[segment_id] = int(start) if start != null else 50


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	level_runner = runner
	bill_stance = {}
	bill_assist = BillAssist.empty()
	mid_stage = false
	last_level_outcome = ""
	last_meta_change = {}
	last_meta_cause = {}
	last_xp_gained = 0
	last_booster_change = {}
	last_booster_cause = {}

	# A level buff used in the Office now runs for every stage of this level.
	level_bonuses = pending_level_bonuses.duplicate()
	pending_level_bonuses = {}

	for stage: Variant in runner.stages:
		record_faced(stage)


## Counts everyone seated in `stage` (opponents and visitors) as met once
## more, so PeopleDraw leans away from them next time.
func record_faced(stage: Variant) -> void:
	if not (stage is Dictionary):
		return
	for person: Variant in ((stage as Dictionary).get("opponents", []) as Array):
		var id := str((person as Dictionary).get("opp_id", ""))
		if not id.is_empty():
			faced_people[id] = int(faced_people.get(id, 0)) + 1
	for person: Variant in ((stage as Dictionary).get("visitors", []) as Array):
		var id := str((person as Dictionary).get("visitor_id", ""))
		if not id.is_empty():
			faced_people[id] = int(faced_people.get(id, 0)) + 1


## True while a level is in progress.
func is_in_level() -> bool:
	return level_runner != null and not level_runner.is_finished()


## Records how a stage went and moves the level on. Returns true when the
## level is now over, which is the battle screen's cue to head back.
##
## `gaffe_caused_loss` (BattleScreen: `state.gaffe >= state.gaffe_limit`,
## false from VisitorScreen, which has no gaffe meter at all — see
## test_game_state_meta_tracking.gd) and `gaffes` (the stage's own final
## BattleState.gaffe) feed the lifetime tracking below; neither changes
## what a stage is WORTH, only what gets counted about it.
##
## `gaffe_caused_loss` is a plain boolean rather than BattleState.
## outcome_reason's own text on purpose: that text is already translated
## by the time BattleScreen sees it (Phrase.say()), so comparing it against
## a key string never matches in a real build — only in a hand-built test
## fixture with an empty wording table, which is exactly the bug a first
## version of this parameter had (caught in review, 2026-09-25, before it
## shipped anywhere real).
##
## `displeased_boosters` (2026-09-28, Cameron) is kept separate from
## `boosters` on purpose: `boosters` (the pleased list) also carries a buff
## into a later stage of the level (LevelRunner.carried_buffs()) — a weak
## answer must never grant that, so it is never mixed into that list, only
## used for the standing penalty below.
##
## `crushed_boosters` (2026-09-29, Cameron) is the organisations behind any
## opponent argued all the way down to zero support (BattleEngine.
## crushed_opponent_boosters()) — a separate, flat penalty from the
## please/displease netting above, since it is never about a question's
## own grade.
func finish_stage(outcome: String, score: int = 0, boosters: Array = [],
		gaffe_caused_loss: bool = false, gaffes: int = 0,
		displeased_boosters: Array = [], crushed_boosters: Array = [],
		opposed_boosters: Array = [], booster_tally: Dictionary = {}) -> bool:
	mid_stage = false
	if level_runner == null:
		return true

	var stage := level_runner.current_stage()
	time_units += TimeClock.units_for_stage(stage)
	_expire_modifiers()
	_record_stage_type_result(str(stage.get("stage_id", "")), outcome)
	_record_lifetime_gaffes(gaffes, outcome, gaffe_caused_loss)

	# What the stage just played did to the player's standing, before the
	# runner moves on and current_stage() becomes the next one.
	if outcome == LevelRunner.WON and str(stage.get("stage_id", "")) == MpVisit.FIGHT_STAGE:
		_won_over_member()
	_apply_stage_rewards(stage, outcome, score)
	_apply_question_boosters(boosters, displeased_boosters, opposed_boosters, booster_tally)
	_apply_instant_win_penalties(crushed_boosters)
	if outcome == LevelRunner.WON and str(stage.get("mode", "")) == "Combat":
		_apply_stance_win_drift()

	level_runner.finish_stage(outcome, score, boosters)

	# Funding freeze has nothing to insert into the queue, so both its edges
	# are always checked — a level ending on this very stage doesn't stop
	# the player finding out their money is frozen (or freed) once they're
	# back in the Office. Town Hall/Steering Committee insert a stage, so
	# their own checks internally skip entering a zone when there is
	# nowhere left to put one (level_runner.is_finished()) — leaving a zone
	# never needs anywhere to put anything, so that half always fires.
	_apply_time_decays()
	arm_patron_requests()
	_check_funding_freeze()
	var level_id := str(level_runner.level.get("level_id", ""))
	_check_town_hall()
	_check_steering_committee()

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()

		# Cooldown counts every completion, win or loss (see the comment on
		# levels_completed_count) — recorded here regardless of which way
		# last_level_outcome comes out, right where the level as a whole (not
		# just the stage just played) is known to be over.
		var patron_level := DataDB.is_runtime_level(level_id)
		if not level_id.is_empty() and not patron_level:
			levels_completed_count += 1
			level_last_completed_at[level_id] = levels_completed_count
			level_cleared_units[level_id] = time_units

		# The level has concluded, success or failure: each Supplies item's
		# Purchase Limit starts counting again, and level buffs run out.
		_conclude_level_items()

		# Laws with an "each level" effect pay out at the end of every level
		# after the one that passed them, win or loss (Law Effects tab).
		_apply_law_effect_rows(StatuteBook.ongoing_effects(
			statute_book, DataDB.law_effects, levels_completed_count))

		if last_level_outcome == LevelRunner.WON:
			_cause = Text.say("record.cause_level_win")
			_pay_level_rewards()
			_apply_level_bonus_win(level_runner.level)
			_cause = ""
			if not level_id.is_empty() and not patron_level:
				levels_cleared[level_id] = int(levels_cleared.get(level_id, 0)) + 1
		if patron_level:
			_conclude_patron_level()

		# A special level, once played (win or lose), is done until its trigger
		# comes round again; after an ordinary level, any special level that is
		# due is forced in next.
		var finished_trigger := SpecialLevels.trigger_of(DataDB.get_level(level_id))
		if not finished_trigger.is_empty():
			special_levels.erase(finished_trigger)
		elif not due_special_levels().is_empty():
			special_forced = true
		SaveManager.autosave(true)
		return true
	SaveManager.autosave(true)
	return false


# ---------------------------------------------------------------------------
# Crisis triggers and lifetime tracking (finish_stage()'s own helpers)
# ---------------------------------------------------------------------------

## Wins/losses for this stage_id, lazily bucketed.
func _record_stage_type_result(stage_id: String, outcome: String) -> void:
	if stage_id.is_empty():
		return
	var bucket: Dictionary = stage_type_results.get(stage_id, {"wins": 0, "losses": 0})
	if outcome == LevelRunner.WON:
		bucket["wins"] = int(bucket.get("wins", 0)) + 1
	elif outcome == LevelRunner.LOST:
		bucket["losses"] = int(bucket.get("losses", 0)) + 1
	stage_type_results[stage_id] = bucket


## Adds this stage's own gaffe count to the run's lifetime total, counts a
## gaffe-caused loss, and applies the one-time Jiban penalty the moment the
## lifetime total crosses the Balance tab's own threshold.
func _record_lifetime_gaffes(gaffes: int, outcome: String, gaffe_caused_loss: bool) -> void:
	if gaffes > 0:
		lifetime_gaffes += gaffes
	if outcome == LevelRunner.LOST and gaffe_caused_loss:
		stages_lost_to_gaffes += 1

	if gaffe_penalty_applied:
		return
	var threshold := int(DataDB.balance.get("gaffes_lifetime_penalty_threshold", 50))
	if lifetime_gaffes < threshold:
		return

	gaffe_penalty_applied = true
	var delta := int(DataDB.balance.get("gaffes_lifetime_penalty_jiban_delta", -15))
	_cause = Text.say("record.cause_gaffes")
	_apply_meta_reward("Constituency support", delta)
	_cause = ""
	pending_trigger_alerts.append({"kind": "gaffe_penalty", "edge": "entered",
		"count": lifetime_gaffes, "amount": absi(delta)})


## Funding freeze inserts nothing, so both edges always fire — there is no
## "nowhere to put it" case the way there is for a forced-in stage.
func _check_funding_freeze() -> void:
	var frozen := MetaRules.funding_frozen(party_support_effective(), DataDB.balance)
	if frozen and not funding_frozen_active:
		funding_frozen_active = true
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "entered"})
	elif not frozen and funding_frozen_active:
		funding_frozen_active = false
		pending_trigger_alerts.append({"kind": "funding_freeze", "edge": "left"})


## Starts the Town Hall countdown the moment Constituency support first
## crosses its threshold (2026-10-18, Cameron: it used to insert a Town Hall
## into the level being played). The special level appears Special Level Delay
## units of the game clock later (due_special_levels()). Says nothing further
## until support has climbed back out again -- losing the Town Hall while
## support is still low must not immediately start a second countdown
## (Cameron, 2026-09-25).
func _check_town_hall() -> void:
	var jiban := int(meta.get("Constituency support", 0))
	var triggered := MetaRules.town_hall_triggered(jiban, DataDB.balance)
	if triggered and not town_hall_active:
		town_hall_active = true
		_arm_special(SpecialLevels.TOWN_HALL)
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "entered", "count": jiban})
	elif not triggered and town_hall_active:
		town_hall_active = false
		pending_trigger_alerts.append({"kind": "town_hall", "edge": "left"})


## Same shape, for the Party Steering Committee Check-In, started when party
## support falls below its own threshold.
func _check_steering_committee() -> void:
	var party_support := party_support_effective()
	var triggered := MetaRules.steering_committee_triggered(party_support, DataDB.balance)
	if triggered and not steering_committee_active:
		steering_committee_active = true
		_arm_special(SpecialLevels.STEERING_COMMITTEE)
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "entered", "count": party_support})
	elif not triggered and steering_committee_active:
		steering_committee_active = false
		pending_trigger_alerts.append({"kind": "steering_committee", "edge": "left"})


## Begins a special level's countdown on the game clock, unless one is
## already running or waiting.
func _arm_special(trigger: String) -> void:
	if not special_levels.has(trigger):
		special_levels[trigger] = {"armed_at": time_units}


## The special levels whose countdown has run out, in the order they come due.
func due_special_levels() -> Array[String]:
	return SpecialLevels.due(special_levels, time_units,
		int(DataDB.balance.get("special_level_delay", 5)))


## The due special level rows, for the top of the level list.
func due_special_level_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for trigger: String in due_special_levels():
		var level := SpecialLevels.level_for(trigger, DataDB.levels)
		if not level.is_empty():
			rows.append(level)
	return rows


## If an ordinary level just ended with a special level due, the one to start
## now (and forget the order); {} otherwise. The Office calls this when it opens.
func take_forced_special() -> Dictionary:
	if not special_forced:
		return {}
	special_forced = false
	var rows := due_special_level_rows()
	return {} if rows.is_empty() else rows[0]


## Everything a finished stage is worth, in the order the brief sets out.
##
## Two separate things, and they stack:
##
##   Win deltas — flat rewards for winning, straight off the stage row.
##   These have been in the workbook and in MetaRules since milestone 1 and
##   have never had a caller, so winning a stage moved nothing at all.
##
##   Score effects — what the closing number was worth, for the stages that
##   produce one. The conversion lives in the stage's own data, so what a
##   press conference is worth is a number Cameron can change rather than a
##   rule written in code.
##
## The playtest stages carry zeroes for the win deltas until Cameron fills
## them in; the wiring is here so the moment he does, they land.
func _apply_stage_rewards(stage: Dictionary, outcome: String, score: int) -> void:
	# NOT reset here (2026-09-30): last_meta_change is scoped to the whole
	# level, the same as last_booster_change — resetting it per stage would
	# wipe out a Floor Vote's own favorability/influence-bonus moves, which
	# land on Sanban before finish_stage() (and this function) ever runs.
	last_xp_gained = 0
	if stage.is_empty():
		return

	# A win pays the stage's win_delta_* columns; a loss charges its
	# loss_delta_* columns (2026-09-27 — before this a loss cost nothing,
	# though every stage's penalties were already in the workbook).
	# 2026-09-22 workbook: xp_reward was renamed win_delta_xp.
	if outcome == LevelRunner.WON or outcome == LevelRunner.LOST:
		var side := "win" if outcome == LevelRunner.WON else "loss"
		_cause = Text.say("record.cause_stage_win" if side == "win" else "record.cause_stage_loss",
			{"stage": str(stage.get("name_en", ""))})
		var paid_stage := stage
		# Funding Freeze (M32) — party support at or below the Balance tab's
		# own threshold. Zeroed at the source rather than undone afterward,
		# so this is the one and only place Funds income can be frozen. Only
		# INCOME freezes: a Funds penalty for losing still lands.
		if "M32" in MetaRules.party_support_modifiers(party_support_effective(), DataDB.balance) \
				and MetaRules.stage_delta(stage, side + "_delta_yen") > 0:
			paid_stage = stage.duplicate(true)
			paid_stage[side + "_delta_yen"] = 0
		var moved := (MetaRules.apply_win_deltas(meta, paid_stage, sanban_rows_with_bonuses()) if side == "win"
			else MetaRules.apply_loss_deltas(meta, paid_stage, sanban_rows_with_bonuses()))
		meta = moved["meta"]
		_record_meta_change(moved["applied"])
		last_xp_gained = MetaRules.stage_delta(stage, side + "_delta_xp")
		_move_xp(last_xp_gained)

	var scored := MetaRules.apply_score_effects(meta, stage, score, sanban_rows_with_bonuses())
	meta = scored["meta"]
	_record_meta_change(scored["applied"])
	_cause = ""


## owned_modifiers, plus M09 (Party Backing) when party_support_modifiers()
## currently grants it for free — CLAUDE.md §8: "> 75 gives M09", never
## added to owned_modifiers
## itself, so losing the standing later correctly turns the free grant back
## off and buying one yourself is never made pointless by already having it
## free. M32 (Funding Freeze) is deliberately excluded here: it is a
## penalty enforced directly in _apply_stage_rewards(), not a bonus a
## reward-paying function should ever hand out.
func _effectively_owned_modifiers() -> Array:
	var mod_ids: Array[String] = owned_modifiers.duplicate()
	for mod_id: String in MetaRules.party_support_modifiers(party_support_effective(), DataDB.balance):
		if mod_id != "M32" and not mod_ids.has(mod_id):
			mod_ids.append(mod_id)

	var found: Array = []
	for id: String in mod_ids:
		var modifier := DataDB.get_modifier(id)
		if not modifier.is_empty():
			found.append(modifier)
	return found


## What the organisations backing you pay out for winning a LEVEL — not a
## single stage. RESOURCE_BONUS_ON_WIN's own workbook wording says "after
## successful completion of a level", so this is called once, when
## finish_stage() sees the level itself is won, rather than after every stage.
##
## Unlike the battle-start effects, this does not care who was in the
## room: a business circle pays for the result, not the audience.
func _pay_level_rewards() -> void:
	# M09's RESOURCE_BONUS_ON_WIN is what this function pays out.
	var owned := _effectively_owned_modifiers()
	# An organisation-triggered backing only pays while that organisation's
	# standing is at or above its number (Cameron, 2026-10-12).
	owned = owned.filter(func(m: Dictionary) -> bool:
		return m.get("trigger_booster_ids", []).is_empty() \
			or MetaRules.booster_trigger_met(m, booster_standing))
	if owned.is_empty():
		return

	# XP first — it is not a sanban row, so it goes through _move_xp rather
	# than the clamp-and-record path the other three share.
	var xp_bonus := ModifierEffects.level_win_resource_bonus(owned, "XP")
	if xp_bonus != 0:
		_move_xp(xp_bonus)
		last_xp_gained += xp_bonus

	for name: String in ["Funds", "Constituency support", "Party support"]:
		_apply_meta_reward(name, ModifierEffects.level_win_resource_bonus(owned, name))


## The level's own "bonus_win_range_*" and "win_delta_bo01..16" columns,
## rolled and applied. Called on the same LEVEL win as _pay_level_rewards().
##
## [DEFAULT] "bonus win" is not a concept CLAUDE.md or the rest of the code
## defines anywhere — there is no separate "ordinary win" the workbook
## contrasts it with, and no flag anywhere marking some level wins as bonus
## and others not. Rather than invent that distinction, every one of these
## ranges is rolled on every win of the level that carries it, per the
## brief's own fallback for this case. If Cameron means something more
## specific by "bonus" — a clean win, a win within the turn limit, a
## first-time clear — that is a design decision for him to make, not one
## to guess at here.
func _apply_level_bonus_win(level: Dictionary) -> void:
	const RANGE_TO_META := {
		"bonus_win_range_jiban": "Constituency support",
		"bonus_win_range_yen": "Funds",
		"bonus_win_range_reputation": "Reputation",
		"bonus_win_range_party_support": "Party support",
	}
	for key: String in RANGE_TO_META.keys():
		_apply_meta_reward(RANGE_TO_META[key], _roll_range(level.get(key)))

	var xp_amount := _roll_range(level.get("bonus_win_range_xp"))
	if xp_amount != 0:
		_move_xp(xp_amount)
		last_xp_gained += xp_amount

	# Every booster gets a chance at its own win_delta_boNN column, not just
	# the 16 that exist today — sorted by ID first so a booster added to the
	# workbook later rolls in the same order these always have (each roll
	# consumes the unseeded RNG, so the ORDER of these calls is part of what
	# "behaviour-neutral" means here, not just the set of keys read).
	var booster_ids: Array[String] = []
	for booster: Dictionary in DataDB.boosters:
		booster_ids.append(str(booster.get("booster_id", "")))
	booster_ids.sort()
	for booster_id: String in booster_ids:
		var key := "win_delta_" + booster_id.to_lower()
		var rolled := _roll_range(level.get(key))
		_under_cause(Text.say("record.cause_level_win"),
			func() -> void: _apply_booster_delta(booster_id, rolled))


## A stage or level reward to one meta-variable: clamped, and filed under
## what the last stage was worth.
func _apply_meta_reward(name: String, amount: int) -> void:
	if amount == 0:
		return
	var before := int(meta.get(name, 0))
	var after := MetaRules.clamp_meta(before, amount, _sanban_row(name))
	meta[name] = after
	_record_meta_change({name: after - before})


## A level's range columns are {"min": x, "max": y} or null ("this level
## carries no such bonus"). Rolled inclusively; null or a malformed value
## rolls nothing, same as an unset flat reward pays nothing.
func _roll_range(range_value: Variant) -> int:
	if not (range_value is Dictionary) or not (range_value as Dictionary).has("min"):
		return 0
	var low := int((range_value as Dictionary)["min"])
	var high := int((range_value as Dictionary)["max"])
	if high <= low:
		return low
	return randi_range(low, high)


func _sanban_row(name: String) -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == name:
			if name == "Funds":
				var with_cap := row.duplicate()
				var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
				var hard_max := int(row.get("max", 0))
				# The hard ceiling (sanban.json's own Funds "max") is the one
				# number nothing — not the starting cap, not any number of
				# SH19 purchases — is ever allowed to push past.
				with_cap["max"] = mini(starting_cap + funds_cap_bonus, hard_max)
				return with_cap
			return row
	return {"min": 0, "max": 999, "start": 0}


## The Funds row's own real ceiling: sanban.json's "max" cell, untouched by
## funds_starting_cap or funds_cap_bonus. Used wherever something needs to
## know the absolute number rather than the player's own current cap — e.g.
## buy_funds_cap()'s own "nothing left to buy" refusal.
func _funds_hard_max() -> int:
	return int(DataDB.get_sanban("Funds").get("max", 0))


## DataDB.sanban, with Funds' own "max" replaced by _sanban_row()'s own
## already-correct current-cap version — the same adjustment _sanban_row()
## already makes for a single lookup, but MetaRules.apply_win_deltas()/
## apply_loss_deltas()/apply_score_effects() each take the whole array, not
## one row at a time, so DataDB.sanban was being passed to them raw. A stage
## reward's own Funds delta was clamping against the workbook's flat max
## even after the player paid to raise it — bug found 2026-09-30, Cameron:
## "the yen/funds cap is not working." Always overridden for Funds now
## (2026-10-04), not just when funds_cap_bonus != 0 — the DEFAULT cap
## (funds_starting_cap) is lower than the raw sanban max too, not only the
## bonus-adjusted one.
func sanban_rows_with_bonuses() -> Array:
	var rows: Array = []
	for row: Dictionary in DataDB.sanban:
		rows.append(_sanban_row(str(row.get("name_en", ""))))
	return rows


## Earns or spends XP, and says so.
##
## Every change to the total goes through here so that nothing can move it
## quietly. The shop screens want to know the moment it changes, and so will
## anything that wants to make a sound about it.
func _move_xp(delta: int) -> void:
	if delta == 0:
		return
	xp += delta
	EventBus.xp_changed.emit(xp, delta)


## Moves one meta-variable outside a stage, and says so.
##
## The sibling of _move_xp, and separate from _record_meta_change on purpose:
## that one also files the change under "what the last stage was worth", and
## money spent in the Office is not a stage reward. Both announce.
## Clamped like every other meta write, and announced with what ACTUALLY
## moved rather than what was asked for — a ceiling that swallows half a
## payment should not be reported as a full one.
func _move_meta(name: String, delta: int) -> void:
	if delta == 0:
		return

	var before := int(meta.get(name, 0))
	var after := MetaRules.clamp_meta(before, delta, _sanban_row(name))
	if after == before:
		return

	meta[name] = after
	EventBus.meta_changed.emit(name, after, after - before)


## Standing Links (2026-10-18). Leftover fractions of a point, per target, so
## small changes add up instead of vanishing.
var _link_carry: Dictionary = {}
## True while a link's own change is being applied (a followed change never
## starts another link) and during neglect decay.
var _links_suspended := false


## The source moved by `points`: every link from it moves its target by
## weight x points, a rivalry (negative weight) the other way.
func _follow_links(source: String, points: float) -> void:
	if _links_suspended or points == 0.0:
		return
	for row: Dictionary in StandingLinks.from_source(DataDB.standing_links, source):
		var target := str(row.get("target", ""))
		var weight := float(row.get("weight", 0.0))
		var settled := StandingLinks.settle(points * weight, float(_link_carry.get(target, 0.0)))
		_link_carry[target] = settled["carry"]
		var whole: int = settled["whole"]
		if whole == 0:
			continue
		var source_name := source if not source.begins_with("BO") else str(DataDB.get_booster(source).get("name_en", source))
		var cause := Text.say("record.cause_link_rival" if weight < 0.0 else "record.cause_link_follow",
			{"source": source_name})
		_links_suspended = true
		_under_cause(cause, func() -> void: _apply_booster_delta(target, whole))
		_links_suspended = false


## Files `amount` under the current cause for `key`, summing with an earlier
## entry for the same cause so a reason appears once with its total.
func _note_cause(store: Dictionary, key: String, amount: int) -> void:
	if amount == 0:
		return
	var cause := _cause if not _cause.is_empty() else Text.say("record.cause_other")
	var entries: Array = store.get(key, [])
	for entry: Dictionary in entries:
		if entry["cause"] == cause:
			entry["amount"] = int(entry["amount"]) + amount
			store[key] = entries
			return
	entries.append({"cause": cause, "amount": amount})
	store[key] = entries


## Runs a block of booster changes under a named cause, then puts the
## previous cause back.
func _under_cause(cause: String, change: Callable) -> void:
	var before := _cause
	_cause = cause
	change.call()
	_cause = before


## Folds one lot of changes into what the screen will report.
##
## A stage can move the same variable twice — a flat reward for winning and
## again for the score it closed on — and the player should be told the
## total, not shown the second overwriting the first.
func _record_meta_change(applied: Dictionary) -> void:
	for name: String in applied.keys():
		last_meta_change[name] = int(last_meta_change.get(name, 0)) + int(applied[name])
		if int(applied[name]) != 0 and not _cause.is_empty():
			_note_cause(last_meta_cause, name, int(applied[name]))
		if int(applied[name]) != 0 and not DataDB.standing_links.is_empty():
			_follow_links(name, StandingLinks.points_for_meta(name, int(applied[name]),
				_sanban_row(name), int(DataDB.balance.get("standing_links_yen_per_point", 10000))))
		# Announced as well as recorded. The recording is for the result
		# screen, which asks afterwards; the announcement is for anything that
		# wants to react as it happens — a sound, or the Office lighting up a
		# number that just moved.
		if int(applied[name]) != 0:
			EventBus.meta_changed.emit(name, int(meta.get(name, 0)), int(applied[name]))


## Moves the player's standing with everyone a stage's question answers
## touched — pleased organisations up, annoyed ones down (2026-09-28,
## Cameron: a weak answer costs the organisation it would have pleased
## `per_displease`, currently 1).
##
## Standing is what survives the level; the pleased list is also what the
## floor debate draws on inside it (LevelRunner.carried_buffs()) — the
## displeased list is never used for that, only for the penalty here.
##
## Net, not additive: an organisation both pleased and annoyed in the same
## stage (two different questions) settles to one number, clamped to
## `question_swing_cap` either way — the hard ceiling on how far a single
## stage's question-answering can move any one organisation, whatever the
## please/displease amounts happen to be tuned to.
func _apply_question_boosters(pleased: Array, displeased: Array,
		opposed: Array = [], tally: Dictionary = {}) -> void:
	if pleased.is_empty() and displeased.is_empty() and opposed.is_empty() and tally.is_empty():
		return
	# One shared piece of arithmetic (BoosterStanding) with the outcome panel,
	# read against where each organisation stands right now.
	for entry: Dictionary in BoosterChange.compute(pleased, displeased, [],
			DataDB.booster_standing, opposed, stance_adjust_tally(tally), booster_standing):
		_under_cause(Text.say("record.cause_answers"),
			func() -> void: _apply_booster_delta(str(entry["booster_id"]), int(entry["net"])))


## An opponent argued all the way down to zero support (§7.2's instant-win
## rule, BattleEngine.crushed_opponent_boosters()) costs their own
## organisation standing — a flat, one-time hit per organisation touched
## this stage, regardless of how many of their own people went down the
## same way. Separate from _apply_question_boosters() above: this is never
## about a question's own grade, so it is never netted or capped alongside
## please/displease.
func _apply_instant_win_penalties(crushed_boosters: Array) -> void:
	if crushed_boosters.is_empty():
		return
	var penalty := int(DataDB.booster_standing.get("instant_win_penalty", 2))
	for booster_id: String in crushed_boosters:
		_under_cause(Text.say("record.cause_crush"),
			func() -> void: _apply_booster_delta(booster_id, -penalty))


## Office Hours (design/proposals/office_hours.md): applies one visitor's
## Reward column (on a correct answer) or Penalty column (on a wrong one) —
## OfficeHoursEngine.answer() hands back the raw, unresolved list exactly as
## stored on the visitor (it has no DataDB access, same as every other rules
## class), so resolving each target's real kind and record, and rolling any
## range delta, both happen here, once, at the moment the reward is actually
## applied — not shown to the player as a range and not rolled earlier at
## setup (open point 5 in the proposal).
func apply_visitor_reward_entries(entries: Array) -> String:
	var before := _cause
	_cause = Text.say("record.cause_visitor")
	var applied := _apply_reward_entries(entries)
	_cause = before
	last_visitor_effects = _effect_chips(applied)
	return _describe_grant_outcomes(applied)


## The one place a target_delta_list entry becomes a real effect — a
## visitor's Reward/Penalty, or a shop item's own Grants when it is used.
##
## A pooled entry ("BO01|BO02 +1") or a tier ("TIER:Party +1") picks one of
## its targets first, then applies like any other — UNLESS `chosen_target`
## is given, in which case that target is used instead of picking (an item
## marked Player Choice, design/proposals/inventory.md; the player already
## chose in the UI, so there is nothing left to roll). `extra_delta` is a
## flat amount added to every booster/segment entry's own delta — an item's
## staff bonus (Items.staff_bonus_rows()), already totalled by the caller,
## layered on top of the base effect wherever it lands.
##
## A shop item (SHxx) named here goes INTO THE INVENTORY, the same as
## buying one — Cameron, 2026-09-25: one consistent place for items to land
## — so there is nothing to recurse into and no way for two items to loop on
## each other. A stage effect (ENERGY, GUARD, ...) named here, outside an
## item being used, waits for the next stage.
##
## Returns every entry actually applied — {"kind","id","delta"} — so a
## caller whose grant was a random pick (a Commission item's "TIER:Party",
## say) can tell the player which organisation it actually landed on
## (2026-09-29, Cameron: a random outcome has to show up on screen, not
## only be inferable later from Important Stakeholders' own "(+1)" line).
## A BOOSTER_TIER pick is recorded as a plain BOOSTER, since by the time it
## is applied it IS one. STAGE_EFFECT is left out — it never names an
## organisation, and the caller reads it from split["stage"] separately.
func _apply_reward_entries(entries: Array, chosen_target: String = "",
		extra_delta: int = 0) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for raw: Variant in entries:
		if not (raw is Dictionary):
			continue
		var entry := _choose_target(raw, chosen_target)
		var resolved := DataDB.resolve_reward_target(entry)
		var kind: String = resolved.get("kind", "")
		var target_id: String = resolved.get("id", "")
		match kind:
			RewardTargets.BOOSTER:
				var delta := _resolve_delta(resolved.get("delta")) + extra_delta
				_apply_booster_delta(target_id, delta)
				applied.append({"kind": kind, "id": target_id, "delta": delta})
			RewardTargets.BOOSTER_TIER:
				# Only reached when nothing was chosen — a chosen target
				# already replaced this with a plain BOOSTER above.
				var pool: Array = (resolved.get("record", {}) as Dictionary).get("boosters", [])
				if not pool.is_empty():
					var picked: Dictionary = pool[randi() % pool.size()]
					var picked_id := str(picked.get("booster_id", ""))
					var delta := _resolve_delta(resolved.get("delta")) + extra_delta
					_apply_booster_delta(picked_id, delta)
					applied.append({"kind": RewardTargets.BOOSTER, "id": picked_id, "delta": delta})
			RewardTargets.MODIFIER:
				if not owned_modifiers.has(target_id):
					owned_modifiers.append(target_id)
					var granted_for := ModifierEffects.duration_units(DataDB.get_modifier(target_id))
					if granted_for > 0:
						modifier_expires[target_id] = time_units + granted_for
				applied.append({"kind": kind, "id": target_id, "delta": 0})
			RewardTargets.SEGMENT:
				var delta := _resolve_delta(resolved.get("delta")) + extra_delta
				_apply_segment_delta(target_id, delta)
				applied.append({"kind": kind, "id": target_id, "delta": delta})
			RewardTargets.SHOP_ITEM:
				# A delta, when given, is how many; a bare "SH04" is one.
				var count := maxi(_resolve_delta(resolved.get("delta")), 1)
				add_item(target_id, count)
				applied.append({"kind": kind, "id": target_id, "delta": count})
			RewardTargets.STAGE_EFFECT:
				_add_bonus(pending_stage_bonuses, target_id, _stage_effect_amount(resolved.get("delta")))
			_:
				push_warning("GameState: reward/penalty target '%s' did not resolve to anything." % target_id)
	return applied


## A grant's outcome in plain English — "Chamber of Commerce +1" — for
## whichever entries named an organisation or a segment. Only those two
## kinds are ever picked at random (a modifier or a shop item's own name
## already says exactly what was granted), so this is deliberately narrow:
## it answers "which one did the roll land on," not "what did I get."
## The standing changes in `applied` as chip entries ({ "id", "delta" }):
## organizations and audience groups only.
func _effect_chips(applied: Array) -> Array:
	var out: Array = []
	for entry: Dictionary in applied:
		if str(entry.get("kind", "")) in [RewardTargets.BOOSTER, RewardTargets.SEGMENT]:
			out.append({"id": str(entry.get("id", "")), "delta": int(entry.get("delta", 0))})
	return out


func _describe_grant_outcomes(applied: Array) -> String:
	var parts: Array[String] = []
	for entry: Dictionary in applied:
		var id: String = str(entry.get("id", ""))
		var delta := int(entry.get("delta", 0))
		match str(entry.get("kind", "")):
			RewardTargets.BOOSTER:
				parts.append("%s %+d" % [DataDB.get_booster(id).get("name_en", id), delta])
			RewardTargets.SEGMENT:
				parts.append("%s %+d" % [DataDB.get_segment(id).get("name_en", id), delta])
	return ", ".join(parts)


## A pool-shaped entry ("BO01|BO02 +1" or "TIER:Party +1"), decided:
## `chosen_target` wins when given (the player already picked it in the
## UI); otherwise a pool is randomly narrowed to one plain target here —
## unseeded, like every other roll here — and a tier is left for
## resolve_reward_target()/_apply_reward_entries() to pick from, since only
## DataDB knows which boosters currently belong to it. A plain entry
## (neither) comes back unchanged either way.
func _choose_target(entry: Dictionary, chosen_target: String) -> Dictionary:
	if not chosen_target.is_empty() and RewardTargets.is_pool_shaped(entry):
		return {"target": chosen_target, "delta": entry.get("delta")}

	var pool: Variant = entry.get("target_pool")
	if not (pool is Array) or (pool as Array).is_empty():
		return entry
	var picked := entry.duplicate()
	picked.erase("target_pool")
	picked["target"] = str((pool as Array)[randi() % (pool as Array).size()])
	return picked


# ---------------------------------------------------------------------------
# The inventory (design/proposals/inventory.md)
# ---------------------------------------------------------------------------

func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


## Adds up to `count` of an item, never past its Stack Cap. Returns how many
## actually went in — a visitor's gift beyond the cap is lost, not banked.
func add_item(item_id: String, count: int = 1) -> int:
	var item := DataDB.get_shop_item(item_id)
	var cap := Items.stack_cap(item)
	var room := count if cap <= 0 else clampi(cap - item_count(item_id), 0, count)
	if room > 0:
		inventory[item_id] = item_count(item_id) + room
	return room


## Buys one item from the Supplies shop: the Ledger-style refusal first, then
## every non-zero price (XP and/or Funds) is spent and announced, and the item
## goes into the inventory. Returns the refusal, or "" when it went through.
func buy_shop_item(item_id: String) -> String:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	add_item(item_id, 1)
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1
	return ""


## Rhetoric Training (Cameron, 2026-09-27) — where new cards come from.
## SH15-17 (XP) and SH27-29 (Yen), each naming a "card_tier" in shop.json.
## A draw shows the player a card BEFORE they pay for it:
##
##   offer_random_card()  starts a draw: one random card of that tier the
##                        player does not own yet, look 1. Nothing is paid.
##                        A draw already in progress is returned as it is.
##   pass_offered_card()  swaps it for another card of the same tier, look
##                        2, then 3 — rules.json's card_training_looks (3).
##   learn_offered_card() pays the item's price, adds exactly the card on
##                        screen, and ends the draw.
##
## The last look cannot be passed and a draw cannot be walked away from
## (Cameron, 2026-09-27: "must learn it") — seeing a card commits the
## player to learning one of up to three. The draw is saved, so closing
## the app does not reroll it; learning a card is what starts a fresh one.
##
## Each returns { "ok": bool, "message": String }; an ok offer or pass also
## carries { "card_id", "look", "looks" } for the pop-up's "#/3" counter.
func offer_random_card(item_id: String) -> Dictionary:
	if not card_draw.is_empty():
		return _draw_result()
	var item := DataDB.get_shop_item(item_id)
	var refusal := _card_training_refusal(item)
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	var choices := _unowned_cards_at_tier(_draw_tier(item))
	var card_id: String = choices[randi() % choices.size()]
	card_draw = {"item_id": item_id, "card_id": card_id, "look": 1, "seen": [card_id]}
	return _draw_result()


func pass_offered_card() -> Dictionary:
	if card_draw.is_empty():
		return {"ok": false, "message": ""}
	if not can_pass_offered_card():
		return {"ok": false, "message": ""}
	var tier := _draw_tier(DataDB.get_shop_item(str(card_draw["item_id"])))
	var seen: Array = card_draw.get("seen", [])
	# Something not shown yet in this draw where possible; with fewer unowned
	# cards left than looks, anything but the card on screen now.
	var fresh := _unowned_cards_at_tier(tier).filter(func(id: String) -> bool: return not seen.has(id))
	if fresh.is_empty():
		fresh = _unowned_cards_at_tier(tier).filter(
			func(id: String) -> bool: return id != str(card_draw["card_id"]))
	var card_id: String = fresh[randi() % fresh.size()]
	card_draw["card_id"] = card_id
	card_draw["look"] = int(card_draw["look"]) + 1
	seen.append(card_id)
	card_draw["seen"] = seen
	return _draw_result()


## True while the card on screen is not the draw's last look, and there is
## some other card of that tier to swap it for.
func can_pass_offered_card() -> bool:
	if card_draw.is_empty() or int(card_draw["look"]) >= card_training_looks():
		return false
	var tier := _draw_tier(DataDB.get_shop_item(str(card_draw["item_id"])))
	return _unowned_cards_at_tier(tier).size() > 1


## How many cards one draw may show — rules.json's card_training_looks.
func card_training_looks() -> int:
	return maxi(int(DataDB.get_rule("card_training_looks", 3)), 1)


func learn_offered_card() -> Dictionary:
	if card_draw.is_empty():
		return {"ok": false, "message": ""}
	var item_id := str(card_draw["item_id"])
	var card_id := str(card_draw["card_id"])
	var item := DataDB.get_shop_item(item_id)
	var free := _is_free_draw(item)
	var refusal := "" if free else _card_training_refusal(item)
	if refusal.is_empty() and not _unowned_cards_at_tier(_draw_tier(item)).has(card_id):
		refusal = Text.say("shop.no_cards_left_at_tier", {"tier": _draw_tier(item)})
	if not refusal.is_empty():
		# Nothing the player did on this screen can cause this (the price was
		# checked when the draw began), so a draw that can no longer be paid
		# for is let go rather than left stuck on screen.
		card_draw = {}
		return {"ok": false, "message": refusal}

	if not free:
		var price := Items.costs(item)
		_move_xp(-int(price["XP"]))
		_move_meta("Funds", -int(price["Funds"]))
		shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1
	owned_cards.append(card_id)
	card_draw = {}
	var card_name := str(DataDB.get_card(card_id).get("name_en", card_id))
	return {"ok": true, "card_id": card_id,
		"message": Text.say("shop.card_unlocked", {"name": card_name})}


func _draw_result() -> Dictionary:
	return {"ok": true, "message": "", "item_id": str(card_draw["item_id"]),
		"card_id": str(card_draw["card_id"]), "look": int(card_draw["look"]),
		"looks": card_training_looks()}


## Why a training session cannot be had right now, or "": the item's own
## price and stock (Items.buy_refusal), then whether any card of its tier
## is left to learn. Shared by the Office's row (to grey its button) and
## both steps above.
func card_training_refusal(item_id: String) -> String:
	return _card_training_refusal(DataDB.get_shop_item(item_id))


func _card_training_refusal(item: Dictionary) -> String:
	var item_id := str(item.get("item_id", ""))
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return refusal
	var tier := int(item.get("card_tier", 0))
	if _unowned_cards_at_tier(tier).is_empty():
		return Text.say("shop.no_cards_left_at_tier", {"tier": tier})
	return ""


## The card tier an item draws from: a coupon's Free Card Tier, else a
## training session's Card Tier.
func _draw_tier(item: Dictionary) -> int:
	var free: Variant = item.get("free_card_tier")
	return int(free) if free != null else int(item.get("card_tier", 0))


## True for a Training Session Coupon: its draw costs nothing (the coupon was
## the payment).
func _is_free_draw(item: Dictionary) -> bool:
	return item.get("free_card_tier") != null


func _unowned_cards_at_tier(tier: int) -> Array[String]:
	var choices: Array[String] = []
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == tier and not owned_cards.has(str(card.get("card_id", ""))):
			choices.append(str(card.get("card_id", "")))
	return choices


## SH13/14 ("Unlock Tier N Level"): the same on-purchase shape as
## the old one-step random-card purchase, and for the same reason — pays, then
## immediately unlocks one random not-yet-unlocked level of shop.json's
## own "level_tier". Ledger.is_level_unlocked() (not a bare levels_unlocked
## check) is what decides "not-yet-unlocked", so a level that is already
## open for some other reason (its own unlock cost is 0) is correctly
## never offered here.
func buy_random_level(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	var tier := int(item.get("level_tier", 0))
	var choices: Array[String] = []
	for level: Dictionary in DataDB.levels:
		if int(level.get("tier", -1)) == tier \
				and not Ledger.is_level_unlocked(level, levels_unlocked, staff_hired):
			choices.append(str(level.get("level_id", "")))
	if choices.is_empty():
		return {"ok": false, "message": Text.say("shop.no_levels_left_at_tier", {"tier": tier})}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	var level_id: String = choices[randi() % choices.size()]
	levels_unlocked.append(level_id)
	var level_name := str(DataDB.get_level(level_id).get("description", level_id))
	return {"ok": true, "message": Text.say("shop.level_unlocked", {"name": level_name})}


## SH18 ("Unlock New Staff Recruitment Tier"): pays, then raises
## staff_recruitment_tier by 1 — Ledger.staff_hire_refusal() is where that
## actually opens up candidates. Refuses once every candidate's own
## highest_tier is already open, rather than let a purchase do nothing.
func buy_staff_recruitment_tier(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	var highest := 0
	for candidate: Dictionary in DataDB.staff:
		highest = maxi(highest, int(candidate.get("highest_tier", 0)))
	if staff_recruitment_tier >= highest:
		return {"ok": false, "message": Text.say("shop.recruitment_tier_maxed")}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	staff_recruitment_tier += 1
	return {"ok": true, "message": Text.say("shop.recruitment_tier_unlocked")}


## SH19 ("Increase Office Funds Cap"): pays, then permanently raises how
## high Funds can go by the item's own "funds_cap_increase" — repeatable
## until the player's own current cap (rules.json's funds_starting_cap
## plus every funds_cap_bonus bought so far) reaches the hard ceiling
## (sanban.json's own Funds "max", 1,000,000). See _sanban_row(), where
## funds_cap_bonus is actually applied.
func buy_funds_cap(item_id: String) -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.buy_refusal(item, item_count(item_id),
		int(shop_bought_this_level.get(item_id, 0)), xp, int(meta.get("Funds", 0)), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}

	var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
	if starting_cap + funds_cap_bonus >= _funds_hard_max():
		return {"ok": false, "message": Text.say("shop.funds_cap_maxed")}

	var price := Items.costs(item)
	_move_xp(-int(price["XP"]))
	_move_meta("Funds", -int(price["Funds"]))
	shop_bought_this_level[item_id] = int(shop_bought_this_level.get(item_id, 0)) + 1

	var increase := int(item.get("funds_cap_increase", 0))
	funds_cap_bonus += increase
	return {"ok": true, "message": Text.say("shop.funds_cap_increased", {"count": increase})}


## Uses one item from the Office. Its standing effects (boosters, segments,
## modifiers) apply now; its stage effects wait for the next stage, or the
## whole next level when its Duration is "Level".
##
## `chosen_target` is which of a Player Choice item's pool to use — required
## the moment Items.is_player_choice(item) is true; left empty first, this
## returns { "ok": false, "needs_choice": true } instead of a refusal, which
## tells the UI to open the picker and call this again with the answer,
## rather than a reason to show the player.
##
## Returns { "ok": bool, "message": String } or { "ok": false, "needs_choice": true }.
func use_item_in_office(item_id: String, chosen_target: String = "") -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.use_refusal(item, Items.OFFICE, item_count(item_id), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if Items.is_player_choice(item) and chosen_target.is_empty():
		return {"ok": false, "needs_choice": true}

	var name := str(item.get("name", item_id))
	if _is_free_draw(item):
		# A Training Session Coupon: a free Rhetoric Training draw. Refused
		# (coupon kept) while another draw is open or no card of the tier is left.
		if not card_draw.is_empty():
			return {"ok": false, "message": Text.say("rhetoric.draw_in_progress")}
		var choices := _unowned_cards_at_tier(_draw_tier(item))
		if choices.is_empty():
			return {"ok": false, "message": Text.say("shop.no_cards_left_at_tier", {"tier": _draw_tier(item)})}
		_take_item(item_id)
		var card_id: String = choices[randi() % choices.size()]
		card_draw = {"item_id": item_id, "card_id": card_id, "look": 1, "seen": [card_id]}
		return {"ok": true, "opens_draw": true,
			"message": Text.say("rhetoric.coupon_used", {"name": name})}

	_take_item(item_id)
	var split := Items.split_grants(item)
	var cause_before := _cause
	_cause = Text.say("record.cause_item", {"item": str(item.get("name_en", ""))})
	var applied := _apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	_cause = cause_before
	var outcome := _describe_grant_outcomes(applied)
	if (split["stage"] as Array).is_empty():
		return {"ok": true, "message": (Text.say("item.used_with_outcome",
			{"name": name, "outcome": outcome}) if not outcome.is_empty()
			else Text.say("item.used", {"name": name})),
			"plain": Text.say("item.used", {"name": name}), "effects": _effect_chips(applied)}

	var level := Items.duration(item) == Items.DURATION_LEVEL
	var lasts := Items.duration_units(item)
	var target := pending_level_bonuses if level else pending_stage_bonuses
	if lasts > 0:
		# A timed item runs from now for that many clock units, whichever
		# stage or level it lands in (take_item_bonuses_for_stage()).
		target = {}
	for effect: Dictionary in _resolve_stage_effects(split["stage"]):
		_add_bonus(target, str(effect["token"]), int(effect["amount"]))
	if lasts > 0:
		timed_bonuses.append({"bonuses": target, "expires_at": time_units + lasts})
	if not outcome.is_empty():
		return {"ok": true, "message": Text.say(
			"item.queued_level_with_outcome" if level else "item.queued_with_outcome",
			{"name": name, "outcome": outcome}),
			"plain": Text.say("item.queued_level" if level else "item.queued", {"name": name}),
			"effects": _effect_chips(applied)}
	return {"ok": true, "message": Text.say(
		"item.queued_level" if level else "item.queued", {"name": name})}


## Uses one item during a stage. Its stage effects land on the battle now
## (BattleEngine.use_item(), which also enforces Uses Per Turn); a level
## buff keeps running for the rest of the level too. Standing effects apply
## now, the same as in the Office. Nothing is taken from the inventory if
## the battle refuses.
##
## `chosen_target` — see use_item_in_office()'s own note; the same
## needs_choice contract applies here.
func use_item_in_stage(item_id: String, engine: BattleEngine, chosen_target: String = "") -> Dictionary:
	var item := DataDB.get_shop_item(item_id)
	var refusal := Items.use_refusal(item, Items.STAGE, item_count(item_id), Text.phrase())
	if not refusal.is_empty():
		return {"ok": false, "message": refusal}
	if Items.is_player_choice(item) and chosen_target.is_empty():
		return {"ok": false, "needs_choice": true}

	var split := Items.split_grants(item)
	var effects := _resolve_stage_effects(split["stage"])
	var result := engine.use_item(item_id, effects, Items.uses_per_turn(item))
	if not result.get("ok", false):
		return {"ok": false, "message": str(result.get("reason", ""))}

	_take_item(item_id)
	var cause_before := _cause
	_cause = Text.say("record.cause_item", {"item": str(item.get("name_en", ""))})
	var applied := _apply_reward_entries(split["meta"], chosen_target, _staff_bonus_total(item))
	_cause = cause_before
	var stage_lasts := Items.duration_units(item)
	if stage_lasts > 0:
		var carried := {}
		for effect: Dictionary in effects:
			_add_bonus(carried, str(effect["token"]), int(effect["amount"]))
		timed_bonuses.append({"bonuses": carried, "expires_at": time_units + stage_lasts})
	elif Items.duration(item) == Items.DURATION_LEVEL:
		for effect: Dictionary in effects:
			_add_bonus(level_bonuses, str(effect["token"]), int(effect["amount"]))
	var name := str(item.get("name", item_id))
	var outcome := _describe_grant_outcomes(applied)
	if not outcome.is_empty():
		return {"ok": true, "message": Text.say("item.used_with_outcome", {"name": name, "outcome": outcome}),
			"plain": Text.say("item.used", {"name": name}), "effects": _effect_chips(applied)}
	return {"ok": true, "message": Text.say("item.used", {"name": name})}


## Everything item-driven the next stage starts with: the level's running
## buffs plus anything used in the Office for "the next stage", which is
## spent by asking. { "ENERGY": 2, ... }.
func take_item_bonuses_for_stage() -> Dictionary:
	var bonuses := level_bonuses.duplicate()
	for token: String in pending_stage_bonuses.keys():
		_add_bonus(bonuses, token, int(pending_stage_bonuses[token]))
	pending_stage_bonuses = {}
	# Timed items still running (the rest are dropped as they run out).
	var still_running: Array = []
	for entry: Variant in timed_bonuses:
		var timed: Dictionary = entry
		if int(timed.get("expires_at", 0)) <= time_units:
			continue
		still_running.append(timed)
		var carried: Dictionary = timed.get("bonuses", {})
		for token: String in carried.keys():
			_add_bonus(bonuses, token, int(carried[token]))
	timed_bonuses = still_running
	return bonuses


func _take_item(item_id: String) -> void:
	var left := item_count(item_id) - 1
	if left > 0:
		inventory[item_id] = left
	else:
		inventory.erase(item_id)


## An item's stage-effect entries as [ { "token", "amount" } ], each pool
## picked and each range rolled once, here, at the moment of use.
func _resolve_stage_effects(entries: Array) -> Array:
	var effects: Array = []
	for raw: Variant in entries:
		if not (raw is Dictionary):
			continue
		var entry := _choose_target(raw, "")
		effects.append({
			"token": str(entry.get("target", "")).to_upper(),
			"amount": _stage_effect_amount(entry.get("delta")),
		})
	return effects


## A stage effect written bare ("ENERGY") means +1 — the natural reading,
## unlike a booster target where a bare ID has no amount to apply.
func _stage_effect_amount(delta: Variant) -> int:
	return 1 if delta == null else _resolve_delta(delta)


func _add_bonus(bonuses: Dictionary, token: String, amount: int) -> void:
	if amount == 0:
		return
	var key := token.to_upper()
	bonuses[key] = int(bonuses.get(key, 0)) + amount


## The sum of an item's Bonus 1/2/3 rows whose named Staff role is hired at
## or above that row's Min Tier — 0 where nobody qualifies. Cameron,
## 2026-09-25: SH01-03 work without the role; having it layers this on top.
func _staff_bonus_total(item: Dictionary) -> int:
	var total := 0
	for row: Dictionary in Items.staff_bonus_rows(item):
		var hired: Dictionary = staff_hired.get(str(row["role"]), {})
		if hired.is_empty():
			continue
		if int(hired.get("tier", -1)) >= int(row["min_tier"]):
			total += int(row["amount"])
	return total


## Every booster standing change goes through here: clamped to
## booster_standing.json's range, and added to what the last level did.
func _apply_booster_delta(booster_id: String, delta: int) -> void:
	if delta == 0:
		return
	var low := int(DataDB.booster_standing.get("min", 0))
	var high := int(DataDB.booster_standing.get("max", 100))
	var before := int(booster_standing.get(booster_id, 50))
	var after := clampi(before + delta, low, high)
	booster_standing[booster_id] = after
	if after != before:
		if not _decaying:
			booster_moved_in_period[booster_id] = true
		last_booster_change[booster_id] = int(last_booster_change.get(booster_id, 0)) + (after - before)
		_note_cause(last_booster_cause, booster_id, after - before)
		_follow_links(booster_id, float(after - before))


## Where the player stands with `party_name`. The player's own party reads
## straight off `meta["Party support"]` — see party_standing's own doc
## comment for why that is the one deliberate exception.
func party_favorability(party_name: String) -> int:
	if party_name == str(DataDB.player.get("party", "")):
		return int(meta.get("Party support", 0))
	return int(party_standing.get(party_name, 50))


## ---------------------------------------------------------------------------
## Party opinion (2026-10-10, Cameron): how each party sees the player. See
## PartyOpinion.gd for the maths. DIRECT is party_favorability() (the Party
## support meta for the player's own party, party_standing for the rest);
## STAKEHOLDER is the weighted standing of the organisations the workbook's
## Party Standing tab ties to that party.
## ---------------------------------------------------------------------------

## The player's own party as a party_id ("" when there is none).
func own_party_id() -> String:
	var own := DataDB.get_party(str(DataDB.player.get("party", "")))
	return str(own.get("party_id", ""))


## Everything the Parties page and the rules need about one party:
## {party_id, name, direct, stakeholder (-1 = none), opinion, band,
## contributions}.
func party_opinion_detail(party_id: String) -> Dictionary:
	var party := {}
	for row: Dictionary in DataDB.parties:
		if str(row.get("party_id", "")) == party_id:
			party = row
	var party_name := str(party.get("name", ""))
	var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, party_id, own_party_id())
	var held := PartyOpinion.stakeholder(rows, booster_standing,
		int(DataDB.booster_standing.get("start", 30)))
	var direct := party_favorability(party_name)
	var score := PartyOpinion.opinion(direct, int(held["score"]), DataDB.balance)
	return {"party_id": party_id, "name": party_name, "direct": direct,
		"stakeholder": int(held["score"]), "opinion": score,
		"band": PartyOpinion.band(score, DataDB.balance),
		"contributions": held["contributions"]}


func party_opinion(party_id: String) -> int:
	return int(party_opinion_detail(party_id)["opinion"])


## What every "Party support" rule reads for the player's own party (Option A,
## Cameron 2026-10-10): the blended opinion, so organisations matter. Stage
## rewards, votes and leans still add to the stored meta number. With no
## player party, or no data for it, this is simply the stored number.
func party_support_effective() -> int:
	var own := own_party_id()
	if own.is_empty():
		return int(meta.get("Party support", 0))
	return party_opinion(own)


## How far the live Party support number (party_support_effective()) moved
## this level, counting both halves: what votes/rewards did to the stored
## number AND what the level did to the organisations tied to the party.
## Works backwards from the current state: the direct number minus its change,
## each organisation's standing minus its own change, then the same blend.
func party_support_change_this_level() -> int:
	var own := own_party_id()
	if own.is_empty():
		return int(last_meta_change.get("Party support", 0))
	var before_standing := booster_standing.duplicate()
	for booster_id: String in last_booster_change.keys():
		before_standing[booster_id] = int(before_standing.get(booster_id, 0)) \
			- int(last_booster_change[booster_id])
	var rows := PartyOpinion.rows_for(DataDB.party_stakeholders, own, own)
	var held := PartyOpinion.stakeholder(rows, before_standing,
		int(DataDB.booster_standing.get("start", 30)))
	var direct_before := int(meta.get("Party support", 0)) - int(last_meta_change.get("Party support", 0))
	return party_support_effective() - PartyOpinion.opinion(direct_before, int(held["score"]), DataDB.balance)


## `meta` with Party support replaced by the effective (blended) number, for
## rules that read the whole dictionary (the Floor Vote influence gate).
func effective_meta() -> Dictionary:
	var copy := meta.duplicate()
	copy["Party support"] = party_support_effective()
	return copy


## Every OTHER party's favorability change goes through here: clamped to
## party_standing.json's range, added to what the last vote did. The
## player's own party is routed through _move_meta() instead (the ordinary
## "Party support" path every other stage already uses), never through
## here — see party_favorability().
func _apply_party_delta(party_name: String, delta: int) -> void:
	if delta == 0 or party_name == str(DataDB.player.get("party", "")):
		return
	var low := int(DataDB.party_standing.get("min", 0))
	var high := int(DataDB.party_standing.get("max", 100))
	var before := int(party_standing.get(party_name, 50))
	var after := clampi(before + delta, low, high)
	party_standing[party_name] = after
	if after != before:
		last_party_change[party_name] = int(last_party_change.get(party_name, 0)) + (after - before)


## Applies what a Floor Vote (ST23) did to every party's favorability —
## { party_name: delta, ... }, straight from FloorVoteEngine.choose()'s own
## "favorability_deltas". The player's own party's share lands on "Party
## support" the same way any other stage's win_delta_party_support does;
## everything else lands on party_standing.
func apply_floor_vote_favorability(deltas: Dictionary, cause: String = "") -> void:
	_cause = cause
	var own_party := str(DataDB.player.get("party", ""))
	for party_name: String in deltas:
		var delta := int(deltas[party_name])
		if party_name == own_party:
			_apply_meta_reward("Party support", delta)
		else:
			_apply_party_delta(party_name, delta)
	_cause = ""


## The Floor Vote influence swing's own bonus (2026-09-28, §7.7): a bill's
## optional "Influence Bonus (Reputation)"/"Influence Bonus (Party support)"
## columns, applied only when the swing actually flipped that bill's own
## pass/fail outcome. Both blank read as 0, same as every other delta column
## — a no-op call is fine and expected for the common case of no bonus set.
func apply_floor_vote_influence_bonus(reputation_delta: int, party_support_delta: int,
		cause: String = "") -> void:
	_cause = cause
	_apply_meta_reward("Reputation", reputation_delta)
	_apply_meta_reward("Party support", party_support_delta)
	_cause = ""


## M48-style backing (PARTY_BILL_FLIP_BONUS): when the player's influence
## turns a bill their own party backs from failing to passing, an owned
## backing whose organization still holds pays its Party support. Returns the
## amount paid (0 when nothing applies).
func apply_flip_backing(bill: Dictionary, result: Dictionary) -> int:
	if not bool(result.get("outcome_flipped_by_influence", false)) or not bool(result.get("passed", false)):
		return 0
	var own := own_party_id()
	var backed := false
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own and str(position.get("disposition", "")) == "Supportive":
			backed = true
	if not backed:
		return 0
	var total := 0
	for modifier: Dictionary in _effectively_owned_modifiers():
		if ModifierEffects.type_of(modifier) == ModifierEffects.PARTY_BILL_FLIP_BONUS \
				and MetaRules.booster_trigger_met(modifier, booster_standing):
			total += int(round(ModifierEffects.value_of(modifier)))
	if total != 0:
		_cause = Text.say("record.cause_flip_backing", {"bill": str(bill.get("bill_name", ""))})
		_apply_meta_reward("Party support", total)
		_cause = ""
	return total


## Every bill_id the influence swing has flipped (§7.7), in the order they
## happened. A bill can only be voted once — every real Floor Vote level is
## One-Time (§8) — so this never needs deduplicating in practice, but
## guarded anyway, the same caution FloorVoteEngine._reallocate_player_
## vote() already takes for its own single-seat move.
func record_bill_flip(bill_id: String) -> void:
	if bill_id.is_empty() or bills_flipped_by_influence.has(bill_id):
		return
	bills_flipped_by_influence.append(bill_id)


## Writes one Floor Vote into the statute book and applies that bill's
## "once" Law Effects for how it went (passed or failed). A bill already in
## the book is ignored, so a replayed screen can never apply it twice.
## Called from FloorVoteScreen._on_vote() (and the playtest bot).
func record_floor_vote(bill: Dictionary, result: Dictionary, choice: String) -> void:
	last_patron_outcome = {}
	var bill_id := str(bill.get("bill_id", ""))
	if bill_id.is_empty() or StatuteBook.has_bill(statute_book, bill_id):
		return
	var level_id := ""
	if level_runner != null:
		level_id = str(level_runner.level.get("level_id", ""))
	var law := StatuteBook.entry(bill, result, choice, level_id, levels_completed_count)
	statute_book.append(law)
	_apply_law_effect_rows(StatuteBook.effects_for(
		DataDB.law_effects, bill_id, bool(law["passed"]), StatuteBook.ONCE))
	_apply_party_tier_lean(bill_id, bool(law["passed"]))
	if patron_requests.has(bill_id):
		_resolve_patron_vote(bill_id, bool(law["passed"]))


## Party-tier organisations (Party Headquarters, Party Faction) answer to
## where the player's own party stood on the bill, not to a fixed row, so
## each protagonist's party sees a bill differently. Sizes come from the
## Balance tab (law_lean_party_tier_pass_delta / law_lean_party_tier_fail_delta).
func _lean_multiplier(booster: Dictionary) -> float:
	var raw: Variant = booster.get("party_lean_multiplier")
	return 1.0 if raw == null else float(raw)


func _apply_party_tier_lean(bill_id: String, passed: bool) -> void:
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var own := own_party_id()
	var disposition := ""
	var scale := 1.0
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own:
			disposition = str(position.get("disposition", ""))
			scale = BattleSetup.salience_factor(position)
	var delta := StatuteBook.party_tier_delta(disposition, passed,
		PartySalience.scaled(int(DataDB.balance.get("law_lean_party_tier_pass_delta", 0)), scale),
		PartySalience.scaled(int(DataDB.balance.get("law_lean_party_tier_fail_delta", 0)), scale))
	if delta == 0:
		return
	for booster: Dictionary in DataDB.boosters:
		if str(booster.get("tier", "")) == "Party":
			var party_body := str(booster.get("booster_id", ""))
			# Each Party Body reacts at its own strength (Boosters tab, Party
			# Lean Multiplier; blank = 1.0).
			var own_delta := PartySalience.scaled(delta, _lean_multiplier(booster))
			_under_cause(Text.say("record.cause_party_lean", {"bill": str(bill.get("bill_name", ""))}),
				func() -> void: _apply_booster_delta(party_body, own_delta))


# ---------------------------------------------------------------------------
# A bill level's stance (BillStance, 2026-10-18)
# ---------------------------------------------------------------------------

## The Floor Vote bill the level in progress votes on ({} when it has none).
func level_bill() -> Dictionary:
	if level_runner == null:
		return {}
	return DataDB.get_floor_vote(str(level_runner.level.get("level_id", "")))


## Records the lean picked on the Level Intro screen. Ignored for a bill with
## nobody on either side to hear it.
func set_bill_lean(bill_id: String, lean: String) -> void:
	if bill_id.is_empty() or not BillStance.is_lean(lean):
		return
	bill_stance = {"bill_id": bill_id, "lean": lean, "cost": {}, "voted": false}


func stance_lean() -> String:
	return str(bill_stance.get("lean", ""))


## { "supporters": [...], "opponents": [...] } for the stance's bill. Party
## Bodies are left out: they follow your party, not the bill's Law Effects.
func stance_sides() -> Dictionary:
	if bill_stance.is_empty():
		return {"supporters": [], "opponents": []}
	var bill: Dictionary = DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {})
	return BillStance.sides(bill, DataDB.law_effects, _party_tier_booster_ids())


func _party_tier_booster_ids() -> Array:
	var ids: Array = []
	for booster: Dictionary in DataDB.boosters:
		if str(booster.get("tier", "")) == "Party":
			ids.append(str(booster.get("booster_id", "")))
	return ids


## The Balance numbers BillStance.vote() reads.
func stance_config() -> Dictionary:
	var balance := DataDB.balance
	return {
		"vote_delta": int(balance.get("stance_vote_delta", 0)),
		"abandoned_penalty": int(balance.get("stance_flip_abandoned_penalty", balance.get("stance_vote_delta", 0))),
		"recovery_percent": int(balance.get("stance_flip_recovery_percent", 0)),
		"party_away": int(balance.get("stance_flip_party_support_away", 0)),
		"party_toward": int(balance.get("stance_flip_party_support_toward", 0)),
	}


## A stage's booster tally with the rhetoric rule applied: answers that would
## please an organization on the side against your lean count for less. A copy;
## the same tally the Outcome panel and the preview read.
## The organisations whose backing the player owns (each owned modifier's
## trigger organisations). Their tastes in rhetoric show on the battle screen.
func backed_booster_ids() -> Array[String]:
	var out: Array[String] = []
	for mod_id: String in owned_modifiers:
		for booster_id: String in (DataDB.get_modifier(mod_id).get("trigger_booster_ids", []) as Array):
			if not out.has(booster_id):
				out.append(booster_id)
	return out


func stance_adjust_tally(tally: Dictionary) -> Dictionary:
	var lean := stance_lean()
	if lean.is_empty() or tally.is_empty():
		return tally
	return BillStance.adjust_tally(tally, BillStance.other_side(stance_sides(), lean),
		int(DataDB.balance.get("stance_other_side_please_percent", 100)))


func _stance_bill_name() -> String:
	return str(DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {}).get("bill_name", ""))


## Winning a Combat stage in a bill level: the side against your lean loses,
## your own side gains. What the far side lost is remembered, because a switch
## at the vote can win a quarter of it back.
func _apply_stance_win_drift() -> void:
	var lean := stance_lean()
	if lean.is_empty():
		return
	var drift := BillStance.win_drift(stance_sides(), lean, int(DataDB.balance.get("stance_win_drift", 0)))
	var cost: Dictionary = bill_stance.get("cost", {})
	for id: String in drift:
		var delta := int(drift[id])
		_under_cause(Text.say("record.cause_stance_drift", {"bill": _stance_bill_name()}),
			func() -> void: _apply_booster_delta(id, delta))
		if delta < 0:
			cost[id] = int(cost.get(id, 0)) - delta
	bill_stance["cost"] = cost


## Your own vote on the stance's bill: moves its supporters and opponents, and
## prices a switch (the side you leave loses more, the side you join wins a
## little back, Party support moves). Returns BillStance.vote()'s result, or {}
## when there is no stance or it was already applied.
func apply_stance_vote(choice: String) -> Dictionary:
	if bill_stance.is_empty() or bool(bill_stance.get("voted", false)):
		return {}
	bill_stance["voted"] = true
	var result := preview_stance_vote(choice)
	var bill: Dictionary = DataDB.floor_votes.get(str(bill_stance.get("bill_id", "")), {})
	var vote_cause := Text.say("record.cause_stance_switch" if bool(result.get("flip", false))
		else "record.cause_stance_vote", {"bill": str(bill.get("bill_name", ""))})
	for id: String in (result["deltas"] as Dictionary):
		var moved := int((result["deltas"] as Dictionary)[id])
		_under_cause(vote_cause, func() -> void: _apply_booster_delta(id, moved))
	var party_delta := int(result["party_delta"])
	if party_delta != 0:
		apply_floor_vote_favorability({str(DataDB.player.get("party", "")): party_delta},
			Text.say("record.cause_stance_switch", {"bill": str(bill.get("bill_name", ""))}))
	return result


## What voting `choice` would do under the current stance, without doing it
## (the vote screen's preview and apply_stance_vote() share this). { } with no
## stance.
func preview_stance_vote(choice: String) -> Dictionary:
	if bill_stance.is_empty():
		return {}
	var bill_id := str(bill_stance.get("bill_id", ""))
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var own := own_party_id()
	var disposition := ""
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) == own:
			disposition = str(position.get("disposition", ""))
	var result := BillStance.vote(stance_sides(), stance_lean(), choice,
		bill_stance.get("cost", {}), disposition, stance_config())
	result["bill_id"] = bill_id
	return result


## What winning a Combat stage would do to the stance's stakeholders, for the
## Outcome panel. { } with no stance.
func stance_drift_preview() -> Dictionary:
	var lean := stance_lean()
	if lean.is_empty():
		return {}
	return BillStance.win_drift(stance_sides(), lean, int(DataDB.balance.get("stance_win_drift", 0)))


## bill_id -> "passed"/"failed", for Office Notices and the Ticker.
func law_statuses() -> Dictionary:
	return StatuteBook.status_map(statute_book)


## Applies Law Effects rows: their Effects cell through the same reward path
## shop items and visitors use (boosters, segments, modifiers, items), and
## their meta and XP columns as rewards, so Your Record shows the change.
func _apply_law_effect_rows(rows: Array) -> void:
	for row: Dictionary in rows:
		var effects: Variant = row.get("effects")
		if effects is Array:
			_apply_reward_entries(effects)
		var deltas := StatuteBook.meta_deltas(row)
		var bill_id := str(row.get("bill_id", ""))
		_cause = Text.say("record.cause_law", {"bill": str(
			DataDB.floor_votes.get(bill_id, {}).get("bill_name", bill_id))})
		for name: String in deltas:
			_apply_meta_reward(name, int(deltas[name]))
		_cause = ""
		_move_xp(StatuteBook.xp_delta(row))


## Every segment favorability change goes through here, clamped 0-100
## (segments.json carries no range of its own).
func _apply_segment_delta(segment_id: String, delta: int) -> void:
	if delta == 0:
		return
	var before := int(segment_favorability.get(segment_id, 50))
	var after := clampi(before + delta, 0, 100)
	segment_favorability[segment_id] = after
	if after != before:
		last_segment_change[segment_id] = int(last_segment_change.get(segment_id, 0)) + (after - before)


## A target_delta_list entry's delta, resolved to a real number: null is no
## magnitude (0), a plain number passes through, and a {"min","max"} range is
## rolled — unseeded, the same as every other range roll in the game
## (_roll_range() itself, BattleSetup._opponent_count()).
func _resolve_delta(delta: Variant) -> int:
	if delta is Dictionary and (delta as Dictionary).has("min"):
		return _roll_range(delta)
	if delta == null:
		return 0
	return int(delta)


## Clears the level, on the way back to the Office.
func end_level() -> void:
	level_runner = null
	patron_runtime = {}
	bill_assist = BillAssist.empty()
	bill_stance = {}
	# Level buffs belong to the level; nothing else here to clear, since
	# finish_stage() already reset the purchase counts when it concluded.
	level_bonuses = {}


## Throws away a level in progress without recording a win, a loss, or a
## completion of any kind — the level goes right back to being just another
## choice in the Levels panel, not shown-locked like a cooldown and not
## hidden like a finished One-Time level, since neither
## level_last_completed_at nor levels_completed_count are touched here.
##
## Whatever the player already banked from stages they actually finished
## earlier in this same attempt stays banked — finish_stage() already
## applied those rewards and saved the game at the time. Only the stage
## still ahead of them, and this attempt's own per-level purchase limits,
## are thrown away; picking the level again starts it over from stage one.
##
## The only real caller is the Office's own "a level was in progress"
## choice (OfficeScreen._show_resume_choice_if_in_level()), reached only
## when the app was closed and reopened mid-level — normal play never
## returns to the Office until a level actually concludes, so this can
## never fire mid-stage by accident.
func abandon_level() -> void:
	if not patron_runtime.is_empty():
		# An abandoned patron level leaves the request open to accept again.
		var abandoned := str(patron_runtime.get("patron_bill_id", ""))
		if patron_requests.has(abandoned) and patron_requests[abandoned]["status"] == PatronRequests.ACCEPTED:
			# A drafted bill cannot be offered again: its cost is spent.
			patron_requests[abandoned]["status"] = PatronRequests.LAPSED if patron_drafts.has(abandoned) else PatronRequests.OPEN
		patron_runtime = {}
	bill_assist = BillAssist.empty()
	level_runner = null
	bill_stance = {}
	level_bonuses = {}
	shop_bought_this_level = {}


func _conclude_level_items() -> void:
	shop_bought_this_level = {}
	level_bonuses = {}


# ---------------------------------------------------------------------------
# Patron Bills (2026-10-19)
# ---------------------------------------------------------------------------

## Patron bills that are due now: standing high enough, not yet asked, a
## Flagship only after its organization's Favor is resolved. Step 4's Requests
## block reads this; it moves nothing.
func patron_bills_due() -> Array:
	var statuses := {}
	for id: String in patron_requests:
		statuses[id] = str((patron_requests[id] as Dictionary).get("status", ""))
	return PatronRequests.due(DataDB.patron_bills, booster_standing, statuses, DataDB.balance)


## Starts the countdown for every request that has just become due (idempotent).
func arm_patron_requests() -> void:
	for id: String in patron_bills_due():
		if not patron_armed.has(id):
			patron_armed[id] = time_units


## The requests the Requests block shows right now, oldest first: those whose
## countdown has run out, plus any returned to the queue, up to
## `patron_requests_waiting_at_once`. Requests that cannot be composed (every
## alternative already law) are left out. Moves nothing but the countdown.
func patron_requests_shown() -> Array:
	arm_patron_requests()
	var delay := int(DataDB.balance.get("special_level_delay", 5))
	var candidates: Array = []
	for id: String in patron_armed:
		var status := str((patron_requests.get(id, {}) as Dictionary).get("status", ""))
		var ready: bool = status == "" and time_units - int(patron_armed[id]) >= delay
		if ready or status == PatronRequests.WAITING or status == PatronRequests.OPEN:
			candidates.append(id)
	candidates.sort_custom(func(a: String, b: String) -> bool:
		return int(patron_armed[a]) < int(patron_armed[b]) or (int(patron_armed[a]) == int(patron_armed[b]) and a < b))
	var out: Array = []
	var cap := int(DataDB.balance.get("patron_requests_waiting_at_once", 2))
	for id: String in candidates:
		if out.size() >= cap:
			break
		if bool(PatronLevel.compose(id, enacted_components)["ok"]):
			out.append(id)
	return out


## Accepts a patron bill (optionally amended) and starts its level. Returns
## false, changing nothing, when a level is already running or the bill cannot
## be composed. `replace`/`with_id` are an Amend swap, both blank for none.
func start_patron_level(patron_bill_id: String, replace: String = "", with_id: String = "") -> bool:
	if is_in_level():
		return false
	var current := str((patron_requests.get(patron_bill_id, {}) as Dictionary).get("status", ""))
	if current in [PatronRequests.PASSED, PatronRequests.FAILED, PatronRequests.DECLINED, PatronRequests.LAPSED]:
		return false
	var built := PatronLevel.register(patron_bill_id, enacted_components, replace, with_id)
	if not built["ok"]:
		return false
	var tries := int((patron_requests.get(patron_bill_id, {}) as Dictionary).get("tries", 0))
	patron_requests[patron_bill_id] = {
		"status": PatronRequests.ACCEPTED, "components": built["component_ids"],
		"amended": built["amended"], "tries": tries,
	}
	patron_composed[patron_bill_id] = {"bill": built["bill"], "component_ids": built["component_ids"]}
	patron_runtime = {"patron_bill_id": patron_bill_id, "level": built["level"]}
	var runner := LevelRunner.new(BattleSetup.expand_level(built["level"] as Dictionary))
	begin_level(runner)
	SaveManager.autosave(true)
	return true


## Declines a request: the organization's standing drops and the request is
## gone for the run.
func decline_patron_bill(patron_bill_id: String) -> void:
	var row := PatronLevel.patron_bill(patron_bill_id)
	if row.is_empty():
		return
	for entry: Dictionary in PatronRequests.decline_deltas(row, DataDB.balance):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))
	patron_requests[patron_bill_id] = {"status": PatronRequests.DECLINED, "components": [], "amended": false, "tries": 0}
	SaveManager.autosave(true)


## The vote on a patron bill has happened: standing moves for the patron, the
## ally and the organizations the bill hurts, the components' own effects
## apply, and a passed bill's components become law.
func _resolve_patron_vote(patron_bill_id: String, passed: bool) -> void:
	var state: Dictionary = patron_requests[patron_bill_id]
	var row := PatronLevel.patron_bill(patron_bill_id)
	var bill: Dictionary = (patron_composed.get(patron_bill_id, {}) as Dictionary).get("bill", {})
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var org := str(row.get("organization", ""))
	var effects: Array = bill.get("effects", []) as Array
	var rivals := PatronRequests.rivals_of(effects, org, ally)
	var outcome := PatronRequests.outcome(row, ally, rivals, passed, bool(state.get("amended", false)), DataDB.balance)
	for entry: Dictionary in (outcome["standing"] as Array):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))
	# What the vote did, for the result pop-up. Not saved: it is only read
	# right after the vote, on the same screen.
	last_patron_outcome = {"patron_bill_id": patron_bill_id, "passed": passed,
		"standing": (outcome["standing"] as Array).duplicate(true),
		"backing_org": org if passed and int(outcome["free_backing_units"]) > 0 else "",
		"components": (state.get("components", []) as Array).duplicate()}
	if passed:
		_apply_reward_entries(effects)
		for component_id: Variant in (state.get("components", []) as Array):
			if not enacted_components.has(component_id):
				enacted_components.append(component_id)
		_grant_free_backing(org, int(outcome["free_backing_units"]))
	state["status"] = PatronRequests.PASSED if passed else PatronRequests.FAILED
	patron_requests[patron_bill_id] = state
	# What the special stages did for (or against) this vote becomes a news
	# story the Office ticker runs for a while, then the record is spent.
	if BillAssist.total(bill_assist, "won_over") > 0:
		record_news("visit_success")
	if BillAssist.total(bill_assist, "worked_against") > 0:
		record_news("lobbyist_work")
	bill_assist = BillAssist.empty()


## Why a bill of `ids` cannot be drafted now ("" when it can).
func draft_refusal(ids: Array) -> String:
	return DraftBill.refusal(ids, {"enacted": enacted_components, "xp": xp, "funds": int(meta.get("Funds", 0)),
		"time_units": time_units, "last_draft_at": last_draft_at, "in_level": is_in_level()})


## Drafts a bill from `ids`: pays the cost, files it as a runtime patron row
## and starts its level. False (nothing paid) when it cannot be drafted.
func start_draft(ids: Array) -> bool:
	if not draft_refusal(ids).is_empty():
		return false
	var draft_id := DraftBill.id_for(draft_counter + 1)
	patron_drafts[draft_id] = DraftBill.row_for(draft_id, ids)
	if not start_patron_level(draft_id):
		patron_drafts.erase(draft_id)
		return false
	draft_counter += 1
	last_draft_at = time_units
	_move_xp(-int(DataDB.balance.get("draft_bill_cost_xp", 350)))
	_move_meta("Funds", -int(DataDB.balance.get("draft_bill_cost_funds", 300000)))
	return true


## A passed Flagship gives the patron's backing for free for a while, using the
## same clock-expiry machinery as a timed backing.
func _grant_free_backing(org: String, units: int) -> void:
	if units <= 0:
		return
	for mod_id: Variant in (DataDB.get_booster(org).get("linked_modifiers", []) as Array):
		var id := str(mod_id)
		if owned_modifiers.has(id):
			continue
		owned_modifiers.append(id)
		modifier_expires[id] = time_units + units


## A patron level ended. If the vote never happened (a stage lost ended the
## level first) the request returns once; a second time it lapses.
func _conclude_patron_level() -> void:
	var patron_bill_id := str(patron_runtime.get("patron_bill_id", ""))
	patron_runtime = {}
	if not patron_requests.has(patron_bill_id):
		return
	var state: Dictionary = patron_requests[patron_bill_id]
	if state["status"] != PatronRequests.ACCEPTED:
		return
	if patron_drafts.has(patron_bill_id):
		# A drafted bill that never reached its vote is lost; no organization is owed anything.
		state["status"] = PatronRequests.LAPSED
		patron_requests[patron_bill_id] = state
		return
	state["tries"] = int(state.get("tries", 0)) + 1
	if int(state["tries"]) >= 2:
		state["status"] = PatronRequests.LAPSED
		_apply_booster_delta(str(PatronLevel.patron_bill(patron_bill_id).get("organization", "")),
				-int(DataDB.balance.get("patron_fail_standing", 2)))
	else:
		state["status"] = PatronRequests.WAITING
	patron_requests[patron_bill_id] = state


## Re-files every composed bill (and the level in progress) with DataDB after a
## load, so the statute book can name them and a resumed level finds its bill.
func _register_saved_patron_bills() -> void:
	DataDB.clear_runtime()
	for patron_bill_id: String in patron_composed:
		var entry: Dictionary = patron_composed[patron_bill_id]
		DataDB.register_runtime_bill(entry.get("bill", {}) as Dictionary, entry.get("component_ids", []) as Array)
	var level: Variant = patron_runtime.get("level")
	if level is Dictionary:
		DataDB.register_runtime_level(level as Dictionary)


## A story about the player's sponsored legislation starts running on the
## Office ticker for `news_ticker_units` clock units.
func record_news(key: String) -> void:
	patron_news[key] = time_units + int(DataDB.balance.get("news_ticker_units", 12))


## The stories still running (expired ones are dropped).
func active_news() -> Array:
	for key: String in patron_news.keys():
		if int(patron_news[key]) <= time_units:
			patron_news.erase(key)
	return patron_news.keys()


## What ticker rows and Office notices test their conditions against: the
## laws on the books, plus "news:<key>" for each story running.
func ticker_facts() -> Dictionary:
	var facts := law_statuses()
	for key: Variant in active_news():
		facts["news:%s" % str(key)] = "active"
	return facts


## Seats a visit or a lobbyist adds to or takes from the vote (BillAssist).
func add_won_over(party_id: String, seats: int = 1) -> void:
	BillAssist.add(bill_assist, "won_over", party_id, seats)


func add_worked_against(party_id: String, seats: int = 1) -> void:
	BillAssist.add(bill_assist, "worked_against", party_id, seats)


## The visit in progress, or {} (the dictionary is the level's own, so changes
## to it are saved with the patron level).
func current_visit() -> Dictionary:
	var level: Variant = patron_runtime.get("level")
	if level is Dictionary and (level as Dictionary).get("visit") is Dictionary:
		return (level as Dictionary)["visit"]
	return {}


## The one-on-one fight was won: the member is won over for this vote.
func _won_over_member() -> void:
	var visit := current_visit()
	if visit.is_empty() or bool(visit.get("won", false)):
		return
	visit["won"] = true
	add_won_over(str(visit.get("party_id", "")), int(DataDB.balance.get("mp_visit_seats_won", 1)))


## The player declined the visit: both of its stages pass with nothing earned
## (no rewards, no fight, no cost, no time).
func skip_member_visit() -> void:
	if level_runner == null or str(level_runner.current_stage().get("stage_id", "")) != MpVisit.VISIT_STAGE:
		return
	level_runner.finish_stage(LevelRunner.WON)
	if str(level_runner.current_stage().get("stage_id", "")) == MpVisit.FIGHT_STAGE:
		level_runner.finish_stage(LevelRunner.WON)
	SaveManager.autosave(true)


# ---------------------------------------------------------------------------
# The lobbyist trade (influence building step C, 2026-10-19)
# ---------------------------------------------------------------------------

## The trade in progress, or {} (the level's own dictionary, so changes are saved).
func current_trade() -> Dictionary:
	var level: Variant = patron_runtime.get("level")
	if level is Dictionary and (level as Dictionary).get("trade") is Dictionary:
		return (level as Dictionary)["trade"]
	return {}


func _patron_kind() -> String:
	return str(PatronLevel.patron_bill(str(patron_runtime.get("patron_bill_id", ""))).get("kind", PatronRequests.FAVOR))


## The bill's party positions as they stand now (the trade may have recomposed it).
func _bill_positions() -> Array:
	return DataDB.get_bill(str(patron_runtime.get("patron_bill_id", ""))).get("positions", []) as Array


## The player met the lobbyist (or refused to) and no deal was made: on a
## Flagship the lobbyists take seats from the bill (BillAssist worked_against),
## fewer for meeting than for refusing; on a Favor, none by default. Returns
## {"seats", "party_id"}.
func conclude_trade_without_deal(refused: bool) -> Dictionary:
	var trade := current_trade()
	if trade.is_empty() or bool(trade.get("done", false)):
		return {"seats": 0, "party_id": ""}
	trade["done"] = true
	trade["deal"] = false
	var seats := LobbyistTrade.seats_lost(_patron_kind(), refused, DataDB.balance)
	var party_id := LobbyistTrade.party_for_org(str(trade.get("org", "")), DataDB.party_stakeholders, _bill_positions())
	if seats > 0 and not party_id.is_empty():
		add_worked_against(party_id, seats)
	else:
		seats = 0
	return {"seats": seats, "party_id": party_id}


## A deal: `dropped_id` leaves the bill, and the chosen `rewards` (LobbyistTrade
## DONATION, SENTIMENT, PARTY_FAVOR, HELP) are paid, if `leverage` covers them.
## The bill is recomposed without the component and the vote stage is updated.
## Returns {"ok", "gains": [{...}]}; ok is false (nothing changes) when the
## deal is not allowed.
func conclude_trade_deal(dropped_id: String, rewards: Array, leverage: int) -> Dictionary:
	var trade := current_trade()
	var patron_bill_id := str(patron_runtime.get("patron_bill_id", ""))
	if trade.is_empty() or bool(trade.get("done", false)) or not patron_requests.has(patron_bill_id):
		return {"ok": false, "gains": []}
	var state: Dictionary = patron_requests[patron_bill_id]
	var ids: Array = (state.get("components", []) as Array).duplicate()
	if not (trade.get("drops", []) as Array).has(dropped_id) or not ids.has(dropped_id) \
			or not LobbyistTrade.can_close(rewards, leverage, DataDB.balance):
		return {"ok": false, "gains": []}

	var row := PatronLevel.patron_bill(patron_bill_id)
	var org := str(trade.get("org", ""))
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var by_id := ComposedBill.index(DataDB.bill_components)
	var dropped_owner := str((by_id.get(dropped_id, {}) as Dictionary).get("owner", ""))
	var phrase := str((by_id.get(dropped_id, {}) as Dictionary).get("phrase", ""))

	# The party each reward works on is chosen against the bill as it stands.
	var ties := DataDB.party_stakeholders
	var positions := _bill_positions()
	var help_party := LobbyistTrade.party_for_help(org, ties, positions)
	var favor_party_id := LobbyistTrade.party_for_org(org, ties, positions)
	if favor_party_id.is_empty():
		favor_party_id = help_party

	ids.erase(dropped_id)
	var bill := PatronLevel.compose_ids(patron_bill_id, ids)
	DataDB.register_runtime_bill(bill, ids)
	patron_composed[patron_bill_id] = {"bill": bill, "component_ids": ids}
	state["components"] = ids
	patron_requests[patron_bill_id] = state
	_refresh_vote_stage(patron_bill_id)

	for entry: Dictionary in LobbyistTrade.drop_costs(dropped_owner, str(row.get("organization", "")), ally, DataDB.balance):
		_apply_booster_delta(str(entry["target"]), int(entry["delta"]))

	var gains: Array = []
	for reward: Variant in rewards:
		match str(reward):
			LobbyistTrade.DONATION:
				var funds := int(DataDB.balance.get("trade_donation_funds", 10000))
				var xp_gain := int(DataDB.balance.get("trade_donation_xp", 20))
				_apply_meta_reward("Funds", funds)
				_move_xp(xp_gain)
				gains.append({"type": LobbyistTrade.DONATION, "funds": funds, "xp": xp_gain})
			LobbyistTrade.SENTIMENT:
				_apply_booster_delta(org, int(DataDB.balance.get("trade_sentiment_standing", 5)))
				gains.append({"type": LobbyistTrade.SENTIMENT, "org": org})
			LobbyistTrade.PARTY_FAVOR:
				var party := DataDB.get_party_by_id(favor_party_id)
				if not party.is_empty():
					apply_floor_vote_favorability({str(party.get("name", "")): int(DataDB.balance.get("trade_party_favor", 3))})
					gains.append({"type": LobbyistTrade.PARTY_FAVOR, "party": str(party.get("name", ""))})
			LobbyistTrade.HELP:
				var seats := int(DataDB.balance.get("trade_help_seats", 1))
				if not help_party.is_empty():
					add_won_over(help_party, seats)
					gains.append({"type": LobbyistTrade.HELP, "count": seats})
	trade["done"] = true
	trade["deal"] = true
	return {"ok": true, "gains": gains, "dropped": phrase}


## The vote stage was built when the level began; after a trade it must carry
## the recomposed bill.
func _refresh_vote_stage(patron_bill_id: String) -> void:
	if level_runner == null:
		return
	for stage: Dictionary in level_runner.stages:
		if str(stage.get("mode", "")) == "Vote":
			stage["floor_vote"] = BattleSetup.enriched_floor_vote(DataDB.get_bill(patron_bill_id))
