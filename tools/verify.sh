#!/usr/bin/env bash
# Checks the whole project in one go. Run this before committing.
#
#   tools/verify.sh           everything (about 2 to 3 minutes)
#   tools/verify.sh --quick   data, boot and unit tests only (about 1 minute)
#   JOBS=2 tools/verify.sh    how many real-click tests run at once (default 4)
#
# It does four things:
#   1. Re-exports the workbook and validates every cross-reference in it.
#   2. Boots the game and confirms the data, font and art loaders all work, and
#      that every script in scripts/, tools/ and tests/ compiles.
#   3. Runs the unit tests (tests/, every folder).
#   4. Clicks the buttons, for real, to prove no screen can trap the player.
#      Every tests/interaction/*_test.tscn is found and run by itself, so a new
#      click test needs no edit here. They run in parallel, each with its own
#      invisible screen and its own save folder so none can touch another's save.
#
# Exits non-zero if any of them fail, so it can be wired into a build server.
set -uo pipefail
# Random events are chance pop-ups; the real-click tests switch them off (GameState.roll_random_event).
export COP_NO_RANDOM_EVENTS=1

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1
JOBS="${JOBS:-4}"

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

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
failures=0

step() {
  echo
  echo "--------------------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------------------"
}

fail() {
  echo ">> FAILED: $1"
  failures=$((failures + 1))
}

step "1/4  Exporting the workbook and checking the data"
python3 tools/export_data.py || fail "the workbook has errors in it."
# Excel's "repair" prompt on opening the workbook comes from broken formula records.
python3 tools/workbook/check_formulas.py || fail "the workbook has formula records Excel would repair."

# A new class_name script is only known to the project once Godot has scanned it.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

step "2/4  Booting the game"
# The boot check scene is named explicitly: the main scene is the battle, and
# running that here would silently stop checking the data and the font.
"$GODOT" --headless --path . scenes/menus/BootCheck.tscn --quit-after 3 || fail "the game did not start cleanly."

# Every script under scripts/, tools/ and tests/ must compile, so a removed
# constant in a tool nobody runs daily still fails the build (2026-10-29).
"$GODOT" --headless --path . tools/compile_check.tscn || fail "a script does not compile (see DID NOT LOAD above)."

# The click tests need a screen (xvfb gives an invisible one). Start them now,
# in the background, so they overlap with the unit tests below.
click_pid=""
if [ "$QUICK" -eq 0 ]; then
  if command -v xvfb-run >/dev/null 2>&1; then
    (
      # One line per test: its name, and ok or FAILED. Each gets its own user
      # data folder (XDG_DATA_HOME), so parallel saves cannot collide.
      ls tests/interaction/*_test.tscn | xargs -P "$JOBS" -I{} bash -c '
        name=$(basename "$1" .tscn)
        dir="$2/$name"; mkdir -p "$dir"
        if XDG_DATA_HOME="$dir" xvfb-run -a --server-args="-screen 0 1080x2340x24" \
              "$3" --path . "$1" > "$dir/log.txt" 2>&1; then
          echo "ok $name" >> "$2/results.txt"
        else
          echo "FAILED $name" >> "$2/results.txt"
        fi' _ {} "$WORK" "$GODOT"
    ) &
    click_pid=$!
  else
    echo ">> SKIPPED: xvfb-run is not installed, so buttons will not be clicked."
    echo "   On Debian or Ubuntu: sudo apt-get install xvfb"
  fi
fi

step "3/4  Running the unit tests"
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests -ginclude_subdirs -gexit || fail "one or more tests did not pass."

if [ -n "$click_pid" ]; then
  step "4/4  Clicking every button that has to be clickable"
  wait "$click_pid"
  while read -r status name; do
    echo "  $status  $name"
    if [ "$status" = "FAILED" ]; then
      fail "$name did not work with real clicks. Its log:"
      tail -40 "$WORK/$name/log.txt"
    fi
  done < <(sort -k2 "$WORK/results.txt" 2>/dev/null)
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
