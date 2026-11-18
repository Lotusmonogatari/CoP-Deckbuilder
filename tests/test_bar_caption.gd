extends GutTest
## The battle bar's caption: the figure with its metric over "to Advance" / "to Win" (2026-11-18),
## with the grammar right for what the bar counts.


func test_a_share_takes_the_metric_as_its_noun() -> void:
	assert_eq(SupportBar.two_row_caption("80%", "Favorability", "to Advance"), "80% Favorability\nto Advance")
	assert_eq(SupportBar.two_row_caption("53%", "Appeasement", "to Win"), "53% Appeasement\nto Win")


func test_a_count_takes_the_metric_as_its_noun() -> void:
	assert_eq(SupportBar.two_row_caption("51", "Seats", "to Win"), "51 Seats\nto Win")
	assert_eq(SupportBar.two_row_caption("20", "Members", "to Advance"), "20 Members\nto Advance")


func test_a_score_is_points_of_the_metric() -> void:
	assert_eq(SupportBar.two_row_caption("55", "Press tone", "to Win", true), "55 points of Press tone\nto Win")
	assert_eq(SupportBar.two_row_caption("65", "Viewer Interest", "to Win", true), "65 points of Viewer Interest\nto Win")


func test_a_bar_with_no_metric_keeps_just_the_figure() -> void:
	assert_eq(SupportBar.two_row_caption("55", "", "to Win"), "55\nto Win")
