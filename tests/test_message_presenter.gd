extends GutTest
## The notices the battle screen shows in passing.
##
## THIS IS THE ONE THAT MUST NOT REGRESS. The old code set the label, waited
## two and a half seconds, and hid it unconditionally. Playing a card and then
## ending the turn — every turn of every stage — started two timers, and the
## first one blanked the second one's message. The player read half of what
## happened and had no way of knowing there had been more.
##
## The tests below wind the dwell right down so the suite does not spend ten
## seconds watching a label. The logic under test is the same at any speed:
## what matters is the ORDER of the timers, not their length.

const QUICK := 0.05

var _label: Label
var _presenter: MessagePresenter


func before_each() -> void:
	_label = Label.new()
	add_child_autofree(_label)
	_presenter = MessagePresenter.new(_label, get_tree())
	_presenter.dwell_seconds = QUICK


## Wait for roughly `dwells` message-lengths, plus a margin.
func _wait(dwells: float) -> void:
	await get_tree().create_timer(QUICK * dwells + 0.02).timeout


func test_a_message_is_shown() -> void:
	_presenter.say("You said nothing.")
	assert_true(_presenter.is_saying_something(), "the label should be up")
	assert_eq(_label.text, "You said nothing.")


func test_an_empty_message_says_nothing() -> void:
	_presenter.say("   ")
	assert_false(_presenter.is_saying_something(),
		"blank text should not raise an empty box over the hand")


# ---------------------------------------------------------------------------
# The defect
# ---------------------------------------------------------------------------

func test_a_second_message_does_not_cut_the_first_short() -> void:
	_presenter.say("First")
	_presenter.say("Second")

	# Still inside the first message's dwell.
	assert_eq(_label.text, "First",
		"the second message should wait its turn, not replace the first")


func test_the_first_timer_does_not_blank_the_second_message() -> void:
	_presenter.say("First")
	_presenter.say("Second")

	# Past the point where the FIRST message's timer fires. Under the old
	# code that timer hid the label outright, taking the second message with
	# it. It should instead have handed over to it.
	await _wait(1.4)

	assert_true(_presenter.is_saying_something(),
		"the screen went blank while there was still something to say")
	assert_eq(_label.text, "Second",
		"the first message's timer should hand over, not hide")


func test_every_message_in_a_turn_gets_read() -> void:
	# A card lands, the opponent answers, a bout is won: three sentences
	# inside one turn is normal, and all three should appear.
	var seen: Array[String] = []
	for line: String in ["Card", "Answer", "Bout"]:
		_presenter.say(line)

	for i in 3:
		seen.append(_label.text)
		await _wait(1.0)

	assert_eq(seen, ["Card", "Answer", "Bout"],
		"all three should be shown, in the order they happened")


func test_the_queue_empties_and_the_label_goes_away() -> void:
	_presenter.say("Only thing")
	await _wait(1.4)
	assert_false(_presenter.is_saying_something(),
		"with nothing left to say the notice should clear itself")


# ---------------------------------------------------------------------------
# Starting over
# ---------------------------------------------------------------------------

func test_clearing_drops_what_was_waiting() -> void:
	_presenter.say("First")
	_presenter.say("Second")
	_presenter.clear()

	assert_false(_presenter.is_saying_something(), "clear should empty the label")

	await _wait(2.4)
	assert_false(_presenter.is_saying_something(),
		"a message dropped by clear() should not reappear afterwards")


func test_a_cleared_presenter_can_speak_again() -> void:
	# A new stage opening after an old one was cut off mid-sentence.
	_presenter.say("Last stage")
	_presenter.clear()
	_presenter.say("New stage")

	assert_true(_presenter.is_saying_something())
	assert_eq(_label.text, "New stage")
