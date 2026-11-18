extends GutTest
## The battle bar's caption: the figure with its metric then "to Advance" / "to Win", on one row (2026-11-18),
## with the grammar right for what the bar counts.


func test_a_share_takes_the_metric_as_its_noun() -> void:
	assert_eq(SupportBar.caption_text("80%", "Favorability", "to Advance"), "80% Favorability to Advance")
	assert_eq(SupportBar.caption_text("53%", "Appeasement", "to Win"), "53% Appeasement to Win")


func test_a_count_takes_the_metric_as_its_noun() -> void:
	assert_eq(SupportBar.caption_text("51", "Seats", "to Win"), "51 Seats to Win")
	assert_eq(SupportBar.caption_text("20", "Members", "to Advance"), "20 Members to Advance")


func test_a_score_is_points_of_the_metric() -> void:
	assert_eq(SupportBar.caption_text("55", "Press tone", "to Win", true), "55 points of Press tone to Win")
	assert_eq(SupportBar.caption_text("65", "Viewer Interest", "to Win", true), "65 points of Viewer Interest to Win")


func test_a_bar_with_no_metric_keeps_just_the_figure() -> void:
	assert_eq(SupportBar.caption_text("55", "", "to Win"), "55 to Win")
