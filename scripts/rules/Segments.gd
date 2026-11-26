class_name Segments
extends RefCounted
## Segments and credibility (P21 phase C, 2026-11-26, Cameron). Pure and UI-free (CLAUDE.md section 12). A segment is a group of organizations (the Segment Map
## tab) that responds to one suit. Its favorability is how far the group takes the player's word:
##
##   favorability = round(average standing of its organizations x min(1, suit plays in the window / segment_suit_use_target)) - debit, clamped 0 to 100
##   credibility  = round(average of the five favorabilities)
##
## Spending credibility (the accusation answers of phase D) adds the amount to every segment's debit, so credibility falls by that amount; every debit shrinks
## `credibility_debit_recovery_percent` each week (rounded down). Every number is a Balance row.


## How many cards of `suit` were played in the last `weeks` weeks up to and including `current_week`; `by_week` is {week: {suit: count}}.
static func plays_in_window(by_week: Dictionary, current_week: int, weeks: int, suit: String) -> int:
	var total := 0
	for key: Variant in by_week.keys():
		var week := int(key)
		if week > current_week - weeks and week <= current_week:
			total += int((by_week[key] as Dictionary).get(suit, 0))
	return total


## The average of the standings (0 to 100); 0 for none.
static func average_standing(standings: Array) -> float:
	if standings.is_empty():
		return 0.0
	var sum := 0.0
	for value: Variant in standings:
		sum += float(value)
	return sum / float(standings.size())


## A segment's favorability, a whole number 0 to 100.
static func favorability(average: float, plays: int, debit: int) -> int:
	var use := minf(1.0, float(plays) / maxf(1.0, Levers.num("segment_suit_use_target")))
	return clampi(roundi(average * use) - maxi(0, debit), 0, 100)


## The credibility: the average of the favorabilities, rounded.
static func credibility(favorabilities: Array) -> int:
	return roundi(average_standing(favorabilities))


## Whether `amount` of credibility can be spent: at least 1 and no more than there is.
static func can_spend(current: int, amount: int) -> bool:
	return amount >= 1 and amount <= current


## A debit after a week's recovery: shrunk by the Balance percent, rounded down (so a small debit reaches 0).
static func debit_after_week(debit: int) -> int:
	return int(floor(float(maxi(0, debit)) * float(100.0 - Levers.num("credibility_debit_recovery_percent")) / 100.0))
