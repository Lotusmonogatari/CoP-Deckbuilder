# Art prompt template (Coliseum of Parliament)

One template for every kind of picture. Fill the **{slots}**, keep the fixed blocks. `python3 tools/art_prompt.py <kind> <ID> [<ID> ...]` fills the slots it can from the data files (names, roles, parties, stage names) and leaves `{APPEARANCE}`-type slots for you, since looks are your call, not mine. Attach 2-4 finished examples of the same kind with every prompt.

## Quick reference

| Kind | File name | Canvas | Background | Slots you fill |
|---|---|---|---|---|
| Character | `{ID}_{expression}.png` | 1024 x 1536, full body | transparent | APPEARANCE, OUTFIT |
| Card art | `{CARD_ID}.png` | 1024 x 768 | scene | SCENE |
| Background | `{STAGE_ID}.png` | 1080 x 2340 | scene | PLACE, MOOD |
| Icon | `{ID}.png` | 256 x 256 | transparent | SUBJECT, COLOUR |

Expressions to request, in order (neutral first, everything falls back to it): neutral, attacking, guarding, gaining, damaged; optional defeated, victory (protagonists).

## 1. Fixed blocks (paste into every prompt)

**STYLE** (replace with your Midjourney/ComiPo! house style line once, then never change it): `{HOUSE_STYLE}`

**CANON GUARD**: Yezo is a fictional parliamentary nation. No real people, no real party logos, no readable text or letters anywhere in the picture. Real communities or faiths (for example Ainu) get only simple, respectful motifs, no caricature or costume cliches.

**CONSISTENCY**: Same face, hair, build and proportions in every expression of one character. Only the pose and facial expression change.

## 2. Per-kind blocks (use one)

**CHARACTER**
```
Full-body standing portrait of {NAME}, {GENDER}, {ROLE}{, TITLE}, member of {PARTY}.
Appearance: {APPEARANCE}.   Outfit: {OUTFIT}.
Expression and pose: {EXPRESSION_LINE}
Canvas 1024 x 1536 (2:3), head to feet fully in frame, centred, transparent background,
no ground shadow, no props that touch the edge.
```
Expression lines: neutral = relaxed, listening; attacking = leaning in, pointed gesture, about to press the point; guarding = arms folded or hands raised, bracing; gaining = open hand, rallying, confident; damaged = flinching, hand to chest or brow, losing the room; defeated = slumped, eyes down; victory = composed smile, fist or papers raised.

**CARD ART** (the picture in the card window, not the frame)
```
Illustration for the rhetoric card "{CARD_NAME}" ({SUIT} suit, {TYPE}). Effect in plain words: {EFFECT_TEXT}.
Scene: {SCENE}. Suit mood: {SUIT_MOOD}. Canvas 1024 x 768 (4:3), one clear focal point,
readable as a small thumbnail, nothing important in the outer 5%.
```
Suit moods (suggested, edit freely): Earnest = warm, steady light; Emotional = soft, close, intimate; Appeal = open, crowd, bright; Data Driven = clean, cool, ordered; Divisive = hard contrast, sharp angles; Duplicitous = shadow, half-hidden, sly.

**BACKGROUND**
```
Empty room for the stage "{STAGE_NAME}" ({MODE}): {PLACE}. Mood: {MOOD}.
Canvas 1080 x 2340 portrait. No people. Keep the lower third calmer and darker (cards
and buttons sit there) and the upper-middle open (two characters stand in the bottom
corners of the art box).
```

**ICON**
```
Flat vector icon: {SUBJECT}, standing for {MEANING}. Dominant colour {COLOUR}.
```
For icons, use the full ready-made prompt `design/ICON_PROMPT.md` (palette, file checks, NOTES.txt); this slot block is what changes per icon.

## 3. Return checklist (append to any prompt)

- File names exactly as listed; one file per picture; nothing else except NOTES.txt (one line per file: what you drew, anything you could not).
- Correct canvas size; transparent where the table says so; no text, no watermark, no frame.
- Characters: all expressions share one face and outfit.

Check and merge what comes back: icons with `python3 tools/merge_icons.py <folder>`; other kinds go straight into the folder named in `data/art.json`, then `python3 tools/art_checklist.py` and `.tools/godot --headless --import`.
