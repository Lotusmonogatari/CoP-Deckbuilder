# Opponents and their party's position on a bill (2026-11-04)

## Executive summary

| Question | Finding |
|---|---|
| Did opponents contradict their party? | Yes, routinely. Bill lines were chosen by speaking style only. Each style's lines mixed sides: of 4,500 bill lines, 38% argue Against the bill, 16% For it and 46% are neutral. So any opponent could profess either side. |
| How often? | Across the 50 bill levels, opponents could be seated 2,047 times: 732 from parties Supportive of that bill (who could say Against lines), 471 from Opposed parties (For lines), 384 from Neutral parties and 460 with no party. |
| Party leaders | 80 leader appearances in bill rooms (for example the Keizaijiyuutou leader Teinei Macmillan on a Finance committee), with the same mixed lines. Their party's own Floor Vote line never appeared. |
| Fix | Every bill line now carries a Side. Opponents say only neutral lines and their own side's. Leaders also say their party's Floor Vote line. Members of a Neutral party, or one where 30%+ of seats abstain, take a personal side rolled from the party's own Aye/Nay/Abstain split. |

## The rule (`scripts/rules/MemberStance.gd`)

| Who | May say |
|---|---|
| Party leader | Neutral lines + their party's side (none if Neutral) + their party's Floor Vote line for the bill |
| Member, party Supportive or Opposed | Neutral + For, or Neutral + Against |
| Member, party Neutral or 30%+ abstaining | Neutral + a personal side rolled from the party's Aye/Nay/Abstain split for that bill, fixed per member and bill. An abstainer gets Neutral only. |
| No party (journalists, lobbyists, staff of organizations) | Their organization's side on the bill (from its stakeholders), else Neutral |

**Lever:** Balance tab, "Member Stance: Split Party Abstain Percent" (30).

## Data

- **Opponent Cues:** five new columns, Cue 1 Side to Cue 5 Side (For, Against or blank). I classified the 900 bill rows and 1,080 bill-part rows as drafts from their sentence frames:
  - Bill rows: 1,704 Against, 716 For, 2,080 Neutral.
  - Bill-part rows: 3,601 Against and 1,799 Neutral. There are no For lines, because the player sponsors these bills.
- **Exporter:** a Side value other than For, Against or blank is an error.

## Tests

- `test_member_stance.gd`:
  - Party side, leader, Neutral-party leader, split parties, a fixed roll, organization side, and the leader line.
  - A real-data audit of every bill level, everyone seated there, every style and move: no line on the opposite side.

## Thin spots (not changed)

- **Pure neutral speakers:** where a speaker may say only neutral lines (a Neutral leader, an abstaining member), a style and move often has only 1 or 2 bill lines, so they will repeat. This covers 476 of 900 bill/style/move combinations.
- **No bill line at all:** 71 combinations for neutral-only speakers, and 28 for For-side speakers. They fall back to the person's general lines, which are not about the bill.
- **Fix if wanted:** more neutral and For lines per bill.
