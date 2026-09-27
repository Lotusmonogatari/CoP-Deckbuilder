#!/usr/bin/env bash
# Beats on the game rather than just proving it works. Run this before a
# release, or after touching BattleEngine.gd, GameState.gd, or Ledger.gd —
# not on every commit, and not part of tools/verify.sh: this takes minutes,
# verify.sh takes seconds, and the two answer different questions.
#
#   tools/stress.sh
#
# It does five things:
#   1. tools/playtest_optimal.gd once, played well (greedy) — the whole
#      real game, real data, now checked for rules-engine invariants
#      (card conservation, guard/gaffe/energy/bar bounds) after every
#      play_card()/end_turn(), not just "did the level get through."
#   2. The same tool four more times, played adversarially at random
#      (PLAYTEST_RANDOM_MOVES=1), once per protagonist — losing constantly
#      is expected and not a failure; only an invariant violation, a
#      crash, or a stuck stage is.
#   3. tools/stress_shop_items.gd (existing, unchanged).
#   4. tools/stress_crisis_triggers.gd (existing, unchanged).
#   5. tests/interaction/mash_test.gd — real rapid-fire clicks (End Turn
#      spam, double-tapped cards, double-submitted purchases/votes) rather
#      than the one-click-at-a-time proof tools/verify.sh already does.
#
# Any bug found by 1 or 2 names its own exact reproducer — a stage ID and
# a BattleEngine seed — since BattleEngine.setup()'s "seed" config key is
# the one thing that decides every random roll in a battle.
#
# Exits non-zero if anything failed, so it can be wired into a release
# checklist the same way tools/verify.sh is wired into every commit.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GODOT="${GODOT:-}"
if [ -z "$GODOT" ]; then
  if [ -x ".tools/godot" ]; then GODOT=".tools/godot"
  elif command -v godot >/dev/null 2>&1; then GODOT="godot"
  else
    echo "Cannot find Godot. Run tools/get_godot.sh, or set GODOT=/path/to/godot" >&2
    exit 1
  fi
fi

failures=0

step() {
  echo
  echo "--------------------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------------------"
}

step "1/5  Full playthrough, played well, invariants checked"
if ! "$GODOT" --headless --path . tools/playtest_optimal.tscn; then
  echo ">> FAILED: the greedy playthrough hit a bug or an invariant violation."
  failures=$((failures + 1))
fi

step "2/5  Full playthrough, played adversarially at random, one run per protagonist"
for pc in PC01 PC02 PC03 PC04; do
  echo
  echo "  -- $pc --"
  if ! PLAYTEST_RANDOM_MOVES=1 PLAYTEST_PROTAGONIST="$pc" \
        "$GODOT" --headless --path . tools/playtest_optimal.tscn; then
    echo ">> FAILED: the random-move playthrough as $pc hit a bug or an invariant violation."
    failures=$((failures + 1))
  fi
done

step "3/5  Fuzzing the shop/Rhetoric Training purchase effects"
if ! "$GODOT" --headless --path . tools/stress_shop_items.tscn; then
  echo ">> FAILED: tools/stress_shop_items.gd found a problem."
  failures=$((failures + 1))
fi

step "4/5  Fuzzing the four crisis triggers"
if ! "$GODOT" --headless --path . tools/stress_crisis_triggers.tscn; then
  echo ">> FAILED: tools/stress_crisis_triggers.gd found a problem."
  failures=$((failures + 1))
fi

step "5/5  Mashing buttons: rapid-fire real clicks, not one at a time"
if command -v xvfb-run >/dev/null 2>&1; then
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/mash_test.tscn; then
    echo ">> FAILED: rapid-fire input caused a double effect or stuck the UI."
    failures=$((failures + 1))
  fi
else
  echo ">> SKIPPED: xvfb-run is not installed, so buttons were not mashed."
  echo "   On Debian or Ubuntu: sudo apt-get install xvfb"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "=============================================================="
  echo "  All stress checks passed."
  echo "=============================================================="
  exit 0
fi

echo "=============================================================="
echo "  $failures stress check(s) failed. See the output above."
echo "=============================================================="
exit 1
