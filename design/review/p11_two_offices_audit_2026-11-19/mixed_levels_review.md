# Mixed levels to review (12 of the 24, the low and medium confidence ones)

**Decided 2026-11-19 (Cameron): LV12 (Family Outreach Tour), LV61 (Rail Fares and Timetables) and LV62 (Fishing Quotas and Harbors) are District levels that start in the District and finish at the Capitol, with the travel built in.** `levels_location.csv` is updated; the rows for those levels below keep the case that was put to you. The rest of this sheet is what is still open.

Follow-up to `levels_location.csv` (2026-11-19). Draft for Cameron. The rule alone ("a level built around a bill, a committee or the media is Capitol, even if it opens with a town hall; its travel is built in and free") put all 24 Mixed levels at Capitol. These 12 are the ones where it was weakest. Each has a Town Hall (a District room) among its rooms, and in most the purpose is spoken by the District Representative, so the level reads local while its rooms mostly sit at the Capitol.

## Executive summary

| Group | Levels | State |
|---|---|---|
| Decided: District, ending at the Capitol | LV12, LV61, LV62 | Done (Cameron, 2026-11-19) |
| Low confidence, still open | LV10, LV21, LV28 | I recommend Capitol: four or five Capitol rooms each, including a floor debate or a caucus |
| Medium confidence | LV17, LV27, LV44, LV70, LV76, LV81 | I recommend Capitol. Each is built around a bill or a hearing with one Town Hall in it |

## The five levels that were low confidence

| Level | Rooms (C = Capitol, D = District, E = Either) | Why the rule says Capitol | The case for District | My view |
|---|---|---|---|---|
| **LV10** Advancing a Bill to Protect Hometown Markets (tier 1) | Town Hall D, Press Conference C, Town Hall D, Policy Study E, Lobbyist Meeting E, Policy Study E, Special Committee C, TV Debate C, Committee on Construction and Development C, Floor Debate C | Ten rooms: 5 Capitol, 2 District, 3 Either. It ends in a floor debate and runs a TV debate | The name reads local ("Hometown Markets") and the District Representative speaks the purpose | **Capitol.** The shape is a bill campaign |
| **LV12** Family Outreach Tour (tier 1) | Office Hours E, Town Hall D, Committee on the Environment C, Committee on Construction and Development C | Two committees against one town hall | The name is "Outreach Tour". Half the rooms (Office Hours and the Town Hall) are constituent-facing, and the District Representative speaks | **Decided: District, ending at the Capitol** (Cameron). A District-based player starts it with no travel |
| **LV21** A Neighborhood Family Compact (tier 2) | Town Hall D, two committees C, Party Steering Committee C, Floor Debate C | Four Capitol rooms against one town hall | The name reads local | **Capitol.** |
| **LV28** Kōenkai Family Ties (tier 2) | Town Hall D, Office Hours E, two committees C, Party Caucus C, Party Steering Committee C, Floor Debate C | Five Capitol rooms against one town hall | The name reads local (a Kōenkai is a local support group) | **Capitol.** The ending is party business and a floor debate |
| **LV62** Fishing Quotas and Harbors (tier 1) | Office Hours E, Lobbyist Meeting E, Town Hall at the Harbor D, Media Ambush E, Hearing on Fishery Quotas C | One hearing against one town hall, with three Either rooms | The only Capitol room is the hearing, the Town Hall is at the harbor, the name reads local and the District Representative speaks | **Decided: District, ending at the Capitol** (Cameron) |

## The seven medium-confidence levels (LV61 is now decided)

| Level | Rooms | Why Capitol | Note |
|---|---|---|---|
| LV17 Building the Next-Generation Coalition (tier 1) | Office Hours E, Town Hall D, Policy Study E, Town Hall D, two committees C, Press Conference C, Media Ambush E, Floor Debate C | Four Capitol rooms, a floor debate | Two town halls, but it ends on the floor |
| LV27 Rural Youth Initiative (tier 2) | Office Hours E, Policy Study E, two committees C, Town Hall D, Floor Debate C | Three Capitol rooms, a floor debate | |
| LV44 Constituency Development Grants Act (tier 1) | Town Hall D, Office Hours E, Press Conference C, two committees C, Party Caucus C, Floor Vote C | An Act: it ends in a floor vote | Bill levels are Capitol in all 50 cases |
| LV61 Rail Fares and Timetables (tier 1) | Office Hours E, Town Hall D, Policy Study E, Press Conference C, Hearing on Rail Safety C | Two Capitol rooms against one town hall | **Decided: District, ending at the Capitol** (Cameron), the same shape as LV12 |
| LV70 Fisheries Quota Modernization Act (tier 1) | Office Hours E, Hearing C, Town Hall D, Party Caucus C, Floor Vote C | An Act | |
| LV76 Farm Succession Support Act (tier 1) | Office Hours E, Town Hall D, Hearing C, Party Caucus C, Floor Vote C | An Act | |
| LV81 Local Government Mergers Act (tier 1) | Office Hours E, Town Hall D, Hearing C, Policy Study E, Party Caucus C, Floor Vote C | An Act | |

## The rule your three decisions fit

**A Mixed level with no floor vote or floor debate is District when its constituent-facing rooms (Town Hall, Office Hours) are at least as many as its Capitol rooms.** Checked against all 24 Mixed levels it describes exactly LV12, LV61 and LV62 and touches nothing else; every level with a floor vote or floor debate stays Capitol. It is written down here, not coded: the audit applies your three decisions by level (`DECIDED` in `a1_levels.py`). If you want it as the rule for future Mixed levels, say so and it goes into the build brief for Phase 2.
