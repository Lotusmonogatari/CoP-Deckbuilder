extends GutTest
## Dragging a staff item or task card (Cameron, 2026-11-16): the whole card moves
## as one piece, held up and to the left of the finger.

func _item_chip() -> TaskChip:
	var chip := TaskChip.new()
	chip.setup_item("SH04", "Coffee", "coffee", "+1 hour", Color.WHITE, false, true)
	add_child_autofree(chip)
	chip.size = Vector2(190, 260)
	return chip


func test_the_preview_is_a_whole_card_not_just_the_picture() -> void:
	var chip := _item_chip()
	var holder := chip.drag_preview()
	add_child_autofree(holder)
	var card := holder.get_child(0) as TaskChip
	assert_not_null(card, "a copy of the card")
	assert_gt(card.find_children("*", "Label", true, false).size(), 0, "with its words")
	assert_eq(card.custom_minimum_size, chip.size, "the same size as the card")


func test_the_preview_sits_up_and_to_the_left_of_the_finger() -> void:
	var chip := _item_chip()
	var holder := chip.drag_preview()
	add_child_autofree(holder)
	var card := holder.get_child(0) as Control
	assert_lt(card.position.x, 0.0)
	assert_lt(card.position.y, 0.0)
	assert_lte(card.position.x + chip.size.x, 0.0, "its right edge is left of the finger")
	assert_lte(card.position.y + chip.size.y, 0.0, "its bottom edge is above the finger")


func test_the_preview_ignores_touches_and_cannot_be_dragged_again() -> void:
	var chip := _item_chip()
	var holder := chip.drag_preview()
	add_child_autofree(holder)
	var card := holder.get_child(0) as TaskChip
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_false(card.draggable)


func test_a_task_card_drags_the_same_way() -> void:
	var chip := TaskChip.new()
	chip.setup("T0", "Review the news", "LL02", 1, Color.GOLD, false, true, "")
	add_child_autofree(chip)
	chip.size = Vector2(190, 260)
	var holder := chip.drag_preview()
	add_child_autofree(holder)
	assert_lt((holder.get_child(0) as Control).position.x, 0.0)
