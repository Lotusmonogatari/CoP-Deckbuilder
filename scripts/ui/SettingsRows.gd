class_name SettingsRows
extends RefCounted
## The player's settings as buttons (text size, Image Scroll, Image Pan), in
## one place so the Office's Administration menu and a stage's own menu show
## the same ones (2026-11-10). Each tap changes the setting through Layout,
## which saves it, and then calls `on_changed` so the menu can redraw.


static func buttons(on_changed: Callable) -> Array[Control]:
	return [text_size_button(on_changed), image_scroll_button(on_changed), image_pan_button(on_changed), haptics_button(on_changed)]


## "Text size: Normal": one tap cycles Small, Normal, Large and applies it at once.
static func text_size_button(on_changed: Callable) -> Button:
	return _button("TextSizeButton", text_size_label(), Layout.cycle_text_size, on_changed)


## "Image Scroll: On": one tap turns dragging event pictures on or off.
static func image_scroll_button(on_changed: Callable) -> Button:
	var state := Text.say("settings.on") if Layout.image_scroll_enabled else Text.say("settings.off")
	return _button("ImageScrollButton", Text.say("office.image_scroll", {"state": state}),
		Layout.toggle_image_scroll, on_changed)


## "Image Pan: On": one tap turns tilting event pictures on or off.
static func image_pan_button(on_changed: Callable) -> Button:
	var state := Text.say("settings.on") if Layout.image_pan_enabled else Text.say("settings.off")
	return _button("ImagePanButton", Text.say("office.image_pan", {"state": state}),
		Layout.toggle_image_pan, on_changed)


## "Haptics: On": one tap turns the short buzz on confirming buttons on or off.
static func haptics_button(on_changed: Callable) -> Button:
	var state := Text.say("settings.on") if Layout.haptics_enabled else Text.say("settings.off")
	return _button("HapticsButton", Text.say("office.haptics", {"state": state}),
		Layout.toggle_haptics, on_changed)


static func text_size_label() -> String:
	var word := Text.say("text_size.normal")
	match Layout.text_size_setting:
		TextScale.SMALL: word = Text.say("text_size.small")
		TextScale.LARGE: word = Text.say("text_size.large")
	return Text.say("office.text_size", {"size": word})


static func _button(node_name: String, label: String, flip: Callable, on_changed: Callable) -> Button:
	var button := UiKit.action_button(label, "", func() -> void:
		flip.call()
		on_changed.call(), 100.0)
	button.name = node_name
	button.custom_minimum_size.x = UiKit.LINE_WIDTH
	return button
