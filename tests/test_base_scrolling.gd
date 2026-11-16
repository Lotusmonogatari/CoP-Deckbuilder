extends GutTest
## The scrolling-screen picture (Cameron, 2026-11-13): BASE_SCROLLING.png sits
## behind every Overlay (events, information screens, shops), shown as drawn
## (no dark tint since 2026-11-16: its text gets plates instead), and never
## swallows a touch.

func test_an_overlay_has_the_picture_at_the_back_and_no_tint() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	var picture := overlay.get_node_or_null("BaseImage") as TextureRect
	assert_not_null(picture, "the scrolling picture is installed")
	assert_eq(overlay.get_child(0), picture, "it is the lowest child")
	assert_null(overlay.get_node_or_null("BaseTint"), "the picture is not darkened")
	assert_eq(picture.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(overlay.theme, BaseImage.plate_theme(), "text gets its own plates instead")
	assert_not_null(overlay.get_node_or_null("Margin/Scroll"), "the content still scrolls")


func test_installing_twice_adds_one_picture() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	BaseImage.install_behind_panel(panel)
	assert_null(BaseImage.install_behind_panel(panel))
	assert_eq(panel.get_child_count(), 1)
