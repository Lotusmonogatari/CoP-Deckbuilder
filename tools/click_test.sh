#!/usr/bin/env bash
# Runs just the real-click tests you name, the way tools/verify.sh runs them (invisible screen, its own save folder,
# the same switches), so you can check the area you changed without the whole 15 to 18 minute run.
#
#   tools/click_test.sh hand_input_test aspect_matrix_test
#   tools/click_test.sh hand_input aspect_matrix        ("_test" may be left off)
#   tools/click_test.sh --list                          every click test there is
#
# Prints "ok <name>" or "FAILED <name>" (with the end of its log) and exits non-zero if any failed. The full
# tools/verify.sh is still the gate before a merge; this is for working.
set -uo pipefail
export COP_NO_RANDOM_EVENTS=1 COP_NO_CONTINUE_DELAY=1 COP_NO_TRAVEL_FADE=1
cd "$(dirname "${BASH_SOURCE[0]}")/.."
GODOT="${GODOT:-.tools/godot}"
[ -x "$GODOT" ] || GODOT="godot"
if [ "${1:-}" = "--list" ] || [ $# -eq 0 ]; then
  ls tests/interaction/*_test.tscn | xargs -n1 basename | sed 's/\.tscn$//'
  exit 0
fi
status=0
for arg in "$@"; do
  name="${arg%.tscn}"
  case "$name" in *_test) ;; *) name="${name}_test" ;; esac
  scene="tests/interaction/${name}.tscn"
  if [ ! -f "$scene" ]; then echo "FAILED $name (no such click test; try --list)"; status=1; continue; fi
  dir="$(mktemp -d)"
  if XDG_DATA_HOME="$dir" xvfb-run -a --server-args="-screen 0 1080x2340x24" "$GODOT" --path . "$scene" > "$dir/log.txt" 2>&1; then
    echo "ok $name"
  else
    echo "FAILED $name"; tail -30 "$dir/log.txt"; status=1
  fi
done
exit $status
