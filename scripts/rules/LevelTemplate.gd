class_name LevelTemplate
extends RefCounted
## Turns a Bill Level Template row (data/bill_level_templates.json) and a
## composed bill into an ordered list of real stage ids (2026-10-19). The
## template names families, not stages: a meeting with the patron, the
## committee hearing for the bill's lead component, a public room, your own
## caucus, the floor vote. The stage numbers come from the generic rooms of
## those families, the same rooms the bill-specific copies were cloned from, so
## the existing bot trials apply.
##
## Pure and UI-free (CLAUDE.md section 12).

## Token -> generic room. HEARING and PUBLIC are decided per bill (below).
const FIXED := {
	"PATRON_MEETING": "ST20",
	"PATRON_VISIT": "ST263",
	"CAUCUS": "ST03",
	"STEERING": "ST08",
	"VOTE": "ST23",
}
const PUBLIC_BY_TIER := {"Constituency": "ST05", "National": "ST04"}


## `hearing_stage` is the lead component's committee; `owner_tier` is the
## patron organization's Boosters-tab tier. `visit_offered` says whether an
## MP_VISIT token becomes its two stages (the visit and the fight); false
## drops the token. Returns [] when a token cannot be resolved, so a
## half-written template never produces a broken level.
static func stages(template: Dictionary, hearing_stage: String, owner_tier: String,
		visit_offered: bool = false, trade_offered: bool = false) -> Array:
	var out: Array = []
	for slot in slot_numbers(template):
		var token: Variant = template.get("stage_%d" % slot)
		if token == null or str(token).strip_edges().is_empty():
			continue
		if str(token).strip_edges() == "MP_VISIT":
			if visit_offered:
				out.append(MpVisit.VISIT_STAGE)
				out.append(MpVisit.FIGHT_STAGE)
			continue
		if str(token).strip_edges() == "LOBBYIST_TRADE":
			if trade_offered:
				out.append(LobbyistTrade.TRADE_STAGE)
			continue
		var stage_id := _resolve(str(token).strip_edges(), hearing_stage, owner_tier)
		if stage_id.is_empty():
			return []
		out.append(stage_id)
	return out


static func _resolve(token: String, hearing_stage: String, owner_tier: String) -> String:
	if token == "HEARING":
		return hearing_stage
	if token == "PUBLIC":
		return str(PUBLIC_BY_TIER.get(owner_tier, ""))
	return str(FIXED.get(token, ""))


## The template's own stage_N columns, in numeric order. The levels pull from
## whatever stages the row has; no fixed slot count lives in code.
static func slot_numbers(template: Dictionary) -> Array[int]:
	var numbers: Array[int] = []
	for key: Variant in template.keys():
		var text := str(key)
		if text.begins_with("stage_") and text.substr(6).is_valid_int():
			numbers.append(text.substr(6).to_int())
	numbers.sort()
	return numbers
