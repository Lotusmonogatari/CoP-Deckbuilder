extends GutTest
## Delegation choices are greyed out with no staff hired (2026-10-28).

const PHRASES := ["a staff member", "a staffer", "a deputy"]


func test_delegation_wording_is_recognised() -> void:
	for text in ["Send a staff member.", "Forward it to a staffer", "Send a staffer in your place", "I could send a deputy."]:
		assert_true(StaffDelegation.is_delegation(text, PHRASES), text)


func test_ordinary_choices_are_not_delegation() -> void:
	for text in ["Ask my staff, they keep the list.", "Gladly. Name a day.", "Send regrets"]:
		assert_false(StaffDelegation.is_delegation(text, PHRASES), text)


func test_blocked_only_with_no_staff() -> void:
	assert_true(StaffDelegation.blocked("Send a staff member", PHRASES, {}))
	assert_false(StaffDelegation.blocked("Send a staff member", PHRASES, {"Secretary": {"staff_id": "SF01"}}))
	assert_false(StaffDelegation.blocked("Gladly", PHRASES, {}))
