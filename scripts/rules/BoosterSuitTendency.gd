class_name BoosterSuitTendency
extends RefCounted
## Which suits tend to please which organisations (2026-10-11, Cameron).
##
## Nothing in the data says "National Media likes Earnest". What pleases an
## organisation is a QUESTION'S OWN grade for the suit you answer with, and a
## question is tied to its organisations through its theme. So the tendency is
## read from the questions themselves: for each organisation, over every
## question that pleases it, a Strong grade counts +1, Medium 0, Weak -1, and
## the average is its score for that suit (-1 to +1). Pure arithmetic, no UI;
## the How to Play guide quotes the result, so it follows the workbook.

## An organisation counts for a suit when its average is at least this.
const MIN_SCORE := 0.4
## ...and only when at least this many questions please it (a thin sample proves nothing).
const MIN_QUESTIONS := 5
## The guide stays concise: at most this many organisations per suit.
const MAX_PER_SUIT := 4

const POINTS := {"S": 1.0, "M": 0.0, "W": -1.0}


## {suit: [{booster_id, score}]} best first, for the suits given. `questions`
## is questions.json (pool -> list of question dictionaries).
static func by_suit(questions: Dictionary, suits: Array) -> Dictionary:
	var totals := {}  # booster_id -> {suit: sum}
	var counts := {}  # booster_id -> questions
	for pool in questions.values():
		for question in (pool as Array):
			var grades: Dictionary = question.get("grades", {})
			for booster_id: String in (question.get("pleases_boosters", []) as Array):
				counts[booster_id] = int(counts.get(booster_id, 0)) + 1
				if not totals.has(booster_id):
					totals[booster_id] = {}
				for suit: String in suits:
					var sums: Dictionary = totals[booster_id]
					sums[suit] = float(sums.get(suit, 0.0)) + float(POINTS.get(str(grades.get(suit, "M")), 0.0))

	var out := {}
	for suit: String in suits:
		var rows: Array[Dictionary] = []
		for booster_id: String in counts:
			if int(counts[booster_id]) < MIN_QUESTIONS:
				continue
			var score := float((totals[booster_id] as Dictionary).get(suit, 0.0)) / float(counts[booster_id])
			if score >= MIN_SCORE:
				rows.append({"booster_id": booster_id, "score": score})
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		out[suit] = rows.slice(0, MAX_PER_SUIT)
	return out


## One line per suit: "Earnest: National Media, Ainu Language and Culture Foundation".
## A suit nobody leans towards is left out.
static func lines(questions: Dictionary, suits: Array, names: Dictionary) -> Array[String]:
	var table := by_suit(questions, suits)
	var result: Array[String] = []
	for suit: String in suits:
		var who: Array[String] = []
		for row: Dictionary in (table.get(suit, []) as Array):
			who.append(str(names.get(row["booster_id"], row["booster_id"])))
		if not who.is_empty():
			result.append("%s: %s" % [suit, ", ".join(who)])
	return result
