class_name VoteWords
extends RefCounted
## The two phrases a Floor Vote's requirement is called in play (2026-10-15).


## "Majority Vote to Pass" or "Supermajority Vote to Pass".
static func requirement_label(requirement: String) -> String:
	return Text.say("floor_vote.req_supermajority" if requirement == FloorVoteEngine.SUPERMAJORITY
		else "floor_vote.req_majority")
