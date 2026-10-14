extends GutTest
## An Overlay that is built and never opened must not leave nodes behind
## (stress test 2026-10-14: its Back and Confirm buttons used to float
## outside the tree until opened, so every Office load leaked about 130
## objects and 0.4 MB).


func test_an_unopened_overlay_leaves_no_orphan_nodes() -> void:
	var before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in 20:
		var overlay := Overlay.new()
		add_child(overlay)
		await get_tree().process_frame
		overlay.free()
	var after := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	assert_lte(after, before, "no nodes left floating")


func test_an_opened_overlay_still_has_its_back_and_confirm_buttons() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	await get_tree().process_frame
	var rows: Array[Control] = []
	overlay.open("Title", rows, "Go")
	assert_not_null(overlay.find_child("Back", true, false))
	var confirm := overlay.find_child("Confirm", true, false) as Button
	assert_not_null(confirm)
	assert_true(confirm.visible)
	assert_eq(confirm.text, "Go")
