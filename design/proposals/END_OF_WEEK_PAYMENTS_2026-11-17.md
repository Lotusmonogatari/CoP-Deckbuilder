# End of Week Payments (design spec, 2026-11-17)

**Status:** draft for Cameron. All wording is a draft for the Text tab.
**Decision (Cameron, 2026-11-17):** the Office's dues display becomes **End of Week Payments**: one total of what the week end will take, made of party dues and staff wages, with both parts shown.

## 1. What it shows

| Line | Value | Source (existing code) |
|---|---|---|
| **End of Week Payments** (total) | Party dues + staff wages | Sum of the two lines below |
| Party dues | This week's dues, including the earned share and any National awareness relief, plus anything still owed | `PartyDues.week_dues()`, the owed balance in `GameState` |
| Staff wages | The sum of every hired person's wage, with the head count | `StaffLoyalty.wage(invested, pay_raised)` per person; `invested_for()` |
| Office funds (beside it, unchanged) | Funds now | `GameState` |

**Example (as drawn in the mockups):** party dues 50,000円, plus two staff each hired at 40,000円 and paid 15% (6,000円 each), gives End of Week Payments of **62,000円**.

## 2. Where it shows

| Place | What changes |
|---|---|
| **Office** (today's `DuesBox`) | Title "End of Week Payments", the total, and one line beneath: "Dues 50,000 · Wages 12,000". Each style draws it its own way (UI Styles spec, 5.1); the content is the same. |
| **Tapping it** | A small breakdown panel: party dues (and any owed balance), then each staff member's name and wage, then the total and Office funds after paying. |
| **Week-end popup** (F01) | The same breakdown *before* the player chooses Work the Weekend or Go Home (Information Standard 1). This is P4 item 1; build them together. |
| **No staff hired** | The wages line reads "Staff wages · none", and the total equals the dues. |

## 3. When Funds are short

The order of payment does not change: dues first, then wages, primary first, then the least loyal (`StaffLoyalty.pay_order`, `settle_wages`; nobody is part-paid). When Office funds are below the total, the box and the breakdown say, before the week ends:
- which payments will go unpaid;
- what each one costs: unpaid dues bring the overdue penalty and locked party backings (Balance rows); a missed wage costs that person Loyalty −20 (Balance `Staff Loyalty`);
- the colour turns to the warning red used elsewhere, and the words say it too.

## 4. Rules

- **No rule or number changes.** This is a display of what `PartyDues` and `StaffLoyalty` already settle.
- **One source of truth.** The preview must call the same functions the week end calls. A test sets up dues, two hires (one with raised pay) and Funds below the total, then checks that the preview equals the settlement line for line.
- **Raised pay** (×1.5) shows on that person's line.

## 5. Proposed Text rows (drafts)

| Key | Draft |
|---|---|
| `office.week_payments_title` | End of Week Payments |
| `office.week_payments_parts` | Dues {dues} · Wages {wages} |
| `office.week_payments_no_staff` | Staff wages · none |
| `office.week_payments_short` | Funds are short by {amount}. Unpaid: {who}. |
| `week_end.breakdown_dues` | Party dues |
| `week_end.breakdown_owed` | Still owed from earlier weeks |
| `week_end.breakdown_wage` | {name}'s wage |
| `week_end.breakdown_wage_raised` | {name}'s wage (raised) |
| `week_end.breakdown_total` | Total |
| `week_end.breakdown_after` | Office funds after paying |

## 6. Done means

- [ ] The Office shows End of Week Payments in every UI style, with the total and both parts.
- [ ] The breakdown appears on tap and in the week-end popup before the choice.
- [ ] The preview-equals-settlement test passes, including a shortfall case.
- [ ] Old Text rows for the dues box are retired through the workbook, not deleted by hand.
- [ ] `GAME_SYSTEMS.md`, the Information Standards table (row "Week end") and `CHANGELOG.md` are updated.
