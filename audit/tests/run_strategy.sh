#!/usr/bin/env bash
# Audit Phase 4: campaign-length runs with the project's own strategy bot
# (tools/strategy_playtest.gd, read-only use). Each run is seeded and gets its
# own save folder so parallel runs cannot touch each other's save.
#   audit/tests/run_strategy.sh OUT.jsonl "seeds" "protagonists" "difficulty" strategy...
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-.tools/godot}"
out="$1"; seeds="$2"; pcs="$3"; diff="$4"; shift 4
strategies="$@"
if [ "$strategies" = "all" ]; then
  strategies=$(python3 - <<'PY'
import re
src=open('tools/strategy_playtest.gd').read()
block=src.split('const STRATEGIES := {')[1].split('\n}\n')[0]
print(' '.join(re.findall(r'^\t"(\w+)":',block,re.M)))
PY
)
fi
work="$(mktemp -d)"; mkdir -p "$out.parts"
for st in $strategies; do for pc in $pcs; do for sd in $seeds; do echo "$st $pc $sd"; done; done; done |
xargs -P "${JOBS:-4}" -L 1 bash -c '
  XDG_DATA_HOME='"$work"'/$0_$1_$2 PLAYTEST_STRATEGY=$0 PLAYTEST_PROTAGONIST=$1 PLAYTEST_SEED=$2 \
  PLAYTEST_WEEKS=${PLAYTEST_WEEKS:-30} PLAYTEST_DIFFICULTY='"$diff"' \
  PLAYTEST_OUT='"$out"'.parts/$0_$1_$2.json timeout 600 '"$GODOT"' --headless --path . tools/strategy_playtest.tscn > /dev/null 2>&1'
cat "$out".parts/*.json > "$out" 2>/dev/null; rm -rf "$out".parts "$work"
echo "wrote $(wc -l < "$out") runs to $out"
