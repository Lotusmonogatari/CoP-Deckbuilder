# Card art prompts for Midjourney (2026-10-21)

## Executive summary

| Item | Detail |
|---|---|
| Cards covered | All 70 (none has drawn art yet; every card shows the shared placeholder) |
| Canvas | 4:3 landscape, `--ar 4:3` (the card art template asks for 1024 x 768) |
| Style line | One shared line on every prompt so the set reads as one deck; change it once in the table below and in each prompt together |
| Mood | One light and colour cue per suit, so suits are recognisable at thumbnail size |
| Safety | Every prompt carries `--no text, letters, watermark, logos`; no real people, no readable words; faces are generic legislators |
| Files | Save each as `assets/cards/art/{CARD_ID}.png` (1024 x 768), then `python3 tools/art_checklist.py` and `.tools/godot --headless --import` |

**Style line (on every prompt):** `anime-inspired painterly illustration, cinematic lighting, single clear focal point`  
**Parameters:** `--ar 4:3 --no text, letters, watermark, logos`  
Tip: attach two or three approved cards as `--sref` references once the first ones are chosen, to keep the set consistent.

## Suit moods

| Suit | Mood cue |
|---|---|
| Earnest | warm steady golden light |
| Emotional | soft intimate warm glow, close framing |
| Appeal | open bright welcoming daylight |
| Data Driven | clean cool blue light, ordered |
| Divisive | hard contrast, sharp angles, red accents |
| Duplicitous | deep shadow, half-hidden, amber lamp |

## Earnest

| Card | Name | Prompt |
|---|---|---|
| C01 | Record of Service | `a legislator holding a worn binder of their work, sunlit office, an honest gaze, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C02 | Sincere Answer | `a legislator answering with open palms and steady eyes, warm light, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C03 | Formal Apology | `a legislator bowing deeply at a podium, a hushed chamber, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C04 | Return to First Principles | `a legislator before a framed founding charter with no readable text, morning light, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C25 | Point to the Promise Kept | `a legislator pointing through a window at a finished new school, grateful townspeople, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C26 | Own the Mistake | `a legislator alone at a lectern, shoulders squared, admitting an error, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C27 | Appeal Across the Aisle | `a legislator extending a hand across the chamber aisle to an opposing member, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C28 | Read the Letters Aloud | `a legislator reading handwritten letters from citizens, a pile of envelopes, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C29 | Appeal to Conscience | `a legislator with a hand on heart before the chamber, a shaft of sunlight, warm steady golden light, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |

## Emotional

| Card | Name | Prompt |
|---|---|---|
| C05 | Impassioned Speech | `a legislator mid-speech with an outstretched arm, a packed chamber, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C06 | Tearful Appeal | `a legislator with tears and a hand at the chest, speaking to constituents, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C07 | Rousing Applause | `a chamber on its feet applauding, warm light, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C08 | Speech from the Soul | `a legislator speaking with closed eyes, golden light streaming, a rapt audience, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C30 | Rally the Faithful | `a legislator before party supporters, fists in the air, flags with no writing, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C31 | Righteous Anger | `a legislator slamming a hand on a lectern, flushed with anger, stormy light, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C32 | Raise Your Voice | `a legislator shouting over a noisy chamber, mouth wide, papers flying, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C33 | Refuse to Yield | `a legislator standing firm while others turn away, one against many, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C34 | Bring the Room to Its Feet | `an audience rising together like a wave, the speaker with open arms, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C59 | Let It Go | `a legislator releasing a crumpled page that floats away, a relieved smile, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C60 | A Fresh Start | `a legislator opening a window at dawn, a clean notebook on the desk, hopeful, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C67 | Give Everything | `a legislator holding out empty hands offering everything, tearful, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C68 | Words From the Soul | `a legislator speaking with a ribbon of light rising from the chest carrying the words, soft intimate warm glow, close framing, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |

## Appeal

| Card | Name | Prompt |
|---|---|---|
| C09 | Call for Unity | `legislators of one party standing shoulder to shoulder with raised joined hands, party benches behind, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C10 | Voice of the Hometown | `a legislator speaking to townsfolk in a small town square, shopfronts and a bell tower behind, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C11 | Work the Room First | `a legislator shaking hands and whispering with colleagues in a marble lobby before a session, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C12 | Ask Who's With You | `a legislator turning to survey a packed chamber, several hands raised in support, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C35 | Invoke Party Discipline | `a stern party whip with a raised finger, colleagues in a row of seats sitting up straight, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C36 | Offer a Private Word | `two legislators talking quietly in a corridor alcove, one leaning in, warm lamplight, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C37 | Call for Common Cause | `legislators from both sides of the aisle reaching across to join hands in an open chamber, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C38 | Call In a Favor | `a legislator opening an old ledger of favors, a grinning colleague nodding, cosy office, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C39 | We Have the Votes | `a legislator holding a tally sheet aloft, smiling majority benches glowing behind, open bright welcoming daylight, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |

## Data Driven

| Card | Name | Prompt |
|---|---|---|
| C13 | Present the Stats | `a legislator at a podium pointing to a large clean bar-chart screen, no readable numbers, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C14 | Document Request | `a stack of folders passed across a desk to a clerk, stamped forms, tidy office, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C15 | Pursue the Contradiction | `two documents side by side joined by a red thread between mismatched passages, magnifying glass, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C16 | Table the White Paper | `a thick bound report slammed onto a long committee table, papers fluttering, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C40 | Question the Funding | `a wall flowchart of arrows showing money moving between boxes, a legislator tracing it with a finger, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C41 | Set the Record Straight | `a legislator at a microphone holding a corrected document, stacks of fact sheets beside, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C42 | Press for a Straight Answer | `a legislator leaning over a lectern with a sharp stare, pen pointed like a question, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C43 | Check Their Facts | `a researcher comparing a transcript with a reference book under a desk lamp, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C44 | Demand an Outside Review | `a panel of neutral auditors in plain suits entering a room with briefcases, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C55 | Trim the Appendix | `scissors trimming excess pages from a thick report, a neat pile of cut paper, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C56 | Review the Record | `a legislator between rows of archive shelves reading an open file under a lamp, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C63 | Compile the Dossier | `a thick dossier being assembled, clipped documents and pinned photographs joined by string on a corkboard, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C64 | The Full Audit | `auditors around a long table with ledgers and calculators, every drawer open, clean cool blue light, ordered, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |

## Divisive

| Card | Name | Prompt |
|---|---|---|
| C17 | Labeling | `a legislator pinning a bold coloured tag on an opponent silhouette, a divided crowd behind, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C18 | Drawing Battle Lines | `a chalk line drawn across a chamber floor, two groups facing each other, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C19 | Agitation | `a legislator on a crate before an agitated crowd, raised fists, banners with no writing, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C20 | Loyalty Test | `a legislator holding out a paper to a hesitating colleague, tense stares, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C45 | Name and Shame | `a spotlight pinning one lone figure while others point, sharp shadows, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C46 | Force the Choice | `a legislator gesturing at two doors, one red and one blue, a crowd forced to choose, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C47 | Question Their Loyalty | `a legislator pointing along party benches, suspicious faces turning, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C48 | Media Appeal | `a legislator speaking into a bank of microphones, camera flashes, hard lighting, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C49 | Declare Them Unfit | `a legislator pointing at an empty chair with a cracked nameplate, accusing gesture, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C57 | Burn the Draft | `a draft bill burning in a metal bin, glowing sheets, a defiant legislator, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C58 | Cut Your Losses | `a legislator cutting a rope that holds a heavy anchor, the anchor sinking, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C65 | Burn the Bridge | `a small wooden bridge burning behind a legislator who walks away, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C66 | No Quarter | `a legislator with a hard stare standing over a toppled chair, papers falling like rain, hard contrast, sharp angles, red accents, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |

## Duplicitous

| Card | Name | Prompt |
|---|---|---|
| C21 | Iridescent Answer | `a legislator speaking with a shimmering opalescent aura, an ambiguous gesture, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C22 | "I Have No Recollection" | `a legislator with a vague bewildered look and a hand to the head, tall stacks of files behind, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C23 | Shifting the Issue | `a legislator swinging a big signpost to point another way, a distracted crowd, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C24 | Offer a Quiet Assurance | `a legislator murmuring to a business supporter in a private dining room, an envelope on the table, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C50 | Take It Under Advisement | `a legislator nodding politely while sliding a bulging file drawer shut, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C51 | Feed the Press a Line | `a legislator whispering to a reporter by a pillar, a notebook, distant camera flash, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C52 | Drown Them in Detail | `a desk buried under mountains of paper, an overwhelmed official behind it, a smiling legislator, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C53 | Tell the Room What It Wants | `a legislator mirrored by a crowd, a reflection with a different face, applause, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C54 | Off the Record | `a legislator covering a recorder with a hand, a smoky side room, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C61 | Shuffle the Papers | `hands shuffling files and papers fast on a desk, sheets flying, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C62 | Lose the Evidence | `a file folder slipping into a shredder while a hand hides a document behind a back, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C69 | The Quiet Deal | `two figures shaking hands under a table, a dim lamp, a folded paper, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
| C70 | Back-Room Bargain | `silhouetted figures around a card table in a smoky back room, stacks of chips, deep shadow, half-hidden, amber lamp, anime-inspired painterly illustration, cinematic lighting, single clear focal point --ar 4:3 --no text, letters, watermark, logos` |
