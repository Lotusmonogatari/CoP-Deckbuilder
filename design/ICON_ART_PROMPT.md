# Prompt for Claude Chat: draft the game's 40 icons

Paste everything below the line into Claude Chat (a fresh chat, with file creation / code execution turned on if you have it).

---

You are drafting placeholder icon art for a mobile card game called **Coliseum of Parliament**, a portrait-mode political card battler set in a fictional parliamentary nation. I am not an artist or a programmer. These are DRAFTS that will be replaced by my own final art later, so aim for clean, readable, consistent, and easy to swap, not fancy.

## The files I need

Make **40 icons** in three groups. The file names are exact: the game finds each picture by its file name, so a wrong name means the icon never appears.

## A. Shop items (20) — file name = the Icon column of the Shop tab

| File | Item | Draw |
|---|---|---|
| `policy_research.png` | Commission Policy Research | a stack of policy papers with a magnifying glass |
| `press_engagement.png` | Commission Press Engagement | a microphone with a small press badge |
| `district_engagement.png` | Commission District Engagement | a map pin standing on a simple town skyline |
| `coffee.png` | “ね3” Coffee | a takeaway coffee cup with a steam curl |
| `tea.png` | “ミレニ姫” Tea | a small teacup with steam |
| `paperwork_automation.png` | Paperwork Automation | a document with a gear in front of it |
| `wristwatch.png` | Wristwatch | a wristwatch seen from the front |
| `meditation.png` | Personalized Dear Colleague Letter | a sealed letter: an envelope with a wax seal (NOTE: the item is a "Personalized Dear Colleague Letter", but the file name says "meditation"; keep the file name, draw the letter) |
| `unlock_card_t1.png` | Unlock Random Tier 1 Card | a playing card with an open padlock and ONE small pip |
| `unlock_card_t2.png` | Unlock Random Tier 2 Card | a playing card with an open padlock and TWO small pips |
| `unlock_card_t3.png` | Unlock Random Tier 3 Card | a playing card with an open padlock and THREE small pips |
| `staff_tier.png` | Staff Training Consultancy Session | a person silhouette with an upward arrow |
| `funds_cap.png` | Office Fund Bank Limit Petition | a coin purse or small safe with a yen coin and an upward arrow |
| `buff_draw.png` | Commission a Speech Trainer | two overlapping cards with a plus sign |
| `buff_energy.png` | Kaiju Sized “ね3” Coffee | a lightning bolt |
| `buff_guard.png` | Automated Dear Colleague Letters | a shield |
| `buff_gaffe_cap.png` | Kaiju Sized “ミレニ姫” Tea | a speech bubble with a small shield on it |
| `buff_turn.png` | AI Powered Clock | an hourglass or clock face with a plus sign |
| `booster_dinner.png` | Host a Dinner for a National Booster | a dinner plate under a serving cloche |
| `walking_tour.png` | Host a District Walking Tour for a Constituency Booster | a pair of footprints leading to a map pin |

## B. Cosmetic packages (2) — the Icon column of the Cosmetic Packages tab

| File | Package | Draw |
|---|---|---|
| `Workplace_Casual.png` | Workplace Casual (a business casual outfit) | a relaxed blazer on a coat hanger |
| `Workplace_Modern.png` | Modern Workplace (an updated office) | a modern glass office building or a large window with a desk |

## C. Organisation icons (18) — file name = the organisation's ID

| File | Organisation | Tier | Draw |
|---|---|---|---|
| `BO01.png` | Party Headquarters (党本部) | Party | headquarters building with a flag |
| `BO02.png` | Party Faction (派閥) | Party | a pennant banner with two small figures |
| `BO03.png` | Local Kōenkai (後援会) | Constituency | a hanging paper lantern (a local support association) |
| `BO04.png` | Mayors' Network (市町村長会) | Constituency | a town hall with a ceremonial sash |
| `BO05.png` | Chamber of Commerce (商工会議所) | National | a briefcase with a coin |
| `BO06.png` | Neighborhood Associations (町内会) | Constituency | a cluster of three small houses |
| `BO07.png` | Fisheries Cooperative (漁協) | Constituency | a fish |
| `BO08.png` | National Media (全国紙) | National | a TV camera or newspaper |
| `BO09.png` | Labor Federation (労働組合連合) | National | a gear with a hard hat |
| `BO10.png` | Agricultural Cooperatives (農協) | National | a sheaf of wheat |
| `BO11.png` | Students United (学生団体) | Constituency | a graduation cap on an open book |
| `BO12.png` | Family Network (子育て世代の会) | Constituency | two simple figures, one adult and one child |
| `BO13.png` | Yezo Artisans Guild (職人組合) | National | a hammer and chisel |
| `BO14.png` | Commuter Committee (通勤者連盟) | Constituency | a front-on train |
| `BO15.png` | Our Traditional Society (伝統保守の会) | National | a shrine gate (torii) |
| `BO16.png` | Innovation Society (革新の会) | National | a light bulb with circuit lines |
| `BO17.png` | Members of Parliament (国会議員) | National | a parliament dome building |
| `BO18.png` | Constituency Voters (選挙区の有権者) | Constituency | a ballot box with a ballot going in |

All 40 files are `.png`, with the exact names above (case-sensitive, underscores, no spaces, no braces).

## Technical requirements (the game requires these)

- **Canvas: 256 × 256 pixels, square, PNG.**
- **Transparent background.** No background square, no frame, no border around the canvas.
- Keep the artwork inside the central ~224 × 224 pixels (about 16 px of empty margin on every side) so nothing is clipped.
- **No text, letters, numbers or Japanese characters inside any icon.** Use symbols only (the tier-1/2/3 card icons use one, two or three small dots, not numerals).
- Do not copy real logos, brands, flags or real people. Everything here is fictional.

## Visibility (how they will be seen)

- The icons are shown on a **very dark navy background** (about #12141C), at roughly **120 pixels wide** in lists and **220 pixels** in item detail views. So each icon must still read clearly when shrunk to 100 px.
- Use **light, bright fills** and a thin **light outline (about 6–8 px at 256 px)** so the shape separates from the dark background. Never rely on black or dark-grey shapes.
- One strong silhouette per icon: a single main symbol, bold simple shapes, minimal interior detail. If a detail disappears at 100 px, remove it.

## Style (one consistent family)

- Flat vector style, slightly rounded corners, no gradients, no drop shadows, no photo-realism.
- Shared palette: off-white #F5F1E6 for outlines and highlights, plus ONE main fill colour per icon from this set: gold #E8C468, teal #4FB3A9, coral #E0715F, sky blue #6FA8DC, soft purple #A78BCA, sage green #8DBB7A.
- Group colour coding:
  - **Shop items (A):** use any colour from the set, but give items that do the same kind of thing the same colour. For example, all the "buff" items share one colour, the three card-unlock items share another, the three Commission items share another.
  - **Organisation icons (C):** colour by tier: **Party = gold**, **Constituency = teal**, **National = coral**.
  - **Cosmetics (B):** soft purple.

## How to deliver

1. First, in one short table, show me your plan: one line per file with the main colour you will use. Wait for me to say "go" only if something above is unclear; otherwise continue straight on.
2. Draw each icon as **SVG** with `viewBox="0 0 256 256"` and no background rect.
3. If you can run code or create files: render every SVG to a **256 × 256 transparent PNG** with the exact file name above, and give me all 40 PNGs together (a single .zip is ideal). Verify each one is exactly 256 × 256 with a transparent background before giving it to me.
4. If you cannot create files: give me the 40 SVGs as separate, clearly labelled code blocks named exactly like the PNG (for example `coffee.svg`), and tell me the exact command to convert them, for example `rsvg-convert -w 256 -h 256 coffee.svg -o coffee.png`, or the free ImageMagick equivalent.
5. Do the work in batches of about 10 if it helps quality. Show me a contact sheet (all icons on a dark #12141C background at 120 px) after each batch so I can judge visibility.
6. At the end, list anything you were unsure about, and flag any two icons that look too alike at 100 px.

## Where the files go (for my reference)

Put the PNGs in the game's `assets/icons/` folder. Nothing else needs to be done; the game picks them up by name. Anything missing just shows a placeholder.
