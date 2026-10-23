extends GutTest
## The dining room and the walking route each have a default picture and one
## purchasable alternative (2026-10-23): DINING / DINING_ALT (CP03, 50,000円)
## and TOUR / TOUR_ALT (CP04, 75 XP).

var _active_before: Dictionary = {}
var _owned_before: Array = []
var _meta_before: Dictionary = {}
var _xp_before := 0
var _calendar_before: Dictionary = {}
var _inventory_before: Dictionary = {}


func before_each() -> void:
	_active_before = GameState.active_cosmetics.duplicate()
	_owned_before = GameState.owned_cosmetic_packages.duplicate()
	_meta_before = GameState.meta.duplicate()
	_xp_before = GameState.xp
	_calendar_before = GameState.calendar.duplicate()
	_inventory_before = GameState.inventory.duplicate()
	GameState.active_cosmetics = {}
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	GameState.active_cosmetics = _active_before
	GameState.owned_cosmetic_packages.assign(_owned_before)
	GameState.meta = _meta_before
	GameState.xp = _xp_before
	GameState.calendar = _calendar_before
	GameState.inventory = _inventory_before


func test_the_alternatives_cost_what_was_asked() -> void:
	assert_eq(CosmeticPieces.cost(DataDB.get_cosmetic_package("CP03")), {"XP": 0, "Funds": 50000})
	assert_eq(CosmeticPieces.cost(DataDB.get_cosmetic_package("CP04")), {"XP": 75, "Funds": 0})


func test_each_alternative_has_a_piece_for_its_own_slot_only() -> void:
	var dining := DataDB.get_cosmetic_package("CP03")
	var tour := DataDB.get_cosmetic_package("CP04")
	assert_true(CosmeticPieces.has_piece(dining, CosmeticPieces.DINING))
	assert_false(CosmeticPieces.has_piece(dining, CosmeticPieces.TOUR))
	assert_true(CosmeticPieces.has_piece(tour, CosmeticPieces.TOUR))
	assert_false(CosmeticPieces.has_piece(tour, CosmeticPieces.BACKGROUND), "not the Office background")


func test_the_default_pictures_load_by_their_own_asset_ids() -> void:
	assert_eq(ArtLoader._background_variant("DINING"), "")
	assert_eq(ArtLoader._background_variant("TOUR"), "")


func test_an_equipped_alternative_is_tried_first() -> void:
	GameState.equip_cosmetic(CosmeticPieces.DINING, "CP03")
	GameState.equip_cosmetic(CosmeticPieces.TOUR, "CP04")
	assert_eq(ArtLoader._background_variant("DINING"), "ALT")
	assert_eq(ArtLoader._background_variant("TOUR"), "ALT")
	assert_eq(ArtLoader._background_variant("OFFICE"), "", "the Office picture is a separate slot")


func test_buying_the_dining_room_costs_yen_and_the_route_costs_xp() -> void:
	GameState.meta["Funds"] = 60000
	GameState.xp = 100
	GameState.buy_cosmetic_package("CP03")
	assert_eq(int(GameState.meta["Funds"]), 10000)
	assert_eq(GameState.xp, 100, "the dining room costs no XP")
	GameState.buy_cosmetic_package("CP04")
	assert_eq(GameState.xp, 25)
	assert_eq(int(GameState.meta["Funds"]), 10000, "the route costs no yen")
	assert_true(GameState.owned_cosmetic_packages.has("CP03") and GameState.owned_cosmetic_packages.has("CP04"))


func test_hosting_shows_the_matching_picture() -> void:
	GameState.inventory["SH19"] = 1
	assert_eq(str(GameState.use_item_in_office("SH19", "BO05")["image"]), "DINING")
	GameState.inventory["SH20"] = 1
	assert_eq(str(GameState.use_item_in_office("SH20", "BO07")["image"]), "TOUR")


func test_the_tour_and_dinner_events_carry_the_pictures_too() -> void:
	assert_eq(str(GameState.get_event("EV01")["image"]), "TOUR")
	assert_eq(str(GameState.get_event("EV02")["image"]), "DINING")
