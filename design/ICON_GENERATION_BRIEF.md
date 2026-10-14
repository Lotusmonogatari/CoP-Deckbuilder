# Brief: draw the 12 missing organisation icons (BO19 to BO30)

Written for a Claude (or any illustrator) producing the images. Return the files exactly as described in section 5 so they merge with one command.

## 1. What is needed

Twelve icons, one per organisation. The other 18 organisations (BO01 to BO18), all 20 shop items and both cosmetic packages are already drawn. Nothing else is missing.

| File | Organisation | What it stands for | Suggested picture (one clear object, no text) | Main colour |
|---|---|---|---|---|
| BO19.png | Buddhist Temples Association | Temple community, Buddhist tradition | A pagoda (three or five tiers) or a temple bell | gold |
| BO20.png | Shrine Association | Shinto shrine community, festivals | A shrine rope (shimenawa) with paper streamers, or a small shrine gate with a lantern (not the same torii as BO15) | orange-red |
| BO21.png | Care and Welfare Council | Social care, nursing, elder and disability support | Two hands holding a heart, or a hand supporting a small house | teal |
| BO22.png | Veterans' Association | Former service members, defence families | A folded flag on a stand with a single star, or a medal on a ribbon | maroon and gold |
| BO23.png | Taxpayers' Alliance | Low tax, public spending scrutiny | A coin purse with a magnifying glass, or a receipt with a coin | orange-red |
| BO24.png | Financial Industry Association | Banks, markets, investment | A rising bar chart over a bank building, or a stack of coins with an upward arrow | teal |
| BO25.png | Small Business Owners' Association | Shopkeepers, family firms | A small shopfront with an awning and an open sign (no readable text) | gold |
| BO26.png | Consumer Advocacy Network | Prices, product safety, consumer rights | A shopping basket with a check mark, or a price tag with a shield | teal |
| BO27.png | Urban Neighbourhood Alliance | City residents, housing, transit | Tall apartment blocks with a few lit windows and a tree | orange-red |
| BO28.png | Ainu Community Council | Ainu community and rights | A carved wooden mat or robe pattern (Ainu interlocking spiral and scroll motif) on a simple banner | maroon and teal |
| BO29.png | Ainu Language and Culture Foundation | Language teaching, cultural heritage | An open book with a spiral motif on the page, or a speech bubble with a spiral | gold |
| BO30.png | Rural Revitalization Council | Villages, depopulation, local renewal | A farmhouse with a young sprout or a signpost pointing to a village | teal |

Treat the suggested picture as a starting point. Change it if a clearer silhouette exists, but keep it to one subject, readable at 64 px, and respectful: the Ainu icons use the community's real motifs as simple decoration, with no caricature, no costume cliches and no text.

## 2. Style (match the existing set exactly)

Look at `design/reference/org_icon_style_sheet.png` (the 18 finished organisation icons on a dark background). Also look at any file in `assets/icons/` (for example `BO05.png`, `BO08.png`, `BO16.png`, `coffee.png`).

- **Flat vector look**: solid colour shapes, no gradients, no outlines drawn as black lines, no texture, no photographic detail. Edges are clean and slightly rounded.
- **Two-tone shading**: each shape has a base colour and one darker shade on its lower or right edge (like a thick bevel), plus one lighter lavender-blue highlight on selected edges. No more than three tones per object.
- **One sparkle**: a small white four-point star near the upper left of the main object, as every existing icon has. Keep it small.
- **Cream trim**: bases, rims and frames are cream (`#FFF4DC`), as on the Chamber of Commerce briefcase and the pavilion steps.
- **Palette** (use only these, taken from the existing icons):

| Role | Colour |
|---|---|
| Cream (trim, paper, base) | `#FFF4DC` |
| Teal (main) | `#36A99C` |
| Deep teal (shade) | `#1B5F73` |
| Orange-red (main) | `#E8643F` |
| Maroon (shade for orange-red) | `#8E2F4A` |
| Gold (main) | `#F2B544` |
| Bronze (shade for gold) | `#B8691F` |
| Lavender (highlight) | `#A9B6E6` |
| Sky blue (glass, water) | `#5B9BE0` |
| Leaf green (plants only) | `#7DB650`, shade `#2F6B45` |
| White (sparkle, small marks) | `#FFFFFF` |

- **One dominant colour per icon** (the "Main colour" column) with cream and one accent. Neighbouring icons in a list should not all look the same, so the column above alternates on purpose.
- **No background, no circle, no frame, no drop shadow, no text, no numbers, no letters.**
- **Composition**: one centred object or a tight group, filling about 85 percent of the canvas. A small secondary detail (the cloud, a second figure) is fine, as in BO01 and BO12.

## 3. Technical requirements

- **PNG, 256 x 256 pixels, RGBA, transparent background** (the four corners must be fully transparent).
- Artwork inside a 16 px safe margin on every side (nothing touches the edge). The existing icons occupy roughly x 16 to 238 and y 18 to 235.
- Straight (non-premultiplied) alpha with smooth antialiased edges. No semi-transparent halo of a background colour around the shapes.
- 8-bit colour, no embedded colour profile needed. File size normally under 40 KB.
- File name exactly `BO19.png` to `BO30.png`, upper-case BO, no suffix, no spaces.

## 4. If you can only produce vector or large images

- SVG is fine as an intermediate: draw on a 256 x 256 viewBox and rasterise to PNG at exactly 256 x 256 (no scaling afterwards).
- If a generator only produces 1024 x 1024 or other sizes with a background, remove the background first, crop to the artwork, then resize to fit inside 224 x 224 and centre it on a 256 x 256 transparent canvas. Do not stretch.

## 5. How to hand the files back (so they merge)

1. Put the twelve PNGs in one folder, named as above, nothing else in it.
2. Add a file `NOTES.txt` in the same folder: one line per icon with the object you chose (for example `BO19: five-tier pagoda`). Mention anything you could not draw as planned.
3. Give the folder to the programmer (zip is fine). The programmer runs:

```
python3 tools/merge_icons.py <folder>            # checks every file, copies nothing if any fails
python3 tools/merge_icons.py <folder> --apply    # copies into assets/icons/ and refreshes the art checklist
```

The checker rejects a file that is not 256 x 256 RGBA, has opaque corners, touches the edge, uses a colour far outside the palette, or has a wrong name. It prints a table of what passed or failed and why, so a failed icon can be redrawn individually.

After merging, the programmer runs the Godot import so the game sees them. No data change is needed: the game already looks for `assets/icons/BO19.png` to `BO30.png` and shows a labelled placeholder until they exist.

## 6. Before you start, check

- [ ] Opened the style sheet and at least three existing icons.
- [ ] Each icon is one readable subject at thumbnail size (view it at 64 px).
- [ ] Only palette colours; one dominant colour; one sparkle.
- [ ] No text, no background, corners transparent, 16 px margin.
- [ ] Twelve files, correct names, `NOTES.txt` included.
