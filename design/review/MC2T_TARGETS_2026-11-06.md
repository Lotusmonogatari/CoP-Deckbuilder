# Touch-target audit

405 visible tappable controls on 21 screens and panels. Base width 1080 px = a phone's full width; at 390 pt, 412 dp and 360 dp that makes one base pixel 0.361 pt, 0.381 dp and 0.333 dp, and on a 68 mm wide phone 0.063 mm. The smaller side of each target is judged.

## Thresholds in base pixels

| Standard | Minimum | In base px | Millimetres |
| --- | --- | --- | --- |
| iOS 44 pt | 44 | 122 | 7.7 |
| Material 48 dp (412 dp phone) | 48 | 126 | 7.9 |
| Material 48 dp (360 dp phone) | 48 | 144 | 9.1 |
| WCAG 24 px (412 dp phone) | 24 | 63 | 4.0 |

## By screen

| Screen | Targets | Smallest side (px / dp@412) | Median (px) | Under iOS 44 pt (<122 px) | Under WCAG 24 px (<63 px) |
| --- | --- | --- | --- | --- | --- |
| Office | 6 | 100 / 38 | 100 | 5 (83%) | 0 |
| Office > levels | 80 | 90 / 34 | 90 | 79 (98%) | 0 |
| Office > marketplace | 33 | 90 / 34 | 90 | 29 (87%) | 0 |
| Office > staff | 28 | 90 / 34 | 90 | 27 (96%) | 0 |
| Office > backing | 60 | 90 / 34 | 90 | 59 (98%) | 0 |
| Office > deck | 42 | 80 / 31 | 80 | 41 (97%) | 0 |
| Office > record | 7 | 100 / 38 | 100 | 6 (85%) | 0 |
| Office > administration_menu | 15 | 90 / 34 | 100 | 14 (93%) | 0 |
| Office > reputation_menu | 12 | 100 / 38 | 100 | 11 (91%) | 0 |
| Office > organisations | 7 | 100 / 38 | 100 | 6 (85%) | 0 |
| Office > parties | 13 | 90 / 34 | 100 | 12 (92%) | 0 |
| Office > events_list | 16 | 90 / 34 | 90 | 15 (93%) | 0 |
| Office > rhetoric_training | 10 | 90 / 34 | 100 | 9 (90%) | 0 |
| Office > draft a bill | 35 | 90 / 34 | 90 | 34 (97%) | 0 |
| Battle | 9 | 34 / 13 | 336 | 4 (44%) | 1 |
| Battle > details | 13 | 34 / 13 | 80 | 8 (61%) | 1 |
| Office Hours (a dilemma) | 5 | 90 / 34 | 110 | 5 (100%) | 0 |
| Level Intro (first line) | 1 | 110 / 42 | 110 | 1 (100%) | 0 |
| Level Intro (stance) | 5 | 75 / 29 | 90 | 5 (100%) | 0 |
| Floor Vote | 3 | 100 / 38 | 100 | 3 (100%) | 0 |
| Floor Vote result | 5 | 75 / 29 | 100 | 5 (100%) | 0 |

**378 of 405 targets (93%) are below the iOS 44 pt minimum.**

## By kind of control

| Control | Count | Smallest side px (dp@412) | Median px | Under iOS 44 pt |
| --- | --- | --- | --- | --- |
| Button | 393 | 75 (29) | 90 | 376 |
| CardView | 10 | 336 (128) | 336 | 0 |
| HandScrollBar | 2 | 34 (13) | 34 | 2 |

## The 20 smallest distinct controls

| Screen | Control | Text or name | Size px (w x h) | Smaller side dp@412 | mm |
| --- | --- | --- | --- | --- | --- |
| Battle | HandScrollBar | HandScrollBar | 1000 x 34 | 13 | 2.1 |
| Battle | Button | Inventory | 215 x 75 | 29 | 4.7 |
| Battle | Button | Details | 159 x 75 | 29 | 4.7 |
| Battle > details | Button | Room rules | 900 x 75 | 29 | 4.7 |
| Battle > details | Button | Back | 900 x 75 | 29 | 4.7 |
| Level Intro (stance) | Button | Read the Bill | 272 x 75 | 29 | 4.7 |
| Floor Vote result | Button | Back to the Office | 900 x 75 | 29 | 4.7 |
| Office > deck | Button | ✓  1  Sincere Answer | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | View | 190 x 80 | 31 | 5.0 |
| Office > deck | Button | –  2  Impassioned Speech | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  2  Call for Unity | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  1  Document Request | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | –  2  Agitation | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  1  Shifting the Issue | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  2  Point to the Promise Kept | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  1  Rally the Faithful | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  2  Righteous Anger | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  2  Voice of the Hometown | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  1  Ask Who's With You | 798 x 80 | 31 | 5.0 |
| Office > deck | Button | ✓  1  Check Their Facts | 798 x 80 | 31 | 5.0 |
