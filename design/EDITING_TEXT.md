# Editing the writing

Every word the game says comes out of `design/CoP_Starter_Card_Stage_Data.xlsx`.
Nothing is typed into the code. This says which tab holds what, and what to
run afterwards.

---

## The one command

After **any** edit to the workbook:

```
python3 tools/export_data.py
```

It rewrites `data/*.json` and prints a report. Read the last line:

| It says | What to do |
|---|---|
| **No errors** | You are done. |
| **Wording: …** | Your wording changed. If that was deliberate, run it again with `--accept-wording` (below). |
| **N ERROR(S)** | It names the tab and the row. Nothing was written to the game until you fix it. |

---

## Quick reference

| What you want to reword | Tab | Column |
|---|---|---|
| A card's name | **Cards** | Name (EN), Name (JP) |
| What a card's rules text says | **Cards** | Effect text |
| What a card says out loud when played | **Flavor Text** | Cue 1 – Cue 5 |
| A question a reporter or lobbyist asks | **Press Questions** and its four siblings | Question |
| Which organisation a question's theme belongs to | **Question Themes** | Organisation |
| How well each suit answers a question | the five question tabs | Earnest … Duplicitous |
| Anything else on any screen | **Text** | English |
| A level's description | **Levels** worksheet | Level Description |
| The four standing names | **Sanban** | ask first — see the warning below |

---

## 1 · Screen wording — the **Text** tab

Everything the game says that is not a card, a question or a level line: the
buttons, the outcome panel, the room brief, the shop refusals, the narration
after a card lands. The Text worksheet is the source for these catalog strings.

| Column | What it is |
|---|---|
| **Key** | The name the code asks for. **Never change this.** |
| **Where** | Which screen it appears on. Yours, for finding things. |
| **English** | The words. This is the one you edit. |
| **Placeholders** | Which `{things}` this line may use. |
| **Notes** | Anything worth knowing about this line. |

**Placeholders** are the bits the game fills in. In

```
Turn {turn} of {total}
```

`{turn}` and `{total}` are replaced with real numbers. You may **move** them
and **write around** them freely:

```
Turn {turn} of {total}          →  {turn} / {total}
                                →  Turn {turn} — {total} in all
```

You may **not** invent a new one. A `{whatever}` the game does not fill in
appears on screen exactly as you typed it, which is ugly and obvious, so you
will see it immediately.

**Plurals.** Where a line reads differently for one and for many, it is two
rows with `.one` and `.other` on the end of the key:

```
narration.gaffe.one     1 gaffe on your record
narration.gaffe.other   {count} gaffes on your record
```

The code asks for `narration.gaffe` and the right one is picked. Where one
wording serves both — `{count} XP` — one row is enough.

**Adding a line.** A new row that no code asks for does nothing: the export
notes it and moves on. Ask for the line to be wired up.

**Deleting a line** the code still asks for is an **error**, and the export
names the file and line number that wanted it. Nothing is written until you
put it back.

---

## 2 · Cards — the **Cards** tab

Name, Japanese name, and **Effect text**. Effect text is the sentence printed
on the card face when nothing more specific is known; the screen usually
shows what the card will actually do in the room you are standing in, worked
out from the numbers, which is why rewording Effect text often does not
change what you see in play. That is deliberate — the card showed a promise
the rules did not keep, once.

The numbers beside it (`Self +`, `Opp −`, cost, and so on) are rules, not
wording. Changing one changes the game.

---

## 3 · What a card says out loud — the **Flavor Text** tab

Five spoken lines per card, in **Cue 1** to **Cue 5**. One is said when the
card is played.

- Under ten words. The **Max words** column turns red at ten.
- The **Tone Guide** tab has your own rules for these: universal setting, no
  time references, no invented history, not a reply.
- The Card ID, Name and Suit columns on the left are copies for reference.
  Leave them; edit the cues.

A card with fewer than five is fine — it uses what is there. A card with none
says nothing and goes straight to what it did.

If a line is ever recorded, its filename goes in `data/sounds.json` under
`speech → PROTAGONIST → C01_1` (card, then which cue). The game already asks
for it at the right moment.

---

## 4 · Questions — the five question tabs

**Press Questions**, **Town Hall Questions**, **Lobbyist Questions**,
**Study Session Questions**, **Media Ambush Questions**. Twenty each.

| Column | What it is |
|---|---|
| **Q ID** | Its name. Keep it unique within the tab. |
| **Question** | What is asked. Edit freely. |
| **Theme** | One word. This is what decides **which organisation** cares — see §5. |
| **Earnest … Duplicitous** | `S`, `M` or `W` for each suit. |
| Strong suits, Words, Sample answers | Your own checks. The game ignores them. |

**What the grades do:**

| Grade | Answering in that suit |
|---|---|
| **S** | Pleases the organisation behind the question. Standing carries between levels. |
| **M** | Nothing either way. |
| **W** | Costs press tone — `weak_answer_tone_cost` in `data/stage_types.json`. |

A grade that is not S, M or W is an **error** and the export names the
question.

**Adding a question** is one row. The current project has 20 questions per
question worksheet. Adding rows changes the available question pool; it does
not by itself change how many questions a room asks. Check the current stage
configuration and code before changing that behavior; this workbook does not
define a general `questions_count` field.

> The **town hall's** question bank is present, but the current Town Hall stage
> type does not ask those questions.

---

## 5 · Who cares about a question — the **Question Themes** tab

69 themes, each mapped to an existing booster organization. **This mapping is
a draft for review.** The **Why** column explains the reasoning, so a row can
be reviewed without reading every related question.

- **Organisation** must be a booster ID that exists in the current workbook.
  Anything else is an error at export.
- Change a theme's organisation and every question with that theme follows.
- A theme with no organisation is a **warning**: answering those well pleases
  nobody.

---

## 6 · Level descriptions — the **Levels** worksheet

The Levels worksheet contains the canonical level descriptions and stage
references. `data/levels.json` is generated from that worksheet; do not edit
the JSON directly. Run the exporter after workbook changes. The currently
used playtest level has a separate hand-maintained configuration in
`data/playtest_level.json`.

---

## 7 · The four names that are **not** just wording

**Constituency support**, **Reputation**, **Funds** and **Party support**
live in the **Sanban** tab. They are shown on screen *and* they are how the
code finds each variable.

Renaming one in the Sanban tab alone disconnects the code from the variable,
so the export **refuses** and names which files use it. This is on purpose.
If you want one renamed, say so and it will be changed in both places
together.

---

## 8 · Changing wording on purpose

The test suite holds a copy of every line as it last read, in
`tests/wording_snapshot.json`. This is what catches a **code** change that
quietly alters what the player reads.

When **you** reword something, the export tells you:

```
Wording: 'outcome.carried' now reads "Passed" (was "Carried")
Wording: if those were your edits, run
         'python3 tools/export_data.py --accept-wording' to record them
```

Run that, and the change is recorded. The repository then shows exactly
which lines you changed and to what.

If you skip it, nothing breaks in the game — only the test suite complains,
naming the line.

---

## 9 · When something goes wrong

| What you see | What it means |
|---|---|
| A word in curly brackets on screen, like `{count}` | A placeholder the game does not fill in for that line. Check the Placeholders column. |
| A dotted name on screen, like `outcome.carried` | That Key has no English. The export would normally refuse, so this means the game is running on older data — re-export. |
| The export says **ERROR** | Nothing was written. Fix what it names and run it again. |
| The game looks unchanged after an edit | The export was not run, or it errored. Run it and read the last line. |

Everything in one go, including the tests:

```
python3 tools/export_data.py
tools/verify.sh
```
