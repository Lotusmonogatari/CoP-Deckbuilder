extends GutTest
## What the battle screen announces on the noticeboard.
##
## These are the seams sound, text cues and reacting portraits are built on,
## and a seam that fires at the wrong time is worse than one that does not
## fire at all: it is wired, it looks finished, and it misbehaves only once
## somebody hangs something off it.
##
## The screen is instantiated for real rather than mocked. It runs standalone
## when no level is in progress, falling back to the module and step in its
## inspector, which is exactly what this needs.

var _screen: Control
var _gaffes: Array[Dictionary] = []
var _cards: Array[Dictionary] = []


func before_each() -> void:
	_gaffes = []
	_cards = []

	EventBus.gaffe_changed.connect(_note_gaffe)
	EventBus.card_played.connect(_note_card)

	_screen = preload("res://scenes/battle/BattleScreen.tscn").instantiate()
	add_child_autofree(_screen)
	await wait_frames(2)


func after_each() -> void:
	EventBus.gaffe_changed.disconnect(_note_gaffe)
	EventBus.card_played.disconnect(_note_card)


func _note_gaffe(value: int, delta: int, limit: int, final: bool) -> void:
	_gaffes.append({"value": value, "delta": delta, "limit": limit, "final": final})


func _note_card(card_id: String, result: Dictionary) -> void:
	_cards.append({"card_id": card_id, "result": result})


# ---------------------------------------------------------------------------
# The gaffe meter
# ---------------------------------------------------------------------------

func test_a_redraw_that_changed_nothing_says_nothing() -> void:
	# THE BUG THIS IS FOR. This used to be announced on every refresh — every
	# card played, every turn ended, every stage opened — so the first gaffe
	# sound added would have gone off several times a turn, including on
	# turns where nobody made a mistake.
	_gaffes = []
	_screen._refresh()
	_screen._refresh()
	_screen._refresh()

	assert_eq(_gaffes.size(), 0,
		"the meter did not move, so nothing should have been announced")


func test_a_gaffe_earned_is_announced_going_up() -> void:
	_gaffes = []
	_screen.engine.state.gaffe += 2
	_screen._refresh()

	assert_eq(_gaffes.size(), 1, "one announcement for one change")
	assert_eq(_gaffes[0]["value"], 2, "where the meter is now")
	assert_eq(_gaffes[0]["delta"], 2, "and which way it went")


func test_a_gaffe_cleared_is_announced_going_down() -> void:
	# Without the direction, "the meter is at 1" reads the same whether you
	# just made a mistake or just undid one, and a warning sound would play
	# for both.
	_screen.engine.state.gaffe = 3
	_screen._refresh()

	_gaffes = []
	_screen.engine.state.gaffe = 1
	_screen._refresh()

	assert_eq(_gaffes.size(), 1)
	assert_eq(_gaffes[0]["value"], 1)
	assert_lt(_gaffes[0]["delta"], 0, "clearing a gaffe is not the same as earning one")


func test_the_warning_turning_on_is_worth_announcing() -> void:
	# Even at the same count: one more gaffe now ends the stage, and that is
	# news whether or not the number beside it moved.
	var state: BattleState = _screen.engine.state
	state.gaffe = state.gaffe_limit - 1
	_screen._refresh()

	var last: Dictionary = _gaffes[-1]
	assert_true(last["final"], "one from the limit is the final warning")


# ---------------------------------------------------------------------------
# Playing a card
# ---------------------------------------------------------------------------

func test_what_a_card_did_reaches_the_noticeboard() -> void:
	var card_id := str(_screen.engine.state.hand[0])
	_screen._selected_card_id = card_id
	_screen._play_selected()

	assert_eq(_cards.size(), 1, "one card played, one announcement")
	assert_eq(_cards[0]["card_id"], card_id)


func test_the_announcement_says_whether_the_room_cared() -> void:
	# `does_nothing` is never in what the engine's play_card() hands back —
	# only preview() works it out — so anything reading it off the result got
	# false every time and could never tell a card that landed from one the
	# room ignores. The screen puts it in.
	var card_id := str(_screen.engine.state.hand[0])
	_screen._selected_card_id = card_id
	_screen._play_selected()

	var result: Dictionary = _cards[0]["result"]
	assert_true(result.has("does_nothing"),
		"the payload has to carry it, or nothing downstream can ask")
	assert_typeof(result["does_nothing"], TYPE_BOOL)


func test_the_opening_intent_is_announced() -> void:
	# The first intent of a stage — the one the player reads before playing
	# anything — used to be left out, because only end_turn announced it.
	var seen: Array[Dictionary] = []
	var note := func(intent: Dictionary) -> void: seen.append(intent)
	EventBus.intent_revealed.connect(note)

	var fresh: Control = preload("res://scenes/battle/BattleScreen.tscn").instantiate()
	add_child_autofree(fresh)
	await wait_frames(2)

	EventBus.intent_revealed.disconnect(note)
	assert_gt(seen.size(), 0, "a stage should open by saying what is coming")
