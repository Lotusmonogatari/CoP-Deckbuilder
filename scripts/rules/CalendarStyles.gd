class_name CalendarStyles
extends RefCounted
## The other ways the Office calendar can be written (Cameron, 2026-10-26).
##
## Pure, like everything in scripts/rules/: dates and word lists go in, plain
## values come out. The words themselves (era format, weekday kanji, Ainu
## month names) come from the Text tab; the era table (names and start dates)
## comes from data/rules.json's "calendar_eras".
##
## The styles are cosmetic packages with a "Calendar Style" piece:
##   ""     the plain YY.MM.DD calendar (always available)
##   "era"  Japanese era years: 平成30年10月1日, with the weekday in kanji
##   "ainu" 2018.イノミチュㇷ゚.01, in two levels (date and hours), no weekday

const GREGORIAN := ""
const ERA := "era"
const AINU := "ainu"


## The era a date falls in, as { "name", "year" } (year 1 is the era's first
## year), or {} when the date is before the first era in the table.
static func era_for(date: Array, eras: Array) -> Dictionary:
	var found := {}
	for era: Dictionary in eras:
		if _on_or_after(date, era):
			found = era
	if found.is_empty():
		return {}
	return {"name": str(found["name"]), "year": int(date[0]) - int(found["year"]) + 1}


## The pieces of a date written in era style, or {} outside the table:
## { "era": "平成", "year": "30" | "元", "month": "10", "day": "1" }.
static func era_parts(date: Array, eras: Array, first_year_word: String) -> Dictionary:
	var era := era_for(date, eras)
	if era.is_empty():
		return {}
	var year := int(era["year"])
	return {
		"era": str(era["name"]),
		"year": first_year_word if year == 1 else str(year),
		"month": str(int(date[1])),
		"day": str(int(date[2])),
	}


## "2018.イノミチュㇷ゚.01": year, the month's Ainu name, two-digit day.
## `month_names` is the twelve names, January first.
static func ainu_text(date: Array, month_names: Array) -> String:
	var month := int(date[1])
	var name := str(month_names[month - 1]) if month >= 1 and month <= month_names.size() else str(month)
	return "%04d.%s.%02d" % [int(date[0]), name, int(date[2])]


static func _on_or_after(date: Array, era: Dictionary) -> bool:
	var a := [int(date[0]), int(date[1]), int(date[2])]
	var b := [int(era["year"]), int(era["month"]), int(era["day"])]
	for i in 3:
		if a[i] != b[i]:
			return a[i] > b[i]
	return true
