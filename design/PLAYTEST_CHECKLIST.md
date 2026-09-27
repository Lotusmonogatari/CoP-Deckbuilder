# Manual playtest checklist

For the class of bug no automated test can catch (see
`design/MECHANIC_COVERAGE.md`'s "Content-shaped bugs" section): a GUT
test proves a rule against fabricated data, a click test proves a screen
opens and closes — neither one looks at whether real content, at its real
size, on a real 1080×2340 screen, actually reads right. Every one of this
session's nine playtest bugs (the `<null>` title, the 20-question press
conference, the text running off the edge...) was exactly this: correct
rule, correct screen, wrong once real content filled it in.

**How to use this**: one pass per stage *type*, not all 23 stages — the
bug classes repeat by type (a long title breaks the header the same way
whichever committee it is), not by individual stage. Each line is a
concrete action and what "wrong" looks like, not "test the shop." Run it
on a real phone or emulator if you can; a desktop window at 1080×2340 is
the fallback (`window/size/window_width_override` in `project.godot`
already shrinks it to fit a monitor).

Check the box, or write the bug straight into it if something's off —
this file is meant to be marked up, not kept pristine.

## New Game → first level

- [ ] Fresh install (or delete `user://savegame.json`): the New Game
  protagonist picker opens, not a blank screen or a crash.
- [ ] Pick a protagonist. The Office shows their real name and party in
  the header, not a placeholder.
- [ ] Open a level's briefing ("Look it over"). Every stage name is
  readable, no `<null>`, no text overflow. "If you lose:" lines appear
  under stages that have loss penalties and read sensibly.
- [ ] Press "Go in". You land on the real first stage.

## One pass per Combat stage shape

**Single opponent, shared-pool bar** — any Party Caucus/Town Hall/Lobbyist
level.
- [ ] Header: room name + Japanese accent + "Turn X of Y" all fit without
  overlapping or running off the right edge.
- [ ] Opponent name/title reads right — no `<null>`, no run-on sentence
  from someone holding several titles.
- [ ] Bar caption says "N to win" with the real threshold; the bar itself
  visually matches "You / Undecided / Them" once you've played a card.
- [ ] Energy pips: play a level-buff (Extra Energy) mid-stage if you have
  one, confirm the pips wrap onto a second row rather than pushing
  Inventory/Details off-screen.
- [ ] Win it and lose one (restart if needed) — the outcome panel's
  wording and rewards/penalties both read right, and the button says the
  correct next step ("On to the next stage" vs. "Back to the Office").

**Committee sequence** — LV09, Filling in at Committees (ST01, stage 1).
- [ ] The "N of M" caption counts opponents correctly as you beat each one.
- [ ] Support/gaffes/guard/hand genuinely reset between opponents — no
  gaffe carried over from the last one.
- [ ] Losing partway through still ends the whole committee, not just
  that one opponent.

**Press conference** — LV04, Hearing at the Committee on the Environment
(ST04, stage 2).
- [ ] Header counts "Question 1 of 5" (or whatever the stage's own
  `turn_limit` is) — never a number bigger than the turn count.
- [ ] The reporter asking is a journalist, never an MP.
- [ ] Play through all the questions without reaching the threshold: it
  reads as a loss, with loss penalties, and the level still continues
  (Loss Ends Level = No).
- [ ] Play through and reach the threshold: reads as a win.

**Survival (TV debate)** — LV05, Media Rounds (ST06, stage 2).
- [ ] Falling below the threshold on any turn (not just at the very
  start) ends it immediately as a loss.
- [ ] Staying at or above it every turn through the whole clock wins.

## Non-combat

**Office Hours** — any level with an ST07 stage.
- [ ] The visitor's portrait, name/title and question all render with no
  overlap.
- [ ] All four choices are genuinely different text (not two identical
  ones) and the right answer's reward actually lands (check a meta number
  changed).

**Party Steering Committee check-in (ST22)** — only appears when Party
support falls below 25 mid-run. If you can force this
(`tools/stress_crisis_triggers.gd` or just spend recklessly): confirm the
Office shows a popup naming the trigger, and the inserted stage plays
like an ordinary Office Hours room.

## National Assembly Floor Voting

Any Floor Vote level (LV31-60) — pick one whose bill you haven't seen.
- [ ] All six party portraits, names (in their own party colour) and cue
  lines show — no empty card, no `<null>`.
- [ ] The bill's scroll text is readable, not truncated oddly.
- [ ] Cast a vote. The outcome panel's Yes/No/Abstain bars visually match
  the numbers in the text above them.
- [ ] It never offers a "you lost" framing — the close button always
  reads "On to the next stage" or "Back to the Office."
- [ ] Back in the Office, check the party you voted with/against moved
  the way the bill's favorability deltas say it should.

## Level Intro screen

Needs at least one row in the workbook's Level Intro Cues tab
(`design/LEVEL_INTRO_PROMPT.md`) naming a level you have a staffer hired
for.
- [ ] Starting that level shows the intro screen with the real staffer's
  portrait, name, and line before the first stage.
- [ ] Starting any level with nothing written skips straight to the first
  stage — no blank intermediate screen.
- [ ] Multiple hired roles with lines for the same level all speak, one
  after another.

## Office Management

- [ ] **Rhetoric Training**: buy a session. The card shown is genuinely
  random and not one you already own. Pass twice (counter reads 1/3,
  2/3, 3/3) and confirm the third card has no Pass button and the pop-up
  can't be backed out of. Learn it — the card is added and the price is
  actually deducted.
  - Also start the app, open a draw, and quit without finishing it —
    reopening should show the same card, same count, not a new draw.
- [ ] **Supplies**: buy a stacking consumable (Coffee) six times — the
  sixth purchase should refuse once you hold 5, unless it has its own
  higher cap.
- [ ] **Staff**: hire, upgrade, fire — costs and refusals read right.
- [ ] **Backing**: buy a modifier, confirm its effect actually shows up
  in a battle afterward.
- [ ] **Your deck**: swap a card in and out, confirm the count and the
  swapped card both reflect in the next battle.

## Crisis triggers

Force each one (spend down / play badly, or use
`tools/stress_crisis_triggers.gd` as a reference for what "forced" looks
like) and confirm:
- [ ] Jiban ≤ 15 inserts a Town Hall; a popup on your next Office visit
  says so.
- [ ] Party support < 25 inserts the Steering Committee check-in.
- [ ] Party support = 0 freezes Funds income; a popup says so, and Funds
  after a win genuinely doesn't move until it clears.
- [ ] Each trigger fires its "left" popup once you're back out, and does
  NOT fire a second "entered" popup while still inside the same episode.

## Save / load

- [ ] Quit mid-Office (not mid-stage) and relaunch: you're back exactly
  where you left off, all meta numbers intact.
- [ ] Quit mid-stage: reopening restarts that stage fresh (documented
  behavior, not a bug) rather than crashing or resuming a half-played
  battle.
- [ ] Quit with a Rhetoric Training draw on screen: reopening shows the
  same card (see above).

## General, every screen

- [ ] Nothing shows the literal text `<null>` anywhere.
- [ ] No text runs off the right edge of the screen or overlaps another
  label — check any screen with a long real name/title, not just the
  defaults.
- [ ] Every overlay you can open has a way to close it (this is also
  `click_test.tscn`'s job, but worth a human glance).
