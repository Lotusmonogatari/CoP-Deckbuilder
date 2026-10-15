# Japanese text review (2026-10-15)

Scope: every Japanese string in `data/*.json` (the game reads no Japanese from scripts; the only Japanese in the Text tab is the Office accent 陳情). Read for correctness (spelling, grammar, punctuation, word choice) and fitness (does it match the English it sits beside and the rule that Japanese is a small accent next to English).

**Left alone by design (per Cameron):** committee names derived from the game universe author (環境委員会, 戦争委員会, 国会管理委員会, 農林水産委員会, 建設成長委員会, 政府行政委員会, 倫理起訴委員会 and so on), the in-world radio station names (Otaru Radio 今日, 青森の青空109.9!), and the intentional brand names ("ね3" Coffee, "ミレニ姫" Tea).

## Executive summary

| | Count | What it means |
|---|---|---|
| Strings reviewed | about 640 | 54 card names, 6 suits, 30 organisations, 43 backing names, 5 audience groups, 4 meta-variables, 2 cosmetic packages, 59 visitor names, 120 stage names, 5 ticker lines, 3 shop loanwords, 1 Text row |
| **High** | 5 | Broken or nonsensical Japanese a reader will notice (4 ticker lines, 1 missing character in a stage name) |
| **Medium** | 9 | Meaning drifts from the English, inconsistent terms, or a rule break |
| **Low** | 12 | Polish, spelling variants, romaji consistency |
| Confirmed good | the large majority | All 54 card names except the few listed, all suits, boosters, visitor names |

The most important fixes are the **five Japanese-only ticker lines** (four of them are ungrammatical) and **内閣員会** (a missing 委).

## High severity

| # | Where | Current | Problem | Proposed edit |
|---|---|---|---|---|
| H1 | Office Ticker TK17 | 政党は弱くなって続けるので後援会での講演会が予定を交換しています. | Ungrammatical. 弱くなって続ける is not Japanese; 予定を交換 means "swap schedules"; ends in an ASCII period. Probable intent: "party keeps weakening, so kōenkai speaking events are changing their schedules." | 「党勢の衰えが続いているため、後援会での講演会の予定が変更されています。」 |
| H2 | Office Ticker TK18 | 政治家のチームは大事な規定. | A fragment with no verb; 規定 means "regulation", which makes the sentence meaningless. Probable intent: "A politician's team matters." | 「政治家にとって、チームは大切です。」 |
| H3 | Office Ticker TK42 | {player}の後援会は「庶民の成功のための勝利」と言っていました | 庶民の成功 ("success of commoners") is odd; no closing 。; Japanese-only line (see M1). | 「{player}の後援会は「庶民のための勝利」と話しています。」 |
| H4 | Office Ticker TK29 | 政治家が私たちのお金を盗んでいませんか. | Grammatical but ends in an ASCII period and reads as an accusation in the negative form. | 「政治家は私たちのお金を盗んでいませんか？」 (or the softer 無駄遣いしていませんか？) |
| H5 | Stage ST18 name_jp | 内閣員会 | Missing 委: the standard word is 内閣委員会. This is the only committee name that looks like a typo rather than an authorial choice. | 内閣委員会 (confirm with the author) |

TK16 (財務大臣拝眉氏が昨日またサイン会をさせられました.) is grammatical and matches Minister Kitahime Haibi, so only its punctuation changes (see L1).

## Medium severity

| # | Where | Current | Problem | Proposed edit / question |
|---|---|---|---|---|
| M1 | Office Ticker TK16, 17, 18, 29, 42 | Japanese-only sentences | CLAUDE.md §3: Japanese appears only as an accent next to English, never alone. These five lines have no English. | Cameron's call: (a) allow it for in-world radio flavour, or (b) pair each with an English gloss, e.g. `"…" (English line) - Otaru Radio 今日`. Recommend (b) for TK17 and TK42 at least, since they carry plot-relevant news. |
| M2 | Sanban: Reputation (name_jp) | 知名度 | 知名度 means name recognition / fame, not reputation. The design uses Kanban (看板), which Reputation is named after in CLAUDE.md. | 看板 (matches the design) or 評判 (plain "reputation") |
| M3 | Sanban: Funds (name_jp) | 円 | 円 is a currency unit, not the name of a resource; the design's Kaban is 鞄. | 鞄 (matches the design) or 資金 (plain) |
| M4 | Segment SG04 Donors | 支援者 | 支援者 means supporter. Donors are 献金者 / 寄付者 / 後援者. | 後援者 (closest to the kōenkai world) or 献金者 |
| M5 | Stages, 20 topic Party Caucus rooms (ST35, 39, 42, 45, 49, 52, 56, 59, 62, 65, 68, 72, 75, 78, 81, 85, 89, 93, 97, 100) plus ST03 | ST03 is 議員総会; every topic caucus is …党内会合 | Same stage type, two Japanese names. | Pick one. Recommend 議員総会 everywhere, e.g. 原生自然の保護に関する議員総会. |
| M6 | Stages, topic rooms generally | topic + room name with no particle (原生自然の保護党内会合, 公共放送の独立記者会見, 監視カメラテレビ討論, 職場の平等記者会見, 党首選出方法記者会見) | Noun stacks mis-parse: 保護党 reads as "Protection Party", 独立記者 as "independent reporter", カメラテレビ as one word. Hearings, lobbying and town halls already use に関する / を巡る and read fine. | One template for all: 「{topic}に関する{room}」 (記者会見, テレビ討論, 政策検討会, 議員総会) or 「{topic}を巡る住民集会」 for town halls. Example fixes: 公共放送の独立に関する記者会見; 監視カメラを巡るテレビ討論. About 55 rooms; I can regenerate the cells in one pass once the template is chosen. |
| M7 | Stages ST63, 64, 65 | 憲法見直し委員会… | The English topic is "the Constitutional Review" (a process); the Japanese names a committee. Bill BI40 is "Constitutional Review Commission Act", so 委員会 may be intended. | Confirm. If it is the commission: 憲法見直し委員会 stays; if the process: 憲法見直し. |
| M8 | Stage ST07 name_jp and Text row `office.subtitle_jp` | 陳情 | 陳情 = petition. It labels Office Hours (a meeting with visitors) and also the Office screen's heading, where it reads as "Petition". | Office heading: 議員事務所 or 事務所. Office Hours stage: 陳情受付 or 面会. |
| M9 | Modifier M26 | 学生運動ネットワーク | 学生運動 is the historic (1960s) radical student movement; the English is "Campus Organizing Network". | 学生組織ネットワーク |

## Low severity

| # | Where | Current | Note | Proposed edit |
|---|---|---|---|---|
| L1 | Ticker, all Japanese lines | Ends in ".", quotes “ ” | Japanese uses 。 and 「 」; ASCII punctuation looks wrong. Also a stray double space after TK16. | Replace with 。 and 「」 |
| L2 | Office Notices, Shop (SH13 description) | "200,000円", "100,000円" | Number + 円 inside English text, while the rest of the game says "Yen". | "200,000 Yen", or keep as deliberate flavour |
| L3 | Card C04 | 初心表明 | "Return to First Principles": 初心表明 is unusual. | 初心に返る |
| L4 | Card C14 | 資料請求 | 資料請求 means "request a brochure". In the Diet: 資料要求. | 資料要求 |
| L5 | Card C19 | 煽動 | Both 煽動 and 扇動 are used; 扇動 is the current standard spelling. | 扇動 |
| L6 | Card C24 | 密約を持ちかける | 密約 is a "secret agreement", stronger than "Offer a Quiet Assurance". | 内々に請け合う |
| L7 | Card C49 | 不信任を突きつける | 不信任 is a formal no-confidence motion; the English is "Declare Them Unfit". | 資格なしと断じる (or keep, it fits the political register) |
| L8 | Suit 求心 (Appeal) | 求心 | Almost always seen as 求心力; bare 求心 is not a standalone word. | 求心力, or 訴求 for "Appeal". Author's call. |
| L9 | Suit 情熱 (Emotional) | 情熱 | Means passion, which is narrower than "Emotional"; all Emotional cards are passionate, so it works. | Keep; consider 感情 if cards ever turn sad or fearful. |
| L10 | Boosters BO20, BO28 | 神社会; アイヌ協議会 | 神社会 is not a standard term (神社本庁 / 神社連合会). アイヌ民族 is the respectful standard phrase for the people. | 神社連合会; アイヌ民族協議会. The Ainu names are worth a check with the author. |
| L11 | Visitor VI22 | ブラド ちゅんちゅん | "Brad" is ブラッド; ブラド reads "Vlad". | ブラッド ちゅんちゅん |
| L12 | Modifiers M19, M15, M14 | 口利き; 漁協 vs "Fishing Fleet"; 町内会 vs "Community Canvass" | 口利き means brokering favours (corruption flavour); 漁協 is a co-op, not a fleet; canvassing is 戸別訪問. | M19: 橋渡し or 後押し; M15 漁協の船団支援; M14 町内会の戸別訪問 |

## Romaji and spelling consistency (low)

| Where | Observation |
|---|---|
| Visitors VI11 / VI39 | Latin name says "Leo" / "Ray", romaji column says "Reo" / "Rei". Consistent with the Japanese, but pick one spelling for the English name. |
| VI18 | "Chiyo Baachan": long vowel is usually Bāchan. |
| Sanban Funds romaji | "Yen" (English); 円 would be "En". Display choice. |
| BO06 vs BO27 | English "Neighborhood" vs "Neighbourhood" (not Japanese, found in passing). |

## Confirmed correct (no change)

| Group | Notes |
|---|---|
| Card names | 49 of 54 are idiomatic and well matched (記憶にございません, 玉虫色の答弁, 前向きに検討します, 踏み絵, 根回し-style 事前に話を通す, オフレコ and so on). |
| Suits | 誠実, 実証, 分断, 二枚舌 are all natural; romaji correct. |
| Organisations | 28 of 30 names read naturally; romaji correct (macrons right). |
| Segments | 報道陣, 党員, 有権者, 官僚 correct. |
| Stage names (non-committee) | 本会議, 記者会見, 住民集会, 討論番組, ぶら下がり取材 (the correct word for a doorstep interview), ロビー活動, 政策検討会, 本会議採決, 公聴会 all correct. |
| Visitor names | 57 of 59 are valid, plausible names with correct readings, including the Ainu-linked surnames 金成 (Kannari), 知里 (Chiri), 貝沢 (Kaizawa). |
| Shop, packages | 失言 (gaffe) is the exact word; クール・ビズ and 現代の職場 fit. |
| Opponents | No Japanese names exist in `opponents.json` (romanised only), so nothing to review. |

## Questions for Cameron

| # | Question | My recommendation |
|---|---|---|
| 1 | Ticker: allow Japanese-only lines, or add English? | Add English (M1). |
| 2 | Reputation and Funds Japanese: 看板 / 鞄 (the Sanban terms) or 評判 / 資金 (plain)? | 看板 / 鞄, they match the design and the Kanban/Kaban names in the notes. |
| 3 | Topic-room names: use the 「…に関する…」 template everywhere, and use 議員総会 for every caucus? | Yes to both (M5, M6). |
| 4 | 内閣員会: typo, or intentional? | Typo, fix to 内閣委員会. |
| 5 | Constitutional Review: process or commission? | Confirm against BI40. |

Nothing has been changed in the workbook or data; this is a review only.
