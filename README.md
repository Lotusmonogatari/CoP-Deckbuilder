# The web build: what it is, and what it is not

This folder is a browser copy of the game used for playtesting. Open
`index.html`, or use the published link.

## It is the rules, mirrored exactly

`web/src/engine.js` is a hand-port of `scripts/rules/`. Every rule the Godot
engine applies, this one applies the same way and reaches the same numbers.

The browser page runs shared rules assertions and prints a parity summary at
the bottom:

If the summary reports a mismatch, investigate the two implementations before
using the browser build for balance conclusions.

So: a change to `scripts/rules/` is mirrored here in the same commit, and the
count goes up when tests are added, never down.

## It is not the presentation

**The rules are mirrored; the presentation is Godot-only.**

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
