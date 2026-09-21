# The web build: what it is, and what it is not

This folder is a browser copy of the game used for playtesting. Open
`index.html`, or use the published link.

## It is the rules, mirrored exactly

`web/src/engine.js` is a hand-port of `scripts/rules/`. Every rule the Godot
engine applies, this one applies the same way and reaches the same numbers.

That is not a hope, it is checked. `web/src/tests.js` re-runs the assertions
from the GUT suite in the page and prints a line at the bottom:

    148 of 148 agree with the Godot engine

If that line ever reads anything else, the two engines have drifted and one
of them is wrong. **Fix the drift before doing anything else.** It is the only
thing standing between "the playtest told us the committee is too hard" and
"the playtest was playing a different game".

So: a change to `scripts/rules/` is mirrored here in the same commit, and the
count goes up when tests are added, never down.

## It is not the presentation

Cameron decided on 2026-09-21: **the rules are mirrored, the presentation is
Godot-only.**

Portrait expressions, sound, music, spoken lines, card animations, the shoji
frames, screen layout — none of these are copied here and none of them should
be. The page needs to be playable and honest about the numbers. It does not
need to be pretty, and every hour spent making it pretty is an hour not spent
on the game that actually ships to a phone.

If you find yourself about to port an animation into this folder, this
paragraph is here to stop you.

## Which is which

| Lives in Godot only | Mirrored in both |
|---|---|
| `scripts/ui/`, `scenes/`, `theme/`, `assets/` | `scripts/rules/` ↔ `web/src/engine.js` |
| Audio, expressions, animation, layout | Card maths, affinity, guard, gaffes, intents, win and loss |
| — | `data/*.json`, which both read |

## Running the check

Open the page and scroll to the bottom, or run the whole project's checks
with `tools/verify.sh`, which covers the Godot side.
