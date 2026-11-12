extends GutTest
## A very long speaker name (2026-11-12, Cameron's phone screenshot: "Ainu
## Language and Culture Foundation Representative" in Office Hours) wraps
## inside its tag instead of making the band wider than the screen.

const LONG_NAME := "Ainu Language and Culture Foundation Representative"


## A portrait phone-sized viewport of its own, because the banner measures the
## viewport it sits in and the test runner's own is not a phone's.
func _phone_banner() -> CueBanner:
	var phone := SubViewport.new()
	phone.size = Vector2i(1080, 2340)
	add_child_autofree(phone)
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	phone.add_child(holder)
	var banner := CueBanner.new()
	holder.add_child(banner)
	return banner


func test_a_long_speaker_name_does_not_push_the_band_off_the_screen() -> void:
	var banner := _phone_banner()
	await wait_frames(2)

	banner.say(CueBanner.OPPONENT, LONG_NAME, "Training is the root.", "Nods.")
	await wait_frames(4)

	var screen := banner.get_viewport_rect().size.x
	var band: PanelContainer = banner.get_node("Band")
	assert_lte(band.get_combined_minimum_size().x, screen, "the band can fit the screen")
	assert_lte(band.size.x, screen, "and it is no wider than the screen")


func test_a_short_name_keeps_its_own_width() -> void:
	var banner := _phone_banner()
	await wait_frames(2)

	banner.say(CueBanner.OPPONENT, "Visitor A", "Hello.", "")
	await wait_frames(3)

	var speaker: Label = banner._speaker
	var natural := speaker.get_theme_font("font").get_string_size(
		"Visitor A", HORIZONTAL_ALIGNMENT_LEFT, -1.0, speaker.get_theme_font_size("font_size")).x
	assert_lte(speaker.custom_minimum_size.x, natural + 5.0, "no wider than the name needs")
