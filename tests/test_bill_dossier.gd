extends GutTest
## BillDossier (2026-11-04, Cameron): the "Read the bill" page.

func test_sections_keep_reading_order_and_skip_blanks() -> void:
	var bill := {"bill_description": "Does a thing.", "who_gains": "Farmers", "who_pays": null,
		"case_for": "It helps.", "case_against": "  ", "main_risk": "Waste.", "middle_ground": "A pilot."}
	var fields: Array = []
	for section: Dictionary in BillDossier.sections(bill):
		fields.append(section["field"])
	assert_eq(fields, ["bill_description", "who_gains", "case_for", "main_risk", "middle_ground"])


func test_party_leans_group_by_disposition() -> void:
	var bill := {"positions": [
		{"party_id": "PT01", "disposition": "Supportive"},
		{"party_id": "PT02", "disposition": "Opposed"},
		{"party_id": "PT03", "disposition": "Supportive"},
		{"party_id": "PT09", "disposition": "Neutral"}]}
	var parties := [{"party_id": "PT01", "name": "A"}, {"party_id": "PT02", "name": "B"}, {"party_id": "PT03", "name": "C"}]
	var leans := BillDossier.party_leans(bill, parties)
	assert_eq(leans["Supportive"], ["A", "C"])
	assert_eq(leans["Opposed"], ["B"])
	assert_eq(leans["Neutral"], ["PT09"], "an unknown party shows its ID")


func test_every_workbook_bill_has_a_full_dossier() -> void:
	for bill_id: String in DataDB.floor_votes:
		if not bill_id.begins_with("BI"):
			continue
		assert_eq(BillDossier.sections(DataDB.floor_votes[bill_id]).size(), BillDossier.PROSE_FIELDS.size(),
			"%s is missing a dossier section" % bill_id)
