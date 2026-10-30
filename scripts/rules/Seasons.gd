class_name Seasons
extends RefCounted
## Seasonal levels and events (Cameron, 2026-10-30): a Levels or Events row
## whose Seasons cell names one or more seasons ("Winter", "Autumn; Winter")
## only shows in those seasons' months; a blank cell means all year. Which
## months make up a season is rules.json's "seasons" table. Pure and UI-free.


## The season a month (1-12) falls in, or "" when the table names none.
static func season_of(month: int, table: Dictionary) -> String:
	for season: String in table.keys():
		for value: Variant in table[season]:
			if int(value) == month:
				return season
	return ""


## True when `row` may show in `month`: its Seasons list is blank, or names
## the season the month is in.
static func in_season(row: Dictionary, month: int, table: Dictionary) -> bool:
	var listed: Variant = row.get("seasons")
	if not (listed is Array) or (listed as Array).is_empty():
		return true
	return (listed as Array).has(season_of(month, table))
