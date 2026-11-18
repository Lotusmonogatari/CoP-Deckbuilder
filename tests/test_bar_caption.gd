extends GutTest
## The battle bar's caption: "[Number] of [Metric]" over "to Advance" / "to Win" (2026-11-18).


func test_the_caption_reads_number_of_metric_over_the_goal() -> void:
	assert_eq(SupportBar.two_row_caption("80%", "Favorability", "to Advance"), "80% of Favorability\nto Advance")
	assert_eq(SupportBar.two_row_caption("53%", "Appeasement", "to Win"), "53% of Appeasement\nto Win")


func test_a_bar_with_no_metric_keeps_just_the_figure() -> void:
	assert_eq(SupportBar.two_row_caption("55", "", "to Win"), "55\nto Win")
