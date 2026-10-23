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
# Random events are chance pop-ups; the real-click tests switch them off (GameState.roll_random_event).
export COP_NO_RANDOM_EVENTS=1

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

# A new class_name script is only known to the project once Godot has
# scanned it; without this a fresh class fails to resolve (2026-10-14).
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

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

  # And the inventory: buy in Supplies, use in the Office, use mid-stage.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/inventory_test.tscn; then
    echo ">> FAILED: an item could not be bought or used with real clicks."
    failures=$((failures + 1))
  fi

  # And New Game: the first-launch picker, and starting over.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/new_game_test.tscn; then
    echo ">> FAILED: a protagonist could not be chosen with real clicks."
    failures=$((failures + 1))
  fi

  # And Office Hours: a multiple-choice visitor room, answered for real.
  # Existed as a file but was never actually run here until 2026-09-28.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/office_hours_test.tscn; then
    echo ">> FAILED: an Office Hours visitor could not be answered with real clicks."
    failures=$((failures + 1))
  fi

  # And the Supplies/Rhetoric Training purchases (SH13-29): same story,
  # existed but was never run here until 2026-09-28.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/shop_items_test.tscn; then
    echo ">> FAILED: a Supplies or Rhetoric Training purchase failed with real clicks."
    failures=$((failures + 1))
  fi

  # And National Assembly Floor Voting (ST23) — 2026-09-28, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/floor_vote_test.tscn; then
    echo ">> FAILED: the Floor Vote screen did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the member visit (influence building step B, 2026-10-19).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/visit_test.tscn; then
    echo ">> FAILED: the member visit did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the lobbyist trade (influence building step C, 2026-10-19).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/trade_test.tscn; then
    echo ">> FAILED: the lobbyist trade did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the Level Intro screen — 2026-09-28, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/level_intro_test.tscn; then
    echo ">> FAILED: the Level Intro screen did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the Stage Transition screen against real data -- 2026-10-13, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/stage_transition_test.tscn; then
    echo ">> FAILED: the Stage Transition screen did not work with real data and clicks."
    failures=$((failures + 1))
  fi

  # And the listening strip: preview marks, Read -- 2026-10-18, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/org_preview_test.tscn; then
    echo ">> FAILED: the organization preview did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And whipping the vote: the Whip row, the priced vote button, the spend -- 2026-10-22, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/whip_test.tscn; then
    echo ">> FAILED: whipping the vote did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the week: the calendar square, ending the work week, the weekend, going home -- 2026-10-23, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/week_test.tscn; then
    echo ">> FAILED: the week calendar did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And hosting: a dinner's three screens, the guests' reactions and the result -- 2026-10-23, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/hosted_test.tscn; then
    echo ">> FAILED: hosting a dinner did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And events: the Events list, arranging one, choosing, a level an event reveals -- 2026-10-23, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/event_test.tscn; then
    echo ">> FAILED: events did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the discard step for cards that cost a discard -- 2026-10-21, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/discard_test.tscn; then
    echo ">> FAILED: the discard step did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And special levels: the Special Levels block and the forced-in panel --
  # 2026-10-18, new (game clock, step 2).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/special_levels_test.tscn; then
    echo ">> FAILED: special levels did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And patron requests: the Requests block, the Request panel, Amend,
  # Decline and Accept -- 2026-10-19, new (patron step 4).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/requests_test.tscn; then
    echo ">> FAILED: patron requests did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And Draft a Bill: pick parts, preview, draft, start the level --
  # 2026-10-19, new (patron step 7).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/draft_test.tscn; then
    echo ">> FAILED: Draft a Bill did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And every screen shape at phone and tablet sizes: nothing runs off the
  # sides or the bottom -- 2026-10-14, new (dynamic screens plan, step 2).
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/aspect_matrix_test.tscn; then
    echo ">> FAILED: a screen runs off the edge at some screen size."
    failures=$((failures + 1))
  fi

  # And Cosmetic Packages: buy one, equip and un-equip it per slot — 2026-09-28, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/cosmetics_test.tscn; then
    echo ">> FAILED: a cosmetic package could not be bought or equipped with real clicks."
    failures=$((failures + 1))
  fi

  # And the How to Play guide, from the title screen and from the Office — 2026-10-06, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/how_to_play_test.tscn; then
    echo ">> FAILED: the How to Play guide did not open with real clicks."
    failures=$((failures + 1))
  fi

  # And the Office's two intermediary menus — 2026-10-06, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/office_menus_test.tscn; then
    echo ">> FAILED: the Office menus (Reputation and Results, Administration) did not work with real clicks."
    failures=$((failures + 1))
  fi

  # And the Staff Profile — 2026-10-07, new.
  if ! xvfb-run -a --server-args="-screen 0 1080x2340x24" \
        "$GODOT" --path . tests/interaction/staff_profile_test.tscn; then
    echo ">> FAILED: the Staff Profile (tiers, Hire, Upgrade, Fire) did not work with real clicks."
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
