class_name Haptics
extends RefCounted
## One short buzz for a button that confirms a change (2026-11-11, Cameron):
## a card played, a purchase, a hire or fire, a back or continue button.
## Phones only (Input.vibrate_handheld does nothing elsewhere), and the player
## can turn it off in Administration or a stage menu (Layout.haptics_enabled).
## The length is the Balance row "Haptics: Confirm Milliseconds".


static func confirm() -> void:
	if not Layout.haptics_enabled:
		return
	var milliseconds := int(DataDB.balance.get("haptics_confirm_milliseconds", 25))
	if milliseconds > 0:
		Input.vibrate_handheld(milliseconds)
