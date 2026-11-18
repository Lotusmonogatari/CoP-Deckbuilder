extends GutTest
## The battle bar names what it measures (2026-11-18).


func test_a_percentage_bar_names_its_metric() -> void:
	assert_eq(SupportBar.metric_for("Appeasement", "53% to win"), "Appeasement")
	assert_eq(SupportBar.metric_for("Favorability", "80% to advance"), "Favorability")
	assert_eq(SupportBar.metric_for("Seats", "51 to win"), "Seats")


func test_a_caption_that_already_says_it_needs_no_second_row() -> void:
	assert_eq(SupportBar.metric_for("Press tone", "raise press tone as high as you can"), "")
	assert_eq(SupportBar.metric_for("", "55 to win"), "")
