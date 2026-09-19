#!/usr/bin/env bash
# Checks the whole project in one go. Run this before committing.
#
#   tools/verify.sh
#
# It does four things:
#   1. Re-exports the workbook and validates every cross-reference in it.
#   2. Boots the game and confirms the data, font and art loaders all work.
#   3. Runs the unit tests for the rules engine.
#   4. Clicks the buttons, for real, to prove no screen can trap the player.
#
# Exits non-zero if any of them fail, so it can be wired into a build server.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Use a locally downloaded Godot if there is one, otherwise whatever is on
# the PATH. tools/get_godot.sh puts one in .tools/.
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

step "1/4  Exporting the workbook and checking the data"
if ! python3 tools/export_data.py; then
  echo ">> FAILED: the workbook has errors in it."
  failures=$((failures + 1))
fi

step "2/4  Booting the game"
# The boot check scene is named explicitly rather than relying on whichever
# scene happens to be the main one. The main scene is the battle now, and
# running that here would silently stop checking the data and the font.
if ! "$GODOT" --headless --path . scenes/menus/BootCheck.tscn --quit-after 3; then
  echo ">> FAILED: the game did not start cleanly."
  failures=$((failures + 1))
fi

step "3/4  Running the rules engine tests"
if ! "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
      -gdir=res://tests -gexit; then
  echo ">> FAILED: one or more tests did not pass."
  failures=$((failures + 1))
fi

step "4/4  Clicking every button that has to be clickable"
# This one needs a screen, because the whole point is to click things for
# real rather than to call their code directly. xvfb provides an invisible
# one. Without it the check is skipped loudly rather than silently passing.
if command -v xvfb-run >/dev/null 2>&1; then
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/click_test.tscn; then
    echo ">> FAILED: an overlay could not be opened or closed with a real click."
    failures=$((failures + 1))
  fi

  # And that the whole loop is reachable: Office, the stages, back again.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/loop_test.tscn; then
    echo ">> FAILED: the Office-to-stages-to-Office loop is broken."
    failures=$((failures + 1))
  fi
else
  echo ">> SKIPPED: xvfb-run is not installed, so buttons were not clicked."
  echo "   On Debian or Ubuntu: sudo apt-get install xvfb"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "=============================================================="
  echo "  All checks passed."
  echo "=============================================================="
  exit 0
fi

echo "=============================================================="
echo "  $failures check(s) failed. See the output above."
echo "=============================================================="
exit 1
