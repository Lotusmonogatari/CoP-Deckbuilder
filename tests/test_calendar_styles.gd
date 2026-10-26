extends GutTest
## The Era Name and Ainu calendars (Cameron, 2026-10-26).

var _active_before: Dictionary = {}
var _owned_before: Array = []
var _meta_before: Dictionary = {}
var _calendar_before: Dictionary = {}

var _eras: Array = [
	{"name": "平成", "year": 1989, "month": 1, "day": 8},
	{"name": "令和", "year": 2019, "month": 5, "day": 1}]


func before_each() -> void:
	_active_before = GameState.active_cosmetics.duplicate()
	_owned_before = GameState.owned_cosmetic_packages.duplicate()
	_meta_before = GameState.meta.duplicate()
	_calendar_before = GameState.calendar.duplicate()
	GameState.active_cosmetics = {}
	GameState.owned_cosmetic_packages = []
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	GameState.active_cosmetics = _active_before
	GameState.owned_cosmetic_packages.assign(_owned_before)
	GameState.meta = _meta_before
	GameState.calendar = _calendar_before


func test_the_game_start_is_heisei_30() -> void:
	var parts := CalendarStyles.era_parts([2018, 10, 1], _eras, "元")
	assert_eq(parts, {"era": "平成", "year": "30", "month": "10", "day": "1"})


func test_heisei_ends_on_the_last_of_april_and_reiwa_begins_on_the_first_of_may() -> void:
	assert_eq(CalendarStyles.era_parts([2019, 4, 30], _eras, "元")["era"], "平成")
	assert_eq(CalendarStyles.era_parts([2019, 4, 30], _eras, "元")["year"], "31")
	var first := CalendarStyles.era_parts([2019, 5, 1], _eras, "元")
	assert_eq(first["era"], "令和")
	assert_eq(first["year"], "元", "an era's first year is written 元年")
	assert_eq(CalendarStyles.era_parts([2020, 1, 1], _eras, "元")["year"], "2")


func test_a_date_before_every_era_has_no_era_form() -> void:
	assert_true(CalendarStyles.era_parts([1980, 1, 1], _eras, "元").is_empty())


func test_the_ainu_form_is_year_month_name_day() -> void:
	var names := ["イノミチュㇷ゚", "タㇱクㇽチュㇷ゚", "トエタンネ", "キウタチプ", "シキウタチプ",
		"モマウタチプ", "シマウタチプ", "モニヲラク", "シニヲラク", "ウレポク", "シネアンチプ", "クイカイ"]
	assert_eq(CalendarStyles.ainu_text([2018, 10, 1], names), "2018.ウレポク.01")
	assert_eq(CalendarStyles.ainu_text([2019, 1, 31], names), "2019.イノミチュㇷ゚.31")


func test_the_two_calendars_cost_2000_yen_and_can_be_switched_back_and_forth() -> void:
	for id: String in ["CP05", "CP06"]:
		assert_eq(int(DataDB.get_cosmetic_package(id).get("cost_yen")), 2000, id)
	GameState.meta["Funds"] = 5000
	assert_eq(GameState.buy_cosmetic_package("CP05"), "")
	assert_eq(int(GameState.meta["Funds"]), 3000)
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "CP05")
	assert_eq(GameState.calendar_style(), CalendarStyles.ERA)
	assert_eq(GameState.calendar_date_text(), "平成30年10月1日")
	assert_eq(GameState.calendar_weekday_text(), "月曜日", "kanji only")
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "")
	assert_eq(GameState.calendar_date_text(), "18.10.01", "back to the plain calendar")
	assert_eq(GameState.buy_cosmetic_package("CP06"), "")
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "CP06")
	assert_eq(GameState.calendar_date_text(), "2018.ウレポク.01")
	assert_eq(GameState.calendar_weekday_text(), "", "the Ainu calendar has two levels")
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "")


func test_the_era_calendar_turns_from_heisei_to_reiwa_as_the_game_passes_the_date() -> void:
	GameState.owned_cosmetic_packages.append("CP05")
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "CP05")
	# 30 weeks on from Monday 2018-10-01 is Monday 2019-04-29; 31 weeks is 2019-05-06.
	GameState.calendar["week"] = 30
	assert_eq(GameState.calendar_date_text(), "平成31年4月29日")
	GameState.calendar["week"] = 31
	assert_eq(GameState.calendar_date_text(), "令和元年5月6日")
	GameState.equip_cosmetic(CosmeticPieces.CALENDAR, "")
