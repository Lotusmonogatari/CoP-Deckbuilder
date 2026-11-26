class_name Blunders
extends RefCounted
## Gaffes and Blunders! (P21 phase B, 2026-11-26, Cameron). Pure and UI-free (CLAUDE.md section 12): when a run's gaffe total crosses a threshold, how a roll
## comes out, what a Blunder! costs and what it can cost less, and which accusation it can leave behind. Every number is a Balance row read through Levers;
## every roll takes the run's seed and a counter, so a reload gives the same result.
##
## Leftover gaffes add to one run total. Each time it passes another `awareness_gaffes_per_roll` (30) a roll with `awareness_gaffe_roll_chance` (0.2) may cost
## 1 District and National awareness; each time it passes another `blunder_gaffes_per_roll` (25) a roll with `blunder_chance` (1/3) may bring a Blunder!, and so
## may each stage lost to gaffes. A Blunder! costs 10 District and National awareness, never taking either below 21. A Media Spokesperson can cancel the loss
## for Political Capital by tier; afterwards an accusation roll (Scandal! 1/8 first, else Rumor! 1/3; both halved when cancelled) leaves a pending accusation.


## How many thresholds of `per` lie between the two totals (the total passed several in one stage rolls once for each).
static func crossed(before: int, after: int, per: int) -> int:
	var step := maxi(1, per)
	return maxi(0, after / step - before / step)


## A number from 0 up to but not including 1 that depends only on the run's seed and a counter.
static func draw(run_seed: int, counter: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(("%d|blunder|%d" % [run_seed, counter]).hash())
	return rng.randf()


## What a Blunder! takes from a meter at `value`: Balance blunder_awareness_delta (negative), never taking it below blunder_floor; a meter at or under the
## floor loses nothing. A positive number of points lost.
static func loss(value: int) -> int:
	var wanted := absi(Levers.whole("blunder_awareness_delta"))
	return clampi(value - Levers.whole("blunder_floor"), 0, wanted)


## The Political Capital a Media Spokesperson of `tier` takes to cancel a Blunder! (Balance blunder_cancel_xp_tier_0, _1, _2).
static func cancel_price(tier: int) -> int:
	return Levers.whole("blunder_cancel_xp_tier_%d" % clampi(tier, 0, 2))


## The accusation a Blunder! leaves: "scandal", "rumor" or "". `scandal_roll` and `rumor_roll` are draws from 0 to 1. The Scandal! is checked first.
## A cancelled Blunder! halves both chances.
static func accusation(cancelled: bool, scandal_roll: float, rumor_roll: float) -> String:
	var factor := Levers.num("blunder_cancelled_chance_factor") if cancelled else 1.0
	if scandal_roll < Levers.num("blunder_scandal_chance") * factor:
		return "scandal"
	if rumor_roll < Levers.num("blunder_rumor_chance") * factor:
		return "rumor"
	return ""
