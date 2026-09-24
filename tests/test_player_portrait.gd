extends GutTest
## PlayerPortraitPresenter's pure face-selection: which face a just-played
## card, or the opponent's just-resolved move, earns the player. No Control,
## no timers — see test_art_scheme.gd for the Control-facing pieces this
## sits on top of (ArtLoader, PlaceholderArt's draw order).


func test_arguing_the_room_away_wins_over_everything_else() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_card(
		{"opponent_lost": 3, "gained": 2, "guard": 1}), PlayerPortraitPresenter.ATTACKING)


func test_winning_support_beats_merely_banking_guard() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_card(
		{"gained": 2, "guard": 1}), PlayerPortraitPresenter.GAINING)


func test_guard_alone_is_still_worth_a_face() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_card({"guard": 3}), PlayerPortraitPresenter.GUARDING)


func test_a_card_that_did_none_of_these_is_neutral() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_card({"gaffe": 1, "drawn": 2}),
		PlayerPortraitPresenter.NEUTRAL)
	assert_eq(PlayerPortraitPresenter.face_for_card({}), PlayerPortraitPresenter.NEUTRAL)


func test_a_hit_that_gets_through_is_damaged() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_opponent_move(
		{"verb": "attack", "damage": 4}), PlayerPortraitPresenter.DAMAGED)


func test_an_attack_fully_absorbed_by_guard_is_not_a_face() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_opponent_move(
		{"verb": "attack", "absorbed": 5, "damage": 0}), PlayerPortraitPresenter.NEUTRAL)


func test_the_opponent_gaining_or_blocking_is_not_a_hit_on_the_player() -> void:
	assert_eq(PlayerPortraitPresenter.face_for_opponent_move(
		{"verb": "gain", "gained": 5}), PlayerPortraitPresenter.NEUTRAL)
	assert_eq(PlayerPortraitPresenter.face_for_opponent_move(
		{"verb": "block", "guard": 3}), PlayerPortraitPresenter.NEUTRAL)
